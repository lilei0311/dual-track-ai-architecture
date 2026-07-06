# EVIDENCE — 现役产品的 LoB 数据

> **本文件是 Tier 1 证据集。**
> 目标：把已经量产、跑在真实机器上的"接近 Track A"的产品拉出来，算它们的**内部带宽 / 外部接口带宽**比值。
>
> 如果这些量产品的比值都 ≥ 100:1 且已经在生产环境里跑得起来，那 LoB 假设就有存量证据。
>
> ⚠️ **数据可信度声明**：本文件初版数据来自公开厂商规格页与常识记忆。**每一行都需要用官方 datasheet / whitepaper 复核**。TODO 标记待补的引用。

---

## 数据表

| 产品 | 内部（memory / interconnect）带宽 | 外部接口带宽 | 内/外比 | LoB 支持度 | 备注 |
|---|---|---|---|---|---|
| **Apple M4 (base)** | ~120 GB/s (LPDDR5X, unified) | — (SoC 内) | N/A | ✓ 内嵌案例 | ANE ~38 TOPS INT8 |
| **Apple M4 Pro** | ~273 GB/s | — | N/A | ✓ 内嵌案例 | |
| **Apple M4 Max** | ~546 GB/s | — | N/A | ✓ 内嵌案例 | 单机可跑 70B q4 |
| **Apple M2 Ultra** | ~800 GB/s | Thunderbolt 4 (~5 GB/s) 出机箱 | **≈ 160 : 1** | ★★★ 强支持 | 若做外置 M2 Ultra dongle |
| **NVIDIA DGX Spark / GB10** | LPDDR5x-8533 ≈ **273 GB/s** unified | ConnectX-7 200GbE ≈ 25 GB/s | **≈ 11 : 1** | ★★ 中等支持 | 100 GbE 更常用则 ≈ 22:1 |
| **NVIDIA H100 SXM** | HBM3 ≈ **3 TB/s** | NVLink 900 GB/s（域内）/ PCIe Gen5 x16 ~64 GB/s（跨机） | **≈ 47 : 1**（PCIe） | ★★ 中等 | NVLink 域内不能算"外部" |
| **NVIDIA B200** | HBM3e ≈ **8 TB/s** | NVLink 5 ≈ 1.8 TB/s / PCIe Gen5 x16 ~64 GB/s | **≈ 125 : 1**（PCIe） | ★★★ 强支持 | |
| **Google Coral USB Accelerator** | Edge TPU 内部 SRAM ~数十 GB/s（估） | USB 3.0 ≈ 0.625 GB/s | **≈ 数十 : 1** | ★★ 中等 | 小模型场景已被验证 |
| **Hailo-8 M.2** | 板载 SRAM ~数百 GB/s（估） | PCIe Gen3 x4 ≈ 4 GB/s | **≈ 100 : 1** | ★★★ 强支持 | 26 TOPS INT8，边缘视觉 |
| **Qualcomm Hexagon NPU (SD8 Gen3)** | 共享 SoC memory ~77 GB/s | — (SoC 内) | N/A | ✓ 内嵌案例 | |
| **AMD XDNA (Ryzen AI)** | 共享 DDR ~90 GB/s | — (SoC 内) | N/A | ✓ 内嵌案例 | |
| **Thunderbolt 4 eGPU + RTX 4090** | GDDR6X ≈ 1 TB/s | TB4 ≈ 5 GB/s（PCIe Gen3 x4 等效） | **≈ 200 : 1** | ★★★ 强支持 | 游戏场景已量产多年 |
| **OCuLink 外置 GPU 盒 + RTX 4090** | GDDR6X ≈ 1 TB/s | OCuLink PCIe Gen4 x4 ≈ 8 GB/s | **≈ 125 : 1** | ★★★ 强支持 | 便宜、DIY 友好 |

**待补**：Intel Gaudi 3、AMD MI300X、Groq LPU、Cerebras WSE、Tenstorrent Wormhole、SambaNova。TODO(v0.4)。

---

## 关键观察

### 观察 1：**Thunderbolt eGPU 是 LoB 的存量证据**

从 2015 年 Thunderbolt 3 生态到 2026 年 TB4 / TB5，外置 GPU 一直有活跃的消费者市场。GPU 显存内部带宽 ≈ 1 TB/s，跨 TB4 接口 ≈ 5 GB/s，比值 200:1，**这个架构已经跑了 10 年了**。DTA 只是把它从 GPU 场景推广到 AI 推理场景。

如果 LoB 在游戏 GPU 场景成立，就没有强理由说它在 LLM 推理场景不成立——**LLM decoding 的外部 I/O 反而比游戏更低**（游戏还得吐画面到显示器）。

### 观察 2：**NVIDIA B200 已经内嵌了双轨思想**

B200 的 HBM3e 内部带宽 8 TB/s，PCIe Gen5 x16 外部只有 64 GB/s，比值 125:1。这意味着 NVIDIA 在自己的旗舰 AI 芯片上已经**默认接受了内外带宽悬殊**——芯片设计从一开始就假设"权重和 KV cache 不出芯片，外部接口只跑 prompt/token 流"。

我们只是把这个思想从"AI 芯片内部"推到"AI 模块与主机之间"。

### 观察 3：**Apple Silicon 是"Track A 尚未剥离"的证据**

M4 Max 单芯片 546 GB/s memory 已经足够跑 70B q4，但目前它和 CPU/GPU 共享 die。**把 Neural Engine + 一块专属 HBM 从 M4 Max 里剥出来，通过 TB5 连回一台普通 Mac**，就是本架构的 Apple 版原型。这在 Apple 内部技术上完全可行；不做只是产品线定义没到。

### 观察 4：**DGX Spark 是当前最接近 Track A 的量产品**

Grace + Blackwell + 128GB unified memory + 独立机箱 + 网线连回工作站——**这就是 Track A**。它现在贵，但形态已经定义好了。DTA 的产品雏形已经存在，只是需要（a）便宜下来（b）标准化接口（c）走 USB4/TB 而非 200GbE 网线。

### 观察 5：**边缘侧 Coral / Hailo 已经量产了小型 Track A**

Coral USB Accelerator ≈ 60 USD，Hailo-8 M.2 ≈ 200 USD，两者都是"独立封装 + 窄接口 + 内部 SRAM"的经典 DTA 形态。**只是当前它们只跑小模型（<1B）**。DTA 的核心工程挑战是"把这个形态放大到 7B–70B 参数级别，同时保持 <500 USD 的消费者定价"。

---

## 反证候选（待 Tier 4 深挖）

- **DGX Spark 的 200GbE 网线**：如果 25 GB/s 网线已经是当前旗舰的选择，说明厂商认为 USB 级别（5 GB/s）**不够**。为什么？多用户？还是模型热切换？
- **NVLink vs PCIe**：H100/B200 在同一 rack 内跑 NVLink 900+ GB/s，说明在**训练+超大集群**场景 LoB 不成立。但训练本文明确不覆盖。
- **Cerebras WSE**：整晶圆芯片，走的是"全部在片上"路线——是 DTA 的极端版还是反例，取决于外部接口。

---

## 数据来源与复核 TODO

- [ ] Apple M4 系列 memory bandwidth：Apple Newsroom / M4 whitepaper
- [ ] DGX Spark：NVIDIA 官方 spec sheet（Project DIGITS announce）
- [ ] Coral：Google Coral datasheet
- [ ] Hailo-8：Hailo product page
- [ ] Thunderbolt 4/5：Intel TB4/5 spec
- [ ] B200/H100：NVIDIA H100/B200 whitepaper
- [ ] Cerebras / Groq / Tenstorrent：各自 architecture whitepaper

**PR 欢迎**：如果你手边有权威 datasheet 数字，帮忙修正上表。

---

*Version: v0.3 · 2026-07-06*
