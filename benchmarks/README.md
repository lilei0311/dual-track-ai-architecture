# Benchmarks — 本机 LoB 实测

**Tier 2 验证的成果落这里。** 详见 [`../VALIDATION-ROADMAP.md`](../VALIDATION-ROADMAP.md#tier-2-·-本机-benchmark免费--本周可交付).

## 计划中的实验

### E1 · Mac mini M4 上的 memory-bound 采样

**目标**：跑 Ollama 一个 7B q4 模型，同时用 `powermetrics` 采样内存子系统带宽，用 `nettop` 采样外部 I/O。

**脚本骨架**（TODO：真正跑起来）：

```bash
# 后台采样 memory
sudo powermetrics --samplers gpu_power,cpu_power \
  -o /tmp/pm.log -i 500 --show-process-energy &
PM=$!

# 后台采样外部 IO
nettop -n -k time,bytes_in,bytes_out -x -P > /tmp/nt.log 2>&1 &
NT=$!

# 跑推理
time ollama run qwen3:32b-q4 "写一段 500 字的产品介绍，主题是量子计算"

# 停采样
kill $PM $NT

# 汇总
python3 parse_bench.py /tmp/pm.log /tmp/nt.log > E1.csv
```

**产出**：`E1.csv` + `E1.png`（内/外带宽随时间的双 y 轴 log 图）。

### E2 · 长 prompt 敏感度扫描

沿 prompt 长度 = {512, 4k, 32k, 128k} 扫描，观察外部 I/O 峰值。

### E3 · 对照组：Linux + vLLM

在一台 x86 + GPU 机器上跑 vLLM benchmark suite，作为对照。

---

## 状态

- [x] **E1 脚本** — [`E1_run.sh`](./E1_run.sh)
- [x] **E1 数据** — [`results/E1_20260706_160622/`](./results/E1_20260706_160622/)
- [x] **E1 报告** — [`E1_report.md`](./E1_report.md)：**LoB 严格下界 6.0 × 10⁹** ✅
- [x] **E2 脚本** — [`E2_run.sh`](./E2_run.sh)
- [x] **E2 报告** — [`E2_report.md`](./E2_report.md)：prompt 512→4322扫描，LoB 稳定
- [x] **E3 脚本** — [`E3_run.sh`](./E3_run.sh)
- [x] **E3 报告** — [`E3_report.md`](./E3_report.md)：⬜️ UMA 推理+CPU 任务并发无干扰 —— 反驳一个弱论据，精确化双轨价值
- [x] **E4 脚本** — [`E4_run.sh`](./E4_run.sh)
- [x] **E4 报告** — [`E4_report.md`](./E4_report.md)：✅ 长上下文 8k-64k prompt，LoB 均≥ 1.28×10⁸
- [ ] E5 batched serving 多用户并发（待做）
- [ ] E6 x86 + vLLM 对照组（待主人提供机器）

*当前默认引用 严格下界（120 GB/s DRAM 峰值）作为 LoB 内部带宽，以防射 "cache 帮了忙" 的质疑。*
