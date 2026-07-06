# E5_win_run.ps1 · Windows PowerShell one-shot runner for RTX 2050 laptop
# Usage:  .\E5_win_run.ps1
# Or:     .\E5_win_run.ps1 -Model gemma2:2b

param(
    [string]$Model = "qwen2.5:3b"
)

$ErrorActionPreference = "Stop"

Write-Host "==> E5 · Windows Ollama runner" -ForegroundColor Green
Write-Host "    Model: $Model"

# 1. Check Ollama
try {
    $null = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -Method Get -TimeoutSec 5
    Write-Host "    Ollama:  OK (localhost:11434)" -ForegroundColor Green
} catch {
    Write-Host "❌ Ollama not running. Start Ollama Desktop or 'ollama serve'." -ForegroundColor Red
    exit 1
}

# 2. Check model
$tags = Invoke-RestMethod -Uri "http://localhost:11434/api/tags"
$hasModel = $tags.models | Where-Object { $_.name -eq $Model }
if (-not $hasModel) {
    Write-Host "⬇️  Pulling $Model ..." -ForegroundColor Yellow
    ollama pull $Model
}

# 3. Check nvidia-smi
try {
    $null = & nvidia-smi --query-gpu=name --format=csv,noheader
    Write-Host "    nvidia-smi: OK" -ForegroundColor Green
} catch {
    Write-Host "⚠️  nvidia-smi not on PATH; GPU monitoring will be skipped" -ForegroundColor Yellow
}

# 4. Run
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Push-Location $scriptDir
try {
    python E5_win_client.py --model $Model
} finally {
    Pop-Location
}

Write-Host "`n==> Done. See results\ folder." -ForegroundColor Green
