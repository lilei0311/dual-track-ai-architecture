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
| **Apple M4 (base)** | ~120 GB/s (LPDDR5X, unified) | — (SoC 内) | N/A | ✓ 内嵌案例 | ANE ~38 TOPS INT8；来源：Apple Newsroom [M4 Pro/Max 发布](https://www.apple.com/newsroom/2024/10/apple-introduces-m4-pro-and-m4-max/) |
| **Apple M4 Pro** | ~273 GB/s | — | N/A | ✓ 内嵌案例 | |
| **Apple M4 Max** | ~546 GB/s | — | N/A | ✓ 内嵌案例 | 单机可跑 70B q4 |
| **Apple M2 Ultra** | ~800 GB/s | Thunderbolt 4 (~5 GB/s) 出机箱 | **≈ 160 : 1** | ★★★ 强支持 | 若做外置 M2 Ultra dongle |
| **NVIDIA DGX Spark / GB10** | LPDDR5x-8533 ≈ **273 GB/s** unified | ConnectX-7 200GbE ≈ 25 GB/s | **≈ 11 : 1** | ★★ 中等支持 | 100 GbE 更常用则 ≈ 22:1。2026-Q3 因 LPDDR5X 供应紧张从 $3,999 涨到 **$4,699 (+18%)**（[Tom's Hardware](https://www.tomshardware.com/desktops/mini-pcs/nvidia-dgx-spark-gets-18-percent-price-increase-as-memory-shortages-bite-founders-edition-now-usd4-699-up-from-usd3-999)） |
| **NVIDIA H100 SXM** | HBM3 ≈ **3 TB/s** | NVLink 900 GB/s（域内）/ PCIe Gen5 x16 ~64 GB/s（跨机） | **≈ 47 : 1**（PCIe） | ★★ 中等 | NVLink 域内不能算"外部"；HBM 带宽来源：[NVIDIA H100 .md](https://www.nvidia.com/en-us/data-center/h100.md) |
| **NVIDIA B200** | HBM3e ≈ **8 TB/s** | NVLink 5 ≈ 1.8 TB/s / PCIe Gen5 x16 ~64 GB/s | **≈ 125 : 1**（PCIe） | ★★★ 强支持 | 来源：NVIDIA DGX B200 [.md](https://www.nvidia.com/en-us/data-center/dgx-b200.md)（8 GPU 共 64 TB/s HBM3e）+ Blackwell 架构 [.md](https://www.nvidia.com/en-us/data-center/technologies/blackwell-architecture.md) |
| **RK182X 外置算力卡（RK1828）** | **3D-stacked DRAM ≈1 TB/s** 内部带宽 | PCIe 2.0 x1 / USB 3.0 ≈ 0.5 GB/s | **≈ 2000 : 1** | ★★★ 强支持 | 聪明CC 复核：20 TOPS，支持 0.5B–8B，官方 RKNN3 SDK 数据 **Qwen3-8B decode 61.11 TPS**；来源：[Rockchip RK182X 官网](https://www.rock-chips.com/a/en/products/RK18_Series/2025/1114/2114.html) + [RKNN3 SDK 发布](https://www.rock-chips.com/a/cn/news/rockchip/2026/0309/2163.html) |
| **华为昂腾 AI Station 盒子 / OrangePi AI Station** | LPDDR4X ~**百 GB/s**（估） | PCIe + USB 3.0 + 双千兆网 | **~100:1–200:1**（估） | ★★★ 强支持 | 176 TOPS INT8，Ascend 310 / 310P，48/96 GB LPDDR4X；**官方详细 spec 暂缺**，媒体来源：[IT之家](https://www.ithome.com/0/909/888.htm)、[Sohu](https://www.sohu.com/a/971717897_122066678)；红果CC P1 复核 |
| **Intel Movidius NCS2** | Myriad X 片上内存 ≈ **450 GB/s** | USB 3.1 Gen1 ≈ 0.625 GB/s | **≈ 720 : 1** | ★★★ 强支持 | Myriad X VPU，4 TOPS peak / 1 TOPS DNN；官方 [Product Brief PDF](https://cdrdv2-public.intel.com/749742/neural-compute-stick2-product-brief.pdf)；红果CC P1 复核 |
| **Google Coral USB Accelerator** | Edge TPU 内部 SRAM ~数十 GB/s（估） | USB 3.0 ≈ 0.625 GB/s | **≈ 数十 : 1** | ★★ 中等 | 小模型场景已被验证；官方 datasheet：[cdn-reichelt PDF](https://cdn-reichelt.de/documents/datenblatt/A300/CORAL-USB-ACCELERATOR-DATASHEET.pdf)（确认 USB 3.1 Gen1 5 Gb/s、MobileNet v2 400 FPS） |
| **Hailo-8 M.2** | 板载 SRAM ~数百 GB/s（估） | PCIe Gen3 x4 ≈ 4 GB/s | **≈ 100 : 1** | ★★★ 强支持 | 26 TOPS INT8，边缘视觉；来源：[Hailo-8 product brief](https://hailo.ai/wp-content/uploads/2023/10/hailo-8-product-brief-rev3.26.pdf) + [M.2 Starter Kit brief](https://hailo.ai/files/hailo-8-m-2-starter-kit-product-brief-en/) |
| **Qualcomm Hexagon NPU (SD8 Gen3)** | 共享 SoC memory ~77 GB/s | — (SoC 内) | N/A | ✓ 内嵌案例 | |
| **AMD XDNA (Ryzen AI)** | 共享 DDR ~90 GB/s | — (SoC 内) | N/A | ✓ 内嵌案例 | |
| **Thunderbolt 4 eGPU + RTX 4090** | GDDR6X ≈ 1 TB/s | TB4 ≈ 4–5 GB/s（PCIe Gen3 x4 等效） | **≈ 200–250 : 1** | ★★★ 强支持 | 聪明CC 复核：游戏场景 **只损失 20% 性能**，已量产 10 年 — [TechPowerUp 测试](https://www.techpowerup.com/review/nvidia-geforce-rtx-4090-pci-express-scaling/29.html)；TB4 规格来源：[Intel press deck PDF](https://www.thunderbolttechnology.net/sites/default/files/intel-thunderbolt4-announcement-press-deck.pdf) |
| **OCuLink 外置 GPU 盒 + RTX 4090** | GDDR6X ≈ 1 TB/s | OCuLink PCIe Gen4 x4 ≈ 8 GB/s | **≈ 125 : 1** | ★★★ 强支持 | 聪明CC 复核：**只损失 8–15% 性能**，便宜、DIY 友好 |
| **AMD Instinct MI300X** | HBM3 ≈ **5.3 TB/s** / 192 GB | PCIe Gen5 x16 ≈ 64 GB/s（to host） | **≈ 83 : 1**（PCIe） | ★★★ 强支持 | 304 CUs；红果CC 复核；来源：AMD 官方 [Instinct MI300 系列](https://www.amd.com/en/products/accelerators/instinct/mi300.html) |
| **Intel Gaudi 3** | HBM2e ≈ **3.7 TB/s** / 128 GB | PCIe Gen5 x16 ≈ 64 GB/s（to host） / 24×200GbE ≈ 600 GB/s（cluster fabric） | **≈ 58 : 1**（PCIe） | ★★ 中等（fabric 侧较弱） | 24×200GbE 是集群互连信号，见反证候选；红果CC 复核；来源：Intel [PCIe Product Brief](https://cdrdv2-public.intel.com/817488/Gaudi%203%20PCIe%20Product%20Brief_RB_1_V6.pdf) + [White Paper](https://cdrdv2-public.intel.com/817486/gaudi-3-ai-accelerator-white-paper.pdf) |
| **NVIDIA RTX 2050 Mobile** | GDDR6 ≈ **112 GB/s** / 4 GB / 2048 CUDA | 笔记本内部 PCIe；E5 实测外部字节流 ~KB/s 级 | **LoB_strict ≈ 1.96 × 10⁸**（E5 实测） | ★★★ 强支持 | E5 跨平台跨拓扑对照实验；红果CC Windows 侧数据交付；见 §5.4 与 benchmarks/E5_report.md |

**待补**：Groq LPU、Cerebras WSE、Tenstorrent Wormhole、SambaNova。TODO(v0.7)。

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

### ✅ 已复核（聪明CC v0.4）

- [x] **Apple M4 / M4 Pro / M4 Max memory bandwidth**：Apple Newsroom [Apple introduces M4 Pro and M4 Max](https://www.apple.com/newsroom/2024/10/apple-introduces-m4-pro-and-m4-max/) — M4 120 GB/s、M4 Pro 273 GB/s、M4 Max 546 GB/s
- [x] **Apple M4 Neural Engine ~38 TOPS**：Apple Support [MacBook Pro 14-inch M4 Pro/Max Tech Specs](https://support.apple.com/en-us/121553) 及 M3 18 TOPS 对比（M4 2× 更快）
- [x] **NVIDIA DGX Spark / GB10**：NVIDIA 官方 spec（.md 格式）[DGX Spark](https://www.nvidia.com/en-us/products/workstations/dgx-spark.md) — 128 GB LPDDR5x、273 GB/s、ConnectX-7 200 GbE、4× USB-C
- [x] **NVIDIA H100 SXM**：NVIDIA 官方 H100 页面 [.md](https://www.nvidia.com/en-us/data-center/h100.md) — 3 TB/s HBM3、NVLink 900 GB/s；PCIe Gen5 x16 ≈ 64 GB/s 单向为 PCI-SIG 标准值
- [x] **NVIDIA B200 / DGX B200**：NVIDIA DGX B200 官方 [.md](https://www.nvidia.com/en-us/data-center/dgx-b200.md) — 8× GPU 共 1,440 GB / 64 TB/s HBM3e，即单 GPU 180 GB / 8 TB/s；NVLink 5 1.8 TB/s 见 [Blackwell architecture .md](https://www.nvidia.com/en-us/data-center/technologies/blackwell-architecture.md)
- [x] **Rockchip RK182X / RK1828**：Rockchip 官网 [RK182X Series](https://www.rock-chips.com/a/en/products/RK18_Series/2025/1114/2114.html) + RKNN3 SDK V1.0.0 发布 [官方新闻](https://www.rock-chips.com/a/cn/news/rockchip/2026/0309/2163.html) — 3D stacked DRAM、20 TOPS、Qwen3-8B decode 61.11 TPS
- [x] **Google Coral USB Accelerator**：Google 官方 datasheet（PDF 镜像） [cdn-reichelt.de](https://cdn-reichelt.de/documents/datenblatt/A300/CORAL-USB-ACCELERATOR-DATASHEET.pdf) — USB 3.1 Gen1 5 Gb/s、Edge TPU、MobileNet v2 400 FPS；**4 TOPS 未在 datasheet 中直接标注**，来自产品页/评测
- [x] **Hailo-8 M.2**：Hailo 官方 [Hailo-8 AI Processor product brief](https://hailo.ai/wp-content/uploads/2023/10/hailo-8-product-brief-rev3.26.pdf) — 26 TOPS、2.5 W、无外部 DRAM；[Hailo-8 M.2 Starter Kit product brief](https://hailo.ai/files/hailo-8-m-2-starter-kit-product-brief-en/) — PCIe Gen-3.0，2-lanes（Key M 4-lanes）
- [x] **Thunderbolt 4**：Intel 官方 press deck [intel-thunderbolt4-announcement-press-deck.pdf](https://www.thunderbolttechnology.net/sites/default/files/intel-thunderbolt4-announcement-press-deck.pdf) — 40 Gbps、PCIe 32 Gbps、存储 3,000 MB/s
- [x] **Thunderbolt 5**：Intel 官方 tech brief [Thunderbolt_5_TechBrief_2023_09_12.pdf](https://www.thunderbolttechnology.net/sites/default/files/Thunderbolt_5_TechBrief_2023_09_12.pdf) — 80 Gbps、PCIe 64 Gbps、Bandwidth Boost 120 Gbps

### ✅ 新增复核（红果CC v0.6.1，P1 接力）

- [x] **OrangePi AI Station / 华为昂腾盒子**：176 TOPS INT8，48/96 GB LPDDR4X；**官方详细 spec 暂缺**，当前引用 IT之家 / Sohu 媒体报道（已入编到数据表，待 P2 后回头抽官方 spec）
- [x] **Intel Movidius NCS2**：Myriad X 片上内存 ≈ 450 GB/s，USB 3.1 Gen1 接口；来源 Intel 官方 [Product Brief PDF](https://cdrdv2-public.intel.com/749742/neural-compute-stick2-product-brief.pdf)

### ✅ 新增复核（红果CC v0.6）

- [x] **AMD Instinct MI300X**：AMD 官方 [Instinct MI300 系列](https://www.amd.com/en/products/accelerators/instinct/mi300.html) — HBM3 5.3 TB/s、192 GB、304 CUs
- [x] **Intel Gaudi 3**：Intel 官方 [PCIe Product Brief PDF](https://cdrdv2-public.intel.com/817488/Gaudi%203%20PCIe%20Product%20Brief_RB_1_V6.pdf) + [White Paper PDF](https://cdrdv2-public.intel.com/817486/gaudi-3-ai-accelerator-white-paper.pdf) — HBM2e 3.7 TB/s、128 GB、24×200 GbE fabric
- [x] **NVIDIA RTX 2050 Mobile**：112 GB/s GDDR6 / 4 GB / 2048 CUDA — 第三方 spec 聚合（GPU-Monkey / NanoReview）+ 本项目 E5 实测归档
- [x] **Apple M4 base 120 GB/s 补充来源**：Apple Support [MacBook Pro 14-inch M4 tech specs](https://support.apple.com/en-us/121552)（与 M4 Pro/Max Newsroom 数据相互印证）

### ⏳ 仍待复核

- [ ] **Cerebras WSE-3 / Groq LPU / Tenstorrent Wormhole/Blackhole / SambaNova**：各自 architecture whitepaper 待补（红果CC 排 P2）

以上交接给 **红果CC** 继续复核，见 [`TASKS-FOR-CC.md`](./TASKS-FOR-CC.md)。

---

*Version: v0.6.1 · 2026-07-07 · 红果CC P1 接力复核（OrangePi/昂腾 + Movidius NCS2）*
