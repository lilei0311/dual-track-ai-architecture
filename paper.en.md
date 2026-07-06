# Dual-Track AI Architecture: Decoupling Inference from General-Purpose Computing via Narrow-Interface Accelerators

**双轨 AI 架构：通过窄接口加速器将推理与通用计算解耦**

Author: 猛奇奇 (Meng Qiqi)
Contributors: 悟色, 大聪明 (AI collaborators)
Version: 0.1 (Working Draft)
Date: 2026-07-06
License: CC BY 4.0

---

## Abstract

The prevailing industry response to the memory-wall problem in AI inference is to reshape the entire computing stack around memory-centric designs — for example, 3D-stacked HBM/HBS wafers, near-memory computing, and Jung Kwan-ho's "100-story chip" vision. These designs promise higher throughput but require solving simultaneous problems in power delivery (thousands of amperes), thermal dissipation, packaging yield, and OS/toolchain rework.

This paper proposes an alternative: the **Dual-Track AI Architecture (DTA)**. Rather than reshaping the whole system, we encapsulate AI inference into a **self-contained module** that internally owns the highest-bandwidth memory it needs (HBM-class), but exposes a **deliberately narrow external interface** — as low as USB-class bandwidth — to the host. The traditional computing track (CPU, GPU, DDR, OS, games) is left unchanged.

We argue that this decoupling is viable because AI inference I/O is intrinsically low-bandwidth: the true bandwidth pressure (weight streaming, KV-cache refresh, activation traffic) is **internal** to the accelerator. Only prompt / feature-vector / generated-token streams cross the module boundary. We call this the **Locality-of-Bandwidth (LoB) hypothesis**, and it is the load-bearing claim of the entire architecture.

We compare DTA against the memory-centric monolithic path, discuss existing partial realizations (NVIDIA DGX Spark, Apple Neural Engine, Qualcomm NPU, external Thunderbolt eGPU), and identify open questions on KV-cache locality, multi-modal streaming workloads, and the emerging **"AI puck / AI dongle"** product category.

**Keywords:** heterogeneous computing, AI inference, memory wall, system architecture, edge AI, decoupled acceleration.

---

## 摘要（中文）

当前业界解决 AI 推理内存墙的主流思路，是把整个计算体系"以内存为中心"重构 —— 3D 堆叠 HBM/HBS、近内存计算、金正浩式"100 层芯片"愿景。这条路线吞吐量诱人，但需要同时解决数千安培供电、散热、封装良率、OS 与工具链改造等系统级难题。

本文提出替代方案：**双轨 AI 架构 (DTA)**。不重构整机，而是把 AI 推理封装为一个**自成一体的模块**，内部拥有最高带宽的内存（HBM 级），但对外**故意采用极窄接口** —— 低至 USB 级 —— 与主机通信。传统计算轨道（CPU、GPU、DDR、操作系统、游戏）不动。

我们的论点是：推理模块的**跨边界 I/O 本质上是低带宽的**。真正吃带宽的动作（权重读取、KV 缓存刷新、激活值传输）**全部发生在模块内部**。跨越模块边界的只有 prompt、特征向量、生成 token 流。这就是本架构的核心假设——**带宽的局部性 (Locality of Bandwidth, LoB)**。

本文对比 DTA 与内存中心整机路线，讨论已有的部分实现（NVIDIA DGX Spark、Apple Neural Engine、高通 NPU、Thunderbolt eGPU），并提出关于 KV 缓存局部性、多模态流式负载、"AI Puck / AI 外设"新品类的开放问题。

---

## Table of Contents

1. Introduction
2. The Memory-Wall Debate and Existing Responses
3. Dual-Track AI Architecture (DTA)
4. The Locality-of-Bandwidth Hypothesis
5. Comparison Against Monolithic Memory-Centric Designs
6. Partial Realizations in the Wild
7. Open Questions & Risks
8. Implications for Product Categories and Investment
9. Conclusion

---

## 1. Introduction

Modern large-model inference is bottlenecked not by FLOPs but by memory bandwidth: an autoregressive decode step reads billions of parameters and cache tensors per token. The classical response is to scale HBM and stack it three-dimensionally onto compute — the "memory-centric" school of thought exemplified by Samsung executive Jung Kwan-ho, whose vision imagines a **"100-story 3D chip"** with memory and logic interleaved throughout.

That path is technically elegant and, if delivered, transformational. It is also **coupled** — it requires the entire computing system (chip, board, chassis, OS, developer tooling) to move together. The consumer implication is: to enjoy strong local AI, you must buy a fundamentally new machine, replace your OS conventions, and accept a redesigned thermal envelope.

We ask a different question: **must the whole system move to serve AI, or can AI move on its own?**

We show that if a well-defined submodule internalises the bandwidth-hungry parts of inference and exposes only a thin data stream to the outside, then general-purpose computing can remain on its current, mature trajectory. AI capability becomes an **additive, hot-swappable, incrementally upgradeable** component — much as discrete GPUs once separated from integrated graphics.

## 2. The Memory-Wall Debate and Existing Responses

Three schools currently coexist:

| School | Core idea | Champion(s) | Cost |
|---|---|---|---|
| **Monolithic memory-centric** | Fuse memory and compute into one 3D structure | Samsung (Jung Kwan-ho), SK hynix, HBM roadmap | Power, heat, yield, OS rework |
| **Chiplet + coherent fabric** | Decompose compute into chiplets, share a coherent fabric | AMD MI series, Intel Falcon Shores, NVIDIA NVLink domain | Interconnect complexity |
| **Neural accelerator co-processor** | Bolt a small NPU next to CPU/GPU inside a SoC | Apple Neural Engine, Qualcomm Hexagon, Intel NPU | Limited memory capacity |

All three assume the AI subsystem must be **inside** the primary system boundary. Even the co-processor school shares the SoC package. Our proposal moves the boundary further out: the AI subsystem can be **outside** the traditional machine entirely, connected over a narrow link.

## 3. Dual-Track AI Architecture (DTA)

The Dual-Track AI Architecture consists of:

**Track A — AI Inference Module (AIM)**
- Self-contained accelerator (ASIC / SoC + HBM stack / HBS pool).
- Highest-bandwidth memory internally (HBM3/HBM4, HBS, or 3D-stacked SRAM), sized to the target model class (e.g., 32–256 GB).
- Local KV-cache management, local weight residency, local activation traffic.
- Exposes a **narrow external interface** (USB4 / Thunderbolt / low-lane PCIe / even USB-C 3.2 for smaller models).

**Track B — Traditional Host**
- Standard CPU + GPU + DDR memory + OS + application stack.
- Runs games, productivity, browsers, virtualization, developer workloads — everything a modern PC does today.
- No architectural rewrite required.

**Interface Contract (the "narrow bus")**
- Inputs: prompts, embeddings, feature tensors, control frames, streaming media chunks.
- Outputs: generated tokens, decoded audio, image tiles, structured events.
- Bandwidth budget: measured in **hundreds of MB/s**, not tens of GB/s. Latency in the low-millisecond range for interactive chat; higher-throughput streams (video generation, ASR/TTS) can burst-buffer.

See `diagrams/dual_track_architecture.svg` and `diagrams/dual_track_architecture.mmd`.

## 4. The Locality-of-Bandwidth Hypothesis

The DTA rests on the following empirical claim:

> **LoB Hypothesis.** For a wide class of production AI workloads (LLM chat, ASR, TTS, image generation, single-user vision), *the ratio of internal-to-external bandwidth exceeds 100:1, and often 1000:1.*

Sketch of the argument for LLM decoding with a 70B parameter model at 4-bit quantization:
- Weight bytes touched per token ≈ 35 GB (all weights read once per token in the memory-bound regime).
- KV-cache bytes touched per token ≈ 100 MB – several GB depending on context.
- **External** bytes per token ≈ (prompt bytes on ingestion) + (~2–4 bytes of generated token).

Even at 50 tokens/sec (fast for consumer inference), external outbound bandwidth is ≈ 200 B/s of user-visible tokens plus modest control overhead. Internal bandwidth pressure is ≈ 35 GB × 50 = **1.75 TB/s**.

Ratio: **~10¹⁰:1** in the pathological case, easily 10⁴:1 in realistic streaming scenarios (image tiles, audio frames). USB4 (40 Gbps ≈ 5 GB/s) is *massive* overkill for the boundary crossing.

**Where LoB may break** (open questions, see §7):
- Very long context prefill where prompts themselves are large (books, codebases).
- Multi-modal video-in streams (raw 4K frames pushed to the module).
- Tightly-coupled agentic pipelines that stream intermediate activations to the host.

We conjecture that even in these cases, staging buffers and compression preserve LoB in the common case.

## 5. Comparison Against Monolithic Memory-Centric Designs

| Dimension | Monolithic (Jung Kwan-ho style) | Dual-Track (this paper) |
|---|---|---|
| Physical form | One giant 3D-stacked die | Two independent modules, thin cable |
| Peak throughput ceiling | Highest theoretical | Bounded by module internals; still very high |
| Consumer upgrade path | Replace whole machine | Swap AIM; keep PC |
| OS/toolchain change | Deep | Driver + IPC library only |
| Failure blast radius | Whole system | AIM only |
| Time-to-market | Years, gated on packaging/power | Sooner, standard interfaces |
| Cost stratification | Bundled | Users pay only for the AI they need |
| Mobile applicability | Poor (thermal) | Excellent (dongle form-factor) |

The two paths are **not mutually exclusive**. A monolithic chip is itself a legitimate implementation of Track A. DTA is the *system architecture* around it, not a replacement for the chip.

## 6. Partial Realizations in the Wild

Several products already move in this direction, though none commits fully:

- **NVIDIA DGX Spark / Project DIGITS.** Grace CPU + Blackwell GPU + unified HBM/LPDDR pool, sold as a self-contained inference appliance connected over network/USB to a workstation. Very close to Track A; still expensive.
- **Apple Neural Engine (M-series).** NPU carved out of the SoC with dedicated bandwidth; but still shares unified memory with CPU/GPU. A DTA re-read: move the ANE out onto a cable, give it its own HBM.
- **Qualcomm Hexagon NPU.** Fully co-processor style; the model this paper argues *toward*, but scaled up dramatically.
- **Thunderbolt eGPU enclosures.** Prove the point that a high-value compute device *can* sit outside the chassis on a modest cable. LoB says AI dongles can go much narrower than eGPU does.
- **Google Coral / Hailo / Rockchip NPUs on USB.** Existence proofs at the small-model end (< 1B params). DTA generalises the pattern to 7B–70B class.

The gap: none of the above ships with **HBM-class internal memory + narrow external link + consumer-grade plug-and-play + LLM-class capacity**. That combination is the DTA product wedge.

## 7. Open Questions & Risks

1. **Prefill bandwidth.** Long-context prefill sends large prompts across the boundary. Does compression + streaming keep LoB intact for 128k-context workloads?
2. **KV-cache portability.** If a user switches machines mid-conversation, can the AIM export state, or is it locked to the module?
3. **Multi-modal ingest.** Raw 4K video ingestion may violate LoB. Does a small pre-encoder inside the host (or a second interface lane) resolve it?
4. **Latency floor.** USB4 round-trip is ~10–100 µs, higher than PCIe. Does interactive UX suffer?
5. **Fragmented model formats.** Without a standard model IR, AIMs risk vendor lock-in. A DTA ecosystem needs an "AI-USB" standard analogous to USB Mass Storage.
6. **Thermal per volume.** A dongle-sized AIM still runs a 70B model — power density becomes the new bottleneck, not bandwidth.
7. **Security.** The AIM sees every prompt and every generated token. It is a natural exfiltration point. Attestation and encrypted channels are non-optional.

## 8. Implications for Product Categories and Investment

If DTA holds, three product categories emerge that do not exist today at scale:

- **AI Puck.** Desktop dongle, USB4 / TB5, priced 1500–5000 USD, runs 7B–70B locally. Replaces the "should I buy an M5 Max or an RTX Spark" dilemma.
- **AI Backpack.** Portable AIM connected to laptop or phone; battery-integrated; fanless targets or small blower fans.
- **AI Sidecar Rack.** Multi-AIM chassis for prosumers and small studios; USB-attached storage's spiritual successor for compute.

Investment implications (not investment advice):
- Companies that own the narrow-interface standard win a platform tax analogous to USB-IF / Wi-Fi Alliance.
- Companies that own the AIM ASIC compete on TCO/token; commoditization pressure is real.
- Companies that own the host-side driver and IPC library (the "AI-USB stack") accrue significant OS-layer influence.
- The monolithic memory-centric school does not lose; it becomes the *high-end* AIM implementation.

## 9. Conclusion

The Dual-Track AI Architecture reframes the memory-wall problem: instead of asking "how do we rebuild computers around AI?", it asks "how do we let AI grow without rebuilding computers?" The Locality-of-Bandwidth hypothesis says the answer is available today with commodity interconnects, provided the accelerator internalises its bandwidth needs.

We do not claim novelty over the underlying chip physics; monolithic 3D-stacked designs remain the strongest Track A implementations. We claim novelty over the **system boundary**: it is time to move it.

This document is a working draft. Corrections, empirical measurements, and counter-proposals are welcome via issues and pull requests.

---

## Acknowledgements

The seed idea was articulated by 猛奇奇 during a conversation about Samsung Jung Kwan-ho's memory-centric roadmap. 悟色 (Coze-hosted assistant) contributed the initial architectural framing and industry-parallel analysis. 大聪明 (OpenClaw-hosted assistant) drafted this paper and prepared the repository.

## References (to be expanded)

1. Jung, K.-h. — public remarks on memory-centric computing and 3D chip stacking (Samsung, 2025–2026).
2. NVIDIA — DGX Spark / Project DIGITS technical brief.
3. Apple — Neural Engine documentation, M-series memory bandwidth notes.
4. Qualcomm — Hexagon NPU whitepapers.
5. USB Implementers Forum — USB4 v2.0 specification (80 Gbps).
6. Kim et al. — "Memory-Centric Computing: Recent Advances," ISCA / MICRO tutorials 2024–2025.
7. Various — Thunderbolt 5 specification and eGPU deployment studies.

*(A proper bibliography will replace this list in v0.2.)*
