#!/usr/bin/env bash
# E5 · x86 + vLLM control group for DTA LoB validation
# Purpose: reproduce E1/E2/E4 methodology on x86+NVIDIA GPU, prove LoB is architecture-agnostic
# Target: rented bare-metal cloud (Vultr / Hetzner / Lambda / CoreWeave)
# Prereq: Ubuntu 22/24, NVIDIA driver, CUDA 12+, python3.10+, sudo, nvidia-smi
#
# Usage:
#   bash E5_run.sh                         # default gemma-2-9b-it
#   MODEL=Qwen/Qwen2.5-7B-Instruct bash E5_run.sh
#
# Outputs:  results/E5_<stamp>/  containing per-scenario json + gpu_dmon logs + summary

set -euo pipefail

MODEL="${MODEL:-google/gemma-2-9b-it}"
MODEL_DIR="${MODEL_DIR:-$HOME/models/$(basename "$MODEL")}"
STAMP="$(date +%Y%m%d_%H%M%S)"
OUT="results/E5_${STAMP}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$OUT"

echo "==> E5 · x86 + vLLM"
echo "    Model:  $MODEL"
echo "    Output: $OUT"

# ── 0. env probe ──
nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv > "$OUT/gpu_info.csv"
lscpu > "$OUT/cpu_info.txt"
free -h > "$OUT/mem_info.txt"
uname -a > "$OUT/kernel_info.txt"
sudo dmidecode -t memory 2>/dev/null | grep -E "Speed|Type:" | head -20 > "$OUT/dram_info.txt" || true
echo "    GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)"
echo "    CPU: $(lscpu | awk -F: '/Model name/{print $2}' | xargs)"

# ── 1. install vLLM ──
if ! python3 -c "import vllm" 2>/dev/null; then
  echo "==> installing vllm"
  pip3 install --quiet 'vllm>=0.6.3'
fi

# ── 2. download model ──
if [ ! -d "$MODEL_DIR" ] || [ -z "$(ls -A "$MODEL_DIR" 2>/dev/null)" ]; then
  echo "==> downloading $MODEL"
  python3 -c "from huggingface_hub import snapshot_download; snapshot_download('$MODEL', local_dir='$MODEL_DIR')"
fi

# ── 3. start vLLM server ──
echo "==> starting vLLM server (port 8000, max_model_len=8192)"
python3 -m vllm.entrypoints.openai.api_server \
  --model "$MODEL_DIR" --served-model-name test \
  --port 8000 --max-model-len 8192 --gpu-memory-utilization 0.85 \
  > "$OUT/vllm_server.log" 2>&1 &
VLLM_PID=$!
trap 'kill $VLLM_PID 2>/dev/null; sleep 2; kill -9 $VLLM_PID 2>/dev/null; true' EXIT

for i in {1..120}; do
  if curl -sf http://localhost:8000/v1/models > /dev/null 2>&1; then
    echo "    ready in ${i}s"; break
  fi
  sleep 1
  [ $i -eq 120 ] && { echo "vLLM never became ready"; exit 1; }
done

# ── 4. run scenarios via python helper ──
python3 "$SCRIPT_DIR/E5_client.py" --out "$OUT"

# ── 5. summary ──
python3 "$SCRIPT_DIR/E5_analyze.py" --out "$OUT" > "$OUT/E5_summary.json"
echo
echo "==> DONE"
echo "    Summary: $OUT/E5_summary.json"
cat "$OUT/E5_summary.json"
