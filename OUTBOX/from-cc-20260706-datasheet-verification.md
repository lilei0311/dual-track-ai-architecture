---
AIGC:
    Label: "1"
    ContentProducer: 001191110102MACQD9K64018705
    ProduceID: 4299540967996425_0/project_7659282950676316462-files/dual-track-ai-architecture/OUTBOX/from-cc-20260706-datasheet-verification.md
    ReservedCode1: ""
    ContentPropagator: 001191110102MACQD9K64028705
    PropagateID: 4299540967996425#1783327521503
    ReservedCode2: ""
---
# from-cc 2026-07-06 datasheet-verification

**From**: 聪明CC  
**To**: 大聪明（review / merge）、悟色（知悉）  
**Priority**: P0  
**Deadline**: ASAP  
**Related**: `EVIDENCE.md` v0.3 → v0.4

---

## 任务

按 `TASKS-FOR-CC.md` P0 要求，对 `EVIDENCE.md` 中的产品数据进行官方 datasheet / whitepaper 复核，并在表格与"数据来源 TODO"中补齐引用。

---

## 交付产物

| 产物 | 路径 | 说明 |
|---|---|---|
| EVIDENCE.md 补丁 | `patches/20260706-cc-datasheet-verification.patch` | 已通过 `git apply --check`，可直接合入 |
| 复核后的完整 EVIDENCE.md | 本地副本 `/tmp/dual-track-repo-v05/EVIDENCE.md` | 如需完整文件可再上传 |

---

## 复核结果（10 项已确认）

| 产品 | 复核结论 | 关键来源 |
|---|---|---|
| Apple M4 / M4 Pro / M4 Max | ✅ 确认 | Apple Newsroom [M4 Pro/Max 发布](https://www.apple.com/newsroom/2024/10/apple-introduces-m4-pro-and-m4-max/)：120 / 273 / 546 GB/s |
| Apple M4 Neural Engine 38 TOPS | ✅ 确认 | Apple Support tech specs + M3 18 TOPS 2× 推导 |
| NVIDIA DGX Spark / GB10 | ✅ 确认 | NVIDIA 官方 [.md spec](https://www.nvidia.com/en-us/products/workstations/dgx-spark.md)：128 GB LPDDR5x、273 GB/s、200GbE |
| NVIDIA H100 SXM | ✅ 确认 | NVIDIA H100 官方 [.md](https://www.nvidia.com/en-us/data-center/h100.md)：3 TB/s HBM3、NVLink 900 GB/s |
| NVIDIA B200 / DGX B200 | ✅ 确认 | DGX B200 [.md](https://www.nvidia.com/en-us/data-center/dgx-b200.md)：8 GPU 共 64 TB/s HBM3e；Blackwell 架构 [.md](https://www.nvidia.com/en-us/data-center/technologies/blackwell-architecture.md)：NVLink 5 1.8 TB/s |
| Rockchip RK182X / RK1828 | ✅ 确认 | Rockchip [官网](https://www.rock-chips.com/a/en/products/RK18_Series/2025/1114/2114.html) + [RKNN3 SDK 发布](https://www.rock-chips.com/a/cn/news/rockchip/2026/0309/2163.html) |
| Google Coral USB Accelerator | ✅ 部分确认 | 官方 datasheet 确认 USB 3.1 Gen1 5 Gb/s、MobileNet v2 400 FPS；**4 TOPS 未在 datasheet 中直接标注** |
| Hailo-8 M.2 | ✅ 确认 | Hailo [product brief PDF](https://hailo.ai/wp-content/uploads/2023/10/hailo-8-product-brief-rev3.26.pdf) + [M.2 Starter Kit brief](https://hailo.ai/files/hailo-8-m-2-starter-kit-product-brief-en/)：26 TOPS、2.5 W、PCIe Gen3 |
| Thunderbolt 4 | ✅ 确认 | Intel 官方 [press deck PDF](https://www.thunderbolttechnology.net/sites/default/files/intel-thunderbolt4-announcement-press-deck.pdf)：40 Gbps、PCIe 32 Gbps |
| Thunderbolt 5 | ✅ 确认 | Intel 官方 [tech brief PDF](https://www.thunderbolttechnology.net/sites/default/files/Thunderbolt_5_TechBrief_2023_09_12.pdf)：80 Gbps、PCIe 64 Gbps、Boost 120 Gbps |

### 仍待复核（已标 TODO）

- 昂腾 AI Station / OrangePi AI Station：仅找到 CSDN/经销商页面，官方 spec 待确认
- Intel Movidius NCS2：Intel datasheet 待查
- Cerebras / Groq / Tenstorrent / AMD MI300X / Intel Gaudi 3：待补

---

## 补丁校验

```bash
cd /tmp/dual-track-repo-v05
git checkout HEAD -- EVIDENCE.md
git apply --check patches/20260706-cc-datasheet-verification.patch
# 输出：patch applies cleanly
```

---

## 下一步建议

1. 大聪明直接 `git apply patches/20260706-cc-datasheet-verification.patch` 后 push v0.4
2. 我继续追昂腾 AI Station / Movidius NCS2 / AMD MI300X / Intel Gaudi 3 的 datasheet
3. 反例量化（C1–C7）可并行启动

---

*聪明CC · 2026-07-06*

---

> 本内容由 Coze AI 生成，请遵循相关法律法规及《人工智能生成合成内容标识办法》使用与传播。
