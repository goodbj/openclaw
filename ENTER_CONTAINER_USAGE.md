# OpenClaw Docker 开发环境 - 快速启动指南

## 🚀 双击进入容器（推荐）

### Windows 用户

**方法 1: PowerShell 脚本（现代化界面）**
```
双击运行：enter-container.ps1
```

**方法 2: 批处理文件（兼容性更好）**
```
双击运行：enter-container.bat
```

---

## 📋 功能特性

✅ **自动检查** - 检测 Docker 是否运行  
✅ **自动启动** - 容器未运行时自动启动  
✅ **健康检查** - 验证容器状态是否正常  
✅ **友好提示** - 显示常用命令列表  
✅ **错误处理** - 详细的错误信息和解决建议  

---

## 💻 使用示例

### 正常运行流程

```
1. 双击 enter-container.ps1
   ↓
2. 自动检查 Docker 状态 ✓
   ↓
3. 自动启动容器（如需要） ✓
   ↓
4. 显示容器信息
   ┌─────────────────────────────────────┐
   │ NAMES              STATUS   PORTS   │
   │ openclaw-gateway-dev  Up     ...    │
   └─────────────────────────────────────┘
   ↓
5. 进入容器 Bash 终端
   root@container:/app$ 
   ↓
6. 执行开发命令...
```

---

## 🔧 常用开发命令

### 在容器内可以执行的命令：

```bash
# 启动开发服务器（热重载）
pnpm dev

# 运行测试
pnpm test

# TypeScript 类型检查
pnpm tsgo

# 构建项目
pnpm build

# 代码格式化
pnpm format

# 查看 CLI 帮助
openclaw --help

# 安装新依赖
pnpm add <package-name>

# 退出容器
exit
```

---

## ⚠️ 常见问题

### 问题 1: "Docker 未运行"

**解决方案**:
1. 启动 Docker Desktop
2. 等待 Docker 图标变为绿色（就绪状态）
3. 重新运行脚本

---

### 问题 2: "容器启动失败"

**可能原因**:
- ❌ 端口被占用（18789, 18790, 18791）
- ❌ Docker 资源不足（内存/CPU）
- ❌ docker-compose.dev.yml 文件缺失

**解决方案**:
```powershell
# 检查端口占用
netstat -ano | findstr :18789

# 释放端口或重启 Docker
# Docker Desktop → Settings → Resources → 增加内存到 4GB+
```

---

### 问题 3: "无法连接到容器"

**解决方案**:
```powershell
# 查看容器日志
docker compose logs openclaw-gateway-dev

# 重启容器
docker compose restart openclaw-gateway-dev

# 完全重建
docker compose down
docker compose up -d
```

---

## 🛠️ 手动命令行方式

如果你喜欢使用命令行，也可以手动执行：

```powershell
# 1. 启动容器
docker compose -f docker-compose.dev.yml up -d

# 2. 进入容器
docker compose exec openclaw-gateway-dev bash

# 3. 在容器内执行命令
root@container:/app$ pnpm dev
```

---

## 📝 脚本说明

### enter-container.ps1 (PowerShell 版本)

**特点**:
- ✅ 彩色输出（更美观）
- ✅ 详细的状态提示
- ✅ 现代化的错误处理
- ✅ 支持 PowerShell 5.1+ 和 PowerShell 7+

**运行权限**（如果需要）:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\enter-container.ps1
```

---

### enter-container.bat (批处理版本)

**特点**:
- ✅ 兼容所有 Windows 版本
- ✅ 无需权限设置
- ✅ 简单直接

---

## 🎯 最佳实践

### 日常开发流程

```
1. 启动电脑 → Docker Desktop 自动启动
   ↓
2. 双击 enter-container.ps1
   ↓
3. 进入容器终端
   ↓
4. pnpm dev (启动热重载)
   ↓
5. 修改源代码 → 自动生效
   ↓
6. 测试通过 → git commit
   ↓
7. exit (退出容器)
```

---

## 📊 系统要求

| 组件 | 最低要求 | 推荐配置 |
|------|---------|---------|
| **操作系统** | Windows 10 | Windows 11 |
| **Docker** | Docker Desktop 4.0 | Docker Desktop 最新版 |
| **内存** | 4GB | 8GB+ |
| **磁盘** | 10GB 可用 | 20GB 可用 |
| **CPU** | 2 核心 | 4 核心+ |

---

## 🔗 相关文档

- [DOCKER_DEV_DEPLOYMENT_GUIDE.md](./DOCKER_DEV_DEPLOYMENT_GUIDE.md) - 完整部署指南
- [README.md](./README.md) - 项目说明

---

**祝你开发顺利！** 🎉

有任何问题随时查看完整文档或联系团队！
