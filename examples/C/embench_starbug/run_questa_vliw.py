#!/usr/bin/env python3
"""Build and run Embench Starbug benchmarks on Questa, one by one."""

from __future__ import annotations

import argparse
import math
import os
import re
import shutil
import subprocess
import sys
import time
from collections.abc import Iterable
from dataclasses import dataclass
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
WALLY_ROOT = SCRIPT_DIR.parents[2]
DEFAULT_CONFIGS = ("rv32gc", "starbug")
DEFAULT_SCALAR_CONFIG = "rv32gc"
PASS_TOKEN = "TEST PASS"
FAIL_TOKEN = "TEST FAIL"
ANSI_GREEN = "\033[32m"
ANSI_RED = "\033[31m"
ANSI_YELLOW = "\033[33m"
ANSI_BLUE = "\033[34m"
ANSI_RESET = "\033[0m"
ELF_SUFFIX_BY_TARGET = {
    "scalar-wally": "scalar_wally",
    "empty-wally": "empty_wally",
    "vliw-wally": "vliw_wally",
    "starbug-compile": "starbug",
    "empty-starbug": "empty_starbug",
}


@dataclass
class CommandResult:
    command: list[str]
    returncode: int
    output: str


@dataclass
class SimResult:
    benchmark: str
    variant: str
    config: str
    passed: bool
    warning: str
    log_path: Path
    elf_path: Path
    elf_size: ElfSizeInfo | None
    ccnt: int | None
    sim_time_ns: int | None


@dataclass(frozen=True)
class SimJob:
    variant: str
    build_target: str
    configs: tuple[str, ...]


@dataclass(frozen=True)
class SpeedupComparison:
    benchmark: str
    baseline_value: int
    contender_value: int
    unit: str
    speedup: float
    reduction_pct: float
    baseline_size: ElfSizeInfo | None
    contender_size: ElfSizeInfo | None


@dataclass(frozen=True)
class ElfSizeInfo:
    file_bytes: int
    alloc_total: int
    text: int
    rodata: int
    data: int
    bss: int
    other_alloc: int


def colorize(text: str, color: str) -> str:
    if os.environ.get("NO_COLOR"):
        return text
    return f"{color}{text}{ANSI_RESET}"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build each Embench Starbug benchmark and run it on Questa."
    )
    parser.add_argument(
        "--bench",
        action="append",
        default=[],
        help="Benchmark directory name to run. May be repeated.",
    )
    parser.add_argument(
        "--configs",
        default=",".join(DEFAULT_CONFIGS),
        help="Comma-separated config list. Default: rv32gc,starbug",
    )
    parser.add_argument(
        "--build-target",
        default="",
        help="Optional single make target to run instead of the default scalar/vliw matrix.",
    )
    parser.add_argument(
        "--log-dir",
        default=str(SCRIPT_DIR / "logs" / "questa_vliw"),
        help="Directory where per-run logs are written.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print commands without executing them.",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Print full build and simulator output as commands run.",
    )
    return parser.parse_args()


def default_jobs(vliw_configs: Iterable[str]) -> list[SimJob]:
    return [
        SimJob(variant="scalar", build_target="scalar-wally", configs=(DEFAULT_SCALAR_CONFIG,)),
        SimJob(variant="vliw", build_target="vliw-wally", configs=tuple(vliw_configs)),
    ]


def jobs_from_args(args: argparse.Namespace, vliw_configs: list[str]) -> list[SimJob]:
    if args.build_target:
        return [
            SimJob(
                variant=args.build_target.replace("-wally", "").replace("-", "_"),
                build_target=args.build_target,
                configs=tuple(vliw_configs),
            )
        ]
    return default_jobs(vliw_configs)


def benchmark_dirs(requested: Iterable[str]) -> list[Path]:
    if requested:
        benches = [SCRIPT_DIR / name for name in requested]
    else:
        # A benchmark directory is one with a Makefile. Testing for "any
        # directory that is not common/" also picked up logs/ and
        # presentation_assets/, which then failed to build on every run.
        benches = sorted(
            path
            for path in SCRIPT_DIR.iterdir()
            if path.is_dir()
            and path.name != "common"
            and not path.name.startswith(".")
            and (path / "Makefile").is_file()
        )
    missing = [path.name for path in benches if not path.is_dir()]
    if missing:
        raise SystemExit(f"Unknown benchmark directory(s): {', '.join(sorted(missing))}")
    return benches


def run_command(
    command: list[str],
    *,
    cwd: Path,
    env: dict[str, str],
    dry_run: bool,
    verbose: bool,
) -> CommandResult:
    pretty = " ".join(command)
    if dry_run or verbose:
        print(f"$ (cd {cwd} && {pretty})")
    if dry_run:
        return CommandResult(command=command, returncode=0, output="")
    completed = subprocess.run(
        command,
        cwd=cwd,
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        errors="replace",
    )
    if verbose and completed.stdout:
        print(completed.stdout, end="" if completed.stdout.endswith("\n") else "\n")
    return CommandResult(
        command=command,
        returncode=completed.returncode,
        output=completed.stdout,
    )


def build_benchmark(
    bench_dir: Path,
    build_target: str,
    *,
    env: dict[str, str],
    dry_run: bool,
    verbose: bool,
) -> CommandResult:
    return run_command(
        ["make", build_target],
        cwd=bench_dir,
        env=env,
        dry_run=dry_run,
        verbose=verbose,
    )


def extract_sim_time_ns(output: str) -> int | None:
    stop_match = re.search(
        r"\*\* Note: \$stop.*?\n#\s+Time:\s*([0-9]+)\s*ns",
        output,
        re.DOTALL,
    )
    if stop_match:
        return int(stop_match.group(1))

    matches = re.findall(r"Time:\s*([0-9]+)\s*ns", output)
    return int(matches[-1]) if matches else None


def extract_ccnt(output: str) -> int | None:
    match = re.search(r"CCNT\s*=\s*([0-9]+)", output)
    return int(match.group(1)) if match else None


def find_first_tool(candidates: Iterable[str]) -> str | None:
    for candidate in candidates:
        resolved = shutil.which(candidate)
        if resolved:
            return resolved
    return None


def capture_tool_output(command: list[str], *, cwd: Path, env: dict[str, str]) -> str | None:
    completed = subprocess.run(
        command,
        cwd=cwd,
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        errors="replace",
    )
    if completed.returncode != 0:
        return None
    return completed.stdout


def extract_alloc_sections_from_objdump(
    elf_path: Path, *, cwd: Path, env: dict[str, str]
) -> dict[str, int] | None:
    objdump_tool = find_first_tool(
        ("riscv64-unknown-elf-objdump", "llvm-objdump", "objdump")
    )
    if objdump_tool is None:
        return None

    output = capture_tool_output([objdump_tool, "-h", str(elf_path)], cwd=cwd, env=env)
    if output is None:
        return None

    sections: dict[str, int] = {}
    pending_name: str | None = None
    pending_size = 0
    header_re = re.compile(r"^\s*\d+\s+(\S+)\s+([0-9A-Fa-f]+)\s+")
    for line in output.splitlines():
        match = header_re.match(line)
        if match:
            pending_name = match.group(1)
            pending_size = int(match.group(2), 16)
            continue
        if pending_name is None:
            continue
        flags = line.strip()
        if flags:
            if "ALLOC" in flags:
                sections[pending_name] = sections.get(pending_name, 0) + pending_size
            pending_name = None
            pending_size = 0

    return sections or None


def extract_alloc_sections_from_size(
    elf_path: Path, *, cwd: Path, env: dict[str, str]
) -> dict[str, int] | None:
    size_tool = find_first_tool(("riscv64-unknown-elf-size", "llvm-size", "size"))
    if size_tool is None:
        return None

    output = capture_tool_output([size_tool, "-A", "-d", str(elf_path)], cwd=cwd, env=env)
    if output is None:
        return None

    skip_prefixes = (
        ".debug",
        ".comment",
        ".note",
        ".strtab",
        ".symtab",
        ".shstrtab",
        ".stab",
        ".line",
    )
    skip_exact = {".riscv.attributes"}
    sections: dict[str, int] = {}
    for line in output.splitlines():
        parts = line.split()
        if len(parts) < 2:
            continue
        section_name = parts[0]
        if section_name in {"section", "filename", "Total"}:
            continue
        if section_name.startswith(skip_prefixes) or section_name in skip_exact:
            continue
        try:
            section_size = int(parts[1], 0)
        except ValueError:
            continue
        sections[section_name] = sections.get(section_name, 0) + section_size

    return sections or None


def summarize_elf_size(elf_path: Path, sections: dict[str, int]) -> ElfSizeInfo:
    rodata = sections.get(".rodata", 0) + sections.get(".srodata", 0)
    data = sections.get(".data", 0) + sections.get(".sdata", 0) + sections.get(".tdata", 0)
    bss = sections.get(".bss", 0) + sections.get(".sbss", 0) + sections.get(".tbss", 0)
    text = sections.get(".text", 0) + sections.get(".init", 0) + sections.get(".fini", 0)
    alloc_total = sum(sections.values())
    other_alloc = alloc_total - text - rodata - data - bss
    return ElfSizeInfo(
        file_bytes=elf_path.stat().st_size,
        alloc_total=alloc_total,
        text=text,
        rodata=rodata,
        data=data,
        bss=bss,
        other_alloc=other_alloc,
    )


def analyze_elf_size(elf_path: Path, *, cwd: Path, env: dict[str, str]) -> ElfSizeInfo | None:
    if not elf_path.is_file():
        return None

    sections = extract_alloc_sections_from_objdump(elf_path, cwd=cwd, env=env)
    if sections is None:
        sections = extract_alloc_sections_from_size(elf_path, cwd=cwd, env=env)
    if sections is None:
        return None

    return summarize_elf_size(elf_path, sections)


def comparable_metric_pair(
    baseline: SimResult, contender: SimResult
) -> tuple[int, int, str] | None:
    if baseline.ccnt is not None and contender.ccnt is not None:
        return baseline.ccnt, contender.ccnt, "cyc"
    if baseline.sim_time_ns is not None and contender.sim_time_ns is not None:
        return baseline.sim_time_ns, contender.sim_time_ns, "ns"
    return None


def collect_starbug_scalar_speedups(results: list[SimResult]) -> list[SpeedupComparison]:
    results_by_key = {
        (result.benchmark, result.variant, result.config): result
        for result in results
        if result.passed
    }

    comparisons: list[SpeedupComparison] = []
    for benchmark in sorted({result.benchmark for result in results}):
        scalar = results_by_key.get((benchmark, "scalar", DEFAULT_SCALAR_CONFIG))
        starbug = results_by_key.get((benchmark, "vliw", "starbug"))
        if scalar is None or starbug is None:
            continue

        metric_pair = comparable_metric_pair(scalar, starbug)
        if metric_pair is None:
            continue

        baseline_value, contender_value, unit = metric_pair
        if baseline_value <= 0 or contender_value <= 0:
            continue

        speedup = baseline_value / contender_value
        reduction_pct = (1.0 - (contender_value / baseline_value)) * 100.0
        comparisons.append(
            SpeedupComparison(
                benchmark=benchmark,
                baseline_value=baseline_value,
                contender_value=contender_value,
                unit=unit,
                speedup=speedup,
                reduction_pct=reduction_pct,
                baseline_size=scalar.elf_size,
                contender_size=starbug.elf_size,
            )
        )

    return comparisons


def format_size_bytes(value: int | None) -> str:
    if value is None:
        return "n/a"
    return f"{value} B"


def format_signed_bytes(value: int | None) -> str:
    if value is None:
        return "n/a"
    return f"{value:+d} B"


def run_sim(
    bench_dir: Path,
    variant: str,
    elf_path: Path,
    elf_size: ElfSizeInfo | None,
    config: str,
    log_dir: Path,
    *,
    env: dict[str, str],
    dry_run: bool,
    verbose: bool,
) -> SimResult:
    wsim = Path(env["WALLY"]) / "bin" / "wsim"
    command = [str(wsim), "--sim", "questa", config, "--elf", str(elf_path)]
    result = run_command(
        command, cwd=bench_dir, env=env, dry_run=dry_run, verbose=verbose
    )

    log_path = log_dir / bench_dir.name / f"{variant}_{config}.log"
    if not dry_run:
        log_path.parent.mkdir(parents=True, exist_ok=True)
        log_path.write_text(result.output, encoding="utf-8")

    if dry_run:
        return SimResult(
            benchmark=bench_dir.name,
            variant=variant,
            config=config,
            passed=True,
            warning="dry-run",
            log_path=log_path,
            elf_path=elf_path,
            elf_size=elf_size,
            ccnt=None,
            sim_time_ns=None,
        )

    passed = PASS_TOKEN in result.output and FAIL_TOKEN not in result.output
    warning_parts = []
    ccnt = extract_ccnt(result.output)
    sim_time_ns = extract_sim_time_ns(result.output)
    if "Aborted (core dumped)" in result.output:
        warning_parts.append("objdump/memfile helper aborted")
    if "Errors: 0, Warnings:" in result.output:
        warning_parts.append("questa reported warnings")
    if result.returncode != 0:
        warning_parts.append(f"wsim exited with {result.returncode}")
    if not passed and PASS_TOKEN not in result.output:
        warning_parts.append("missing TEST PASS")
    if passed and ccnt is None:
        warning_parts.append("missing CCNT")

    return SimResult(
        benchmark=bench_dir.name,
        variant=variant,
        config=config,
        passed=passed,
        warning=", ".join(warning_parts),
        log_path=log_path,
        elf_path=elf_path,
        elf_size=elf_size,
        ccnt=ccnt,
        sim_time_ns=sim_time_ns,
    )


def print_summary(results: list[SimResult], total_planned: int) -> None:
    print("\nSummary")
    print("-------")
    for result in results:
        status = colorize("PASS", ANSI_GREEN) if result.passed else colorize("FAIL", ANSI_RED)
        timing = f"{result.ccnt} cyc" if result.ccnt is not None else "n/a"
        line = (
            f"{status:4}  {result.benchmark:32}  {result.variant:6}  "
            f"{result.config:8}  {timing:>12}  {result.log_path}"
        )
        if result.sim_time_ns is not None:
            line += f"  [sim {result.sim_time_ns} ns]"
        if result.warning:
            line += f"  [{colorize(result.warning, ANSI_YELLOW)}]"
        print(line)

    passed_tests = sum(1 for result in results if result.passed)
    print(f"\nTests Passed: {passed_tests}/{total_planned}")
    if len(results) != total_planned:
        print(f"Runs Completed: {len(results)}/{total_planned}")

    size_results = [result for result in results if result.elf_size is not None]
    if size_results:
        print("\nELF Size")
        print("--------")
        print(
            f"{'Benchmark':32}  {'Variant':6}  {'Config':8}  "
            f"{'File':>10}  {'Alloc':>10}  {'Text':>10}  {'Rodata':>10}  "
            f"{'Data':>10}  {'Bss':>10}  {'Other':>10}"
        )
        for result in size_results:
            assert result.elf_size is not None
            size = result.elf_size
            print(
                f"{result.benchmark:32}  {result.variant:6}  {result.config:8}  "
                f"{size.file_bytes:10d}  {size.alloc_total:10d}  {size.text:10d}  "
                f"{size.rodata:10d}  {size.data:10d}  {size.bss:10d}  {size.other_alloc:10d}"
            )

    comparisons = collect_starbug_scalar_speedups(results)
    if not comparisons:
        return

    print("\nStarbug Over Scalar")
    print("-------------------")
    print(
        f"{'Benchmark':32}  {'Kernel':>20}  {'Speedup':>8}  {'Alloc Δ':>12}  "
        f"{'Text Δ':>12}  {'Rodata Δ':>12}  {'Data Δ':>12}  {'Bss Δ':>12}"
    )
    for comparison in comparisons:
        alloc_delta = None
        text_delta = None
        rodata_delta = None
        data_delta = None
        bss_delta = None
        if comparison.baseline_size is not None and comparison.contender_size is not None:
            alloc_delta = comparison.contender_size.alloc_total - comparison.baseline_size.alloc_total
            text_delta = comparison.contender_size.text - comparison.baseline_size.text
            rodata_delta = comparison.contender_size.rodata - comparison.baseline_size.rodata
            data_delta = comparison.contender_size.data - comparison.baseline_size.data
            bss_delta = comparison.contender_size.bss - comparison.baseline_size.bss
        print(
            f"{comparison.benchmark:32}  "
            f"{comparison.baseline_value:9} -> {comparison.contender_value:8} {comparison.unit:3}  "
            f"{comparison.speedup:6.3f}x  "
            f"{format_signed_bytes(alloc_delta):>12}  "
            f"{format_signed_bytes(text_delta):>12}  "
            f"{format_signed_bytes(rodata_delta):>12}  "
            f"{format_signed_bytes(data_delta):>12}  "
            f"{format_signed_bytes(bss_delta):>12}"
        )

    geomean_speedup = math.exp(
        sum(math.log(comparison.speedup) for comparison in comparisons) / len(comparisons)
    )
    mean_speedup = sum(comparison.speedup for comparison in comparisons) / len(comparisons)
    mean_reduction_pct = (
        sum(comparison.reduction_pct for comparison in comparisons) / len(comparisons)
    )
    total_baseline = sum(comparison.baseline_value for comparison in comparisons)
    total_contender = sum(comparison.contender_value for comparison in comparisons)
    overall_speedup = total_baseline / total_contender
    overall_reduction_pct = (1.0 - (total_contender / total_baseline)) * 100.0

    print("\nSpeedup Stats")
    print("-------------")
    print(f"Compared Benchmarks: {len(comparisons)}")
    print(f"Geomean Speedup:   {geomean_speedup:.3f}x")
    print(f"Mean Speedup:      {mean_speedup:.3f}x")
    print(f"Mean Reduction:    {mean_reduction_pct:.2f}%")
    print(f"Overall Speedup:   {overall_speedup:.3f}x")
    print(f"Overall Reduction: {overall_reduction_pct:.2f}%")

    size_comparisons = [
        comparison
        for comparison in comparisons
        if comparison.baseline_size is not None and comparison.contender_size is not None
    ]
    if not size_comparisons:
        return

    total_baseline_alloc = sum(
        comparison.baseline_size.alloc_total for comparison in size_comparisons
    )
    total_contender_alloc = sum(
        comparison.contender_size.alloc_total for comparison in size_comparisons
    )
    total_baseline_text = sum(comparison.baseline_size.text for comparison in size_comparisons)
    total_contender_text = sum(comparison.contender_size.text for comparison in size_comparisons)
    total_baseline_rodata = sum(
        comparison.baseline_size.rodata for comparison in size_comparisons
    )
    total_contender_rodata = sum(
        comparison.contender_size.rodata for comparison in size_comparisons
    )
    geomean_alloc_ratio = math.exp(
        sum(
            math.log(comparison.contender_size.alloc_total / comparison.baseline_size.alloc_total)
            for comparison in size_comparisons
            if comparison.baseline_size.alloc_total > 0 and comparison.contender_size.alloc_total > 0
        )
        / len(size_comparisons)
    )

    print("\nSize Stats")
    print("----------")
    print(f"Compared Benchmarks:  {len(size_comparisons)}")
    print(
        f"Overall Alloc Delta:  {format_signed_bytes(total_contender_alloc - total_baseline_alloc)}"
    )
    print(
        f"Overall Text Delta:   {format_signed_bytes(total_contender_text - total_baseline_text)}"
    )
    print(
        f"Overall Rodata Delta: {format_signed_bytes(total_contender_rodata - total_baseline_rodata)}"
    )
    print(f"Geomean Alloc Ratio:  {geomean_alloc_ratio:.3f}x of scalar")


def main() -> int:
    args = parse_args()
    vliw_configs = [config.strip() for config in args.configs.split(",") if config.strip()]
    if not vliw_configs:
        raise SystemExit("No configs selected.")
    jobs = jobs_from_args(args, vliw_configs)

    env = os.environ.copy()
    env.setdefault("WALLY", str(WALLY_ROOT))
    env["PATH"] = f"{Path(env['WALLY']) / 'bin'}:{env.get('PATH', '')}"

    benches = benchmark_dirs(args.bench)
    log_dir = Path(args.log_dir).resolve()
    total_planned = sum(len(job.configs) for _ in benches for job in jobs)

    sim_results: list[SimResult] = []
    failures: list[str] = []

    for bench_dir in benches:
        for job in jobs:
            build = build_benchmark(
                bench_dir,
                job.build_target,
                env=env,
                dry_run=args.dry_run,
                verbose=args.verbose,
            )
            if build.returncode != 0:
                failures.append(f"{bench_dir.name}/{job.variant}: build failed")
                if not args.dry_run:
                    build_log = log_dir / bench_dir.name / f"build_{job.variant}.log"
                    build_log.parent.mkdir(parents=True, exist_ok=True)
                    build_log.write_text(build.output, encoding="utf-8")
                print(
                    f"{colorize('FAIL', ANSI_RED):4}  {bench_dir.name:32}  {job.variant:6}  "
                    f"build     {colorize('build failed', ANSI_RED)}"
                )
                continue

            if not args.dry_run:
                build_log = log_dir / bench_dir.name / f"build_{job.variant}.log"
                build_log.parent.mkdir(parents=True, exist_ok=True)
                build_log.write_text(build.output, encoding="utf-8")

            elf_suffix = ELF_SUFFIX_BY_TARGET.get(
                job.build_target, job.build_target.replace("-", "_")
            )
            elf_path = bench_dir / f"{bench_dir.name}_{elf_suffix}.elf"
            if not args.dry_run and not elf_path.is_file():
                failures.append(f"{bench_dir.name}/{job.variant}: missing ELF {elf_path.name}")
                print(
                    f"{colorize('FAIL', ANSI_RED):4}  {bench_dir.name:32}  {job.variant:6}  "
                    f"build     {colorize('missing ELF', ANSI_RED)}"
                )
                continue

            elf_size = None if args.dry_run else analyze_elf_size(elf_path, cwd=bench_dir, env=env)

            for config in job.configs:
                result = run_sim(
                    bench_dir,
                    job.variant,
                    elf_path,
                    elf_size,
                    config,
                    log_dir,
                    env=env,
                    dry_run=args.dry_run,
                    verbose=args.verbose,
                )
                time.sleep(0.2) # give the simulator a chance to finish to avoid race conditions
                sim_results.append(result)
                status = colorize("PASS", ANSI_GREEN) if result.passed else colorize("FAIL", ANSI_RED)
                if result.ccnt is not None:
                    detail = colorize(f"{result.ccnt} cyc", ANSI_BLUE)
                elif result.sim_time_ns is not None:
                    detail = colorize(f"{result.sim_time_ns} ns", ANSI_BLUE)
                else:
                    detail = colorize("ok", ANSI_BLUE)
                if result.warning:
                    detail = f"{detail}  [{colorize(result.warning, ANSI_YELLOW)}]"
                print(
                    f"{status:4}  {bench_dir.name:32}  {job.variant:6}  {config:8}  {detail}"
                )
                if not result.passed:
                    failures.append(f"{bench_dir.name}/{job.variant}/{config}: simulation failed")

    print_summary(sim_results, total_planned)
    if failures:
        print("\nFailures")
        print("--------")
        for failure in failures:
            print(failure)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
