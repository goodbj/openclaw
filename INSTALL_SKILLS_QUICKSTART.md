# OpenClaw 技能批量安装 - 快速启动指南

> 🚀 每 10 分钟自动安装一个高星级、高点赞的 OpenClaw 高级开发技能

---

## ⚡ 快速开始（3 种方式）

### 方式 1: PowerShell 脚本（Windows 推荐）⭐

```powershell
# 进入项目目录
cd E:\AI\openclaw_docker\openclaw

# 运行安装脚本
.\scripts\install-skills-schedule.ps1

# 或者指定要安装的技能
.\scripts\install-skills-schedule.ps1 -Skills @("skill-vetter","find-skills","tavily-search") -IntervalMinutes 10
```

---

### 方式 2: Bash 脚本（Unix/Linux/Mac）

```bash
# 进入项目目录
cd /path/to/openclaw

# 给脚本执行权限
chmod +x scripts/install-skills-schedule.sh

# 运行安装脚本
./scripts/install-skills-schedule.sh

# 或者跳过倒计时（测试用）
./scripts/install-skills-schedule.sh --skip-countdown
```

---

### 方式 3: 手动逐个安装（适合学习）

```bash
# 每个技能间隔 10 分钟
npx clawhub@latest install skill-vetter
# 等待 10 分钟...

npx clawhub@latest install find-skills
# 等待 10 分钟...

npx clawhub@latest install tavily-search
```

---

## 📋 默认安装清单

脚本会按顺序安装以下技能（每 10 分钟 1 个）：

| # | 技能名称 | 用途 | 优先级 |
|---|---------|------|--------|
| 1 | **skill-vetter** | 技能质量评估工具 | P0 |
| 2 | **find-skills** | 技能搜索和发现 | P0 |
| 3 | **tavily-search** | 网络搜索增强 | P0 |
| 4 | **code-analyzer** | 代码静态分析 | P1 |
| 5 | **test-generator** | 单元测试生成 | P1 |

---

## 🎯 功能特性

### ✅ 自动化流程

```
[查找技能] → [检查依赖] → [执行安装] → [验证成功] → [记录日志]
     ↓
  等待 10 分钟
     ↓
下一个技能...
```

### 📊 实时反馈

- ✓ 彩色输出（状态清晰）
- ✓ 倒计时显示（剩余时间）
- ✓ 详细日志（skills-install.log）
- ✓ 最终统计（成功率等）

### 🔒 安全保障

- ✓ 安装前确认（防止误操作）
- ✓ 错误处理（失败不中断）
- ✓ 可中断（Ctrl+C 随时停止）
- ✓ 可恢复（从中断点继续）

---

## 🛠️ 自定义配置

### 修改技能列表

编辑 `scripts/install-skills-schedule.ps1`:

```powershell
param(
    [string[]]$Skills = @(
        "skill-vetter",
        "find-skills", 
        "tavily-search",
        "你的技能",
        "更多技能..."
    ),
    [int]$IntervalMinutes = 10  # 修改间隔时间
)
```

### 跳过倒计时（快速测试）

```powershell
.\scripts\install-skills-schedule.ps1 -SkipCountdown
```

---

## 📝 日志文件

安装过程会记录到 `skills-install.log`:

```log
[2026-03-13 21:30:45] 安装：skill-vetter
  状态：成功
  耗时：45.23 秒
  Stars: 256
  下载：5000/月
---
[2026-03-13 21:40:50] 安装：find-skills
  状态：成功
  耗时：38.91 秒
  Stars: 189
  下载：3200/月
---
```

---

## ⚠️ 常见问题

### Q1: 速率限制怎么办？

**A**: npx clawhub 有 API 速率限制，如果触发：

```powershell
# 方案 A: 增加间隔时间
-IntervalMinutes 15

# 方案 B: 使用 GitHub Token
$env:GITHUB_TOKEN="your-token-here"
```

---

### Q2: 技能已存在怎么办？

**A**: 脚本会自动跳过或更新：

```powershell
# 查看已安装技能
openclaw skills list

# 更新技能
npx clawhub@latest update "skill-name"
```

---

### Q3: 如何查看进度？

**A**: 三种方式：

```powershell
# 方式 1: 查看日志文件
Get-Content skills-install.log -Tail 20

# 方式 2: 列出已安装技能
openclaw skills list

# 方式 3: 查看 JSON 导出
openclaw skills list --json > installed.json
```

---

### Q4: 中途停止后如何继续？

**A**: 从停止的技能继续：

```powershell
# 假设在第 3 个技能停止，从第 4 个开始
.\scripts\install-skills-schedule.ps1 -Skills @("code-analyzer","test-generator")
```

---

## 🎓 学习建议

### 第一个小时

```
🕐 09:00-09:10  安装 skill-vetter
                → 了解什么是高质量技能
                
🕐 09:10-09:20  安装 find-skills
                → 学会发现和筛选技能
                
🕐 09:20-09:30  安装 tavily-search
                → 体验网络搜索增强
```

### 第二个小时

```
🕐 09:30-09:40  安装 code-analyzer
                → 代码质量提升工具
                
🕐 09:40-09:50  安装 test-generator
                → 自动化测试生成
```

---

## 📊 预期成果

### 完成第一阶段（5 个技能）后：

```
✓ 掌握技能筛选方法
✓ 拥有核心开发工具集
✓ 理解 OpenClaw 生态
✓ 建立自动化工作流
```

### 完成全部阶段（30 个技能）后：

```
✓ 高级开发能力全面提升
✓ AI 辅助编程效率×10
✓ 工程化水平质的飞跃
✓ 成为 OpenClaw 专家
```

---

## 🔗 相关文档

- [SKILLS_INSTALLATION_PLAN.md](./SKILLS_INSTALLATION_PLAN.md) - 完整计划文档
- [README.md](./README.md) - 项目说明

---

## 💡 最佳实践

1. **每天安装 5-10 个技能** - 不要贪多，消化吸收最重要
2. **先试用再深入** - 每个技能先跑通示例，再探索高级功能
3. **做笔记** - 记录每个技能的使用场景和心得
4. **分享经验** - 在团队内部分享好用的技能

---

**准备好提升你的 OpenClaw 开发能力了吗？** 🚀

选择一个方式，立即开始！
