#!/usr/bin/env bash
# E2 · prompt-length sweep on Apple M4
# 目的：扫描 prompt = {512, 4k, 32k} tokens，观察外部 I/O 峰值和 TPS 稳定性
# 输出：results/E2_YYYYMMDD/E2_summary.json 汇总

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STAMP=$(date +%Y%m%d_%H%M%S)
RUN_DIR="$SCRIPT_DIR/results/E2_$STAMP"
mkdir -p "$RUN_DIR"

MODEL="${MODEL:-gemma4:latest}"

# gemma4 上下文默认只有 8k, 我们跑三档: 512 / 2048 / 6144（在 8k ctx 里安全）
PROMPT_LENGTHS=(512 2048 6144)

# ollama server 保活
if ! curl -s -m 1 http://localhost:11434/api/tags > /dev/null 2>&1; then
    (ollama serve > "$RUN_DIR/ollama_server.log" 2>&1 &)
    sleep 3
fi

curl -s -m 60 http://localhost:11434/api/generate \
    -d "{\"model\":\"$MODEL\",\"prompt\":\"hi\",\"stream\":false,\"keep_alive\":\"10m\"}" > /dev/null

echo "==> E2 sweep on $MODEL"
for LEN in "${PROMPT_LENGTHS[@]}"; do
    echo "==> generating prompt with ~$LEN tokens..."
    # 生成大约 LEN tokens 的填充 prompt（每 token ≈ 3 chars 中文，2 for eng）
    PROMPT=$(python3 -c "
import random, string
tokens_target = $LEN
# 用有意义的英文短句填充，避免退化到无意义 token
templates = [
    'The intersection of memory bandwidth and inference throughput remains a critical bottleneck for large language models.',
    'Locality of bandwidth suggests that data movement inside a compute module vastly exceeds data movement across its boundaries.',
    'Modern accelerators like Apple M4, NVIDIA B200, and Rockchip RK1828 illustrate this phenomenon across three orders of scale.',
    'Consider the following scenario for architectural analysis.',
]
result = []
approx_chars = tokens_target * 4  # rough
while len(' '.join(result)) < approx_chars:
    result.append(random.choice(templates))
prompt = ' '.join(result) + ' Please summarize the above in exactly 200 tokens.'
print(prompt)
")

    OUT_FILE="$RUN_DIR/L${LEN}_inference.json"
    PM_FILE="$RUN_DIR/L${LEN}_powermetrics.log"

    # 短采样窗口
    echo "122333" | sudo -S -p '' powermetrics \
        --samplers gpu_power,cpu_power,network,disk \
        -i 500 -o "$PM_FILE" > /dev/null 2>&1 &
    PM_PID=$!

    T0=$(date +%s.%N)
    curl -s http://localhost:11434/api/generate \
        -d "{\"model\":\"$MODEL\",\"prompt\":$(python3 -c "import json,sys;print(json.dumps(sys.argv[1]))" "$PROMPT"),\"stream\":false,\"options\":{\"num_predict\":200,\"temperature\":0.5,\"num_ctx\":8192}}" \
        > "$OUT_FILE"
    T1=$(date +%s.%N)

    echo "122333" | sudo -S -p '' kill $PM_PID 2>/dev/null || true
    wait 2>/dev/null || true

    # 快速摘要
    python3 -c "
import json
d = json.load(open('$OUT_FILE'))
tin, tout = d.get('prompt_eval_count',0), d.get('eval_count',0)
peval = d.get('prompt_eval_duration',0)/1e9
eval_d = d.get('eval_duration',0)/1e9
tps = tout/eval_d if eval_d else 0
prefill_tps = tin/peval if peval else 0
print(f'  L=$LEN: in={tin} tok, out={tout} tok, prefill={prefill_tps:.1f} tok/s, decode={tps:.1f} tok/s, prompt_dur={peval:.2f}s, eval_dur={eval_d:.2f}s')
"
done

echo "122333" | sudo -S chown -R $(whoami) "$RUN_DIR" 2>&1 | tail -1

# 汇总
python3 - "$RUN_DIR" <<'PYEOF'
import sys, os, json, glob
run_dir = sys.argv[1]
rows = []
for f in sorted(glob.glob(os.path.join(run_dir, 'L*_inference.json'))):
    d = json.load(open(f))
    tin = d.get('prompt_eval_count', 0)
    tout = d.get('eval_count', 0)
    prefill_d = d.get('prompt_eval_duration', 0) / 1e9
    eval_d = d.get('eval_duration', 0) / 1e9
    prefill_tps = tin / prefill_d if prefill_d else 0
    decode_tps = tout / eval_d if eval_d else 0
    resp_bytes = len(d.get('response','').encode('utf-8'))
    # external throughput = (prompt_bytes + response_bytes) / total_dur
    total_dur = d.get('total_duration', 0) / 1e9
    # approx prompt utf-8 bytes: tin tokens * ~4 bytes/token in english
    prompt_bytes_est = tin * 4
    ext_bps = (prompt_bytes_est + resp_bytes) / total_dur if total_dur else 0
    # internal bw estimate (weights scanned per decoded token)
    model_size_gb = 9.6
    weights_gb = tout * model_size_gb
    int_gbps = weights_gb / eval_d if eval_d else 0
    ratio = (int_gbps * 1e9) / ext_bps if ext_bps else 0
    rows.append({
        'input_tokens': tin,
        'output_tokens': tout,
        'prefill_tps': round(prefill_tps, 1),
        'decode_tps': round(decode_tps, 1),
        'prefill_duration_sec': round(prefill_d, 3),
        'eval_duration_sec': round(eval_d, 3),
        'external_bps': round(ext_bps, 1),
        'internal_gbps_est': round(int_gbps, 1),
        'lob_ratio': f'{ratio:.2e}',
    })

summary = {
    'experiment': 'E2 · prompt-length sweep on Apple M4 base + gemma4',
    'sweep_points': rows,
    'observation_placeholder': 'to be filled after analysis',
}
p = os.path.join(run_dir, 'E2_summary.json')
json.dump(summary, open(p, 'w'), indent=2)
print('\n==>', p)
print(json.dumps(summary, indent=2))
PYEOF
