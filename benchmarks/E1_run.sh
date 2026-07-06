#!/usr/bin/env bash
# E1 · LoB benchmark on Apple M4 base
# 目标：在推理期间同时采样：
#   - 内部 memory subsystem bandwidth（近似 = LLM 权重 & KV cache 的搬运量）
#   - 外部网络/USB I/O（近似 = 外界与推理引擎的实际数据量）
# 输出：E1_summary.json + 时间序列 CSV

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="$SCRIPT_DIR/results"
mkdir -p "$OUT_DIR"
STAMP=$(date +%Y%m%d_%H%M%S)
RUN_DIR="$OUT_DIR/E1_$STAMP"
mkdir -p "$RUN_DIR"

MODEL="${MODEL:-gemma4:latest}"
PROMPT="${PROMPT:-写一篇 500 字的短文，主题是深空探索的意义。要求：文笔诗意，结构完整。}"

echo "==> E1 benchmark start"
echo "    host: $(hostname) · $(sw_vers -productName) $(sw_vers -productVersion) · $(sysctl -n machdep.cpu.brand_string)"
echo "    model: $MODEL · out: $RUN_DIR"

# --- Sampler 1: powermetrics (memory + package power) ---
# Sample every 500ms during the inference. Requires sudo (passwordless via `echo pw | sudo -S`).
PM_LOG="$RUN_DIR/powermetrics.log"
echo "==> starting powermetrics sampler..."
echo "122333" | sudo -S -p '' powermetrics \
    --samplers gpu_power,cpu_power,ane_power,network,disk \
    -i 500 \
    -o "$PM_LOG" \
    > /dev/null 2>&1 &
PM_PID=$!

# --- Sampler 2: nettop (external network I/O) ---
NT_LOG="$RUN_DIR/nettop.log"
echo "==> starting nettop sampler..."
nettop -P -n -x -k state,rx_dupe,rx_ooo,re-tx,rtt_avg,rcvsize,tx_win,tc_class,tc_mgt,cc_algo,P,C,R,W,arch \
    -s 1 -L 0 > "$NT_LOG" 2>&1 &
NT_PID=$!

# 冷启动 ollama server（如果没起来）
if ! curl -s -m 1 http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "==> starting ollama server..."
    (ollama serve > "$RUN_DIR/ollama_server.log" 2>&1 &)
    sleep 3
fi

# 预加载模型（避免第一次加载磁盘 I/O 混入采样）
echo "==> preloading model..."
curl -s -m 60 http://localhost:11434/api/generate \
    -d "{\"model\":\"$MODEL\",\"prompt\":\"hi\",\"stream\":false,\"keep_alive\":\"5m\"}" \
    > /dev/null

sleep 2

# --- Actual inference under observation ---
INF_LOG="$RUN_DIR/inference.json"
echo "==> running inference..."
T_START=$(date +%s.%N)
curl -s http://localhost:11434/api/generate \
    -d "{
        \"model\": \"$MODEL\",
        \"prompt\": $(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$PROMPT"),
        \"stream\": false,
        \"options\": {\"num_predict\": 800, \"temperature\": 0.7}
    }" \
    > "$INF_LOG"
T_END=$(date +%s.%N)

sleep 1

# 停采样
echo "==> stopping samplers..."
echo "122333" | sudo -S -p '' kill $PM_PID 2>/dev/null || true
kill $NT_PID 2>/dev/null || true
wait 2>/dev/null || true

# --- 解析结果 ---
python3 - "$RUN_DIR" "$T_START" "$T_END" <<'PYEOF'
import sys, os, json, re
run_dir, t_start, t_end = sys.argv[1], float(sys.argv[2]), float(sys.argv[3])
duration = t_end - t_start

inf = json.load(open(os.path.join(run_dir, 'inference.json')))
tokens_out = inf.get('eval_count', 0)
tokens_in = inf.get('prompt_eval_count', 0)
tps = tokens_out / (inf.get('eval_duration', 1) / 1e9) if inf.get('eval_duration') else 0
model = inf.get('model', '?')
resp_bytes = len(inf.get('response', '').encode('utf-8'))

# Parse powermetrics for network + disk bytes and package power
pm = open(os.path.join(run_dir, 'powermetrics.log')).read()
net_out = sum(int(x) for x in re.findall(r'out:\s*(\d+)\s*bytes', pm))
net_in = sum(int(x) for x in re.findall(r'in:\s*(\d+)\s*bytes', pm))
disk_read = sum(int(x) for x in re.findall(r'read:\s*(\d+)\s*bytes', pm))
disk_write = sum(int(x) for x in re.findall(r'write:\s*(\d+)\s*bytes', pm))

pkg_power = [float(x) for x in re.findall(r'Combined Power \(CPU \+ GPU \+ ANE\): (\d+)', pm)]
avg_pkg_w = sum(pkg_power)/len(pkg_power)/1000 if pkg_power else 0

# Estimate memory bandwidth from token count and model size
# gemma4 latest is 9.6 GB. Each decode step scans all weights => weights_scanned ≈ N_tokens × model_size
model_size_gb = 9.6
weights_scanned_gb = tokens_out * model_size_gb
internal_bw_gbps = weights_scanned_gb / duration if duration > 0 else 0
external_bw_bps = (net_in + net_out + resp_bytes) / duration if duration > 0 else 0

summary = {
    'model': model,
    'device': 'Apple M4 base (16GB unified, 10-core)',
    'duration_sec': round(duration, 3),
    'tokens_in': tokens_in,
    'tokens_out': tokens_out,
    'tokens_per_sec': round(tps, 2),
    'avg_pkg_power_w': round(avg_pkg_w, 2),
    'internal': {
        'model_size_gb': model_size_gb,
        'weights_scanned_gb': round(weights_scanned_gb, 1),
        'est_memory_bandwidth_gbps': round(internal_bw_gbps, 1),
        'note': 'lower bound: assumes 1x weight scan per decode step, ignores KV cache reads'
    },
    'external': {
        'net_in_bytes': net_in,
        'net_out_bytes': net_out,
        'disk_read_bytes': disk_read,
        'disk_write_bytes': disk_write,
        'inference_response_bytes': resp_bytes,
        'total_external_bytes': net_in + net_out + resp_bytes,
        'avg_external_throughput_bps': round(external_bw_bps, 1),
        'avg_external_throughput_kbps': round(external_bw_bps/1024, 2)
    },
    'lob_ratio_internal_over_external': (
        round(internal_bw_gbps * 1e9 / external_bw_bps, 1) if external_bw_bps > 0 else None
    ),
    'interpretation': 'Internal:external memory-bandwidth ratio for a single-user local inference session.'
}
out = os.path.join(run_dir, 'E1_summary.json')
json.dump(summary, open(out, 'w'), indent=2, ensure_ascii=False)
print('==>', out)
print(json.dumps(summary, indent=2, ensure_ascii=False))
PYEOF

echo "==> Done. Results at $RUN_DIR"
