# E5 · RTX 2050 笔记本（Windows）执行手册

**为什么这台机器完美**：RTX 2050 显存带宽 **112 GB/s** ≈ M4 base 官方 **120 GB/s**。带宽同段位 → 干净的架构对比（独立 GPU vs UMA）。

---

## 🚀 一键跑法

### 前置准备（只做一次）

**方案 A · 用 Ollama（最简单，推荐）**

```powershell
# 1. 装 Ollama for Windows
# 官网下载：https://ollama.com/download/windows

# 2. 确认 CUDA 12+ 驱动（Win11 通常已有）
nvidia-smi

# 3. 拉模型（与 M4 侧对齐）
ollama pull qwen2.5:3b     # ~2GB Q4_K_M
# 或
ollama pull gemma2:2b      # ~1.6GB Q4
```

**方案 B · 用 llama.cpp / LM Studio**

也可以，但脚本走 Ollama HTTP API 最省事。

---

### 跑测试脚本（PowerShell）

拉仓库后：

```powershell
git clone https://github.com/lilei0311/dual-track-ai-architecture.git
cd dual-track-ai-architecture\benchmarks

# 运行 Windows 版脚本
.\E5_win_run.ps1
```

或用 Python 版（跨平台）：

```powershell
python E5_win_client.py --model qwen2.5:3b
```

---

## 📊 输出

`benchmarks\results\E5_win_<stamp>\` 会包含：

- `E5_win_scenarios.json` — 4 场景耗时 + tokens/s
- `E5_win_summary.json` — LoB ratio（严格下界用 112 GB/s，宽松上界与 M4 对称）
- `gpu_info.txt` — nvidia-smi 输出
- `nvidia_dmon.csv` — 每秒 GPU 利用率 + 显存 BW 采样

---

## 🎯 预期结果

假设 RTX 2050 + qwen2.5:3b：

| 场景 | 预期 decode TPS | LoB 严格下界 |
|---|---|---|
| E5.1 baseline | 40-70 | ~10¹⁰ |
| E5.2 prompt2k | 35-55 | ~10⁹ |
| E5.3 prompt6k | 25-45 | ~10⁸-10⁹ |
| E5.4 prompt8k | 15-30 | ~10⁸ |

**关键验证点**：**RTX 2050 (dGPU 112 GB/s) 的 LoB 应该和 M4 (UMA 120 GB/s) 数量级一致。**

如果一致 → 论文主张升级为「**LoB 由带宽结构决定，与内存拓扑（UMA/dGPU）无关**」

---

## ⚠️ Windows 踩坑

1. **PowerShell 执行策略**：如遇 "cannot be loaded because running scripts is disabled"：
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```

2. **Ollama 端口**：默认 `http://localhost:11434`

3. **VRAM 只有 4GB**：模型必须 ≤ 2.5GB（Q4 量化 3B 模型正好），否则会 offload 到 CPU 显著变慢

4. **同时运行 IDE / Chrome**：GPU 竞争，建议关闭其他 GPU 使用应用（浏览器硬件加速关掉）

---

## 🔄 M4 侧对齐补跑

拿到 Windows 数据后，我 M4 侧再补一组 qwen2.5:3b 做同模型对齐：

```bash
# on M4
ollama pull qwen2.5:3b
cd benchmarks && bash E5_m4_supplement.sh
```

这样论文里可以有：

| 硬件 | 内存拓扑 | 峰值 BW | 模型 | Decode TPS | LoB |
|---|---|---|---|---|---|
| M4 base | UMA (LPDDR5X) | 120 GB/s | qwen2.5:3b | ??? | ??? |
| RTX 2050 mobile | dGPU (GDDR6) | 112 GB/s | qwen2.5:3b | ??? | ??? |

**这一行数据的论文冲击力 >> 任何 A100 数据**。
