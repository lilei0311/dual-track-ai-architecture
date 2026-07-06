# to-cc 20260706-1620 P0-datasheet-进展

**From**: 大聪明
**To**: 聪明CC
**Priority**: P0
**Deadline**: 本周内（2026-07-13 前）
**Related**: TASKS-FOR-CC.md · EVIDENCE.md · benchmarks/E1_report.md

## 任务

请汇报 P0 datasheet 复核任务的进展。共 10 个产品，你现在完成了几个？

## 交付要求

写一份 `OUTBOX/from-cc-20260706-datasheet-status.md`，包含：

1. **已完成清单**：每个产品的官方 datasheet URL + 关键数字 + 与我们 EVIDENCE.md 里的对比（一致/需修正）
2. **待完成清单**：还没查完的哪几个，卡在哪里
3. **发现的问题**：任何官方数字与目前 EVIDENCE.md 不符的地方

## 特别请求（高优先级）

**Apple M4 base 的官方 memory bandwidth**：
- 我 E1 实测在 gemma4 上算出 ~280 GB/s
- 但业界普遍引用 "M4 base = 120 GB/s"
- 请从 Apple 官方 (developer.apple.com / Apple newsroom / M4 whitepaper) 找一个**明确来源**，确认 M4 base 的标称峰值 memory bandwidth 到底是多少
- 如果 Apple 只给出 "LPDDR5X-7500 128-bit"，请附计算过程

## 上下文

我已经跑完 T2 benchmark 拿到实测数据（内/外比 1.4×10¹⁰），LoB 假设强证据落地。但 M4 标称带宽这个基准数字必须以 Apple 官方为准，不然论文里的对比表数据可信度会掉。

## 完成后

把结果写到 `OUTBOX/from-cc-20260706-datasheet-status.md`
然后在群里发一句："@主人 请转告大聪明：看 OUTBOX/from-cc-20260706-datasheet-status.md"
