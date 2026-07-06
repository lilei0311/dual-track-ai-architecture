#!/usr/bin/env python3
"""E5 analyzer: compute LoB ratios (strict lower bound + loose upper bound) for each scenario.

Mirrors E1/E2/E4 methodology so results are directly comparable across
Apple M4 (unified memory) vs x86+NVIDIA (discrete HBM + PCIe).
"""
import argparse
import json
import subprocess
from pathlib import Path

# HBM/GDDR peak bandwidth lookup (GB/s) — official NVIDIA datasheet values
HBM_PEAK = {
    # by contains-substring match against nvidia-smi name
    "A100-SXM4-80GB": 2039,
    "A100 80GB PCIe": 1935,
    "A100 40GB": 1555,
    "A100": 1555,
    "H100 SXM": 3350,
    "H100 PCIe": 2000,
    "H100 80GB HBM3": 3350,
    "H100": 3350,
    "H200": 4800,
    "RTX 6000 Ada": 960,
    "RTX A6000": 768,
    "RTX 4090": 1008,
    "RTX 4080": 736,
    "L40S": 864,
    "L4": 300,
    "V100": 900,
}


def gpu_peak_bw(gpu_name: str) -> tuple[float, str]:
    for key, val in HBM_PEAK.items():
        if key.lower() in gpu_name.lower():
            return val, key
    return 0.0, "UNKNOWN"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    out = Path(args.out)

    # detect gpu
    gpu_name = subprocess.check_output(
        ["nvidia-smi", "--query-gpu=name", "--format=csv,noheader"]
    ).decode().strip().splitlines()[0]
    hbm_peak_gbs, matched = gpu_peak_bw(gpu_name)

    scenarios = json.loads((out / "E5_scenarios.json").read_text())

    # compute LoB for each scenario
    for s in scenarios:
        ext_bps = s["external_bps_total"]
        # strict lower bound: HBM peak / external total bytes-per-second
        if hbm_peak_gbs > 0 and ext_bps > 0:
            s["lob_ratio_strict"] = (hbm_peak_gbs * 1e9) / ext_bps
        else:
            s["lob_ratio_strict"] = None
        # loose upper bound: weight-scan estimate (params × tokens ÷ elapsed)
        # gemma-2-9b at bf16 ≈ 18GB; at Q4 ≈ 5GB. We use 9.6GB (M4-side gemma4 Q4_K_M) for direct compare.
        model_bytes = 9.6 * 1e9  # match M4-side model size for comparability
        total_out_tokens = s.get("completion_tokens") or 0
        if s["wall_elapsed_sec"] > 0 and total_out_tokens > 0:
            weight_scan_bps = (model_bytes * total_out_tokens) / s["wall_elapsed_sec"]
            s["internal_bw_loose_gbs"] = weight_scan_bps / 1e9
            if ext_bps > 0:
                s["lob_ratio_loose"] = weight_scan_bps / ext_bps
        else:
            s["internal_bw_loose_gbs"] = None
            s["lob_ratio_loose"] = None

    summary = {
        "experiment": "E5 · x86 + vLLM control group (mirror of M4 E1/E2/E4)",
        "gpu": gpu_name,
        "matched_datasheet_key": matched,
        "hbm_peak_bandwidth_gbs": hbm_peak_gbs,
        "model_size_bytes_for_loose_estimate": 9.6e9,
        "methodology_note": (
            "Strict lower bound uses GPU HBM peak / external byte flow. "
            "Loose upper bound uses model-size × tokens / elapsed (matches M4-side E1). "
            "External BPS = (prompt + response bytes) / total wall time."
        ),
        "scenarios": scenarios,
        "conclusion_hint": (
            "If all lob_ratio_strict > 100 across scenarios, LoB holds on x86+NVIDIA too, "
            "proving the hypothesis is architecture-agnostic (not an Apple UMA artifact)."
        ),
    }
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
