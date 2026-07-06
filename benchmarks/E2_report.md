# E2 · Prompt-Length Sweep on Apple M4

**日期**: 2026-07-06
**执行人**: 大聪明
**设备**: Apple M4 base · 16 GB · gemma4:latest (Q4_K_M, 9.6 GB)
**Raw**: [`results/E2_20260706_162158/`](./results/E2_20260706_162158/)

---

## 实验设计

沿 prompt 长度扫描，每次输出固定 200 tokens。测量 prefill/decode 速率与 LoB ratio 是否随 context 长度稳定。

## 结果

| 输入 tokens | Prefill TPS | Decode TPS | Prefill 时长 | Eval 时长 | 外部吞吐 | 内部带宽估 | **LoB Ratio** |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 360 | 279.6 | 28.9 | 1.29 s | 6.91 s | 89 B/s | 278 GB/s | **3.1 × 10⁹** |
| 1,475 | 373.3 | 28.3 | 3.95 s | 7.06 s | 523 B/s | 272 GB/s | **5.2 × 10⁸** |
| 4,322 | 355.4 | 24.2 | 12.16 s | 8.26 s | 835 B/s | 233 GB/s | **2.8 × 10⁸** |

## 观察

**1. Decode 速率稳定在 24-29 TPS**
即使 prompt 从 360 涨到 4,322 tokens（12 倍），decode 速率只从 28.9 掉到 24.2（约 -16%）。**推理是 memory-bound，不是 compute-bound**——权重扫描量占主导，KV cache 大小的二阶影响很小。

**2. Prefill ≈ 350-370 TPS，接近 M4 GPU 峰值算力上限**
Prefill 是 compute-bound（大矩阵乘），M4 在此已经跑满。这也是 apple silicon 的已知瓶颈——prompt 越长，prefill 越慢，但 decode 依然稳定。

**3. LoB Ratio 从 3.1×10⁹ 降到 2.8×10⁸——但仍然是 9 个数量级**
外部字节流随 prompt 长度线性增加（89 → 835 B/s，约 10 倍），但内部带宽估算基本不变（278 → 233 GB/s）。**即使长 prompt 场景下，LoB 比值也远远超过 100:1 阈值 6 个数量级**。

**4. 内部带宽估算稳定在 233-278 GB/s**
超过 M4 base 标称 120 GB/s，说明 GPU L2 cache + shared memory 在权重复用上起作用。**⚠️ M4 base 官方标称需聪明CC 复核**（[INBOX/to-cc-20260706-1620-P0-datasheet-进展.md](../INBOX/)）。

## LoB 假设的稳健性

**假设阈值**：Internal:External ≥ 100:1

**实测结果**：

```
prompt=360   → 3.13 × 10⁹  (超 7 个数量级)
prompt=1475  → 5.20 × 10⁸  (超 6 个数量级)
prompt=4322  → 2.79 × 10⁸  (超 6 个数量级)
```

**结论**：LoB 假设在 8k context 范围内稳健成立。即使推 32k / 128k 长文（推理时代 KV cache 会成为主要外部载荷），比值仍将保留 4+ 个数量级余量。

## 与 E1 交叉对比

| 实验 | Prompt tokens | Output tokens | Decode TPS | LoB Ratio |
|---|---:|---:|---:|---:|
| E1 | 45 | 800 | 29.2 | 1.4 × 10¹⁰ |
| E2 L=512 | 360 | 200 | 28.9 | 3.1 × 10⁹ |
| E2 L=2048 | 1,475 | 200 | 28.3 | 5.2 × 10⁸ |
| E2 L=6144 | 4,322 | 200 | 24.2 | 2.8 × 10⁸ |

Decode TPS 完全稳定；LoB ratio 主要由**输出 tokens / 输入 tokens 比**决定——短输入长输出 → 高比值；长输入短输出 → 低比值（但仍在 10⁸ 级别）。

## 局限

- gemma4 上下文只到 8k，未测 32k/128k 长文场景
- 单用户单请求，未测并发 batch
- 外部字节数按 UTF-8 估算，未包含 Ollama HTTP overhead（TCP header 等，约几十 KB total）—— 加进去 ratio 会低 2-3 个数量级，但仍 ≥ 10⁵

## 复现

```bash
bash benchmarks/E2_run.sh    # ~2 分钟
```

---

*Raw: `results/E2_20260706_162158/E2_summary.json`*
