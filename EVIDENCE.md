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
| **NVIDIA DGX Spark / GB10** | LPDDR5x-8533 ≈ **273 GB/s** unified | ConnectX-7 200GbE ≈ 25 GB/s | **≈ 11 : 1** | ★★ 中等支持 | 100 GbE 更常用则 ≈ 22:1。2026-Q3 因 LPDDR5X 供应紧张从 $3,999 涨到 **$4,699 (+18%)**（[Tom's Hardware](https://www.tomshardware.com/desktops/mini-pcs/nvidia-dgx-spark-gets-18-percent-price-increase-as-memory-shortages-bite-founders-edition-now-usd4-699-up-from-usd3-999)） |
| **NVIDIA H100 SXM** | HBM3 ≈ **3 TB/s** | NVLink 900 GB/s（域内）/ PCIe Gen5 x16 ~64 GB/s（跨机） | **≈ 47 : 1**（PCIe） | ★★ 中等 | NVLink 域内不能算"外部" |
| **NVIDIA B200** | HBM3e ≈ **8 TB/s** | NVLink 5 ≈ 1.8 TB/s / PCIe Gen5 x16 ~64 GB/s | **≈ 125 : 1**（PCIe） | ★★★ 强支持 | |
| **RK182X 外置算力卡（RK1828）** | **3D-stacked DRAM ≈1 TB/s** 内部带宽 | PCIe 2.0 x1 / USB 3.0 ≈ 0.5 GB/s | **≈ 2000 : 1** | ★★★ 强支持 | 聪明CC 复核：20 TOPS，支持 0.5B–8B，官方 RKNN3 SDK 数据 **Qwen3-8B decode 61.11 TPS**。**8B 模型已能跑在“窄接口外置协处理器”上——DTA 低端形态已实现** |
| **华为昂腾 AI Station 盒子** | 内部专用总线 ~百 GB/s（估） | PCIe + USB | **~100:1**（估） | ★★★ 强支持 | 176 TOPS，具身智能盒子形态 |
| **Intel Movidius NCS2** | 内部 SRAM | USB 3.0 | 估 ≥ 50:1 | ★★ 中等 | 视觉推理专用 |
| **Google Coral USB Accelerator** | Edge TPU 内部 SRAM ~数十 GB/s（估） | USB 3.0 ≈ 0.625 GB/s | **≈ 数十 : 1** | ★★ 中等 | 小模型场景已被验证 |
| **Hailo-8 M.2** | 板载 SRAM ~数百 GB/s（估） | PCIe Gen3 x4 ≈ 4 GB/s | **≈ 100 : 1** | ★★★ 强支持 | 26 TOPS INT8，边缘视觉 |
| **Qualcomm Hexagon NPU (SD8 Gen3)** | 共享 SoC memory ~77 GB/s | — (SoC 内) | N/A | ✓ 内嵌案例 | |
| **AMD XDNA (Ryzen AI)** | 共享 DDR ~90 GB/s | — (SoC 内) | N/A | ✓ 内嵌案例 | |
| **Thunderbolt 4 eGPU + RTX 4090** | GDDR6X ≈ 1 TB/s | TB4 ≈ 4–5 GB/s（PCIe Gen3 x4 等效） | **≈ 200–250 : 1** | ★★★ 强支持 | 聪明CC 复核：游戏场景 **只损失 20% 性能**，已量产 10 年 — [TechPowerUp 测试](https://www.techpowerup.com/review/nvidia-geforce-rtx-4090-pci-express-scaling/29.html) |
| **OCuLink 外置 GPU 盒 + RTX 4090** | GDDR6X ≈ 1 TB/s | OCuLink PCIe Gen4 x4 ≈ 8 GB/s | **≈ 125 : 1** | ★★★ 强支持 | 聪明CC 复核：**只损失 8–15% 性能**，便宜、DIY 友好 |

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

### 观察 6（聪明CC v0.4 新增）：**RK1828 是边缘侧最强的 LoB 实证**

Rockchip RK182X 系列采用 **3D-stacked DRAM 方案，内部带宽 ≈ 1 TB/s**，对外只有 PCIe 2.0 x1 / USB 3.0（~0.5 GB/s）——**内/外带宽比 2000:1**。官方 RKNN3 SDK V1.0.0 预发数据显示 **Qwen3-8B 在 RK1828 上 decode 能到 61.11 TPS**。

这直接推翻了一个直觉：“8B 模型一定需要宽接口。” **DTA 的低端形态已经存在于 Rockchip 的产品路线图里**；现在的问题只是“从 8B 变 70B 需要多少 HBM”，不是“架构能不能成立”。

### 观察 7（聪明CC v0.4 新增）：**2026 内存危机为 DTA 提供市场推力**

- DGX Spark 从 $3,999 涨到 $4,699 （+18%），直接原因是 LPDDR5X 供应紧张
- HBM 售罄，DDR5 预计 2026 同比翻倍，GPU 交付周期 36–52 周
- **意义**：把 AI 推理所需的高带宽内存从“通用系统”里剥离，采购可以分批、供应链反而变灵活——一体化方案（金正浩 100 层、Apple unified memory）在内存短缺周期里反而风险更高

---

## 反证候选（待 Tier 4 深挖）

- **DGX Spark 的 200GbE 网线**：如果 25 GB/s 网线已经是当前旗舰的选择，说明厂商认为 USB 级别（5 GB/s）**不够**。为什么？多用户？还是模型热切换？
- **NVLink vs PCIe**：H100/B200 在同一 rack 内跑 NVLink 900+ GB/s，说明在**训练+超大集群**场景 LoB 不成立。但训练本文明确不覆盖。
- **Cerebras WSE**：整晶圆芯片，走的是"全部在片上"路线——是 DTA 的极端版还是反例，取决于外部接口。

---

## 三个子假设的产业证据（悟色 v1.0 预研成果合并）

悟色的 `validation_plan.md` 把 LoB 假设拆成了三个可验证的子命题，下面把她拉的产业证据归类存档。

### H1 · 内外带宽需求比 > 10⁶:1

- **DDN 实测**：GPU HBM 仅 512GB，系统 RAM 512GB，推理中 GPU 有效利用率 **10%-30%**
  — [来源](https://wiki.lustre.org/images/b/b8/LUG2026-DDN_Sponsor_Talk-LLM_Experiments-Skupinski.pdf)
- **金正浩**："AI 装100万台GPU，真正工作的时间只有10%"
  — [来源](https://tech.ifeng.com/c/8uVduE3DXN2)
- **7B 模型在 2048 token 上下文时 KV Cache 已超 32GB 显存**
  — [来源](https://blog.csdn.net/gfdr5/article/details/158498850)
- **DRAM 价格暴涨 3.5-5 倍，内存占服务器成本从 50% → 75%**

→ **结论**：内存是当前瓶颈，内部带宽需求确实远超外部。

### H2 · USB 级接口足以支撑推理外部传输

- **Coral USB Accelerator**：树莓派 + USB 3.0 稳定跑推理，延迟 60–100ms，功耗 <2W
  — [来源](https://blog.csdn.net/weixin_42590539/article/details/154431696)
- **RK182X**：USB+PCIe 与主控通信，支持 8B 大模型本地推理
  — [来源](https://developer.cloud.tencent.cn/article/2682979)
- **昂腾 AI Station**：PCIe+USB 接口运行 176 TOPS 推理
  — [来源](https://m.elecfans.com/article/7833562.html)

→ **结论**：USB 级接口已被 **量产产品** 验证可支撑边缘 AI 推理；DTA 的工程先辈已存在。

### H3 · 独立模块方案比整合方案更具工程可行性

- 金正浩 100 层 3D 方案：预计 **10-15 年** 初步实现，供电需数千安培
- **HBF 标准化联盟**：闪迪 + SK 海力士 **2026 年 2 月启动**，2027 年出样品
  — [来源](https://tech.ifeng.com/c/8uVduE3DXN2)
- **MRDIMM 过渡方案**：兼容现有 DDR5 插槽，带宽提升 40%，2026-2028 规模化
  — [来源](https://m.eeworld.com.cn/news_mp/AIxintianxia/a426958.jspx)
- **RK182X / Coral USB / 昂腾 AI Station** 均验证"独立模块"形态可行

→ **结论**：独立模块形态已被产业实践采用，但 HBM 级独立模块尚未有成品——这就是 DTA 的市场空档。

---

## 数据来源与复核 TODO

- [ ] Apple M4 系列 memory bandwidth：Apple Newsroom / M4 whitepaper
- [ ] DGX Spark：NVIDIA 官方 spec sheet（Project DIGITS announce）
- [ ] Coral：Google Coral datasheet
- [ ] Hailo-8：Hailo product page
- [ ] Thunderbolt 4/5：Intel TB4/5 spec
- [ ] B200/H100：NVIDIA H100/B200 whitepaper
- [ ] Cerebras / Groq / Tenstorrent：各自 architecture whitepaper
- [ ] RK182X：Rockchip 官方 datasheet（惟色 v1.0 引入）
- [ ] 昂腾 AI Station：华为 Ascend 官方 spec（惟色 v1.0 引入）
- [ ] Intel Movidius NCS2：Intel datasheet

以上交接给 **聪明CC** 统一复核，见 [`TASKS-FOR-CC.md`](./TASKS-FOR-CC.md)。

---

*Version: v0.3 · 2026-07-06*
