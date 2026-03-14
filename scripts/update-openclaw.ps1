#!/usr/bin/env pwsh
# OpenClaw 源码热重载一键更新脚本
# 适用：Docker 源码部署 + 热重载模式
# 用法：.\scripts\update-openclaw.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "🔄 OpenClaw 源码热重载一键更新" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

try {
    # ========== 步骤 1: 环境检查 ==========
    Write-Host "步骤 1: 环境检查..." -ForegroundColor Yellow
    
    # 检查工作目录
    $projectRoot = "E:\AI\openclaw_docker\openclaw"
    if (-not (Test-Path $projectRoot)) {
        throw "项目根目录不存在：$projectRoot"
    }
    Set-Location $projectRoot
    
    # 检查 Docker
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "未检测到 Docker，请确保 Docker Desktop 已安装并运行"
    }
    
    # 检查 Git
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "未检测到 Git"
    }
    
    Write-Host "✅ 环境检查通过" -ForegroundColor Green
    Write-Host ""
    
    # ========== 步骤 2: 备份关键配置 ==========
    Write-Host "步骤 2: 备份关键配置..." -ForegroundColor Yellow
    
    $backupDir = "E:\AI\openclaw_docker\backups\pre-update-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    
    # 备份 openclaw.json
    $configPath = "E:\AI\openclaw_docker\data\openclaw.json"
    if (Test-Path $configPath) {
        Copy-Item $configPath "$backupDir\openclaw.json.bak" -Force
        Write-Host "  ✓ 已备份 openclaw.json" -ForegroundColor Green
    }
    
    # 备份 .env（如果存在）
    $envPath = "E:\AI\openclaw_docker\.env"
    if (Test-Path $envPath) {
        Copy-Item $envPath "$backupDir\.env.bak" -Force
        Write-Host "  ✓ 已备份 .env" -ForegroundColor Green
    }
    
    Write-Host "✅ 备份完成：$backupDir" -ForegroundColor Green
    Write-Host ""
    
    # ========== 步骤 3: Git Pull ==========
    Write-Host "步骤 3: 拉取最新代码..." -ForegroundColor Yellow
    
    # 显示当前分支
    $currentBranch = git branch --show-current
    Write-Host "  当前分支：$currentBranch" -ForegroundColor Gray
    
    # 尝试从上游仓库拉取
    Write-Host "  拉取来源：upstream main" -ForegroundColor Gray
    git pull upstream main --rebase
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ⚠️ 从 upstream 拉取失败，尝试 fork..." -ForegroundColor Yellow
        git pull fork main --rebase
        
        if ($LASTEXITCODE -ne 0) {
            throw "Git Pull 失败，请检查网络连接或手动执行 git pull"
        }
    }
    
    Write-Host "✅ 代码拉取成功" -ForegroundColor Green
    Write-Host ""
    
    # ========== 步骤 4: 等待热重载 ==========
    Write-Host "步骤 4: 等待热重载自动完成..." -ForegroundColor Yellow
    Write-Host "  提示：可通过以下命令查看实时日志：" -ForegroundColor Gray
    Write-Host "  docker compose logs -f openclaw-gateway" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  等待 30 秒..." -ForegroundColor Gray
    Start-Sleep -Seconds 30
    Write-Host "✅ 热重载应该已完成" -ForegroundColor Green
    Write-Host ""
    
    # ========== 步骤 5: 验证更新 ==========
    Write-Host "步骤 5: 验证更新..." -ForegroundColor Yellow
    
    # 检查容器状态
    $containerStatus = docker compose ps --format json | ConvertFrom-Json
    if ($containerStatus.State -ne "running") {
        Write-Host "⚠️ 容器未运行，正在启动..." -ForegroundColor Yellow
        docker compose up -d
    }
    
    # 尝试获取版本信息
    Write-Host "  检查容器版本..." -ForegroundColor Gray
    $version = docker compose exec -T openclaw-gateway bash -c "openclaw --version 2>/dev/null" 2>$null
    if ($version) {
        Write-Host "  ✓ 版本信息：$version" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ 无法获取版本信息（可能正在重启）" -ForegroundColor Yellow
    }
    
    Write-Host "✅ 验证完成" -ForegroundColor Green
    Write-Host ""
    
    # ========== 完成 ==========
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "🎉 更新成功！" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Host "📋 后续检查:" -ForegroundColor Yellow
    Write-Host "  1. 在飞书中测试消息收发" -ForegroundColor White
    Write-Host "  2. 访问 Control UI: http://localhost:18791/" -ForegroundColor White
    Write-Host "  3. 查看详细日志：docker compose logs openclaw-gateway --tail=50" -ForegroundColor White
    Write-Host ""
    
    Write-Host "💾 备份位置:" -ForegroundColor Yellow
    Write-Host "  $backupDir" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "💡 如需回滚:" -ForegroundColor Yellow
    Write-Host "  cd E:\AI\openclaw_docker\openclaw" -ForegroundColor Gray
    Write-Host "  git reset --hard HEAD~1" -ForegroundColor Gray
    Write-Host "  Copy-Item '$backupDir\openclaw.json.bak' 'E:\AI\openclaw_docker\data\openclaw.json' -Force" -ForegroundColor Gray
    Write-Host "  docker compose restart openclaw-gateway" -ForegroundColor Gray
    Write-Host ""
    
} catch {
    Write-Host "`n========================================" -ForegroundColor Red
    Write-Host "❌ 更新失败" -ForegroundColor Red
    Write-Host "========================================`n" -ForegroundColor Red
    
    Write-Host "错误信息：$_" -ForegroundColor Red
    Write-Host ""
    
    Write-Host "💡 建议操作:" -ForegroundColor Yellow
    Write-Host "  1. 检查网络连接后重试" -ForegroundColor White
    Write-Host "  2. 手动执行 git pull" -ForegroundColor White
    Write-Host "  3. 从备份恢复配置" -ForegroundColor White
    Write-Host ""
    
    exit 1
}
