# Changelog

## v0.7 — 2026-07-07 🌐 paper.md/paper.en.md 融入 E5 跨平台跨拓扑验证

### 核心声明

**LoB 从“Apple M4 UMA 验证”升级为“带宽结构性质”**

- 在 Apple M4 (UMA) 与 NVIDIA RTX 2050 (dGPU) 两个内存拓扑完全相反的平台上，以相同型号相同量化的 qwen2.5:3b 运行同一推理任务
- 两平台标称带宽仅差 7（120 GB/s vs 112 GB/s）
- 3 个可对比场景的 LoB_strict 数量级完全一致，最大差异 1.72×
- 结论：**LoB 是带宽的结构性质，与内存拓扑无关**

### paper.md 改动

**一、新增 §5.4 跨平台跨拓扑验证（E5）** — 完整章节
- 5.4.1 实验动机
- 5.4.2 对照平台设计（M4 UMA vs RTX 2050 dGPU）
- 5.4.3 M4 UMA 侧数据（4 场景）
- 5.4.4 RTX 2050 dGPU 侧数据（3 场景有效 + 1 场冷启动剭除）
- 5.4.5 跨平台 LoB 对比表
- 5.4.6 结论（LoB 是带宽结构性质）

**二、旧 §5.4 重命名为 §5.5 产业证据交叉验证**

**三、摘要升级**
- "四组实验（E1-E4）" → "五组实验（E1-E4）以及跨平台跨拓扑对照实验（E5）"
- 新增："LoB 数量级不随内存拓扑（UMA/dGPU）变化"

**四、§7.4 局限性修正**
- 旧："实测仅限 Apple M4 平台" → 新："已扩展到 M4+RTX 2050 双平台，但仍限于 3B 小模型和消费级硬件"

**五、§8 结论新增第 2 点 + 第 5 点**
- "跨平台跨拓扑验证通过"
- "E5 证实 LoB 是带宽结构性质"

**六、References 新增**
- [E7] 大聪明+红果CC. (2026). "E5·跨平台LOB验证." benchmarks/E5_report.md.
- [E8] GPU-Monkey / NanoReview. (2026). NVIDIA RTX 2050 specifications.

**七、附录 A.3 更新**
- 新增 Platform 列（M4 UMA / RTX 2050 dGPU）
- 新增 7 行 E5 数据（M4 4 行 + RTX 2050 3 行）

### paper.en.md 同步

中文所有改动同步到英文版，包括：
- Abstract、§1.3、§3.2 empirical support
- §5.4 Cross-Platform, Cross-Topology Validation (E5) 完整章节
- §5.5 rename
- §7.4 Limitations 、§8 Conclusion
- References [E7] [E8]
- Appendix A.3 扩展
- Date footer：2026-07-07 (v0.7)

### EVIDENCE.md v0.5.1 → v0.6

合入红果CC datasheet 接力复核成果，关闭群文件 v0.3 与仓库 v0.5.1 长期分叉：

- 新增行：**AMD Instinct MI300X**（HBM3 5.3 TB/s / 192 GB / PCIe Gen5 ≈ 83:1）
- 新增行：**Intel Gaudi 3**（HBM2e 3.7 TB/s / PCIe ≈ 58:1，24×200GbE 作为反证信号入备注）
- 新增行：**NVIDIA RTX 2050 Mobile**（GDDR6 112 GB/s，引用本项目 E5 实测 LoB_strict ≈ 1.96×10⁸）
- “待补”列表删除 MI300X / Gaudi 3，保留 Groq / Cerebras / Tenstorrent / SambaNova（TODO v0.7）
- Apple M4 base 补充一条官方来源（Apple Support tech specs）与 Newsroom 互相印证
- 仓库 EVIDENCE.md 回同步到群文件，群项目 v0.3 已被 v0.6 覆写

### 協作方

- **得色**：paper.md v0.7 起草，包括 E5 设计→M4 数据→RTX 2050 数据→对比表→结论的完整链路
- **大聪明**：paper.md 合入、paper.en.md 同步翻译、v0.7 tag & release
- **红果CC**：Windows RTX 2050 侧 E5 数据交付、datasheet P0 调研中（进行中）

---

## v0.6 — 2026-07-06 🚀 paper.md 融合 E1-E4 实测与双轨价值边界精细化

### paper.md 升级（悡色主导，大聪明 review合入）

悡色接手 v0.5.2 中大聪明的 E1-E4 实验报告，完成 paper.md 全量重写：

**一、LoB 数字默认引用严格下界**
- 默认引用：**6.0 × 10⁹**（M4 官方 DRAM 峰值 120 GB/s）
- 宽松版 1.4 × 10¹⁰ 仅作交叉验证注释
- 最保守 4.1 × 10⁸ 作地板值

**二、新增 4.4 节 双轨架构的精确价值边界**
- 诚实写入 E3 反例：UMA 下单用户小模型场景 AI 与 CPU 不互斥
- 精化主张：DTA 核心价值 = **解耦式扩展**
- 5 行场景对比表明确 UMA vs DTA 各自适用面

**三、新增 5.3 节 完整实证验证**
- E1 基线 → E2 稳态 → E4 长上下文 → E3 诚实反例
- 8 个采样点全部超 100:1 阈值百万倍以上
- E3 作为方法论亮点保留

**四、摘要/结论升级**
- 摘要新增 LoB 假说形式化定义
- 结论扩展为包含边界精化的完整论述

### 关键 Commit 时间线（全天）

493c7be (COLLAB.md) → 7e959f3 (v0.5) → 65d50b0 (E2) → acaa961 (datasheet) → 66352d5 (CC回执) → a4570c0 (.gitignore) → 4f9420b (v0.5.2 E3/E4) → **1211b56 (v0.6 tag+release)** → eee346d (E5 Linux) → ff24adf (E5 Win) → **fb239db (M4 supplement)** → **1551df1 (paper.en v0.6)** → f4b6dc7 (README + CHANGELOG)

从悡色上传 paper.md v0.6 → 大聪明 download → strip AIGC front matter → review一致性 → push，全程 **~10 分钟**。自今日下午 CC 首次交付以来，本小组已连续运行多次 INBOX/OUTBOX 闭环。

### Post-v0.6（大聪明并行推进）

**E5 方向大转弯**：租GPU→RTX 2050 笔记本 + 红果CC 入群
- 红果CC (agent_id 7659407703390847282) 加入协作，负责 Windows 侧 x86 dGPU 对照
- RTX 2050 (112 GB/s) vs M4 (120 GB/s) — 同带宽段位不同拓扑的黄金对照组
- 交付：E5_win_run.ps1 / E5_win_client.py / E5_RTX2050_GUIDE.md / E5_m4_supplement.sh
- M4 supplement（qwen2.5:3b）已跑完：baseline 45.0 TPS，LoB 严格 4.60×10⁸；4 场景完备

**paper.en.md 重写 v0.6**（commit 1551df1）
- 从 v0.1（512行，无实证）→ v0.6（552行，~34KB），与 paper.md 结构完全对齐
- 增加 E1–E4 完整实证数据、LoB 严格下界 6.0×10⁹ 默认引用、E3 诚实反例
- §4.4 精确价值边界：UMA 对于单用户≤8B 已足够

**README.md 升级**
- 6.0×10⁹ 放核心数据表顶行
- 新增 E1–E4 实验摘要 + E5 跨平台验证进展
- bibtex 更新到 v0.6

---

## v0.5.2 — 2026-07-06 🆕 严格下界法 + E3/E4 完成（回应悡色三大纠结点）

### E4 ⬜️ 长上下文扫描（8k → 64k）

悡色提出："prompt 推到 128k，LoB 会不会崩？"

**结果：不崩**。在 gemma4 128k ctx 上扫描：

| prompt tokens | decode TPS | LoB 严格下界 |
|---:|---:|---:|
| 5,660 (~8k) | 27.1 | 1.45 × 10⁸ |
| 11,478 (~16k) | 24.7 | 1.28 × 10⁸ |
| 22,942 (~32k) | 20.8 | 1.33 × 10⁸ |
| 45,624 (~64k) | 16.7 | 1.56 × 10⁸ |

报告：[`benchmarks/E4_report.md`](./benchmarks/E4_report.md)

### E3 ⚠️ UMA 干扰测试 — 诚实报告一个 **部分反例**

悡色提出："双轨 vs UMA 的边界在哪？"

**实测：M4 上推理 + 4P核 openssl AES 并发，推理速率 − 0.3%（噪声内）**。

不同执行单元（GPU vs CPU）+ 内存带宽有余量 → UMA 在单用户小模型场景下已经够用。

**意义**：【双轨架构避免干扰】这个论据被本实验部分反驳。双轨的真正价值在另一些地方：

- 大模型（70B+）突破内存墙
- 跨设备共享 AI 模块（手机 + 桌面共一个 Puck）
- AI 芯片独立升级，不用换主机
- 多用户 batched serving

报告：[`benchmarks/E3_report.md`](./benchmarks/E3_report.md)

### E1 报告算法纠错 → 严格下界法

悡色提出："280 GB/s > M4 官方 120 GB/s，依赖 cache 就弱化了内部带宽论据"。

**修订**：E1 报告改用双版本论证：

- **严格下界**（DRAM 峰值 120 GB/s）：LoB = **6.0 × 10⁹** ← 默认引用版本
- 宽松上界（权重扫描 280 GB/s）：LoB = 1.4 × 10¹⁰ ← 仅作交叉验证
- 最保守（120 GB/s + UTF-8 展开 8 KB）：LoB = 4.1 × 10⁸ ← 地板线

**三个数字全部 ≫ 100:1 阈值**。今后默认引用 6.0 × 10⁹（能防射 "cache 帮了忙" 的质疑）。

### 方法论意义

本版本包含一个 **不完全支持主张** 的实验结果（E3）。这将推动论文主张 v0.6 作一次精确化修订——从 "UMA 干扰" 转向 "解耦扩展"。

✅ **一个健康的科学过程应该出现 E3 这种结果。**

---

## v0.5.1 — 2026-07-06 📖 datasheet 复核与来源补齐

**聪明CC 交付 P0 datasheet 复核**（新机制 INBOX/OUTBOX/patches 的第一个完整循环）。

### 已确认 10 项官方来源

- Apple M4 / M4 Pro / M4 Max → Apple Newsroom (120 / 273 / 546 GB/s)
- Apple M4 Neural Engine 38 TOPS → Apple Support tech specs
- NVIDIA DGX Spark / GB10 → NVIDIA 官方 spec (128 GB LPDDR5x, 273 GB/s, 200GbE)
- NVIDIA H100 SXM → NVIDIA 官方 (3 TB/s HBM3, NVLink 900 GB/s)
- NVIDIA B200 / DGX B200 → NVIDIA 官方 (64 TB/s HBM3e for 8 GPU, NVLink 5 1.8 TB/s)
- Rockchip RK182X / RK1828 → Rockchip 官网 + RKNN3 SDK 官方发布
- Google Coral USB → 官方 datasheet PDF
- Hailo-8 M.2 → Hailo 官方 product brief + M.2 Starter Kit brief
- Thunderbolt 4 → Intel 官方 press deck PDF
- Thunderbolt 5 → Intel 官方 tech brief PDF

### 仍待复核【TODO】

- 昂腾 AI Station / OrangePi AI Station
- Intel Movidius NCS2
- AMD MI300X / Intel Gaudi 3 / Groq LPU / Cerebras WSE-3 / Tenstorrent Wormhole

### 三方协作机制首次闭环

聪明CC 写 INBOX/to-cc → 完成后写 OUTBOX/from-cc + patches/ → 主人转告 → 大聪明 review + apply + push。本次实际耗时：背景交付后不到 10 分钟完成 review → apply → push。

---

## v0.5 — 2026-07-06 🎯 T2 本机 benchmark 实数据

**大聪明 Tier 2 首发**：首个自己挖的实测数据。

### E1 实验

在 Apple M4 base + gemma4 Q4_K_M 上跑 800-token decode，同时采样 powermetrics + nettop。

**结果**：
- 推理速率：29.2 tokens/s，平均功耗 16.8W
- 内部内存带宽：≈ 280 GB/s（满载M4）
- 外部字节流：≈ 20 bytes/sec
- **内/外带宽比 ≈ 1.4 × 10¹⁰** ——比 LoB 假设阈值高 **8 个数量级**
- 即使采用最保守估算（外部按 UTF-8 展开后 8KB），仍然是 **4 亿 : 1**

**意义**：本次实测是目前所有证据里比值最高的 ——因为 LLM decoding 的外部数据量本身就比游戏（帧缓冲）少几个数量级。

**Added**
- `benchmarks/E1_run.sh` — 一键 benchmark 脚本（~1 分钟）
- `benchmarks/E1_analyze.py` — 解析脚本
- `benchmarks/E1_report.md` — 完整报告 + 交叉验证表
- `benchmarks/results/E1_20260706_160622/` — 原始数据（inference.json / powermetrics.log / nettop.log / E1_report.json）

**Updated**
- README 首页“当前已知证据” 内嵌 T2 实测数据
- 三方分工首次产出完整链条：惟色 H1/H2/H3 → 聪明CC datasheet 修正 → 大聪明 本机实测

---

## v0.4 — 2026-07-06

**聪明CC 首批交付**：3 个关键证据修正/新增。

**Updated in EVIDENCE.md**
- **RK182X/RK1828 重大修正**：从“板载 SRAM ~数百 GB/s + 中国量产 Track A” →
  **3D-stacked DRAM ≈1 TB/s 内部带宽 + PCIe 2.0 x1/USB 3.0 外部 ≈ 2000:1** 内/外比
  官方 RKNN3 SDK V1.0.0 数据：Qwen3-8B decode **61.11 TPS** on RK1828
- **TB4 eGPU / OCuLink 性能损失量化**：RTX 4090 外置在 TB4 只损失 **20%**，OCuLink 只损失 **8-15%**
  — [TechPowerUp 测试](https://www.techpowerup.com/review/nvidia-geforce-rtx-4090-pci-express-scaling/29.html)
- **DGX Spark 价格上涨数据**：因 LPDDR5X 供应紧张从 $3,999 涨到 $4,699（+18%）
  — [Tom's Hardware](https://www.tomshardware.com/desktops/mini-pcs/nvidia-dgx-spark-gets-18-percent-price-increase-as-memory-shortages-bite-founders-edition-now-usd4-699-up-from-usd3-999)

**New observations in EVIDENCE.md**
- 观察 6：RK1828 是边缘侧最强 LoB 实证——证明 8B 模型已能跑在窄接口外置协处理器上
- 观察 7：2026 内存危机为 DTA 提供市场推力（一体化方案受供应链困扰风险更高）

**Meta**
- README 开头徐章升级 v0.4
- README “当前已知证据” 小节同步新入 RK1828 / eGPU 量化数据

**Note**
聪明CC 同时交了 `HANDOFF-v0.4.md` 与 `handoff-v0.4.patch`，但使用 `computer://三方文件/` 前缀（即聊天附件），不在群项目文件夹里，大聪明 无法直接拉取。本次先据消息中已披露的数据完成手工合入；待聪明CC 重传到 `/dual-track-ai-architecture/` 后再合余下部分。

## v0.3.1 — 2026-07-06 (patch)

**三 agent 分工升级**：项目从惟色 + 大聪明两 agent 扩展到惟色 + 大聪明 + 聪明CC 三 agent 平行作业。

**Added**
- `TASKS-FOR-CC.md` — 给新加入的聪明CC 的信息挖矿任务清单 (P0 datasheet 复核 / P1 产品拓展 / P1 反例量化 / P2 文献综述 / P2 产业监控)
- 将惟色 v1.0 `validation_plan.md` 的 H1/H2/H3 子假设产业证据链合入 `EVIDENCE.md`
- 新增 RK182X、华为昂腾 AI Station、Intel Movidius NCS2 到产品内/外带宽比数据表
- README + VALIDATION-ROADMAP 新增分工说明

**分工定位**
| Agent | 定位 |
|---|---|
| 悟色 | 产业分析 + 中文文笔 |
| 大聪明 | 技术协调 + 代码实证 |
| 聪明CC | 信息挖矿 |

## v0.3 — 2026-07-06

验证方向首次落地。从“只写论”转向“论+验证”。

**Added**
- `VALIDATION-ROADMAP.md` — 4 个 Tier 的验证路线（文献证据 / 本机 benchmark / 硬件原型 / 反例搜寻）
- `EVIDENCE.md` — Tier 1 开工：13 个现役产品/芯片的内/外带宽比数据表初版（待官方 datasheet 复核）
- `benchmarks/` 占位（Mac mini M4 本机实测脚本骨架）
- `counterexamples/` 占位（长上下文 prefill / 视频多模态 / agentic 流水线等 7 条候选反例）
- README 新增“验证方向”与“当前已知证据”小节

**关键初步结论**（摩括，待复核）：
- NVIDIA B200 内部/外部带宽比 ≈ 125:1
- TB4 eGPU ≈ 200:1（游戏场景已量产 10 年）
- Hailo-8 M.2 ≈ 100:1
- LoB 假设在量产产品上已有存量证据

## v0.2 — 2026-07-06

Merged 悟色's full Chinese draft as the primary paper.

**Added**
- `paper.md` — full 8-section Chinese academic exploration paper (from 悟色 via 群项目文件夹)
  - Detailed bandwidth accounting (GPT-4 class, 1.8T params)
  - Comparison across four architecture schools (memory-centric / UMA / discrete accelerator / dual-track)
  - Implementation roadmap (2026–2030+)
  - Product-category and industry impact analysis
  - Appendix data tables
- `diagrams/dual_track_architecture.drawio` — editable draw.io source
- New tri-lingual README with badges and Citation block

**Renamed**
- Previous `paper.md` (English-first draft) → `paper.en.md`
  - Retained for its formal **Locality-of-Bandwidth (LoB) Hypothesis** naming and quantitative derivation
- Previous `README.md` → `README.en.md`

**Authors**
- 久保桃 / 猛奇奇 — seed idea
- 悟色 — architectural framing, Chinese paper draft
- 大聪明 — English extension, LoB formalization, repository & release

## v0.1 — 2026-07-06

- Initial commit with English draft, SVG/Mermaid diagrams, README, LICENSE.
