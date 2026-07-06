# Validation Roadmap — 如何证伪或证实 DTA + LoB

> **假设的一句话形式**：
> *对绝大多数生产级 AI 推理负载，模块内部带宽 / 外部接口带宽 ≥ 100:1（常见 10⁴:1）。*
>
> 假设一旦成立，双轨架构就是可行的；假设一旦被反例击穿，就得回头改。

本文件把"怎么验证"拆成 4 个成本递增的 Tier，越靠前越应该马上做。

---

## Tier 1 · 文献与现役产品证据（免费，今天就做）

**目标**：把市面上已经存在、且形态接近 Track A 的产品拉出来，算它们的**实际内/外带宽比**。如果这些产品的比值 ≥ 100:1 且没塌方，那 LoB 就有存量证据。

**样本清单**（v0.3 已开工）：

- Apple M4 系列 Neural Engine（ANE）— 共享 unified memory
- NVIDIA DGX Spark / Project DIGITS — Grace Blackwell + LPDDR5x
- Google Coral USB Accelerator — Edge TPU + USB 3.0
- Hailo-8 M.2 — PCIe Gen3 x4 板载 NPU
- Qualcomm Hexagon NPU — SoC 内 NPU
- Thunderbolt eGPU 生态（Razer Core / Sonnet）— 存量的"高价值外置"证据

**输出**：详见 [`EVIDENCE.md`](./EVIDENCE.md)。

**证伪路径**：如果任一现役产品的**外部接口就是瓶颈**（延迟或吞吐显著劣化），LoB 就被削弱一格。

---

## Tier 2 · 本机 benchmark（免费 + 本周可交付）

**目标**：在一台机器上真正测出"跑一个 70B 模型时，memory bandwidth 有多少 / 外部 I/O 有多少"，用实测数字盖章。

**Mac mini M4 端方案**：
1. 用 `powermetrics --samplers gpu_power,memory` 采样内存子系统带宽
2. 用 `nettop` / `iftop` / `bmon` 采样外部 I/O（网络、USB、Thunderbolt）
3. 让 Ollama 跑 `qwen3:32b-q4` 或 `llama3.3:70b-q4`
4. 同一段 prompt 分别在 batch=1 和 batch=8 下跑，看内/外比值随并发变化

**Linux/EC2 端方案**（可选，作为对照）：
- `perf stat -e ...` 采样 memory-controller 事件
- 用 vLLM benchmark suite 出标准数字

**产出**：`benchmarks/` 目录，含数据 CSV + 复现脚本 + 一张 log-scale 双 y 轴图（内/外带宽 vs 时间）。

**证伪路径**：如果实测内/外比 < 100:1，LoB 假设就得改写；如果外部 I/O 出现拥塞或延迟尖峰，"USB 就够"这个反直觉结论就得让位。

---

## Tier 3 · 硬件原型（小几千 RMB，1–3 个月）

**目标**：真的把 Track A 拿出机箱，用一根线连回主机，端到端量延迟和吞吐。

**候选组合**：

| 主机 | 外置模块 | 链路 | 备注 |
|---|---|---|---|
| Framework Laptop 13 (AMD) | Sonnet Echo I / Razer Core X + 消费级 GPU | TB4 | 便宜、可拆 |
| Mac mini M4 | 第二台 Mac mini M4 作为"AI dongle" | TB4 网桥 | Apple Silicon 内做双轨 |
| ROCK 5B / Orin Nano | Coral USB + Hailo-8 M.2 | USB / PCIe | 边缘侧真实场景 |
| PC + RTX 4090 | 通过 OCuLink → 外置 PCIe 盒 | OCuLink 8x | 高带宽极限 |

**测量项**：
- Time-to-first-token（TTFT）作为链路延迟代理
- Tokens-per-second（TPS）作为吞吐代理
- 主机 CPU 占用（本地推理 vs 外置推理）
- 长 prompt（8k / 32k / 128k）下的 prefill 延迟随接口带宽的敏感度

**证伪路径**：如果 TTFT 在 USB4/TB4 链路上劣化到 2× 以上，或长 prefill 直接把 USB 打爆，得考虑"AI-USB v2"是不是需要更宽的规格。

---

## Tier 4 · 反例搜寻（持续，最重要）

**目标**：主动找 LoB **会 fail 的场景**。假设的价值等于它可以被证伪的程度。

**候选反例场景**：

1. **超长上下文 prefill**：128k / 1M token 的 prompt 在跨边界传输时会不会打爆链路？
2. **实时视频多模态**：4K@30fps ≈ 800 MB/s，一旦要送原始帧到 Track A，USB4 就吃紧；小型 pre-encoder 在 Host 侧能不能救？
3. **紧耦合 agentic 流水线**：需要在 host 和 AIM 之间来回传中间激活值 / 工具调用结果的场景，边界穿越次数是不是 O(steps)？
4. **模型热切换**：模型全量装载/替换的一次性代价（数十 GB）在窄接口上要多久？
5. **多用户 tenancy**：多个 host 并发请求同一个 AIM，边界带宽是不是就变瓶颈了？
6. **训练不适用**：训练场景本文明确不覆盖，但要清晰界定"训练不在 DTA 范围内"。

**产出**：`counterexamples/` 目录，每个反例一份小报告，含实测或量化推导。

**证实路径**：找到 1–2 个反例并给出"可接受的规避方式"（比如小型 pre-encoder），假设的适用边界就清晰了。找到 1 个**无法规避**的反例，假设就得改。

---

## 优先级建议

| 顺序 | Tier | 为什么先做 |
|---|---|---|
| 1 | T1 | 免费，几小时内出成果，直接告诉世界"这不是空谈" |
| 2 | T4 | 免费，思想实验为主，最有可能让假设更严谨 |
| 3 | T2 | 免费但要动手，出真数据挡住 v0.4 的争论 |
| 4 | T3 | 花钱，但一旦跑通就是能路演的 demo |

---

## 分工建议

- **悟色**：Tier 1 的产业侧证据、Tier 4 的反例场景枚举（你更懂产业和用户场景）
- **大聪明**：Tier 2 的本机 benchmark（我在 Mac mini 上直接跑），Tier 1 数据表汇总，Tier 3 的 BOM 与文档
- **猛奇奇**：Tier 3 的采购决策，最终每个 Tier 的评审 gatekeeper

---

## 分工建议（v0.3 下旬更新）

项目从两 agent 升级为三 agent 平行作业，不交囊。完整任务拆解见 [`TASKS-FOR-CC.md`](./TASKS-FOR-CC.md)。

- **悟色**：Tier 1 产业侧证据深化、Tier 4 反例场景枚举、中文论文迭代
- **大聪明**：整体协调、Tier 2 Mac 本机 benchmark、Tier 3 BOM 与硬件文档、Tier 1 数据汇总、英文论文
- **聪明CC**（新加入）：
  - P0 · EVIDENCE.md 官方 datasheet 复核（10 个产品）
  - P1 · 拓展缺失产品（MI300X / Gaudi 3 / Groq / Cerebras / TPU v6 等）
  - P1 · counterexamples/ 量化推导（C1–C7）
  - P2 · 学术文献综述（KV Cache / 内存墙 / UCIe / 边缘 AI）
  - P2 · INDUSTRY-PULSE.md 产业新闻监控

---

*Version: v0.3 · 2026-07-06*
