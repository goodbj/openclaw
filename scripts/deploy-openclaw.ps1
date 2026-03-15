#!/usr/bin/env pwsh
# OpenClaw Docker 一键部署脚本（Windows）
# 适用：Windows 10/11 + Docker Desktop
# 用法：.\scripts\deploy-openclaw.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "🚀 OpenClaw 一键部署（Windows）" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

try {
    # ========== 步骤 1: 环境检查 ==========
    Write-Host "`n步骤 1: 环境检查..." -ForegroundColor Yellow
    
    # 检查 Docker
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "未检测到 Docker，请先安装 Docker Desktop for Windows`n下载地址：https://www.docker.com/products/docker-desktop"
    }
    
    # 检查 Docker Compose
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "未检测到 Docker Compose"
    }
    
    # 检查 Git
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "⚠️  未检测到 Git（可选，建议安装）" -ForegroundColor Yellow
    }
    
    # 检查 Docker Desktop 是否运行
    $dockerRunning = docker info 2>$null
    if (-not $dockerRunning) {
        throw "Docker Desktop 未运行，请启动 Docker Desktop"
    }
    
    Write-Host "✅ 环境检查通过" -ForegroundColor Green
    
    # ========== 步骤 2: 配置检查 ==========
    Write-Host "`n步骤 2: 配置检查..." -ForegroundColor Yellow
    
    $envFile = ".env"
    if (-not (Test-Path $envFile)) {
        Write-Host "⚠️  .env文件不存在，正在创建..." -ForegroundColor Yellow
        
        if (Test-Path ".env.example") {
            Copy-Item ".env.example" $envFile
            Write-Host "✅ 已从 .env.example 创建 .env" -ForegroundColor Green
            Write-Host "💡 请编辑 .env文件并配置 OPENCLAW_GATEWAY_TOKEN" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "按任意键继续打开 .env 编辑器..." -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            notepad $envFile
            
            Write-Host "`n配置完成后请重新运行此脚本" -ForegroundColor Yellow
            exit 0
        } else {
            throw "未找到 .env.example 文件"
        }
    }
    
    # 验证关键配置
    $envContent = Get-Content $envFile -Raw
    if ($envContent -match "OPENCLAW_GATEWAY_TOKEN=你的网关令牌") {
        Write-Host "⚠️  OPENCLAW_GATEWAY_TOKEN 仍为默认值" -ForegroundColor Yellow
        Write-Host "   请编辑 .env文件并修改为真实值" -ForegroundColor Gray
        Write-Host ""
        $response = Read-Host "是否现在打开 .env 编辑器？(Y/N)"
        if ($response -eq 'Y' -or $response -eq 'y') {
            notepad $envFile
            Write-Host "`n配置完成后请重新运行此脚本" -ForegroundColor Yellow
            exit 0
        }
    }
    
    Write-Host "✅ 配置检查完成" -ForegroundColor Green
    
    # ========== 步骤 3: 创建必要目录 ==========
    Write-Host "`n步骤 3: 创建数据目录..." -ForegroundColor Yellow
    
    $dataDir = "E:\AI\openclaw_docker\data"
    if (-not (Test-Path $dataDir)) {
        New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
        Write-Host "  ✓ 已创建：$dataDir" -ForegroundColor Green
    } else {
        Write-Host "  ✓ 目录已存在：$dataDir" -ForegroundColor Green
    }
    
    $workspaceDir = Join-Path $dataDir "workspace"
    if (-not (Test-Path $workspaceDir)) {
        New-Item -ItemType Directory -Path $workspaceDir -Force | Out-Null
        Write-Host "  ✓ 已创建：$workspaceDir" -ForegroundColor Green
    }
    
    Write-Host "✅ 目录准备完成" -ForegroundColor Green
    
    # ========== 步骤 4: 启动容器 ==========
    Write-Host "`n步骤 4: 启动 Docker 容器..." -ForegroundColor Yellow
    
    Write-Host "  拉取镜像（首次可能较慢）..." -ForegroundColor Gray
    docker compose pull
    
    Write-Host "  启动容器..." -ForegroundColor Gray
    docker compose up -d --build
    
    if ($LASTEXITCODE -ne 0) {
        throw "容器启动失败，请查看错误信息"
    }
    
    Write-Host "✅ 容器启动成功" -ForegroundColor Green
    
    # ========== 步骤 5: 等待服务就绪 ==========
    Write-Host "`n步骤 5: 等待服务就绪..." -ForegroundColor Yellow
    
    Write-Host "  等待 30 秒让服务初始化..." -ForegroundColor Gray
    Start-Sleep -Seconds 30
    
    # 检查健康状态
    Write-Host "  检查 Gateway 健康状态..." -ForegroundColor Gray
    $healthy = $false
    for ($i = 0; $i -lt 10; $i++) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:18789/healthz" -TimeoutSec 5 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                $healthy = $true
                break
            }
        } catch {
            Start-Sleep -Seconds 3
        }
    }
    
    if ($healthy) {
        Write-Host "  ✓ Gateway 健康检查通过" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Gateway 仍在启动中，请稍后手动检查" -ForegroundColor Yellow
    }
    
    Write-Host "✅ 服务初始化完成" -ForegroundColor Green
    
    # ========== 步骤 6: 显示访问信息 ==========
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "🎉 部署成功！" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Host "📋 访问信息:" -ForegroundColor Yellow
    Write-Host "" -ForegroundColor White
    Write-Host "  Control UI: http://localhost:18791/" -ForegroundColor Cyan
    Write-Host "  WebSocket:  ws://localhost:18789/" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor White
    
    Write-Host "🔧 常用命令:" -ForegroundColor Yellow
    Write-Host "" -ForegroundColor White
    Write-Host "  查看状态：docker compose ps" -ForegroundColor Gray
    Write-Host "  查看日志：docker compose logs -f" -ForegroundColor Gray
    Write-Host "  停止服务：docker compose down" -ForegroundColor Gray
    Write-Host "  重启服务：docker compose restart" -ForegroundColor Gray
    Write-Host "" -ForegroundColor White
    
    Write-Host "💡 下一步:" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor White
    Write-Host "  1. 在浏览器打开 Control UI: http://localhost:18791/" -ForegroundColor White
    Write-Host "  2. 配置飞书/Telegram 等消息信道" -ForegroundColor White
    Write-Host "  3. 阅读文档：docs/安装部署指南.md" -ForegroundColor White
    Write-Host "" -ForegroundColor White
    
    # 询问是否打开浏览器
    $response = Read-Host "是否现在打开 Control UI? (Y/N)"
    if ($response -eq 'Y' -or $response -eq 'y') {
        Start-Process "http://localhost:18791/"
    }
    
} catch {
    Write-Host "`n========================================" -ForegroundColor Red
    Write-Host "❌ 部署失败" -ForegroundColor Red
    Write-Host "========================================`n" -ForegroundColor Red
    
    Write-Host "错误信息：$_" -ForegroundColor Red
    Write-Host ""
    
    Write-Host "💡 建议操作:" -ForegroundColor Yellow
    Write-Host "  1. 检查 Docker Desktop 是否正常运行" -ForegroundColor White
    Write-Host "  2. 检查 .env 配置是否正确" -ForegroundColor White
    Write-Host "  3. 查看详细日志：docker compose logs openclaw-gateway" -ForegroundColor White
    Write-Host ""
    
    exit 1
}
