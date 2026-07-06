#!/usr/bin/env bash
# E3 · Interference test — 悟色纠结点 3 "双轨 vs UMA 边界"
# 目的：M4 跑推理时，其他 CPU 密集型任务被拖累多少
# 对照组: A. baseline 推理独占 SoC
#         B. 推理 + 后台 CPU-bound 任务 (7z 压缩)
#         C. 只跑后台任务 (无推理)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STAMP=$(date +%Y%m%d_%H%M%S)
RUN_DIR="$SCRIPT_DIR/results/E3_$STAMP"
mkdir -p "$RUN_DIR"

MODEL="${MODEL:-gemma4:latest}"

# 准备一个 CPU-bound 后台任务: 用 openssl 做 AES 加密循环
run_cpu_bg() {
    # 4 个进程持续压 4 个 P 核
    for i in 1 2 3 4; do
        (dd if=/dev/urandom bs=1M count=200 2>/dev/null | openssl enc -aes-256-cbc -k pwd -salt > /dev/null) &
    done
    wait
}

if ! curl -s -m 1 http://localhost:11434/api/tags > /dev/null 2>&1; then
    (ollama serve > "$RUN_DIR/ollama_server.log" 2>&1 &)
    sleep 3
fi

curl -s -m 60 http://localhost:11434/api/generate \
    -d "{\"model\":\"$MODEL\",\"prompt\":\"warm up\",\"stream\":false,\"keep_alive\":\"10m\"}" > /dev/null

# 定义: 三个场景各跑 200 token 推理 + 记录时间
scenarios=("A_baseline" "B_with_cpu_bg" "C_only_cpu_bg")

for SC in "${scenarios[@]}"; do
    echo "==> Scenario $SC"
    OUT="$RUN_DIR/${SC}_inference.json"
    CPU_LOG="$RUN_DIR/${SC}_cpu_bench.log"

    if [[ "$SC" == "B_with_cpu_bg" ]]; then
        # 后台起 CPU 负载
        run_cpu_bg > "$CPU_LOG" 2>&1 &
        CPU_PID=$!
        sleep 1
    fi

    if [[ "$SC" != "C_only_cpu_bg" ]]; then
        T0=$(date +%s.%N)
        curl -s http://localhost:11434/api/generate \
            -d "{\"model\":\"$MODEL\",\"prompt\":\"Explain memory bandwidth locality in 200 tokens.\",\"stream\":false,\"options\":{\"num_predict\":200,\"temperature\":0.5}}" \
            > "$OUT"
        T1=$(date +%s.%N)
    fi

    if [[ "$SC" == "C_only_cpu_bg" ]]; then
        # 单独测 CPU bench 完成用时
        T0=$(date +%s.%N)
        run_cpu_bg > "$CPU_LOG" 2>&1
        T1=$(date +%s.%N)
        echo "  C cpu-only elapsed: $(python3 -c "print(f'{$T1-$T0:.2f}s')")"
    fi

    if [[ "$SC" == "B_with_cpu_bg" ]]; then
        # 等 CPU bench 完成
        wait $CPU_PID 2>/dev/null || true
    fi

    if [[ -f "$OUT" ]]; then
        python3 -c "
import json
d = json.load(open('$OUT'))
tps = d.get('eval_count',0) / (d.get('eval_duration',1)/1e9)
print(f'  $SC decode: {tps:.1f} tok/s')
"
    fi
done

echo "122333" | sudo -S chown -R $(whoami) "$RUN_DIR" 2>&1 | tail -1

python3 - "$RUN_DIR" <<'PYEOF'
import os, json, sys
run_dir = sys.argv[1]
rows = {}
for sc in ['A_baseline', 'B_with_cpu_bg']:
    p = os.path.join(run_dir, f'{sc}_inference.json')
    if os.path.exists(p):
        d = json.load(open(p))
        eval_d = d.get('eval_duration',0)/1e9
        tps = d.get('eval_count',0) / eval_d if eval_d else 0
        rows[sc] = {'decode_tps': round(tps,1), 'eval_duration_sec': round(eval_d,3)}

if 'A_baseline' in rows and 'B_with_cpu_bg' in rows:
    a = rows['A_baseline']['decode_tps']
    b = rows['B_with_cpu_bg']['decode_tps']
    slowdown = (a-b)/a*100 if a else 0
    rows['inference_slowdown_pct'] = round(slowdown, 1)

summary = {
    'experiment': 'E3 · UMA interference test',
    'purpose': '悟色纠结点3: does inference workload starve co-located CPU tasks (or vice versa) on UMA?',
    'results': rows,
    'interpretation_hint': 'Large slowdown => strong case for Dual-Track (external AI puck decouples). Small slowdown => UMA is fine.',
}
p = os.path.join(run_dir, 'E3_summary.json')
json.dump(summary, open(p, 'w'), indent=2)
print('\n==>', p)
print(json.dumps(summary, indent=2))
PYEOF
