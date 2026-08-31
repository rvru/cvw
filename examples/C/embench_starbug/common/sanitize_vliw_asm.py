#!/usr/bin/env python3
"""Trim verbose GCC comments from seeded VLIW assembly files."""

from __future__ import annotations

import argparse
from pathlib import Path

HEADER = [
    "# ==============================================================================",
    "# SECTION: Compiler Seed",
    "# PURPOSE: Shared GCC-generated baseline for manual Starbug VLIW scheduling.",
    "# NOTES: Re-run seed-vliw-asm to refresh, then edit bundles and hazards by hand.",
    "# ==============================================================================",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--source", required=True)
    parser.add_argument("--benchmarks", default="")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    input_path = Path(args.input)
    output_path = Path(args.output)
    source_name = Path(args.source).name

    raw_lines = input_path.read_text(encoding="utf-8", errors="replace").splitlines()

    cleaned_lines: list[str] = []
    pending_blank = False

    for line in raw_lines:
        if line.lstrip().startswith("#"):
            continue

        stripped = line.rstrip()
        if not stripped:
            if cleaned_lines:
                pending_blank = True
            continue

        if pending_blank:
            cleaned_lines.append("")
            pending_blank = False

        cleaned_lines.append(stripped)

    while cleaned_lines and cleaned_lines[-1] == "":
        cleaned_lines.pop()

    header_lines = HEADER + [f"# SOURCE: {source_name}"]
    if args.benchmarks:
        header_lines.append(f"# BENCHMARKS: {args.benchmarks}")

    final_lines = header_lines + [""] + cleaned_lines + [""]
    output_path.write_text("\n".join(final_lines), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
