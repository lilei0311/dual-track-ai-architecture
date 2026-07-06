# Changelog

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
