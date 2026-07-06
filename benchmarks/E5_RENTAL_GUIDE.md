# E5 · x86 + vLLM 对照组租机与执行手册

**目的**：在 x86 + NVIDIA GPU + 独立 HBM 架构上复现 M4 侧 E1/E2/E4 实验，证明 **LoB 是架构无关的普适现象**，而不是 Apple UMA 的特殊性。

---

## 🎯 推荐机型：实体云主机（bare-metal cloud）

| 供应商 | 机型 | 价格 | 位置 | 备注 |
|---|---|---|---|---|
| 🥇 **Vultr Bare Metal + GPU** | AMD EPYC + RTX A6000 48GB | $2.10/h | 东京 40ms | 5 分钟部署，按小时租 |
| 🥈 **Hetzner GPU Server** | RTX 6000 Ada 48GB | €1.19/h ≈ $85/三天 | 德国 | 便宜但延迟高 |
| 🥉 **CoreWeave / Lambda** | A100 80GB PCIe | $2.06/h | 美西 | 论文级严谨 |

**首选建议**：Vultr 东京 + RTX A6000 48GB · **$10-20 通宵**。

---

## 🚀 一键执行流程（拿到机器后）

```bash
# 1. SSH 上机
ssh root@<your-cloud-ip>

# 2. 装依赖（Ubuntu 22.04/24.04）
apt update && apt install -y python3-pip git dmidecode
pip3 install huggingface_hub requests

# 3. 拉仓库
git clone https://github.com/lilei0311/dual-track-ai-architecture.git
cd dual-track-ai-architecture/benchmarks

# 4. 一键跑
chmod +x E5_run.sh
bash E5_run.sh
```

**预计耗时**：15-30 分钟（含 vLLM 首次装载 + 4 组场景推理）
**预计花费**：$5-10（Vultr 按小时结算）

---

## 📊 输出对齐 M4 侧

`results/E5_<stamp>/E5_summary.json` 会给出 4 个场景的：

- `decode_tps_wall` — 与 M4 侧 27-29 TPS 直接对比
- `lob_ratio_strict` — 用 GPU HBM 峰值下界（A6000 = 768 GB/s，A100 = 1555 GB/s，H100 = 3350 GB/s）
- `lob_ratio_loose` — 用与 M4 相同的 9.6GB 权重扫描估算

---

## ✅ 预期结果

假设跑 A100 80GB（HBM 峰值 1555 GB/s）+ gemma-2-9b：

| 场景 | 预期 decode TPS | 预期 LoB 严格下界 |
|---|---|---|
| E5.1 baseline | 80-120 | ~10¹⁰ |
| E5.2 prompt2k | 60-100 | ~10⁹ |
| E5.3 prompt6k | 40-80 | ~10⁸-10⁹ |
| E5.4 prompt8k | 30-60 | ~10⁸ |

**如果 x86+NVIDIA 侧全部 LoB > 100:1**：论文主张升级为 **架构无关的普适规律**，可以直接放 6.1 节讨论。

**如果 x86 侧 LoB 显著低于 M4 侧**：反而更有意思——说明 UMA 在数据流上有隐藏优势，会需要额外一节讨论"为什么苹果做得更彻底"。

---

## ⚠️ 已知踩坑

1. **vLLM 首次装载 6-10 分钟**，脚本已加 120s 等待循环
2. **HuggingFace 下载慢**：可预先在国内镜像下载（`HF_ENDPOINT=https://hf-mirror.com`）
3. **A6000 vs A100 vs H100 HBM 峰值**：脚本 `E5_analyze.py` 已内置官方 datasheet 查表
4. **需要 sudo**：脚本用 `sudo dmidecode` 读 DRAM 类型，Vultr 默认 root
5. **max_model_len=8192**：8k 已够 E5 前 3 组；如要跑 32k/64k，改 `max-model-len 65536` + `gpu-memory-utilization 0.95`

---

## 🔀 备用方案：容器 / VM

如果实体云主机排队等太久，AutoDL/RunPod 容器也可以跑（但读不到 CPU 侧 `perf` 硬件计数器），出的数据只能到"应用层 tokens/s + GPU dmon" 级别，不影响 LoB 主张验证，只是不能对齐 M4 powermetrics 深度。

---

*本手册对齐 v0.6 paper.md § 5.3 实证方法学。*
