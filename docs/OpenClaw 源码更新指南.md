# OpenClaw 源码部署热重载更新指南

> **适用场景**: Docker 源码部署 + 目录持久化挂载 + 热重载模式  
> **最后更新**: 2026-03-14  
> **维护者**: OpenClaw 团队

---

## 📋 目录

1. [架构概述](#架构概述)
2. [更新策略](#更新策略)
3. [标准更新流程](#标准更新流程)
4. [故障恢复](#故障恢复)
5. [备份与回滚](#备份与回滚)
6. [常见问题](#常见问题)

---

## 架构概述

### 部署模式

```yaml
部署方式：源码直挂（非镜像）
容器基础镜像：openclaw-with-go:local
代码位置：E:\AI\openclaw_docker\openclaw (Windows)
          ↓ bind mount
          /home/node/.openclaw/workspace (容器内)
热重载：支持（代码修改即时生效）
数据持久化：E:\AI\openclaw_docker\data → /home/node/.openclaw
```

### 核心特性

| 特性 | 说明 |
|------|------|
| **源码部署** | 代码直接在 Windows 目录，Docker 实时映射 |
| **热重载** | Gateway 自动检测代码变化，无需重启容器 |
| **目录持久化** | 配置、技能、插件独立于代码，永久保存 |
| **自定义分支** | PigClaw 分支（基于 openclaw/openclaw） |

---

## 更新策略

### ⭐ 推荐方案：Git Pull + 热重载

**为什么不用重新构建镜像？**

1. **架构设计**: `openclaw-with-go:local` 只提供运行时环境（Node.js、Go 等）
2. **代码分离**: 业务代码在挂载目录，不在镜像中
3. **热重载**: Gateway 支持代码热更新，修改立即生效
4. **效率**: Git Pull 几秒完成，Docker Build 需要 5-10 分钟

**对比分析：**

| 方案 | 耗时 | 适用场景 | 推荐度 |
|------|------|----------|--------|
| Git Pull + 热重载 | 几秒 - 几十秒 | 日常更新 | ⭐⭐⭐⭐⭐ |
| Docker Build | 5-10 分钟 | 修改了 Dockerfile/基础镜像 | ⭐ |

---

## 标准更新流程

### 前置检查清单

```bash
# 1. 确认当前分支
git branch --show-current
# 应该输出：PigClaw

# 2. 确认远程仓库
git remote -v
# 应该有：
#   upstream  https://github.com/openclaw/openclaw.git (fetch/push)
#   fork      https://github.com/goodbj/openclaw.git (fetch/push)

# 3. 检查工作区状态
git status --short
# 应该是干净的（无未提交更改）
```

---

### 步骤 1: 备份关键配置

**PowerShell 命令：**

```powershell
# 创建备份目录
$backupDir = "E:\AI\openclaw_docker\backups\pre-update-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force

# 备份 .env（如果在 openclaw 目录）
if (Test-Path "E:\AI\openclaw_docker\.env") {
    Copy-Item "E:\AI\openclaw_docker\.env" "$backupDir\.env.bak"
}

# 备份 openclaw.json
if (Test-Path "E:\AI\openclaw_docker\data\openclaw.json") {
    Copy-Item "E:\AI\openclaw_docker\data\openclaw.json" "$backupDir\openclaw.json.bak"
}

Write-Host "✅ 备份完成：$backupDir"
```

**备份内容：**
- `.env` - Docker 环境变量配置
- `openclaw.json` - OpenClaw 主配置文件
- （可选）`data/feishu/` - 飞书会话数据

---

### 步骤 2: 执行 Git Pull

**从上游仓库拉取（推荐）：**

```bash
cd E:\AI\openclaw_docker\openclaw
git pull upstream main --rebase
```

**如果网络问题，使用 fork 仓库：**

```bash
git pull fork main --rebase
```

**或者分步操作：**

```bash
# 1. 获取最新代码
git fetch upstream main

# 2. 变基到最新
git rebase upstream/main

# 3. 如果有冲突
git rebase --abort
# 或解决冲突后
git rebase --continue
```

---

### 步骤 3: 监控热重载日志

**实时查看 Gateway 日志：**

```powershell
docker compose logs -f openclaw-gateway | Select-String -Pattern "reload|restart|updated"
```

**典型的热重载日志：**

```
[Gateway] detected file changes in /workspace
[Gateway] hot reload triggered...
[Gateway] reloading plugins...
[Gateway] ✓ reload complete
```

**等待时间：**
- 小改动：5-10 秒
- 大改动：30-60 秒

---

### 步骤 4: 验证更新成功

**1. 检查版本信息：**

```bash
docker compose exec openclaw-gateway bash -c "openclaw --version"
```

**2. 测试核心功能：**

```bash
# 飞书消息收发（在飞书中给机器人发消息）
# Control UI 访问（浏览器打开 http://localhost:18791/）
```

**3. 检查错误日志：**

```powershell
docker compose logs openclaw-gateway --since 5m | Select-String -Pattern "error|fatal|panic"
```

---

### 步骤 5: 清理备份（可选）

**保留最近 7 个备份：**

```powershell
$backupRoot = "E:\AI\openclaw_docker\backups"
Get-ChildItem $backupRoot -Directory | Sort-Object CreationTime -Descending | Select-Object -Skip 7 | Remove-Item -Recurse -Force
```

---

## 故障恢复

### 场景 1: Git Pull 失败

**问题：** 网络连接超时、SSL 错误

**解决方案：**

```bash
# 1. 尝试 HTTP 协议
git config url."http://github.com/".insteadOf "https://github.com/"
git pull upstream main

# 2. 使用代理
export https_proxy=http://proxy-server:port
git pull upstream main

# 3. 手动下载代码
# 从 GitHub 下载 ZIP，解压覆盖
```

---

### 场景 2: 热重载失败

**问题：** 代码更新后功能异常

**解决方案：**

```bash
# 1. 强制重启容器（热重载卡住时）
docker compose restart openclaw-gateway

# 2. 查看详细日志
docker compose logs openclaw-gateway --tail=200

# 3. 检查文件权限
docker compose exec openclaw-gateway bash -c "ls -la /home/node/.openclaw/workspace"
```

---

### 场景 3: 配置丢失

**问题：** 更新后配置被覆盖

**解决方案：**

```bash
# 1. 从备份恢复
Copy-Item "E:\AI\openclaw_docker\backups\pre-update-*/openclaw.json.bak" "E:\AI\openclaw_docker\data\openclaw.json" -Force

# 2. 重启容器
docker compose restart openclaw-gateway
```

---

## 备份与回滚

### 快速回滚方案

**如果发现更新后有严重问题：**

```bash
# 1. 停止容器
docker compose stop openclaw-gateway

# 2. 回滚 Git 代码
cd E:\AI\openclaw_docker\openclaw
git reset --hard HEAD~1  # 回滚一次提交
# 或指定 commit
git reset --hard <commit-hash>

# 3. 恢复配置
Copy-Item "E:\AI\openclaw_docker\backups\pre-update-*/openclaw.json.bak" "E:\AI\openclaw_docker\data\openclaw.json" -Force

# 4. 重启容器
docker compose start openclaw-gateway
```

---

### 完整灾难恢复

**如果整个系统崩溃：**

```powershell
# 1. 停止所有容器
docker compose down

# 2. 完全回滚 Git
cd E:\AI\openclaw_docker\openclaw
git reset --hard <known-good-commit>
git clean -fdx  # 警告：删除所有未跟踪文件！

# 3. 恢复所有备份
Copy-Item "E:\AI\openclaw_docker\backups\latest\*" "E:\AI\openclaw_docker\" -Recurse -Force

# 4. 重建容器
docker compose up -d --force-recreate
```

---

## 常见问题

### Q1: 每次更新都需要备份吗？

**A:** 
- ✅ **建议每次都备份**（只需几秒钟）
- 备份占用空间很小（配置文件只有几 KB）
- 关键时刻能救命

---

### Q2: 热重载不工作怎么办？

**A:** 

1. **检查 Gateway 是否启用了热重载**
   ```bash
   docker compose exec openclaw-gateway bash -c "cat /home/node/.openclaw/openclaw.json | grep hot-reload"
   ```

2. **手动触发重启**
   ```bash
   docker compose restart openclaw-gateway
   ```

3. **检查文件监视器**
   ```bash
   docker compose exec openclaw-gateway bash -c "lsof | grep workspace"
   ```

---

### Q3: 更新后性能下降怎么办？

**A:**

1. **检查是否有新插件加载**
   ```bash
   docker compose logs openclaw-gateway | Select-String "loaded plugin"
   ```

2. **禁用不必要的插件**
   ```json
   // openclaw.json
   "plugins": {
     "disabled": ["plugin-name"]
   }
   ```

3. **回滚到上一个稳定版本**

---

### Q4: 如何知道当前版本是否需要更新？

**A:**

```bash
# 查看本地版本
git rev-parse HEAD

# 查看上游最新版本
git ls-remote upstream main

# 比较差异
git log HEAD..upstream/main --oneline
```

如果有输出，说明有新版本可更新。

---

### Q5: 更新会影响正在进行的对话吗？

**A:**

- ✅ **热重载不会影响** - 对话状态保存在内存中
- ⚠️ **容器重启会影响** - 会中断 WebSocket连接
- 💡 **建议** - 在低峰期更新（深夜或清晨）

---

## 附录：一键更新脚本

**PowerShell 一键更新（生产就绪版）：**

```powershell
#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "🔄 OpenClaw 一键热重载更新" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

try {
    # 1. 备份
    $backupDir = "E:\AI\openclaw_docker\backups\pre-update-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Copy-Item "E:\AI\openclaw_docker\data\openclaw.json" "$backupDir\openclaw.json.bak" -Force -ErrorAction SilentlyContinue
    Write-Host "✅ 备份完成：$backupDir" -ForegroundColor Green
    
    # 2. Git Pull
    Set-Location "E:\AI\openclaw_docker\openclaw"
    Write-Host "`n📥 拉取最新代码..." -ForegroundColor Yellow
    git pull upstream main --rebase
    if ($LASTEXITCODE -ne 0) {
        throw "Git Pull 失败，请检查网络连接"
    }
    Write-Host "✅ 代码拉取完成" -ForegroundColor Green
    
    # 3. 提示用户监控日志
    Write-Host "`n📊 请监控热重载日志:" -ForegroundColor Yellow
    Write-Host "   docker compose logs -f openclaw-gateway" -ForegroundColor Gray
    Write-Host "`n等待 30 秒让热重载完成..." -ForegroundColor Gray
    Start-Sleep -Seconds 30
    
    # 4. 验证
    Write-Host "`n🧪 验证更新..." -ForegroundColor Yellow
    docker compose exec openclaw-gateway bash -c "openclaw --version" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 更新成功！" -ForegroundColor Green
    } else {
        Write-Host "⚠️ 版本检查失败，但更新可能已应用" -ForegroundColor Yellow
    }
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "💡 提示：如有问题可从备份恢复" -ForegroundColor Yellow
    Write-Host "   备份路径：$backupDir" -ForegroundColor Gray
    Write-Host "========================================`n" -ForegroundColor Cyan
    
} catch {
    Write-Host "`n❌ 更新失败：$_" -ForegroundColor Red
    Write-Host "💡 请手动执行 Git Pull 或联系管理员" -ForegroundColor Yellow
    exit 1
}
```

**使用方法：**

```powershell
.\update-openclaw.ps1
```

---

## 维护记录

| 日期 | 操作 | 结果 | 备注 |
|------|------|------|------|
| 2026-03-14 | 首次创建文档 | ✅ 成功 | 建立标准化流程 |
| - | - | - | - |

---

## 总结

**核心要点：**

1. ✅ **源码部署 + 热重载** 是最佳实践
2. ✅ **Git Pull** 是主要更新手段（无需 Docker Build）
3. ✅ **备份习惯** 能避免 99% 的灾难
4. ✅ **快速回滚** 能力比完美更新更重要
5. ✅ **文档化** 每次更新的经验和教训

**下次 AI 助手失忆后，把这个文档发给它，它能立即恢复记忆！** 🦞
