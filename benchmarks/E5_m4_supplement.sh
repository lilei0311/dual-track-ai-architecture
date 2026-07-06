#!/usr/bin/env bash
# E5 · M4 supplement: rerun with qwen2.5:3b to align with Windows RTX 2050 side
# This creates a same-model comparison between M4 UMA (120 GB/s) and RTX 2050 dGPU (112 GB/s)

set -euo pipefail

MODEL="${MODEL:-qwen2.5:3b}"
STAMP="$(date +%Y%m%d_%H%M%S)"
OUT="results/E5_m4_supplement_${STAMP}"
mkdir -p "$OUT"

echo "==> E5 · M4 supplement run"
echo "    Model:  $MODEL (matches RTX 2050 side for same-model x-arch compare)"
echo "    Output: $OUT"

# Ensure model is pulled
if ! ollama list | grep -q "^$MODEL"; then
  echo "==> Pulling $MODEL"
  ollama pull "$MODEL"
fi

# Reuse the M4 E1/E4 style client. If E1_run.sh exists, we invoke similar prompts.
# For simplicity, write minimal inline client here.

python3 <<'PYEOF' 2>&1 | tee "$OUT/run.log"
import json, os, sys, time, urllib.request

MODEL = os.environ.get("MODEL", "qwen2.5:3b")
OUT = os.environ.get("OUT")
URL = "http://localhost:11434/api/generate"

scenarios = [
    ("E5_1_baseline", "Explain memory bandwidth in modern computing systems in about 500 words.", 800),
    ("E5_2_prompt2k", "The quick brown fox jumps over the lazy dog. " * 100, 200),
    ("E5_3_prompt6k", "The quick brown fox jumps over the lazy dog. " * 500, 200),
    ("E5_4_prompt8k", "Once upon a time in a distant galaxy far far away, " * 800, 100),
]

results = []
for name, prompt, mt in scenarios:
    print(f"  → {name}  prompt_bytes={len(prompt.encode())}")
    body = json.dumps({
        "model": MODEL, "prompt": prompt, "stream": False,
        "options": {"num_predict": mt, "temperature": 0.7},
    }).encode()
    req = urllib.request.Request(URL, data=body, headers={"Content-Type": "application/json"})
    t0 = time.time()
    with urllib.request.urlopen(req, timeout=1800) as resp:
        data = json.loads(resp.read())
    elapsed = time.time() - t0
    resp_text = data.get("response", "")
    entry = {
        "name": name,
        "prompt_bytes": len(prompt.encode()),
        "response_bytes": len(resp_text.encode()),
        "prompt_tokens": data.get("prompt_eval_count"),
        "completion_tokens": data.get("eval_count"),
        "eval_ns": data.get("eval_duration"),
        "total_ns": data.get("total_duration"),
        "wall_elapsed_sec": elapsed,
        "decode_tps_ollama": (data.get("eval_count") or 0) / (data.get("eval_duration", 1) / 1e9) if data.get("eval_duration") else None,
        "decode_tps_wall": (data.get("eval_count") or 0) / elapsed if elapsed > 0 else 0,
        "external_bps_total": (len(prompt.encode()) + len(resp_text.encode())) / elapsed if elapsed > 0 else 0,
    }
    with open(f"{OUT}/{name}_response.json", "w") as f:
        json.dump({**data, "_meta": entry}, f, ensure_ascii=False, indent=2)
    results.append(entry)
    print(f"    done in {elapsed:.1f}s · decode {entry['decode_tps_wall']:.1f} tok/s")

# LoB compute (M4 base = 120 GB/s official)
M4_PEAK_GBS = 120
MODEL_BYTES = 2.0e9  # qwen2.5:3b Q4_K_M
for s in results:
    ext = s["external_bps_total"]
    s["lob_ratio_strict"] = (M4_PEAK_GBS * 1e9) / ext if ext > 0 else None
    out_tok = s.get("completion_tokens") or 0
    if s["wall_elapsed_sec"] > 0 and out_tok > 0:
        ibw = (MODEL_BYTES * out_tok) / s["wall_elapsed_sec"]
        s["internal_bw_loose_gbs"] = ibw / 1e9
        s["lob_ratio_loose"] = ibw / ext if ext > 0 else None

summary = {
    "experiment": "E5 · M4 supplement (aligned model with RTX 2050 side)",
    "hardware": "Apple M4 base 16GB, UMA LPDDR5X-7500, 120 GB/s official peak",
    "model": MODEL,
    "scenarios": results,
}
with open(f"{OUT}/E5_m4_supplement_summary.json", "w") as f:
    json.dump(summary, f, ensure_ascii=False, indent=2)
print(f"\n==> Summary written: {OUT}/E5_m4_supplement_summary.json")
for r in results:
    strict = r.get("lob_ratio_strict")
    if strict is not None:
        print(f"    {r['name']:<20} TPS={r['decode_tps_wall']:6.1f}  LoB_strict={strict:.2e}")
    else:
        print(f"    {r['name']:<20} TPS={r['decode_tps_wall']:6.1f}")
PYEOF

echo
echo "==> DONE"
