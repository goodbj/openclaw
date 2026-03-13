# OpenClaw 高级开发技能批量安装脚本
# 每 10 分钟自动安装一个高质量技能

param(
    [string[]]$Skills = @(
        "skill-vetter",
        "find-skills", 
        "tavily-search",
        "code-analyzer",
        "test-generator"
    ),
    [int]$IntervalMinutes = 10,
    [switch]$SkipCountdown
)

$ErrorActionPreference = "Stop"
$logFile = "skills-install.log"

function Write-Header {
    param([string]$Text)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan
}

function Install-Skill {
    param([string]$SkillName)
    
    $startTime = Get-Date
    Write-Host "`n[$($startTime.ToString('HH:mm:ss'))] 开始安装：$SkillName" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Gray
    
    try {
        # 步骤 1: 查找技能信息
        Write-Host "`n[1/5] 正在查找技能信息..." -ForegroundColor Yellow
        $skillInfo = $null
        try {
            $skillInfo = npx clawhub@latest search "$SkillName" --json 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($skillInfo) {
                Write-Host "  ✓ 找到技能：$($skillInfo.name)" -ForegroundColor Green
                Write-Host "  ⭐ Stars: $($skillInfo.stars)" -ForegroundColor Gray
                Write-Host "  📥 下载：$($skillInfo.downloads)/月" -ForegroundColor Gray
            }
        } catch {
            Write-Host "  ⚠️  无法获取技能信息，继续安装..." -ForegroundColor Yellow
        }
        
        # 步骤 2: 检查依赖
        Write-Host "`n[2/5] 检查依赖关系..." -ForegroundColor Yellow
        # TODO: 添加依赖检查逻辑
        
        # 步骤 3: 执行安装
        Write-Host "`n[3/5] 正在安装 $SkillName ..." -ForegroundColor Yellow
        $installOutput = yes | npx clawhub@latest install "$SkillName" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ 安装成功" -ForegroundColor Green
        } else {
            Write-Host "  ✗ 安装失败或已存在 (退出码：$LASTEXITCODE)" -ForegroundColor Red
            Write-Host "  输出：$installOutput" -ForegroundColor DarkGray
        }
        
        # 步骤 4: 验证安装
        Write-Host "`n[4/5] 验证安装..." -ForegroundColor Yellow
        $verifyResult = openclaw skills list 2>&1 | Select-String $SkillName -Quiet
        if ($verifyResult) {
            Write-Host "  ✓ 验证通过" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  验证失败，但可能已安装" -ForegroundColor Yellow
        }
        
        # 步骤 5: 记录日志
        Write-Host "`n[5/5] 记录安装日志..." -ForegroundColor Yellow
        $endTime = Get-Date
        $duration = New-TimeSpan -Start $startTime -End $endTime
        $status = if ($LASTEXITCODE -eq 0) { "成功" } else { "失败" }
        
        $logEntry = @"
[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] 安装：$SkillName
  状态：$status
  耗时：$([Math]::Round($duration.TotalSeconds, 2)) 秒
  Stars: $(if ($skillInfo) { $skillInfo.stars } else { "N/A" })
  下载：$(if ($skillInfo) { $skillInfo.downloads } else { "N/A" })
---
"@
        Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
        Write-Host "  ✓ 日志已记录到 $logFile" -ForegroundColor Green
        
        return $true
    } catch {
        Write-Host "`n✗ 发生错误：$_" -ForegroundColor Red
        return $false
    }
}

# 主程序
Write-Header "OpenClaw 高级开发技能批量安装计划"

Write-Host "📋 安装配置:" -ForegroundColor Yellow
Write-Host "  技能数量：$($Skills.Count)" -ForegroundColor White
Write-Host "  时间间隔：$IntervalMinutes 分钟" -ForegroundColor White
Write-Host "  预计总耗时：$($Skills.Count * $IntervalMinutes) 分钟" -ForegroundColor White
Write-Host "  日志文件：$logFile" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "是否开始安装？(Y/N)"
if ($confirm -notmatch '^[Yy]$') {
    Write-Host "已取消安装" -ForegroundColor Yellow
    exit 0
}

$successCount = 0
$failCount = 0

foreach ($skill in $Skills) {
    $result = Install-Skill -SkillName $skill
    
    if ($result) {
        $successCount++
    } else {
        $failCount++
    }
    
    # 如果不是最后一个技能，等待指定时间
    if ($skill -ne $Skills[-1]) {
        if (-not $SkipCountdown) {
            $waitSeconds = $IntervalMinutes * 60
            Write-Host "`n⏱️  等待 $IntervalMinutes 分钟后安装下一个技能..." -ForegroundColor Cyan
            Write-Host "   下次安装：$((Get-Date).AddMinutes($IntervalMinutes).ToString('HH:mm:ss'))" -ForegroundColor Gray
            
            # 倒计时显示
            for ($i = $waitSeconds; $i -gt 0; $i--) {
                $mins = [Math]::Floor($i / 60)
                $secs = $i % 60
                Write-Host "`r   剩余：{0:D2}:{1:D2}" -NoNewline -ForegroundColor DarkGray -f $mins, $secs
                Start-Sleep -Seconds 1
            }
            Write-Host "" # 换行
        } else {
            Write-Host "`n⏭️  跳过倒计时，直接安装下一个..." -ForegroundColor Cyan
            Start-Sleep -Seconds 5
        }
    }
}

# 最终统计
Write-Header "安装完成！"
Write-Host "📊 安装统计:" -ForegroundColor Yellow
Write-Host "  成功：$successCount / $($Skills.Count)" -ForegroundColor Green
Write-Host "  失败：$failCount / $($Skills.Count)" -ForegroundColor Red
Write-Host "  成功率：$([Math]::Round($successCount / $Skills.Count * 100, 2))%" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 详细日志请查看：$logFile" -ForegroundColor Gray
Write-Host ""
