# OpenClaw Docker Production Deployment Script
# Data persistence to E:\AI\openclaw_docker

param([switch]$Clean)

$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $RootDir
Set-Location $RootDir

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "OpenClaw Docker Production Deploy" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check Docker
try {
    $dockerVersion = docker version --format "{{.Server.Version}}" 2>$null
    if (-not $dockerVersion) { throw "Docker not running" }
    Write-Host "[OK] Docker: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    exit 1
}

# Load environment
$EnvFile = Join-Path $RootDir ".env.prod"
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^\s*([^#=]+)\s*=\s*(.+)\s*$' -and $_ -notmatch '^\s*#') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim().Trim('"').Trim("'")
            [Environment]::SetEnvironmentVariable($key, $value, "Process")
        }
    }
    Write-Host "[OK] Loaded: $EnvFile" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Not found: $EnvFile" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Create directories
Write-Host "Creating data directories..." -ForegroundColor Yellow
$BaseDataDir = "E:\AI\openclaw_docker\data"
$LogsDir = "E:\AI\openclaw_docker\logs"

New-Item -ItemType Directory -Force -Path $BaseDataDir | Out-Null
New-Item -ItemType Directory -Force -Path $LogsDir | Out-Null

$DataPaths = @(
    "$BaseDataDir\home",
    "$BaseDataDir\config",
    "$BaseDataDir\workspace",
    "$BaseDataDir\skills",
    $LogsDir
)

foreach ($path in $DataPaths) {
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Force -Path $path | Out-Null
        Write-Host "  Created: $path" -ForegroundColor Gray
        
        # Init subdirs
        if ($path -eq "$BaseDataDir\home") {
            New-Item -ItemType Directory -Force -Path "$path\identity" | Out-Null
            New-Item -ItemType Directory -Force -Path "$path\agents\main\agent" | Out-Null
            New-Item -ItemType Directory -Force -Path "$path\agents\main\sessions" | Out-Null
            New-Item -ItemType Directory -Force -Path "$path\memory" | Out-Null
        }
    } else {
        Write-Host "  Exists: $path" -ForegroundColor Gray
    }
}
Write-Host "[OK] Directories ready" -ForegroundColor Green
Write-Host ""

# Set permissions
Write-Host "Setting NTFS permissions..." -ForegroundColor Yellow
try {
    $dockerServiceSid = "NT SERVICE\com.docker.service"
    
    foreach ($path in $DataPaths) {
        $acl = Get-Acl $path
        
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $dockerServiceSid,
            "FullControl",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        $acl.AddAccessRule($rule)
        
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $userRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $currentUser,
            "FullControl",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        $acl.AddAccessRule($userRule)
        
        Set-Acl $path $acl
        Write-Host "  Set: $path" -ForegroundColor Gray
    }
    Write-Host "[OK] Permissions configured" -ForegroundColor Green
} catch {
    Write-Host "[WARN] Permission setup: $_" -ForegroundColor Yellow
}
Write-Host ""

# Stop old containers
Write-Host "Stopping containers..." -ForegroundColor Yellow
docker compose -f docker-compose.prod.yml down --remove-orphans 2>&1 | Out-Null
Write-Host "[OK] Stopped" -ForegroundColor Green
Write-Host ""

# Start services
Write-Host "Starting OpenClaw Gateway..." -ForegroundColor Yellow
docker compose -f docker-compose.prod.yml up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to start" -ForegroundColor Red
    exit 1
}

Start-Sleep -Seconds 15

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Gateway: http://localhost:$($env:OPENCLAW_GATEWAY_PORT)" -ForegroundColor Cyan
Write-Host "Token: $($env:OPENCLAW_GATEWAY_TOKEN)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Data Locations:" -ForegroundColor White
Write-Host "  Home: $BaseDataDir\home" -ForegroundColor Gray
Write-Host "  Config: $BaseDataDir\config" -ForegroundColor Gray
Write-Host "  Workspace: $BaseDataDir\workspace" -ForegroundColor Gray
Write-Host "  Skills: $BaseDataDir\skills" -ForegroundColor Gray
Write-Host "  Logs: $LogsDir" -ForegroundColor Gray
Write-Host ""
Write-Host "Commands:" -ForegroundColor White
Write-Host "  Logs: docker compose -f docker-compose.prod.yml logs -f openclaw-gateway" -ForegroundColor Gray
Write-Host "  Restart: docker compose -f docker-compose.prod.yml restart" -ForegroundColor Gray
Write-Host "  CLI: docker compose -f docker-compose.prod.yml exec openclaw-cli node dist/index.js" -ForegroundColor Gray
Write-Host ""
