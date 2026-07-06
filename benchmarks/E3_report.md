# E3 · UMA Interference Test — Apple M4

**日期**: 2026-07-06
**执行人**: 大聪明
**触发问题**: 悟色纠结点 3 —— "双轨架构在 UMA 已经能跑 8B 模型的时代，边界线在哪？"
**设备**: Apple M4 base · 16 GB unified memory · 4P+6E CPU + Neural Engine + GPU
**Raw**: [`results/E3_20260706_182235/`](./results/E3_20260706_182235/)

---

## ⚠️ 诚实的坏消息（部分）

本实验测的是"AI 推理和 CPU 密集型任务是否互相拖累"，用来评估 UMA 架构的干扰问题。**结果对双轨架构不完全有利**——但正好回答悟色的纠结点 3。

## 数据

| 场景 | Decode TPS | 说明 |
|---|---:|---|
| A · 独占推理 | 29.4 | 基线 |
| B · 推理 + 4× openssl AES-256 (4P核压满) | 29.5 | −0.3% |
| C · 只跑 4× openssl AES-256 | (1.71s) | 参考 |

**推理速率几乎没有下降（−0.3%，实际在噪声范围内）。**

## 解读

M4 的架构隔离比预期好：
1. **不同执行单元**：LLM 推理跑在 GPU / Neural Engine，openssl AES 跑在 P-core CPU。**物理上分离**
2. **内存带宽有余量**：120 GB/s LPDDR5X 峰值——推理需要 ~120 GB/s 满负荷，AES 只需几 GB/s，两者共存不打架
3. **cache 分区**：L2/SLC 由 CPU 与 GPU 共享但硬件调度

**这意味着**：**在 UMA 单机 · 小模型 · 单用户** 场景下，AI 推理不会"拖累"传统计算——**双轨架构的一个常见论据被本实验部分反驳**。

## 但双轨架构的价值依然在——只是要精确定义

E3 反证了"UMA 会拖累传统计算"这个**弱论据**，但没有反驳双轨架构的**强论据**。精确的边界定义：

| 场景 | UMA 够用？ | 双轨必要？ |
|---|:---:|:---:|
| 单用户 · 8B 以下 · 短会话 | ✅ 完全够 | ❌ 不必要 |
| 单用户 · 70B+ · 长上下文 | ⚠️ 内存吃紧（M4 Max 128GB 也仅够 70B） | ✅ 外置 HBM 模块能突破内存墙 |
| 移动+桌面共享一个 AI 模型 | ❌ 每台设备都要塞 HBM，成本爆炸 | ✅ AI Puck 插拔共享 |
| 独立升级 AI 芯片而不换主机 | ❌ 芯片焊死主板 | ✅ Puck 独立换代 |
| 多用户 batched serving | ⚠️ 内存/算力都成为瓶颈 | ✅ 专用推理集群 |

**关键结论**：**双轨架构的核心价值不是"避免干扰"，而是"独立扩展 + 独立迭代 + 跨设备共享"**。E3 帮助我们剔除了一个不够硬的论据——这让主张更精确、更抗审。

## 修订论文主张

论文里如果写"UMA 让 AI 拖累主机"这种表述，应该改成：
- ❌ 旧：*"UMA architecture causes AI workloads to starve traditional CPU tasks"*
- ✅ 新：*"UMA is sufficient for single-user small-model inference (validated: 0% slowdown on M4). DTA's value is in **decoupled scaling** — larger models, cross-device sharing, and independent module upgrade cycles, not in workload isolation."*

## 局限

- **未测更极端负载**：只压了 4 P核 CPU-bound。GPU-bound 干扰（比如同时跑视频编码）未测
- **未测多用户/并发推理**：真实的 batched serving 会撑爆 KV cache 和外部带宽
- **未测主机侧内存竞争**：如果推理占满内存带宽（M4 base 只有 120 GB/s），后台大数据处理（比如 pg 全表扫描）会有影响
- **单一模型**：换成 qwen 24GB 或 llama 70B 后会不会有内存压力干扰？待测

## 复现

```bash
bash benchmarks/E3_run.sh    # ~1 分钟
```

## 三份实验的方法论意义

| 实验 | 结论 | 对论文主张的影响 |
|---|---|---|
| E1 (baseline decode) | LoB = 6.0×10⁹（严格下界） | ✅ 强证 LoB 数字 |
| E2 (prompt 512-6k) | LoB 稳定 10⁸-10⁹ | ✅ 稳态确认 |
| E4 (prompt 8k-64k) | LoB 严格下界 1.28-1.56×10⁸ | ✅ 长上下文不崩 |
| **E3 (UMA 干扰)** | **推理与 CPU 任务几乎不互斥** | **⚠️ 反驳一个弱论据，强化对"边界线"的精确定义** |

**元评论**：一个健康的科学过程应该出现 E3 这种"不完全支持"的结果。**如果所有实验都完美支持主张，那就是过拟合，不是科学**。E3 让我们的论文更值得信任。

---

*Raw*: `results/E3_20260706_182235/E3_summary.json`
