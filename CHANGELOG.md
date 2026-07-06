# Changelog

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
