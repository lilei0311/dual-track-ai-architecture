# Dual-Track Computing Architecture

**双轨计算架构：AI推理与传统计算的解耦范式**

[![License: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](./LICENSE)
[![Status: Working Draft v0.4](https://img.shields.io/badge/status-working%20draft%20v0.4-orange.svg)](./paper.md)
[![Language](https://img.shields.io/badge/paper-中文%20/%20EN-blue.svg)](./paper.md)

> "AI的本质是内存，GPU真正工作的时间只有10%。" — 金正浩教授（HBM之父）

## 核心洞察

当前计算系统面临根本矛盾：GPU算力持续增长，但有效利用率仅10%-30%。瓶颈不在"算多快"，而在"搬多快"。

**双轨架构**提出一个不同的设计哲学：

> AI推理不需要绑架整个系统架构。将其封装为独立模块，内部闭环高带宽需求，对外仅需低带宽数据接口。

## 架构概览

```
┌──────────────────────────┐     ┌──────────────────────────┐
│   轨道一：AI推理轨         │     │   轨道二：传统计算轨       │
│                          │     │                          │
│  ┌────────────────────┐  │     │  ┌──────┐  ┌──────────┐  │
│  │  HBS (SRAM)        │  │     │  │ CPU  │  │  GPU     │  │
│  │  快1000倍          │  │     │  │x86/ARM│  │ 图形渲染  │  │
│  ├────────────────────┤  │     │  └──────┘  └──────────┘  │
│  │  HBF (Flash)       │  │     │  ┌──────┐  ┌──────────┐  │
│  │  容量10x DRAM      │  │     │  │DDR5  │  │ NVMe SSD │  │
│  ├────────────────────┤  │     │  │OS/应用│  │ 持久存储  │  │
│  │  HBM (DRAM)        │  │     │  └──────┘  └──────────┘  │
│  │  模型权重/KV缓存    │  │     │                          │
│  ├────────────────────┤  │     │  ┌────────────────────┐   │
│  │  AI计算单元 (ASIC)  │  │     │  │ 操作系统 + 应用     │   │
│  └────────────────────┘  │     │  └────────────────────┘   │
│           │              │     │                          │
│  ┌────────▼────────┐    │     │                          │
│  │  USB4 / USB-C    │    │     │                          │
│  │  低速I/O接口      │    │     │                          │
│  └────────┬────────┘    │     │                          │
│           │              │     │                          │
└───────────┼──────────────┘     └──────────────────────────┘
            │                               │
            └─────────┬─────────────────────┘
                      │
              低带宽数据通道 (<1MB/s)
              仅传输输入输出数据流
```

## 关键数据

| 指标 | 数值 | 说明 |
|------|------|------|
| GPU有效利用率 | 10%-30% | 90%时间在等数据 |
| AI轨内部带宽 | >1TB/s | 权重加载+KV缓存全闭环 |
| 外部接口带宽 | <1MB/s | 仅传输prompt和输出 |
| 内外带宽比 | >1,000,000:1 | 所以USB就够用 |

## 论文

- 中文主版：[paper.md](paper.md) — 8 章完整学术探索，含数据表与参考文献
- English extended draft：[paper.en.md](paper.en.md) — 引入 **Locality-of-Bandwidth (LoB) Hypothesis** 的形式化命名与量化推导

## 架构图

- [`diagrams/dual_track_architecture.svg`](./diagrams/dual_track_architecture.svg) — 系统总览（Web 直渲）
- [`diagrams/dual_track_architecture.drawio`](./diagrams/dual_track_architecture.drawio) — draw.io 源文件（可编辑）
- [`diagrams/dual_track_architecture.mmd`](./diagrams/dual_track_architecture.mmd) — Mermaid 版本
- [`diagrams/locality_of_bandwidth.mmd`](./diagrams/locality_of_bandwidth.mmd) — 带宽局部性数据流图

## 与现有方案对比

| 方案 | 思路 | 工程难度 | 消费者友好度 |
|------|------|---------|------------|
| 金正浩100层3D大楼 | 一切围绕内存整合 | 极高 | 低 |
| Apple统一内存 | CPU/GPU/NPU共享内存 | 中 | 中 |
| NVIDIA独立加速卡 | 多GPU通过NVLink互联 | 中 | 中 |
| **双轨架构（本文）** | **AI独立封装+低带宽桥接** | **低** | **高** |

## 分工协作（v0.3 下旬）

项目现在三 agent 分工，完整任务清单见 [`TASKS-FOR-CC.md`](./TASKS-FOR-CC.md)：

| Agent | 定位 | 当前已投入产出 |
|---|---|---|
| **悟色** | 产业分析 + 中文文笔 | `paper.md`、`validation_plan.md`（H1/H2/H3 细分）、产业证据链 |
| **大聪明** | 技术协调 + 代码实证 | GitHub 仓库 / 英文扩展 / VALIDATION-ROADMAP / Mac 本机 benchmark |
| **聪明CC** | 信息挖矿 | datasheet 复核 / 新产品补齐 / 学术文献 / 产业新闻监控 |

## 验证方向（v0.3 新增）

不能只立论，得能被验证。完整路线图见 [`VALIDATION-ROADMAP.md`](./VALIDATION-ROADMAP.md)：

| Tier | 内容 | 目前状态 |
|---|---|---|
| **T1 · 文献与现役产品证据** | 拉商家规格，算现役产品的内/外带宽比 | [`EVIDENCE.md`](./EVIDENCE.md) 初版 ✓ |
| **T2 · 本机 benchmark** | Mac mini M4 上实测 memory BW vs external I/O | [`benchmarks/`](./benchmarks) 占位 |
| **T3 · 硬件原型** | TB4/USB4 外置 AI 盒，端到端测延迟后吞 | 待启动 |
| **T4 · 反例搜寻** | 主动找 LoB 会 fail 的场景（长 prefill / 视频 / agentic） | [`counterexamples/`](./counterexamples) 初稿 7 条候选 |

### 当前已知证据（摩括，待官方文档复核）

- **NVIDIA B200**：HBM3e 8 TB/s 内部 vs PCIe Gen5 x16 64 GB/s 外部 → **125:1**
- **Rockchip RK1828**（3D-stacked DRAM）：≈ 1 TB/s vs PCIe 2.0 x1 / USB 3.0 → **~2000:1**，且 **Qwen3-8B decode 61 TPS** 已官方公布
- **Thunderbolt eGPU**：GDDR6X 1 TB/s vs TB4 4–5 GB/s → **200–250:1**（游戏场景性能只损失 **20%**，已量产 10 年）
- **OCuLink eGPU**：同内存 vs PCIe Gen4 x4 8 GB/s → **125:1**（性能只损失 **8–15%**）
- **Hailo-8 M.2**：板载 SRAM 数百 GB/s vs PCIe Gen3 x4 4 GB/s → **~100:1**
- **NVIDIA DGX Spark**：LPDDR5x 273 GB/s vs 200GbE 25 GB/s → 11:1（弱一些，但形态已存在）

**初步结论**：LoB 在现有量产产品上已有存量证据；DTA 不是新发明，而是 **把已经在 GPU/NPU 内部实现的带宽悬殊推到“模块与主机之间”**。

## 实现路线图

- **近期(2026-2028)**: FPGA原型验证，现有HBM3e模组搭建推理模块
- **中期(2028-2030)**: 定制推理ASIC + HBM4封装，标准化接口协议
- **远期(2030+)**: HBF/HBS融合，模块内迷你3D架构

## 参考文献

1. 金正浩教授专访：AI本质就是内存（2026-07-05）[36kr](https://36kr.com/p/3883376811044866)
2. Apple Silicon Unified Memory Architecture
3. NVIDIA NVLink and NVSwitch Technical Brief

## License

**[CC BY 4.0](./LICENSE)** — 自由复用，请署名。

## Authors

- **久保桃 / 猛奇奇** — 原始思路
- **悟色** — 架构框架 + 中文论文起草
- **大聪明** — 英文扩展 + LoB 假设形式化 + GitHub 仓库发布

## Citation

```bibtex
@misc{dta2026,
  author = {久保桃 and 悟色 and 大聪明},
  title  = {Dual-Track Computing Architecture: Decoupling AI Inference from General-Purpose System Design},
  year   = {2026},
  howpublished = {\url{https://github.com/lilei0311/dual-track-ai-architecture}},
  note   = {Working draft v0.2}
}
```

## Contributing

欢迎实证测量、反例、遗漏的相关工作 —— 详见 [CONTRIBUTING.md](./CONTRIBUTING.md)。

---

> 本内容由 Coze AI 生成，请遵循相关法律法规及《人工智能生成合成内容标识办法》使用与传播。
