#!/usr/bin/env python3
"""E5 · Windows/Linux Ollama-based client.

Runs 4 scenarios against a local Ollama server (matches M4-side gemma4
methodology). Works on RTX 2050 laptop with qwen2.5:3b or gemma2:2b.

Usage:
  python E5_win_client.py --model qwen2.5:3b
  python E5_win_client.py --model gemma2:2b
"""
import argparse
import json
import os
import platform
import subprocess
import sys
import time
from pathlib import Path

import urllib.request
import urllib.error

OLLAMA_URL = "http://localhost:11434/api/generate"

# Scenarios mirror M4-side E1/E2/E4 methodology
SCENARIOS = [
    ("E5_1_baseline", "Explain memory bandwidth in modern computing systems in about 500 words.", 800),
    ("E5_2_prompt2k", "The quick brown fox jumps over the lazy dog. " * 100, 200),
    ("E5_3_prompt6k", "The quick brown fox jumps over the lazy dog. " * 500, 200),
    ("E5_4_prompt8k", "Once upon a time in a distant galaxy far far away, " * 800, 100),
]

# GPU peak BW lookup (GB/s) — official NVIDIA datasheet values
GPU_PEAK = {
    "rtx 2050": 112,          # ← YOUR MACHINE
    "rtx 3050": 224,
    "rtx 3060": 360,
    "rtx 4060": 272,
    "rtx 4070": 504,
    "rtx 4080": 736,
    "rtx 4090": 1008,
    "rtx a6000": 768,
    "rtx 6000 ada": 960,
    "a100": 1555,
    "h100": 3350,
    "l40s": 864,
    "l4": 300,
    "t4": 320,
}


def get_gpu_info():
    try:
        out = subprocess.check_output(
            ["nvidia-smi", "--query-gpu=name,memory.total,driver_version", "--format=csv,noheader"],
            encoding="utf-8", timeout=10,
        )
        return out.strip()
    except Exception as e:
        return f"NO_NVIDIA_SMI: {e}"


def gpu_peak_bw(gpu_line: str):
    gl = gpu_line.lower()
    for key, val in GPU_PEAK.items():
        if key in gl:
            return val, key
    return 0.0, "UNKNOWN"


def ollama_generate(model: str, prompt: str, max_tokens: int, timeout: int = 1800):
    body = json.dumps({
        "model": model,
        "prompt": prompt,
        "stream": False,
        "options": {"num_predict": max_tokens, "temperature": 0.7},
    }).encode("utf-8")
    req = urllib.request.Request(
        OLLAMA_URL, data=body, headers={"Content-Type": "application/json"}
    )
    t0 = time.time()
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        raw = resp.read()
    elapsed = time.time() - t0
    data = json.loads(raw)
    return data, elapsed


def run_scenario(model: str, name: str, prompt: str, max_tokens: int, out: Path) -> dict:
    print(f"  → {name}  prompt_bytes={len(prompt.encode())}  max_tokens={max_tokens}", flush=True)

    # start nvidia-smi dmon in background
    dmon_csv = out / f"{name}_gpu_dmon.csv"
    dmon_fh = open(dmon_csv, "w")
    try:
        dmon = subprocess.Popen(
            ["nvidia-smi", "dmon", "-s", "pucm", "-d", "1", "-c", "600"],
            stdout=dmon_fh, stderr=subprocess.STDOUT,
        )
    except FileNotFoundError:
        dmon = None
        print("    (nvidia-smi not found on PATH, skipping dmon)")

    try:
        data, elapsed = ollama_generate(model, prompt, max_tokens)
    finally:
        if dmon:
            dmon.terminate()
            try:
                dmon.wait(timeout=5)
            except Exception:
                dmon.kill()
        dmon_fh.close()

    resp_text = data.get("response", "")
    entry = {
        "name": name,
        "prompt_bytes": len(prompt.encode()),
        "response_bytes": len(resp_text.encode()),
        "prompt_tokens": data.get("prompt_eval_count"),
        "completion_tokens": data.get("eval_count"),
        "prompt_eval_ns": data.get("prompt_eval_duration"),
        "eval_ns": data.get("eval_duration"),
        "total_ns": data.get("total_duration"),
        "wall_elapsed_sec": elapsed,
        "decode_tps_ollama": (data.get("eval_count") or 0) / (data.get("eval_duration", 1) / 1e9)
            if data.get("eval_duration") else None,
        "decode_tps_wall": (data.get("eval_count") or 0) / elapsed if elapsed > 0 else 0,
        "external_bps_total": (len(prompt.encode()) + len(resp_text.encode())) / elapsed if elapsed > 0 else 0,
    }

    (out / f"{name}_response.json").write_text(
        json.dumps({**data, "_meta": entry}, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"    done in {elapsed:.1f}s · decode {entry['decode_tps_wall']:.1f} tok/s (wall)", flush=True)
    return entry


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default="qwen2.5:3b", help="Ollama model tag (must be already pulled)")
    ap.add_argument("--out", default=None, help="output dir (default: results/E5_win_<stamp>)")
    args = ap.parse_args()

    stamp = time.strftime("%Y%m%d_%H%M%S")
    out = Path(args.out or f"results/E5_win_{stamp}")
    out.mkdir(parents=True, exist_ok=True)

    # env probe
    gpu_info = get_gpu_info()
    (out / "gpu_info.txt").write_text(gpu_info, encoding="utf-8")
    (out / "platform_info.txt").write_text(
        f"{platform.platform()}\n{platform.processor()}\nPython {sys.version}\n",
        encoding="utf-8",
    )
    print(f"==> E5 · Ollama on {platform.system()}")
    print(f"    Model:  {args.model}")
    print(f"    GPU:    {gpu_info}")
    print(f"    Output: {out}")

    peak_bw, matched = gpu_peak_bw(gpu_info)
    print(f"    HBM/GDDR peak BW: {peak_bw} GB/s (matched: {matched})")

    # sanity: model pulled?
    try:
        r = urllib.request.urlopen("http://localhost:11434/api/tags", timeout=5)
        tags = json.loads(r.read())
        available = [m["name"] for m in tags.get("models", [])]
        if args.model not in available:
            print(f"\n⚠️  Model '{args.model}' not pulled yet.")
            print(f"    Run first:  ollama pull {args.model}")
            print(f"    Available:  {available}")
            sys.exit(1)
    except Exception as e:
        print(f"\n❌ Ollama not reachable at localhost:11434: {e}")
        print("    Start Ollama first, then rerun.")
        sys.exit(1)

    # run scenarios
    results = []
    for name, prompt, mt in SCENARIOS:
        results.append(run_scenario(args.model, name, prompt, mt, out))

    (out / "E5_win_scenarios.json").write_text(
        json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    # compute LoB
    summary_rows = []
    for s in results:
        ext_bps = s["external_bps_total"]
        lob_strict = (peak_bw * 1e9) / ext_bps if peak_bw > 0 and ext_bps > 0 else None
        # loose bound: match M4 side — 9.6GB gemma4 → but here use actual model size lookup
        model_size_estimate = {"qwen2.5:3b": 2.0e9, "gemma2:2b": 1.6e9, "llama3.2:3b": 2.0e9}
        msize = model_size_estimate.get(args.model, 2.0e9)
        out_tokens = s.get("completion_tokens") or 0
        loose_ibw = (msize * out_tokens) / s["wall_elapsed_sec"] if s["wall_elapsed_sec"] > 0 and out_tokens > 0 else None
        lob_loose = loose_ibw / ext_bps if loose_ibw and ext_bps > 0 else None
        summary_rows.append({
            **s,
            "lob_ratio_strict": lob_strict,
            "internal_bw_loose_gbs": (loose_ibw / 1e9) if loose_ibw else None,
            "lob_ratio_loose": lob_loose,
        })

    summary = {
        "experiment": "E5 · Windows/Linux Ollama control group",
        "purpose": "Prove LoB is architecture-agnostic (dGPU with same-tier BW should show equivalent LoB to M4 UMA)",
        "platform": platform.platform(),
        "gpu_info": gpu_info,
        "gpu_peak_bandwidth_gbs": peak_bw,
        "matched_datasheet": matched,
        "model": args.model,
        "scenarios": summary_rows,
        "compare_to_m4": (
            "M4 base: 120 GB/s UMA · gemma4:9b · E1 decode 29.2 TPS · LoB strict 6.0e9. "
            "If this run yields LoB > 1e8 across all scenarios on GPU-BW-equivalent hardware, "
            "LoB is confirmed architecture-agnostic."
        ),
    }
    summary_path = out / "E5_win_summary.json"
    summary_path.write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"\n==> DONE")
    print(f"    Summary: {summary_path}")
    print()
    for row in summary_rows:
        strict = row.get("lob_ratio_strict")
        print(f"    {row['name']:<20}  TPS={row['decode_tps_wall']:6.1f}   "
              f"LoB(strict)={strict:.2e}" if strict else
              f"    {row['name']:<20}  TPS={row['decode_tps_wall']:6.1f}   LoB=N/A")


if __name__ == "__main__":
    main()
