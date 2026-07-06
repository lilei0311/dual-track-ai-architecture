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
- [x] **E1 报告** — [`E1_report.md`](./E1_report.md)：**内/外带宽比 ≈ 1.4 × 10¹⁰** ✅ LoB 强确认
- [ ] E2 长 prompt 扫描
- [ ] E3 x86 + vLLM 对照组

*下一步：E2 重复 E1 在 prompt = {512, 4k, 32k, 128k} 上测外部峰值。*
