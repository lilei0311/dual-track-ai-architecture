#!/usr/bin/env python3
"""E5 client: run 4 scenarios against local vLLM server, collect timing + external byte flow.

Scenarios mirror M4-side E1/E2/E4 methodology:
  E5.1 baseline   - short prompt, 800 tokens out (== E1)
  E5.2 prompt-2k  - medium prompt, 200 tokens out (== E2 mid)
  E5.3 prompt-6k  - long prompt, 200 tokens out (== E2 max)
  E5.4 prompt-8k  - extra long prompt, 100 tokens out (== E4 short end)

For each scenario, also start `nvidia-smi dmon` in background to log GPU
mem-util/bw utilization and log to CSV.
"""
import argparse
import json
import subprocess
import time
from pathlib import Path

import requests

VLLM_URL = "http://localhost:8000/v1/completions"
MODEL_NAME = "test"

SCENARIOS = [
    ("E5_1_baseline", "Explain memory bandwidth in modern computing in about 500 words.", 800),
    ("E5_2_prompt2k", "The quick brown fox jumps over the lazy dog. " * 100, 200),
    ("E5_3_prompt6k", "The quick brown fox jumps over the lazy dog. " * 500, 200),
    ("E5_4_prompt8k", "Once upon a time in a distant galaxy far far away, " * 800, 100),
]


def start_dmon(csv_path: Path):
    """Start nvidia-smi dmon in background, return Popen."""
    f = open(csv_path, "w")
    return subprocess.Popen(
        ["nvidia-smi", "dmon", "-s", "pucm", "-d", "1", "-c", "600"],
        stdout=f, stderr=subprocess.STDOUT,
    ), f


def run_scenario(name: str, prompt: str, max_tokens: int, out: Path) -> dict:
    print(f"  → {name}  prompt_bytes={len(prompt.encode())}  max_tokens={max_tokens}")

    dmon_proc, dmon_fh = start_dmon(out / f"{name}_gpu_dmon.csv")

    t0 = time.time()
    try:
        r = requests.post(
            VLLM_URL,
            json={
                "model": MODEL_NAME,
                "prompt": prompt,
                "max_tokens": max_tokens,
                "temperature": 0.7,
                "stream": False,
            },
            timeout=1800,
        )
        r.raise_for_status()
        data = r.json()
    finally:
        dmon_proc.terminate()
        try:
            dmon_proc.wait(timeout=5)
        except Exception:
            dmon_proc.kill()
        dmon_fh.close()

    elapsed = time.time() - t0
    resp_text = data["choices"][0]["text"]
    usage = data.get("usage", {})
    entry = {
        "name": name,
        "prompt_bytes": len(prompt.encode()),
        "response_bytes": len(resp_text.encode()),
        "prompt_tokens": usage.get("prompt_tokens"),
        "completion_tokens": usage.get("completion_tokens"),
        "wall_elapsed_sec": elapsed,
        "decode_tps_wall": (usage.get("completion_tokens") or 0) / elapsed if elapsed > 0 else 0,
        "external_bps_total": (len(prompt.encode()) + len(resp_text.encode())) / elapsed if elapsed > 0 else 0,
    }
    # save raw response
    (out / f"{name}_response.json").write_text(
        json.dumps({**data, "_meta": entry}, ensure_ascii=False, indent=2)
    )
    print(f"    done in {elapsed:.1f}s · decode {entry['decode_tps_wall']:.1f} tok/s")
    return entry


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    out = Path(args.out)

    results = []
    for name, prompt, mt in SCENARIOS:
        results.append(run_scenario(name, prompt, mt, out))
    (out / "E5_scenarios.json").write_text(json.dumps(results, ensure_ascii=False, indent=2))
    print(f"\nAll {len(results)} scenarios complete → {out}/E5_scenarios.json")


if __name__ == "__main__":
    main()
