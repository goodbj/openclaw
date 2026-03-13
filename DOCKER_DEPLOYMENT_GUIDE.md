# OpenClaw Docker 部署完整指南

## 📋 目录

- [快速开始](#快速开始)
- [三种部署模式](#三种部署模式)
- [详细配置说明](#详细配置说明)
- [故障排查](#故障排查)

---

## 🚀 快速开始

### Windows PowerShell（推荐）

```powershell
# 1. 热重载开发模式（支持代码修改后快速重启）
.\scripts\deploy-docker-hotreload.ps1

# 2. 生产环境模式（完整数据持久化到 E:\AI\openclaw_docker）
.\scripts\deploy-docker-prod.ps1
```

### Linux/macOS Bash

```bash
# 热重载开发模式
chmod +x scripts/deploy-docker-hotreload.sh
./scripts/deploy-docker-hotreload.sh
```

---

## 🎯 三种部署模式

### 1️⃣ 热重载开发模式

**适用场景**: 新功能开发、代码调试  
**特点**: 
- 源代码挂载到容器
- 修改后重启容器即可应用
- 配置文件存储在 `~/.openclaw`

**使用方法**:
```powershell
# Windows
.\scripts\deploy-docker-hotreload.ps1

# 修改代码后重启
docker compose -f .env.hotreload restart openclaw-gateway
```

**挂载点**:
- `./src` → `/app/src`
- `./extensions` → `/app/extensions`
- `./packages` → `/app/packages`
- `./ui` → `/app/ui`
- `./skills` → `/app/skills`

---

### 2️⃣ 生产环境模式

**适用场景**: 长期运行、稳定服务  
**特点**:
- 所有数据持久化到 `E:\AI\openclaw_docker`
- 删除镜像不会丢失数据
- 包含完整的 NTFS 权限配置

**使用方法**:
```powershell
.\scripts\deploy-docker-prod.ps1
```

**数据存储位置**:
```
E:\AI\openclaw_docker\
├── data\
│   ├── home\          # identity, agents, memory, skills
│   ├── config\        # openclaw.json
│   ├── workspace\     # 工作空间文件
│   └── skills\        # 技能包
└── logs\              # 应用日志
```

---

### 3️⃣ 官方标准模式

**适用场景**: 跟随官方文档学习  
**特点**:
- 与官方文档完全一致
- 配置存储在 `~/.openclaw`

**使用方法**:
```bash
# Linux/macOS
./docker-setup.sh

# Windows (手动流程)
docker build -t openclaw:local -f Dockerfile .
docker compose run --rm openclaw-cli onboard
docker compose up -d openclaw-gateway
```

---

## ⚙️ 详细配置说明

### 环境变量（可选）

在运行部署脚本前设置：

```powershell
# 安装额外的 apt 包
$env:OPENCLAW_DOCKER_APT_PACKAGES="git curl vim"

# 启用 Docker 沙箱支持
$env:OPENCLAW_INSTALL_DOCKER_CLI=1

# 使用命名卷持久化 /home/node
$env:OPENCLAW_HOME_VOLUME="openclaw_home"

# 额外挂载主机目录
$env:OPENCLAW_EXTRA_MOUNTS="$HOME/.codex:/home/node/.codex:ro,$HOME/github:/home/node/github:rw"

# 启用的扩展
$env:OPENCLAW_EXTENSIONS="diagnostics-otel matrix"
```

### Gateway Token 配置

部署脚本会自动生成随机 Token。如需自定义：

```powershell
# 方式 1: 设置环境变量
$env:OPENCLAW_GATEWAY_TOKEN="your-custom-token-here"
.\scripts\deploy-docker-prod.ps1

# 方式 2: 修改配置文件
# 编辑 E:\AI\openclaw_docker\data\config\openclaw.json
```

### Control UI 配置

如果遇到 "unauthorized" 错误：

```powershell
# 获取新的仪表板链接
docker compose run --rm openclaw-cli dashboard --no-open

# 批准设备
docker compose run --rm openclaw-cli devices list
docker compose run --rm openclaw-cli devices approve <requestId>
```

---

## 🔧 管理命令

### 查看服务状态

```powershell
# 热重载模式
docker compose -f .env.hotreload -f docker-compose.yml ps

# 生产模式
docker compose -f docker-compose.prod.yml ps
```

### 查看日志

```powershell
# 实时日志
docker compose logs -f openclaw-gateway

# 最近 100 行
docker compose logs --tail=100 openclaw-gateway
```

### 重启服务

```powershell
# 重启 Gateway
docker compose restart openclaw-gateway

# 重启所有服务
docker compose restart
```

### 停止服务

```powershell
# 停止（保留数据）
docker compose down

# 完全清理（包括卷）
docker compose down --volumes --remove-orphans
```

### 进入容器 CLI

```powershell
# 执行命令
docker compose exec openclaw-cli node dist/index.js

# 或进入交互模式
docker compose run --rm openclaw-cli
```

---

## 🐛 故障排查

### 问题 1: Gateway 容器反复重启

**症状**: 容器状态显示 `Restarting (1)`

**原因**: Control UI 配置缺失

**解决方案**:
```powershell
# 检查日志
docker compose logs openclaw-gateway | Select-String "Control UI"

# 如果看到 "non-loopback Control UI requires..."
# 编辑配置文件，添加：
{
  "gateway": {
    "controlUi": {
      "dangerouslyAllowHostHeaderOriginFallback": true
    }
  }
}
```

### 问题 2: 权限错误 (EACCES)

**症状**: 无法写入 `~/.openclaw` 或配置目录

**解决方案 (Linux)**:
```bash
sudo chown -R 1000:1000 ~/.openclaw
```

**解决方案 (Windows)**:
```powershell
# 确保 Docker Desktop 有访问权限
# 右键目录 → 属性 → 安全 → 编辑
```

### 问题 3: 端口被占用

**症状**: `bind: address already in use`

**解决方案**:
```powershell
# 查找占用端口的进程
netstat -ano | findstr :18789

# 停止占用进程或使用不同端口
$env:OPENCLAW_GATEWAY_PORT=18799
.\scripts\deploy-docker-prod.ps1
```

### 问题 4: 镜像构建失败

**症状**: `pull access denied` 或 `repository does not exist`

**解决方案**:
```powershell
# 检查 Docker 是否正常运行
docker version

# 清除缓存重试
docker builder prune -a

# 使用国内镜像源（中国用户）
# 编辑 Docker Desktop 设置 → Docker Engine
# 添加：{"registry-mirrors": ["https://docker.mirrors.ustc.edu.cn"]}
```

---

## 📊 健康检查

```powershell
# 使用内置健康检查
docker compose exec openclaw-gateway node dist/index.js health --token "$OPENCLAW_GATEWAY_TOKEN"

# 或在浏览器访问
http://localhost:18789/healthz
```

---

## 🎓 下一步

1. **配置消息通道**: [查看通道文档](https://docs.openclaw.ai/channels)
2. **安装技能**: `docker compose exec openclaw-cli skills install <skill-name>`
3. **配置 AI 提供商**: 运行 `docker compose exec openclaw-cli providers add`
4. **访问 Control UI**: http://localhost:18789

---

## 📚 参考链接

- [官方 Docker 安装文档](https://docs.openclaw.ai/zh-CN/install/docker)
- [沙箱隔离指南](https://docs.openclaw.ai/gateway/sandboxing)
- [Control UI 使用](https://docs.openclaw.ai/web/dashboard)
- [命令行工具](https://docs.openclaw.ai/cli)

---

**最后更新**: 2026-03-13  
**适用版本**: OpenClaw 2026.3.13+
