# TASKS-FOR-CC — 交接给聪明CC 的信息收集任务

> 项目: [Dual-Track AI Architecture (DTA)](./README.md)
> 版本: v0.3 → v0.4 (目标)
> 交接人: 大聪明（整体协调）
> 承接人: 聪明CC（信息收集）
> 平行协作: 悟色（产业侧深化 + 论文中文迭代）
>
> **本项目分工原则**：三 agent 各占一段光谱，不要抢活。
> - **悟色** = 产业分析师 + 中文文笔（框架 + 中文稿 + 产业 narrative）
> - **大聪明** = 技术协调 + 代码实证（GitHub 维护 + Mac 本机 benchmark + 论文英文版）
> - **聪明CC** = 信息挖矿工（datasheet 复核 + 新证据补充 + 学术文献 + 产业新闻监控）

---

## 你的输入

先读完以下四份，理解项目在哪、缺什么：

1. [`README.md`](./README.md) — 项目总览
2. [`paper.md`](./paper.md) — 悟色的中文 8 章版
3. [`EVIDENCE.md`](./EVIDENCE.md) — 现役产品的内/外带宽比数据表（**你的主战场**）
4. [`VALIDATION-ROADMAP.md`](./VALIDATION-ROADMAP.md) — 4-Tier 验证路径

你不需要读 `paper.en.md` 除非要做英文润色。

---

## 你的输出（按优先级排序）

### 🔴 P0 · Datasheet 复核（本周内）

`EVIDENCE.md` 里的所有产品数据都是"记忆+估算"，需要用官方 datasheet 复核。任务清单：

| 产品 | 需要核对的字段 | 权威来源 |
|---|---|---|
| Apple M4 / M4 Pro / M4 Max | memory bandwidth GB/s | Apple Newsroom + M4 whitepaper |
| NVIDIA H100 SXM | HBM3 带宽 + PCIe Gen5 x16 带宽 + NVLink 4 带宽 | NVIDIA H100 whitepaper |
| NVIDIA B200 | HBM3e 带宽 + PCIe Gen5 x16 带宽 + NVLink 5 带宽 | NVIDIA B200 whitepaper |
| NVIDIA DGX Spark | Grace Blackwell memory + ConnectX-7 200GbE | NVIDIA Project DIGITS announce |
| Google Coral USB Accelerator | TPU 内部 SRAM 带宽 + USB 3.0 有效吞吐 | Google Coral datasheet |
| Hailo-8 M.2 | 板载内存带宽 + PCIe Gen3 x4 带宽 | Hailo product page |
| **RK182X**（悟色 v1.0 引入） | 板载内存 + USB/PCIe 接口规格 | Rockchip 官方 |
| **昂腾 AI Station**（悟色 v1.0 引入） | 内部总线 + 外部接口 | 华为 Ascend 官方 |
| Intel Movidius NCS2 | 内部 SRAM + USB 3.0 | Intel datasheet |
| Thunderbolt 4 / 5 | 有效 PCIe 通道数 + 实际吞吐 | Intel TB spec |

**交付方式**：在 EVIDENCE.md 的表格里把估算值换成 datasheet 数字，同时在"数据来源与复核 TODO"章节把对应条目打勾并加引用链接。

**验收标准**：至少 6 个产品打勾。找不到官方 datasheet 的，明确标注"官方文档暂缺"，不要用二手估算蒙混。

---

### 🟡 P1 · 拓展 EVIDENCE.md 缺失的产品（本周内）

`EVIDENCE.md` 目前列了 13 个产品，还差以下几个关键玩家：

- [ ] **AMD MI300X** — HBM3 带宽 + Infinity Fabric + PCIe
- [ ] **AMD MI325X** — HBM3e 升级版
- [ ] **Intel Gaudi 3** — HBM 带宽 + 24×200GbE Ethernet 接口
- [ ] **Groq LPU** — SRAM-only 架构，内部超高带宽，外部 PCIe
- [ ] **Cerebras WSE-3** — 整晶圆芯片，"外部"接口如何？
- [ ] **Tenstorrent Wormhole / Blackhole** — RISC-V + Ethernet 互联
- [ ] **SambaNova SN40L** — RDU 架构 + memory tier
- [ ] **Qualcomm Cloud AI 100** — 边缘/数据中心 NPU
- [ ] **AWS Trainium 2 / Inferentia 2** — 云端定制芯片
- [ ] **Google TPU v5p / v6 Trillium** — TPU 板卡 + ICI 互联

**交付方式**：把每个新产品加到 EVIDENCE.md 的主表里，估算 → 复核 → 引用。

**验收标准**：至少补齐 5 个，加入"内/外带宽比"这一列。

---

### 🟡 P1 · Counterexamples 深化（本周内）

`counterexamples/README.md` 目前有 7 条骨架反例，需要每条给出量化推导。你的任务：

**每条反例 → 一份小报告**（放在 `counterexamples/C1.md` 到 `counterexamples/C7.md`）：

1. **C1 · 超长上下文 prefill (128k / 1M token)**
   - 找 vLLM / SGLang / LMCache 关于 long-context prefill 的实测数据
   - 算跨边界传的 embedding 量
   - 判断 USB4/TB4 是否够
2. **C2 · 实时视频多模态**
   - 找 GPT-4V / Claude Vision / Gemini 关于视频输入的带宽需求
   - 判断"host 侧 pre-encoder"补丁是否合理
3. **C3 · 紧耦合 agentic 流水线**
   - 找 ReAct / Reflexion / OpenAI Agents 关于工具调用轮次的数据
   - 算边界穿越次数 × 每次穿越带宽
4. **C4 · 模型热切换**
   - 找 vLLM / Ollama / llama.cpp 关于模型加载时间的实测
   - 算 USB4 传 70B q4 (35GB) 的时间
5. **C5 · 多用户 tenancy**
   - 找 vLLM continuous batching / SGLang 的吞吐数据
6. **C6 · 训练场景** — 只做范围声明，不深入
7. **C7 · Diffusion 大分辨率输出** — 快速否证

**交付标准**：每条反例给出"结论 + 补丁 / 承认边界"。

---

### 🟢 P2 · 学术文献综述（下周）

DTA 论文里的参考文献只有 5 条，太单薄。需要补：

- **KV Cache 优化路线**：PagedAttention (vLLM)、RadixAttention (SGLang)、LMCache、CachedAttention
- **内存墙综述**：ISCA/HPCA/MICRO 近三年关于 memory bandwidth in LLM inference 的论文
- **异构计算**：UCIe 标准、CXL 3.0 / 3.1、chiplet 综述
- **边缘 AI**：TinyML、on-device LLM 综述
- **金正浩教授的论文** —— 找 KAIST 官方主页 / IEDM 演讲原文

**交付方式**：在 `paper.md` 的参考文献章节补条目（BibTeX 或 markdown），或新建 `references.bib`。

**验收标准**：参考文献从 5 条扩展到 25+ 条。

---

### 🟢 P2 · 产业新闻监控（持续）

设一个跟踪列表，每周更新一次到 `INDUSTRY-PULSE.md`：

- 金正浩教授后续演讲 / 采访
- HBF 标准化联盟里程碑
- HBM4 / HBM5 量产进展
- Apple M5 / A20 rumors（Neural Engine 是否独立化的信号）
- NVIDIA Rubin / Feynman 架构
- 高通 / 联发科 / Intel / AMD 的 NPU 路线图
- 中国国产芯片（Ascend / 燧原 / 沐曦 / 摩尔线程）
- 消费级 eGPU / eNPU 新品发布

**交付方式**：`INDUSTRY-PULSE.md` 按日期倒序，每条 3-5 行 + 引用链接。

---

## 你不需要做的（避免抢活）

- ❌ 论文中文正文写作（悟色的地盘）
- ❌ 论文英文版扩展（大聪明的地盘）
- ❌ Mac 本机 Ollama benchmark 代码（大聪明的地盘）
- ❌ 架构图设计（悟色 draw.io，大聪明 SVG/Mermaid）
- ❌ GitHub push 权限操作（大聪明协调）—— 你的产出通过**在群里发 markdown** 或 **coze agent file** 方式落到项目文件夹，由大聪明 review 后合并到 GitHub

---

## 协作规约

- **进度汇报**：完成任何 P0/P1 后，在群里 @大聪明 报告；大聪明 review 后合入 GitHub 并 push 新版本
- **有分歧**：在群里发出来讨论；三 agent 论证不一致时，主人拍板
- **不确定的数据**：**宁可标 "官方文档暂缺" 也不要蒙**——本项目学术性质，数据可信度是命根子
- **引用格式**：URL + 数字/结论 + 一句话 context

---

## 现状快照（供你上手参考）

- ✅ v0.1: 英文首稿 + 架构图
- ✅ v0.2: 合并悟色中文 8 章版
- ✅ v0.3: 加验证路线图 + Tier 1 证据表 + Tier 4 反例骨架 + 合入悟色 v1.0 产业证据（H1/H2/H3）
- 🎯 v0.4 目标: **EVIDENCE.md datasheet 复核完成 + 反例量化 + 学术参考文献扩展**

Go! 🐒

---

*Version: v0.3 · 2026-07-06 · 大聪明发起*
