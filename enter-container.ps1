# OpenClaw Docker 开发环境 - 容器终端
# 双击运行此脚本快速进入开发容器

Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "  OpenClaw Docker 开发环境 - 容器终端" -ForegroundColor Green
Write-Host "================================================`n" -ForegroundColor Cyan

# 检查 Docker 是否运行
Write-Host "[检查] 验证 Docker 状态..." -ForegroundColor Yellow
try {
    $dockerStatus = docker ps --format "{{.Names}}" 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Docker 未运行"
    }
    Write-Host "[✓] Docker 运行正常" -ForegroundColor Green
} catch {
    Write-Host "`n[错误] Docker 未运行或未安装！" -ForegroundColor Red
    Write-Host "`n请先启动 Docker Desktop，然后重试。" -ForegroundColor Yellow
    Write-Host "`n按任意键退出..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# 检查容器是否在运行
Write-Host "`n[检查] 验证开发容器状态..." -ForegroundColor Yellow
$containerRunning = $dockerStatus | Select-String "openclaw-gateway-dev"

if (-not $containerRunning) {
    Write-Host "[警告] 开发容器未运行！" -ForegroundColor Yellow
    Write-Host "`n正在尝试启动容器..." -ForegroundColor Cyan
    
    # 启动容器
    try {
        docker compose -f docker-compose.dev.yml up -d 2>&1 | Out-String
        
        if ($LASTEXITCODE -ne 0) {
            throw "启动失败"
        }
        
        Write-Host "[等待] 容器启动中..." -ForegroundColor Cyan
        Start-Sleep -Seconds 15
        
        # 再次检查容器状态
        $containerRunning = docker ps --format "{{.Names}}" | Select-String "openclaw-gateway-dev"
        
        if (-not $containerRunning) {
            throw "容器未正常启动"
        }
        
        Write-Host "[✓] 容器已启动并运行正常！" -ForegroundColor Green
    } catch {
        Write-Host "`n[错误] 启动容器失败！" -ForegroundColor Red
        Write-Host "`n请检查以下项目：" -ForegroundColor Yellow
        Write-Host "  1. docker-compose.dev.yml 文件是否存在" -ForegroundColor Gray
        Write-Host "  2. Docker Desktop 是否有足够资源 (内存/CPU)" -ForegroundColor Gray
        Write-Host "  3. 端口 18789, 18790, 18791 是否被占用" -ForegroundColor Gray
        Write-Host "`n查看最近日志:" -ForegroundColor Cyan
        docker compose logs openclaw-gateway-dev --tail 20
        Write-Host "`n按任意键退出..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
} else {
    Write-Host "[✓] 容器已在运行" -ForegroundColor Green
}

# 显示容器信息
Write-Host "`n[信息] 容器状态:" -ForegroundColor Yellow
docker ps --filter "name=openclaw-gateway-dev" `
    --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}"

Write-Host "`n[提示] 正在进入容器终端..." -ForegroundColor Cyan
Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "  欢迎进入 OpenClaw 开发容器！" -ForegroundColor Green
Write-Host "================================================`n" -ForegroundColor Cyan

Write-Host "常用命令:" -ForegroundColor Yellow
Write-Host "  pnpm dev          - 启动开发服务器 (热重载)" -ForegroundColor White
Write-Host "  pnpm test         - 运行测试" -ForegroundColor White
Write-Host "  pnpm build        - 构建项目" -ForegroundColor White
Write-Host "  pnpm tsgo         - TypeScript 类型检查" -ForegroundColor White
Write-Host "  openclaw --help   - 查看 CLI 帮助" -ForegroundColor White
Write-Host "  exit              - 退出容器终端" -ForegroundColor White
Write-Host "`n================================================`n" -ForegroundColor Cyan

# 进入交互式 bash 会话
Write-Host "[连接] 进入容器 Bash 终端...`n" -ForegroundColor Green
docker compose exec openclaw-gateway-dev bash

# 返回到 PowerShell 脚本
Write-Host "`n[提示] 已退出容器终端" -ForegroundColor Cyan
Write-Host "`n按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
