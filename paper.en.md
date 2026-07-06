# Dual-Track Computing Architecture: Decoupling AI Inference from General-Purpose System Design

Author: 猛奇奇 (Meng Qiqi)
Contributors: 悟色 (conceptual framework & Chinese paper), 大聪明 (English paper, LoB formalization & empirical validation)
Version: 0.6 (Incorporating E1–E4 benchmark data)
Date: 2026-07-06
License: CC BY 4.0
Repository: https://github.com/lilei0311/dual-track-ai-architecture

---

## Abstract

As large language models and generative AI evolve rapidly, computing systems face a fundamental contradiction: GPU computational power continues to grow, yet effective utilization remains at only 10%–30%, with the bottleneck shifting from computation to memory bandwidth and capacity. Professor Kim Jung-ho, known as the "father of HBM," argues that "the essence of AI is memory" and advocates for memory-centric restructuring of the entire computing architecture. Building on this foundation, this paper proposes a more engineering-feasible alternative — the **Dual-Track Computing Architecture**: encapsulating AI inference as an independent module, utilizing the highest-bandwidth memory internally (HBM/HBF/HBS) for computational closure, while communicating with the host system through low-bandwidth interfaces for input/output data streams, running in parallel with traditional OS and application architectures. This approach avoids the engineering risks of full system restructuring while achieving optimal decoupling between AI inference performance and general computing experience.

We further propose the **Locality-of-Bandwidth (LoB) Hypothesis**: the ratio of internal bandwidth required by AI inference to the external bandwidth that must traverse system interfaces far exceeds the engineering threshold (≥100:1), making it physically feasible to encapsulate AI inference modules behind narrow interfaces. Through four experiments (E1–E4) on Apple M4, we measured LoB ratios under varying conditions; all sample points exceeded the 100:1 threshold by 6 or more orders of magnitude (≥1.28 × 10⁸ under strict lower-bound methodology).

**Keywords:** Dual-Track Architecture, AI Inference, Memory Wall, HBM, Compute-Memory Decoupling, Standalone Inference Module, Locality-of-Bandwidth Hypothesis

---

## 1. Introduction

### 1.1 Problem Background

In 2025–2026, AI computing underwent a paradigm shift from training-dominated to inference-dominated workloads. In inference scenarios, the core system bottleneck is no longer GPU FLOPS but memory bandwidth and capacity. This structural conflict has sparked intense industry debate along three schools of thought:

- **Memory-centric school**: Led by Professor Kim Jung-ho, arguing to sink GPU functionality into the memory layer, constructing a 100-layer 3D computing architecture centered on HBM/HBF/HBS [1].
- **Unified memory school**: Represented by Apple M-series Silicon, where CPU, GPU, and NPU share a unified memory pool [2].
- **Compute stacking school**: Represented by NVIDIA, continuously scaling GPU compute through chiplets and NVLink [3].

All three schools share one assumption: **AI inference must be deeply integrated with the primary computing architecture.**

### 1.2 Our Hypothesis

This paper challenges the shared assumption above with a different design philosophy:

> **AI inference does not need to restructure the entire system. Encapsulating it as an independent module that internalises high-bandwidth requirements and exposes only a low-bandwidth data interface is a more engineering-feasible evolutionary path.**

To support this, we propose the **Locality-of-Bandwidth (LoB) Hypothesis**:

> **For AI inference workloads, the ratio of internal bandwidth demand (weight scanning, KV-cache access) to external bandwidth demand (prompt input, token output) far exceeds the engineering threshold (≥100:1), making it physically feasible to encapsulate AI inference as an independent module connected to the host over a low-bandwidth link.**

### 1.3 Methodology

This paper follows a "requirements analysis → architecture design → empirical validation → boundary refinement" methodology:

1. Quantitatively analyze the bandwidth demand structure of AI inference (internal vs. external)
2. Derive optimal architecture design from demand structure
3. Empirically validate the LoB hypothesis through four experiments (E1–E4) on Apple M4
4. Precisely define the value boundary of the Dual-Track architecture — including identifying cases where it is **not** needed

---

## 2. Background & Existing Approaches

### 2.1 The Memory Wall Problem

In the von Neumann architecture, computing units (CPU/GPU) are physically separated from storage units (DRAM/HBM), with data transferred over buses. As AI model parameters grow exponentially, this architecture's bottleneck becomes increasingly acute:

| Metric | Value |
|--------|-------|
| GPU effective utilization | 10%–30% [1] |
| Memory read/write time as share of inference | 70%–80% [1] |
| Traditional DDR bandwidth analogy | 8-lane highway |
| HBM bandwidth analogy | 2048 lanes, potentially millions in future [1] |

Kim's core assertion: *"Even with 1 million GPUs installed for AI, only 10% of them are actually working. No matter how much you optimize the algorithm, GPU utilization is hard to push beyond 30%."* [1]

### 2.2 Three Generations of Memory Technology

| Generation | Technology | Medium | Speed | Capacity | Maturity |
|-----------|-----------|--------|-------|----------|----------|
| HBM | High Bandwidth DRAM | DRAM vertical stacking | High | Medium | Mass production |
| HBF | High Bandwidth Flash | NAND vertical stacking | Medium | Large (10× DRAM) | In development |
| HBS | High Bandwidth SRAM | SRAM full-wafer stacking | 1000× faster | 1600 GB (theoretical) | Conceptual |

Kim predicts: **10 years from now, HBF market demand will exceed HBM** [1].

### 2.3 Analysis of Existing Approaches

#### 2.3.1 Memory-Centric Architecture (Kim, 2026)

Kim's ultimate vision is a "100-story 3D building": HBM, HBF, and HBS stacked vertically, with the GPU placed on top for heat dissipation. Key challenges:

- **Power delivery**: thousands of amperes required; power network design is the hardest technical problem
- **Thermal dissipation**: integrating GPU functionality into memory layers creates severe temperature rise (the "warm floor effect")
- **Manufacturing yield**: 100-layer stacking means a single defective layer destroys the entire die
- **Engineering timeline**: estimated 10–15 years for initial implementation

#### 2.3.2 Unified Memory Architecture (Apple Silicon)

Apple's unified memory allows CPU, GPU, and Neural Engine to share a single memory pool. Advantages include zero data copy between chips. Disadvantages include:

- Memory specifications must compromise between CPU/GPU/AI requirements
- Memory capacity ceiling limited by cost and packaging constraints
- Iteration cadence bound to the full-system architecture

**Empirical evidence** (see §5.3): In single-user, small-model scenarios, UMA-based AI inference and CPU-intensive tasks show **almost no mutual interference** — M4 measured only −0.3% slowdown under concurrent AES encryption (E3, within noise). This demonstrates that UMA's weakness is not "AI slowing down general computing" but rather **memory capacity ceiling and independent upgradeability**.

#### 2.3.3 Discrete Accelerator Architecture (NVIDIA DGX)

NVIDIA interconnects multiple GPUs via NVLink to form AI computing clusters. Essentially, this makes the AI subsystem self-contained, but still tightly coupled with the host (PCIe, CPU scheduling, etc.).

---

## 3. AI Inference Bandwidth Demand Analysis

### 3.1 Demand Decomposition: Internal vs. External

The core insight of this paper is to decompose AI inference bandwidth demand into two independent dimensions:

```
Total Bandwidth Demand = Internal Demand + External Demand

Internal Demand (HIGH):
  - Model weight loading (tens to hundreds of GB)
  - KV-cache read/write (grows exponentially with context length)
  - Intermediate computation result transfer
  - Q/K/V matrix operations in attention

External Demand (LOW):
  - Input data: prompt text/images/sensor signals
  - Output data: generated token stream/results
  - Control instructions: model switching, parameter adjustment
```

### 3.2 Quantitative Estimation

Using a GPT-4 class model (~1.8 trillion parameters, FP16) as an example:

| Demand Type | Data Volume | Bandwidth Requirement | Direction |
|------------|------------|----------------------|-----------|
| Model weight loading (first time) | ~3.6 TB | Extremely high (internal) | Memory → Compute |
| KV-cache (128K context) | ~40 GB | Extremely high (internal) | Memory ↔ Compute |
| Single inference input (prompt) | 1–100 KB | Extremely low (external) | Host → AI |
| Single inference output (tokens) | 1–10 KB | Extremely low (external) | AI → Host |
| Streaming output rate | ~100 tokens/s | ~10 KB/s | AI → Host |

**Key finding**: Internal bandwidth demand exceeds external bandwidth demand by **6–9 orders of magnitude**.

### 3.3 Corollary

If the AI inference module's memory bandwidth requirements are fully internalised, the interface bandwidth requirement between module and host system is extremely low. USB 3.2 (20 Gbps) or even USB4 (40 Gbps) is sufficient for the external data transfer needs of most inference scenarios.

**Empirical support** (detailed in §5): On Apple M4, LLM decode scenarios produce external byte streams of roughly 20 bytes/second, while internal bandwidth demand is at minimum 120 GB/s (M4 DRAM peak) — a **LoB ratio strict lower bound of 6.0 × 10⁹, exceeding the 100:1 threshold by 7 orders of magnitude**.

---

## 4. Dual-Track Computing Architecture Design

### 4.1 Architecture Overview

The Dual-Track Computing Architecture divides the computing system into two independently operating tracks:

```
┌─────────────────────────────────────────────────────────────┐
│                Dual-Track Computing Architecture             │
│                                                             │
│  ┌─────────────────────────┐  ┌──────────────────────────┐  │
│  │   Track A: AI Inference  │  │  Track B: General Host   │  │
│  │                         │  │                          │  │
│  │  ┌───────────────────┐  │  │  ┌────────────────────┐  │  │
│  │  │  High-BW Memory    │  │  │  │       CPU          │  │  │
│  │  │ HBM/HBF/HBS layer  │  │  │  │   (x86/ARM)        │  │  │
│  │  │ (weights/KV-cache) │  │  │  └────────────────────┘  │  │
│  │  └────────┬──────────┘  │  │  ┌────────────────────┐  │  │
│  │           │             │  │  │       GPU          │  │  │
│  │  ┌────────▼──────────┐  │  │  │  (graphics render) │  │  │
│  │  │   AI Compute Unit  │  │  │  └────────────────────┘  │  │
│  │  │ (matrix/inference) │  │  │  ┌────────────────────┐  │  │
│  │  └────────┬──────────┘  │  │  │     DDR5 RAM       │  │  │
│  │           │             │  │  │  (OS/apps/games)    │  │  │
│  │  ┌────────▼──────────┐  │  │  └────────────────────┘  │  │
│  │  │   Narrow I/O       │  │  │  ┌────────────────────┐  │  │
│  │  │   USB/USB4/WiFi   │  │  │  │    NVMe SSD        │  │  │
│  │  └────────┬──────────┘  │  │  │   (persistent)     │  │  │
│  │           │             │  │  └────────────────────┘  │  │
│  └───────────┼─────────────┘  └───────────┬──────────────┘  │
│              │                            │                 │
│              └──────────┬─────────────────┘                 │
│                         │                                   │
│                 Low-bandwidth Data Channel                   │
│           (Input/output data streams only)                   │
│           USB 3.2 / USB4 / WiFi 7                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 Detailed Layer Design

#### 4.2.1 AI Inference Track

| Component | Specification | Notes |
|-----------|--------------|-------|
| High-bandwidth memory | HBM3e/HBM4 (current) → HBF (mid-term) → HBS (long-term) | Capacity scales with model class (80 GB–2 TB) |
| Compute unit | Dedicated inference ASIC / GPU die | Matrix-optimized; no graphics pipeline needed |
| Form factor | Independent module (external GPU enclosure style) | Self-powered and cooled |
| External interface | USB4 / USB-C / WiFi 7 (optional) | Data streams only |
| Internal bus | On-chip interconnect (NoC) | Ultra-high BW between memory and compute |

#### 4.2.2 Traditional Host Track

| Component | Specification | Notes |
|-----------|--------------|-------|
| CPU | x86/ARM general-purpose | OS scheduling, application execution |
| GPU | Traditional graphics GPU | Game rendering, video output |
| Memory | DDR5 (64–256 GB) | OS and application memory |
| Storage | NVMe SSD | Persistent data |

#### 4.2.3 Data Channel Protocol

| Scenario | Data Volume | Latency Tolerance | Recommended Interface |
|----------|------------|-------------------|----------------------|
| Text prompt input | 1–100 KB | <100 ms | USB 3.2 sufficient |
| Token streaming | ~10 KB/s | <50 ms | USB 3.2 sufficient |
| Image input | 1–10 MB | <500 ms | USB 3.2 sufficient |
| Video stream input | 5–50 MB/s | <200 ms | USB4 |
| Model hot-swap | 1–100 GB | <30 s | USB4 (preload hides latency) |

### 4.3 Workflow Example

```
User "summarize this paper"
         │
         ▼
┌─── Track B (Host) ───┐     ┌─── Track A (AIM) ────┐
│                       │     │                       │
│  App receives input   │     │                       │
│  Packs as JSON        │     │                       │
│  Sends via USB ───────┼────▶│  Prompt received       │
│                       │     │  Weights loaded from   │
│                       │     │    HBM                 │
│                       │     │  Attention execute     │
│                       │     │  Token stream generate │
│                       │     │  Stream via USB ───────┼──▶
│  Receive token ◀──────┼─────│                       │
│  stream               │     │                       │
│  Render to screen     │     │                       │
│                       │     │                       │
└───────────────────────┘     └───────────────────────┘
External interface bandwidth used: < 1 MB/s
AIM internal bandwidth used: > 1 TB/s
Internal/external ratio: > 1,000,000:1
```

### 4.4 Precise Value Boundary of Dual-Track Architecture

**Critical clarification**: Our empirical study (§5) shows that in single-user, small-model scenarios on UMA architectures (e.g., Apple M4), AI inference and CPU-intensive tasks **show almost no mutual interference** — inference rate dropped only −0.3% under concurrent AES encryption (E3, within noise). This means **the core value of Dual-Track architecture is NOT "preventing AI from slowing down general computing"** .

After empirical correction, the precise value proposition is:

| Scenario | UMA sufficient? | Dual-Track needed? | Core Value |
|----------|:--------------:|:------------------:|------------|
| Single-user · ≤8B · short-context | ✅ Fully | ❌ Not necessary | — |
| Single-user · 70B+ · long-context | ⚠️ Memory pressure | ✅ External HBM breaks memory ceiling | **Independent scaling** |
| Mobile + desktop sharing AI model | ❌ Cost-inefficient for each device | ✅ Swappable AI Puck | **Cross-device sharing** |
| Independent AI chip upgrade | ❌ Chip soldered on board | ✅ Puck independently replaces | **Independent iteration** |
| Multi-user batched serving | ⚠️ Memory/compute bottleneck | ✅ Dedicated inference cluster | **Elastic scaling** |

> **Precise claim**: UMA is sufficient for single-user small-model inference (E3 verified: 0% performance cost on M4). The value of Dual-Track Architecture lies in **decoupled scaling** — larger models, cross-device sharing, and independent module upgrade cycles — rather than workload isolation.

---

## 5. Comparison & Empirical Evaluation

### 5.1 Multi-Dimensional Comparison

| Dimension | Memory-Centric | Unified Memory | Discrete Accelerator | **Dual-Track (this paper)** |
|-----------|:------------:|:-------------:|:-------------------:|:-------------------------:|
| AI inference performance | ★★★★★ | ★★★★ | ★★★★ | **★★★★★** |
| General computing performance | ★★★ (constrained by AI) | ★★★★ | ★★★★ | **★★★★★ (no interference)** |
| Engineering complexity | ★ (extremely high) | ★★★ | ★★★★ | **★★★★ (incremental)** |
| Cost efficiency | ★★ | ★★★ | ★★★ | **★★★★ (pay-as-you-scale)** |
| Upgrade flexibility | ★ (bound to full system) | ★★ | ★★★ | **★★★★ (independent)** |
| Thermal feasibility | ★ (3D stacking extreme) | ★★★★ | ★★★ | **★★★★ (independent)** |
| Consumer friendliness | ★ | ★★★★ | ★★★ | **★★★★★ (plug-and-play)** |

### 5.2 Direct Comparison: "100-Story 3D Chip" vs. Dual-Track

Engineering bottlenecks of Kim's approach:
1. **Power delivery**: thousands of amperes; power network design is the hardest technical problem
2. **Thermal dissipation**: placing GPU on top dissipates poorly; memory layers with integrated compute create "warm floor effect"
3. **Yield**: 100-layer stacking; a single defective layer destroys the entire die
4. **Cost**: per-chip cost may exceed current entire AI server

Advantages of the Dual-Track approach:
1. **Power decoupling**: AI module independently powered, no impact on host
2. **Thermal decoupling**: AI module independently cooled, per-spot optimization
3. **Fault isolation**: AI module failure does not affect general computing
4. **Incremental upgrade**: memory technology iteration requires AIM replacement only

### 5.3 Empirical Validation: Locality-of-Bandwidth Hypothesis

To validate the LoB hypothesis, we conducted four experiments (E1–E4) on Apple M4 base (16 GB unified memory, LPDDR5X-7500, official peak bandwidth 120 GB/s) using gemma4 (Q4_K_M, 9.6 GB).

#### 5.3.1 LoB Ratio Calculation Methods

**Strict lower-bound method** (default reference — resistant to "cache reuse" critique):
- Internal bandwidth = M4 official DRAM peak = 120 GB/s
- External bandwidth = measured UTF-8 byte stream ÷ total wall time

**Loose upper-bound method** (cross-validation only):
- Internal bandwidth = weight file size × tokens ÷ duration ≈ 280 GB/s
- External bandwidth = same as above

**Most conservative method** (floor value):
- Internal bandwidth = 120 GB/s
- External bandwidth = UTF-8 expanded 8 KB ÷ duration

All three methods far exceed the 100:1 threshold.

#### 5.3.2 E1: Baseline Decode

800-token decode with concurrent powermetrics + nettop sampling [E1].

| Metric | Value |
|--------|-------|
| Inference rate | 29.2 tokens/sec |
| Average SoC power | 16.8 W |
| Total external byte stream | 553 bytes |
| External throughput | ~20 bytes/s |
| **LoB ratio (strict lower bound)** | **6.0 × 10⁹** |
| LoB ratio (loose upper bound) | 1.4 × 10¹⁰ |
| LoB ratio (most conservative) | 4.1 × 10⁸ |

**Conclusion:** All three versions far exceed the 100:1 threshold. Even the most conservative method yields a ratio of 4.1 × 10⁸ — exceeding the threshold by 6 orders of magnitude.

#### 5.3.3 E2: Prompt-Length Steady-State Scan

Scan across prompt lengths (360 → 4,322 tokens), each outputting 200 tokens [E2].

| Input tokens | Decode TPS | LoB ratio (strict lower bound) |
|:---:|:---:|:---:|
| 360 | 28.9 | 3.1 × 10⁹ |
| 1,475 | 28.3 | 5.2 × 10⁸ |
| 4,322 | 24.2 | 2.8 × 10⁸ |

**Key observations:**
1. **Decode rate remarkably stable**: prompt grows 12×, decode drops only 16%
2. **Inference is memory-bound, not compute-bound**: weight scanning dominates; KV-cache is a second-order effect
3. **LoB ratio stays at 10⁸ level**: 6 orders of magnitude above threshold

#### 5.3.4 E4: Long-Context LoB Decay

Push prompts from ~8k to ~64k tokens (gemma4 supports 128K context), verifying LoB does not collapse under extreme lengths [E4].

| Input tokens | Decode TPS | Prefill time | LoB ratio (strict lower bound) |
|:---:|:---:|:---:|:---:|
| 5,660 (~8k) | 27.1 | 16.3s | 1.45 × 10⁸ |
| 11,478 (~16k) | 24.7 | 36.9s | 1.28 × 10⁸ |
| 22,942 (~32k) | 20.8 | 88.0s | 1.33 × 10⁸ |
| **45,624 (~64k)** | **16.7** | **222.8s** | **1.56 × 10⁸** |

**Counter-intuitive finding**: The external byte rate actually decreases slightly as prompt length grows (826 → 768 B/s) — because the prefill time stretches total duration, "diluting" the external data rate. This means in real long-session scenarios, the cross-module interface is idle most of the time.

**Conclusion**: **LoB does not collapse.** At 64K prompt, LoB strict lower bound remains 1.56 × 10⁸ — 6 orders of magnitude above the threshold. KV-cache in single-user scenarios resides inside the AI module and is naturally "internal data."

#### 5.3.5 E3: UMA Interference Test (Honest Partial Counter-Example)

Test concurrent AI inference and CPU-intensive tasks (4-core AES-256 saturating P-cores) on M4 [E3].

| Scenario | Decode TPS | Change |
|----------|:---:|:---:|
| A · Standalone inference | 29.4 | Baseline |
| B · Inference + 4× AES-256 | 29.5 | −0.3% (within noise) |

**⚠️ This data partially refutes a common argument for Dual-Track.** Under UMA architecture, AI inference and CPU-intensive tasks show almost no mutual interference — because they use different execution units (GPU vs. CPU), memory bandwidth has headroom (120 GB/s vs. AES demanding ~few GB/s), and L2/SLC hardware arbitration handles contention.

**Paper claim refined:**
- ~~"UMA architecture causes AI to degrade CPU tasks"~~ → Not supported (E3 contradicts)
- ✅ "The core value of Dual-Track Architecture lies in **decoupled scaling** — larger models, cross-device sharing, independent upgrade cycles — rather than workload isolation"

> **Methodological note**: A healthy scientific process should produce results like E3 — partial support for a secondary claim. If every experiment perfectly supported all claims, that would indicate overfitting, not science. E3 helps us remove a weak argument and refines the paper's core insight to be more trustworthy.

#### 5.3.6 E1–E4 Summary

| Experiment | Prompt tokens | Output tokens | Decode TPS | LoB strict lower bound | Impact on thesis |
|-----------|:---:|:---:|:---:|:---:|:---:|
| E1 · Baseline | 45 | 800 | 29.2 | 6.0 × 10⁹ | ✅ Strong LoB support |
| E2 · Steady-state | 360–4,322 | 200 | 24–29 | 2.8×10⁸ – 3.1×10⁹ | ✅ Steady-state confirmed |
| E4 · Long-context | 5,660–45,624 | 100 | 16.7–27.1 | 1.28–1.56 × 10⁸ | ✅ Long-context holds |
| **E3 · UMA interference** | — | — | **29.4 → 29.5** | **—** | **⚠️ Represents weak argument, refines boundary** |

**All LoB sample points ≥ 1.28 × 10⁸ = 6 orders of magnitude above the 100:1 threshold.**

### 5.4 Cross-Validation with Industry Evidence

| Scenario | Internal/External ratio | Source |
|----------|:----------------------:|--------|
| **E1 M4 measured (strict lower bound)** | **6.0 × 10⁹** | This project |
| **E4 M4 at 64K context (strict lower bound)** | **1.56 × 10⁸** | This project |
| Thunderbolt 4 eGPU + RTX 4090 (gaming) | 200:1 | TechPowerUp |
| OCuLink eGPU + RTX 4090 (gaming) | 125:1 | TechPowerUp |
| Rockchip RK1828 (3D-DRAM) | ~2,000:1 | RKNN3 SDK |
| NVIDIA B200 (HBM3e vs PCIe Gen5) | ~125:1 | NVIDIA B200 whitepaper |

The RK1828 is the strongest industry-side evidence — 3D-stacked DRAM (~1 TB/s internal BW) + PCIe 2.0 ×1/USB 3.0 (~0.5 GB/s external), achieving 61.11 TPS on Qwen3-8B decode [E5]. This proves that 8B-class models can already run on narrow-interface external coprocessors.

---

## 6. Implementation Path & Challenges

### 6.1 Near-term (2026–2028): FPGA/ASIC Prototype

- Validate protocol stack and interface design on FPGA
- Build inference module prototype using existing HBM3e modules
- Goal: verify acceptable inference latency over USB interfaces
- **Low-cost pathway**: RK3588 + RK1828 dev board ($300–500) as "AI Puck" proof-of-concept

### 6.2 Mid-term (2028–2030): Dedicated Inference Module

- Custom inference ASIC + HBM4 packaging
- Standardized interface protocol (Thunderbolt-class)
- Target form factor: external AI inference box

### 6.3 Long-term (2030+): HBF/HBS Integration

- Introduce HBF for cold-data storage capacity
- Introduce HBS for extreme-speed scenarios
- Implement a "mini 3D building" within the module (much smaller scale than Kim's vision)

### 6.4 Key Technical Challenges

| Challenge | Difficulty | Approach |
|-----------|:----------:|----------|
| HBM module standardization | Medium | Reference UCIe (Universal Chiplet Interconnect Express) |
| Independent power delivery | Low | Reference external GPU power solutions |
| USB latency | Low | Current USB latency far below human perception threshold |
| Model loading & cache management on module | Medium | Dedicated model scheduling and cache management needed |
| Ecosystem compatibility | Medium | Standardized API definition needed (CUDA-like but for inference modules) |

---

## 7. Discussion

### 7.1 Relationship with Cloud AI

The independent AI inference module complements Cloud AI services (e.g., ChatGPT API):
- **Local inference module**: low latency, privacy-preserving, no network dependency, suitable for frequent lightweight inference
- **Cloud AI**: ultra-large models, latest capabilities, no upfront hardware investment, suitable for complex tasks

### 7.2 Impact on the Storage Industry Chain

If the Dual-Track Architecture is adopted, storage demand will diverge into two independent growth curves:
- **AI Track**: HBM → HBF → HBS (pursuing extreme bandwidth and speed)
- **Traditional Track**: DDR5 → DDR6 (pursuing capacity and cost efficiency)

The 2026 memory supply crisis provides market impetus: LPDDR5X supply tightness caused NVIDIA DGX Spark price to rise 18% (from $3,999 to $4,699) [E6]. Integrate d architectures face supply chain risk; decoupled architectures can diversify risk.

### 7.3 Impact on Consumer Product Form Factors

The Dual-Track Architecture may create new product categories:
- **AI Puck**: External GPU-enclosure-style device, plug-and-play AI capability
- **AI-Enhanced Laptop**: Built-in independent AI module, traditional architecture unchanged
- **Edge AI Node**: Miniaturized inference module for home/office deployment

### 7.4 Limitations

1. **Training not addressed**: Training scenarios still require large-scale GPU clusters
2. **Tightly-coupled workloads**: Real-time robot control requiring CPU–AI collaboration may not tolerate module latency
3. **Standardization**: Interface standards require industry consortium, hard in short term
4. **Single-user, single-request only**: Multi-user batched serving is a different problem (future E5/E6)
5. **Apple M4 platform only**: Cross-platform replication needed (x86+GPU, RK1828 dev board, etc.)
6. **LLM decode only**: Prefill, multi-modal input, agentic loops need separate validation

---

## 8. Conclusion

The Dual-Track Computing Architecture is founded on a simple insight: **decouple rather than integrate.**

1. **The Locality-of-Bandwidth hypothesis holds**: AI inference bandwidth demand is overwhelmingly internal to the module; external interface bandwidth requirements are extremely low. Four experiments (E1–E4) across all test conditions confirm LoB ratios exceeding the 100:1 threshold by 6+ orders of magnitude.

2. **The value boundary has been precisely defined**: The core value of Dual-Track is not "preventing AI from degrading general computing" (E3 shows no such degradation on UMA), but rather **decoupled scaling** — larger models, cross-device sharing, independent upgrade cycles.

3. Encapsulating AI inference as an independent module enables independently optimized thermal, power, and iteration cadence.

4. This approach avoids the 10–15 year engineering risk of the "100-story 3D building" while retaining the performance advantages of memory-centric design.

The core intuition is: **Don't be fooled by the surface claim that "AI needs the highest bandwidth" — that bandwidth demand is internal to the AI module and does not need to propagate to the entire system.** Just as a discrete GPU has its own high-bandwidth memory independent of the CPU, a discrete AI inference module can be architecturally self-contained.

And the "imperfect" E3 result — showing UMA does not actually suffer from AI–CPU interference — is evidence that science is working correctly: it helps us remove weak arguments, refine claims, and make the paper's core insight more credible.

---

## References

[1] Kim, J. (2026). "The essence of AI is memory; GPUs work only 10% of the time." Dong-A Ilbo exclusive interview. Republished on 36kr, Fenghuang, Xueqiu, et al., 2026-07-05.
[2] Apple Inc. (2024). "Apple Silicon: Unified Memory Architecture." Apple Developer Documentation.
[3] NVIDIA Corporation. (2025). "NVLink and NVSwitch: Scaling AI Computing." NVIDIA Technical Brief.
[4] Kim, J. (2026). HBM-HBF-HBS Technology Roadmap. KAIST Research Lab, planned through HBM8.
[5] Kioxia Corporation. (2026). "High Bandwidth Flash: The Next Era of AI Storage." Kioxia Technology Whitepaper.
[E1] 大聪明. (2026). "E1·Apple M4 LoB Benchmark Report." dual-track-ai-architecture/benchmarks/E1_report.md.
[E2] 大聪明. (2026). "E2·Prompt-Length Sweep on Apple M4." dual-track-ai-architecture/benchmarks/E2_report.md.
[E3] 大聪明. (2026). "E3·UMA Interference Test — Apple M4." dual-track-ai-architecture/benchmarks/E3_report.md.
[E4] 大聪明. (2026). "E4·Long-context LoB Decay on Apple M4." dual-track-ai-architecture/benchmarks/E4_report.md.
[E5] Rockchip. (2026). "RKNN3 SDK V1.0.0." Qwen3-8B on RK1828 decode 61.11 TPS.
[E6] Tom's Hardware. (2026). "NVIDIA DGX Spark Gets 18 Percent Price Increase As Memory Shortages Bite."

---

## Appendix: Core Data Tables

### A.1 AI Inference Internal vs. External Bandwidth Demand

| Scenario | Internal Demand | External Demand | Ratio |
|----------|---------------|---------------|:-----:|
| GPT-4 class inference | >1 TB/s (weights + KV-cache) | <1 MB/s (prompt + tokens) | >1,000,000:1 |
| Image generation (SD3) | >500 GB/s | <10 MB/s | >50,000:1 |
| Real-time speech inference | >100 GB/s | <1 MB/s | >100,000:1 |
| **E1 M4 measured (strict lower bound)** | **120 GB/s** | **20 B/s** | **6.0 × 10⁹ : 1** |
| **E4 M4 at 64K context (strict lower bound)** | **120 GB/s** | **768 B/s** | **1.56 × 10⁸ : 1** |
| RK1828 (3D-DRAM) | ~1 TB/s | ~0.5 GB/s | ~2,000:1 |

### A.2 Interface Bandwidth Headroom

| Interface Standard | Bandwidth | Supported AI Output Rate |
|-------------------|:---------:|:------------------------:|
| USB 3.2 Gen2 | 20 Gbps | ~2.5 GB/s |
| USB4 | 40 Gbps | ~5 GB/s |
| USB4 v2.0 | 80 Gbps | ~10 GB/s |
| WiFi 7 | 46 Gbps | ~5.7 GB/s |

> Note: Current AI inference output rate is typically <100 tokens/s (~100 KB/s). All of the above interfaces have **10,000× headroom** or more.

### A.3 E1–E4 LoB Ratio Complete Data

| Experiment | Prompt tokens | Decode TPS | LoB strict lower bound | × above threshold |
|:---------:|:---:|:---:|:---:|:---:|
| E1 | 45 | 29.2 | 6.0 × 10⁹ | 60,000,000× |
| E2 L=512 | 360 | 28.9 | 3.1 × 10⁹ | 31,000,000× |
| E2 L=2048 | 1,475 | 28.3 | 5.2 × 10⁸ | 5,200,000× |
| E2 L=6144 | 4,322 | 24.2 | 2.8 × 10⁸ | 2,800,000× |
| E4 L=8k | 5,660 | 27.1 | 1.45 × 10⁸ | 1,450,000× |
| E4 L=16k | 11,478 | 24.7 | 1.28 × 10⁸ | 1,280,000× |
| E4 L=32k | 22,942 | 20.8 | 1.33 × 10⁸ | 1,330,000× |
| E4 L=64k | 45,624 | 16.7 | 1.56 × 10⁸ | 1,560,000× |

**All sample points exceed the 100:1 threshold by over a million-fold.**

---

*This document is an academic exploration. It presents a novel architectural perspective and does not represent any commercial product plan.*

*Authors: 猛奇奇 (seed idea), 悟色 (architectural framework & Chinese paper), 大聪明 (English paper, LoB formalization & empirical validation)*

*Date: 2026-07-06 (v0.6 — Incorporating E1–E4 empirical data and boundary refinement)*

*License: CC BY 4.0*

*Repository: https://github.com/lilei0311/dual-track-ai-architecture*
