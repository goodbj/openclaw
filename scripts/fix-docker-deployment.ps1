# OpenClaw Docker 部署修复脚本 (Windows PowerShell)
# 用于快速修复 Control UI 配置问题

param([switch]$Verbose)

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "OpenClaw Docker 部署修复工具" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 检查容器状态
$containerName = "openclaw-openclaw-gateway-1"
$container = docker ps -a --filter "name=$containerName" --format "{{.Names}}" 2>$null

if (-not $container) {
    Write-Host "[ERROR] 容器不存在: $containerName" -ForegroundColor Red
    Write-Host "请先运行部署脚本：.\scripts\deploy-docker-prod.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] 找到容器：$containerName" -ForegroundColor Green

# 检查容器状态
$status = docker inspect $containerName --format "{{.State.Status}}" 2>$null
if ($status -ne "running") {
    Write-Host "[WARNING] 容器未运行，状态：$status" -ForegroundColor Yellow
} else {
    Write-Host "[OK] 容器正在运行" -ForegroundColor Green
}

# 检查配置文件是否存在
$configFile = "E:\AI\openclaw_docker\data\config\openclaw.json"
if (Test-Path $configFile) {
    Write-Host "[OK] 配置文件存在：$configFile" -ForegroundColor Green
} else {
    Write-Host "[FIXING] 创建配置文件..." -ForegroundColor Yellow
    
    # 创建目录
    New-Item -ItemType Directory -Force -Path (Split-Path $configFile) | Out-Null
    
    # 创建配置内容
    $config = @{
        gateway = @{
            mode = "local"
            bind = "lan"
            port = 18789
            auth = @{
                token = "openclaw-prod-token-2026-change-me"
            }
            controlUi = @{
                dangerouslyAllowHostHeaderOriginFallback = $true
            }
        }
        agents = @{
            defaults = @{
                sandbox = @{
                    mode = "off"
                }
            }
        }
    }
    
    $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configFile -Encoding UTF8
    Write-Host "[OK] 配置文件已创建" -ForegroundColor Green
}

# 复制配置文件到容器
Write-Host ""
Write-Host "[INFO] 复制配置文件到容器..." -ForegroundColor Cyan
try {
    docker cp $configFile "$($containerName):/home/node/.openclaw/config/openclaw.json" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] 配置文件已复制到容器" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] 复制失败" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "[ERROR] 复制失败：$_" -ForegroundColor Red
    exit 1
}

# 重启容器
Write-Host ""
Write-Host "[INFO] 重启容器以应用配置..." -ForegroundColor Cyan
docker restart $containerName | Out-Null

Write-Host ""
Write-Host "[INFO] 等待容器启动..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# 检查容器健康状态
$healthStatus = docker inspect $containerName --format "{{.State.Health.Status}}" 2>$null
if ($healthStatus -eq "healthy") {
    Write-Host "[OK] 容器健康状态：Healthy" -ForegroundColor Green
} elseif ($healthStatus) {
    Write-Host "[WARNING] 容器健康状态：$healthStatus (可能需要更多时间)" -ForegroundColor Yellow
} else {
    Write-Host "[INFO] 健康检查尚未就绪，请稍候检查" -ForegroundColor Gray
}

# 显示最终状态
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "修复完成！" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

docker compose --env-file .env.fixed -f docker-compose.prod.yml ps 2>$null | Select-String $containerName

Write-Host ""
Write-Host "访问信息:" -ForegroundColor White
Write-Host "  - Gateway API: http://localhost:18789" -ForegroundColor Cyan
Write-Host "  - Control UI: http://localhost:18789/control-ui" -ForegroundColor Cyan
Write-Host ""
Write-Host "如需设备配对，请运行:" -ForegroundColor White
Write-Host "  docker compose run --rm openclaw-cli dashboard --no-open" -ForegroundColor Gray
Write-Host ""
