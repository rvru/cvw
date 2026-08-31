# Embench Starbug Check.out Summary

Source: `/Users/leomarek/mnt/remote/cvw/examples/C/embench_starbug/check.out`

## Headline Findings

- The real benchmark matrix completed at **30/30 passing runs** across **10 benchmarks**.
- The raw runner reported `30/33`, but that denominator was inflated because `logs/` was treated as a benchmark directory. The benchmark runs themselves are cleanly **30/30**.
- Relative to scalar, the VLIW ELF on baseline RV32GC achieves a **1.121x geomean speedup**.
- Relative to scalar, the same VLIW ELF on the Starbug config achieves a **1.404x geomean speedup**.
- On a cycle-weighted basis, the gains are **1.234x** for RV32GC VLIW over scalar and **1.531x** for Starbug over scalar.
- Starbug adds another **1.252x geomean speedup over RV32GC VLIW**, which shows the microarchitecture is helping on top of the software scheduling changes.
- The best Starbug result is **fir_f32_taps256_n128 at 1.917x**, and the only regression is **biquad_cascade_df2T_f32_sos3_n1 at 0.926x**.
- The VLIW ELF grows allocated footprint by **+19898 B total** across the suite, with a **1.057x geomean size ratio** vs scalar.

## Figures

- [starbug_vs_scalar_speedup.png](/Users/leomarek/mnt/remote/cvw/examples/C/embench_starbug/presentation_assets/figures/starbug_vs_scalar_speedup.png)
- [normalized_runtime_vs_scalar.png](/Users/leomarek/mnt/remote/cvw/examples/C/embench_starbug/presentation_assets/figures/normalized_runtime_vs_scalar.png)
- [vliw_alloc_delta_vs_scalar.png](/Users/leomarek/mnt/remote/cvw/examples/C/embench_starbug/presentation_assets/figures/vliw_alloc_delta_vs_scalar.png)
- [benchmark_summary.csv](/Users/leomarek/mnt/remote/cvw/examples/C/embench_starbug/presentation_assets/benchmark_summary.csv)

## Benchmark Table

| Benchmark | Scalar cyc | VLIW cyc (RV32GC) | Starbug cyc | VLIW speedup | Starbug speedup | Starbug over VLIW | Alloc delta | Text delta | Rodata delta |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| fir_f32_taps256_n128 | 233653 | 156130 | 121898 | 1.497x | 1.917x | 1.281x | +580 B | +580 B | +0 B |
| fir_f32_taps256_n1 | 3660 | 2458 | 2123 | 1.489x | 1.724x | 1.158x | +580 B | +580 B | +0 B |
| lms_f32_taps256_n128 | 497726 | 343021 | 295351 | 1.451x | 1.685x | 1.161x | +942 B | +942 B | +0 B |
| lms_f32_taps256_n1 | 5737 | 3963 | 3619 | 1.448x | 1.585x | 1.095x | +942 B | +942 B | +0 B |
| biquad_cascade_df2T_f32_sos3_n128 | 4635 | 4685 | 3079 | 0.989x | 1.505x | 1.522x | +264 B | +264 B | +0 B |
| dct4_2048_f32 | 304097 | 287066 | 228987 | 1.059x | 1.328x | 1.254x | +5596 B | +5596 B | +0 B |
| rfft2048_f32 | 128281 | 144424 | 98300 | 0.888x | 1.305x | 1.469x | +2766 B | +2766 B | +0 B |
| dct4_512_f32 | 64849 | 58643 | 50903 | 1.106x | 1.274x | 1.152x | +5398 B | +5398 B | +0 B |
| rfft512_f32 | 27739 | 28988 | 25422 | 0.957x | 1.091x | 1.140x | +2566 B | +2566 B | +0 B |
| biquad_cascade_df2T_f32_sos3_n1 | 126 | 186 | 136 | 0.677x | 0.926x | 1.368x | +264 B | +264 B | +0 B |
