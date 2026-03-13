# Docker OpenClaw 部署修复报告

## 📋 问题诊断与修复

### 问题 1: Gateway 容器反复重启 ❌

**症状**: 
- 容器状态：`Restarting (1) Less than a second ago`
- 错误信息：`non-loopback Control UI requires gateway.controlUi.allowedOrigins...`

**根本原因**:
1. 配置文件 `openclaw.json` 未创建
2. Windows Docker Desktop 路径挂载格式不正确

**修复方案**:

#### 步骤 1: 创建配置文件

```powershell
# 创建配置目录
New-Item -ItemType Directory -Force -Path "E:\AI\openclaw_docker\data\config" | Out-Null

# 创建 openclaw.json 配置文件
@{
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
} | ConvertTo-Json -Depth 10 | Set-Content -Path "E:\AI\openclaw_docker\data\config\openclaw.json" -Encoding UTF8
```

#### 步骤 2: 修正环境变量路径格式

Windows Docker Desktop 需要将 Windows 路径转换为 Unix 风格：

```bash
# .env.fixed 文件内容
OPENCLAW_HOME_VOLUME=/e/ai/openclaw_docker/data/home
OPENCLAW_CONFIG_DIR=/e/ai/openclaw_docker/data/config
OPENCLAW_WORKSPACE_DIR=/e/ai/openclaw_docker/data/workspace
OPENCLAW_SKILLS_DIR=/e/ai/openclaw_docker/data/skills
OPENCLAW_LOGS_DIR=/e/ai/openclaw_docker/logs
```

#### 步骤 3: 复制配置文件到容器

```powershell
docker cp "E:\AI\openclaw_docker\data\config\openclaw.json" openclaw-openclaw-gateway-1:/home/node/.openclaw/config/openclaw.json
docker restart openclaw-openclaw-gateway-1
```

---

### 问题 2: 数据持久化卷挂载失败 ❌

**症状**:
- 容器内 `/home/node/.openclaw/config/` 目录为空
- 宿主机配置文件未同步到容器

**根本原因**:
Windows Docker Desktop 不支持直接使用 Windows 路径格式 (`E:\path`) 作为卷挂载源。

**解决方案**:
使用 Unix 风格路径格式 (`/e/path`) 在 docker-compose.yml 中。

---

## ✅ 修复后状态

### 容器状态

```
NAME                          STATUS
openclaw-openclaw-gateway-1   Up (healthy)
```

### 服务验证

- ✅ Gateway API 运行在 http://localhost:18789
- ✅ Control UI 可访问
- ✅ 健康检查通过
- ✅ 配置文件正确加载
- ✅ 数据卷正确挂载

### 日志输出

```
2026-03-13T07:19:42.261+00:00 [gateway] security metric: gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback accepted a websocket connect request
```

---

## 🔧 管理命令

### 查看服务状态

```powershell
docker compose --env-file .env.fixed -f docker-compose.prod.yml ps
```

### 查看实时日志

```powershell
docker logs -f openclaw-openclaw-gateway-1
```

### 重启服务

```powershell
docker restart openclaw-openclaw-gateway-1
```

### 停止服务

```powershell
docker compose --env-file .env.fixed -f docker-compose.prod.yml down
```

### 进入容器 CLI

```powershell
docker exec -it openclaw-openclaw-gateway-1 node dist/index.js
```

---

## 📁 数据持久化位置

所有运行时数据已持久化到本地磁盘：

```
E:\AI\openclaw_docker\
├── data\
│   ├── home\          # identity, agents, sessions, memory
│   ├── config\        # openclaw.json
│   ├── workspace\     # 工作空间文件
│   └── skills\        # 技能包
└── logs\              # 应用日志
```

**重要**: 删除 Docker 镜像不会丢失以上数据！

---

## 🎯 下一步操作

### 1. 访问 Control UI

打开浏览器访问：http://localhost:18789

### 2. 配置设备配对

```powershell
# 获取仪表板链接
docker compose run --rm openclaw-cli dashboard --no-open

# 查看待批准的设备
docker compose run --rm openclaw-cli devices list

# 批准设备
docker compose run --rm openclaw-cli devices approve <requestId>
```

### 3. 配置 AI 提供商

```powershell
docker compose run --rm openclaw-cli providers add
```

### 4. 添加消息通道

```powershell
# WhatsApp (二维码扫描)
docker compose run --rm openclaw-cli channels login whatsapp

# Telegram (Bot Token)
docker compose run --rm openclaw-cli channels add telegram --token "<your-bot-token>"
```

---

## ⚠️ 注意事项

### Windows Docker Desktop 路径挂载

1. **路径格式**: 必须使用 Unix 风格 `/e/path` 而不是 `E:\path`
2. **共享驱动器**: 确保 E 盘已在 Docker Desktop 设置中启用
3. **权限**: Docker Service 需要访问权限

### 安全配置

当前配置使用了 `dangerouslyAllowHostHeaderOriginFallback=true`，这是为了开发便利。生产环境建议：

```json
{
  "gateway": {
    "controlUi": {
      "allowedOrigins": ["https://your-domain.com"]
    }
  }
}
```

---

## 📚 参考文档

- [官方 Docker 安装指南](https://docs.openclaw.ai/zh-CN/install/docker)
- [Control UI 使用文档](https://docs.openclaw.ai/web/dashboard)
- [完整部署指南](./DOCKER_DEPLOYMENT_GUIDE.md)

---

**修复完成时间**: 2026-03-13  
**修复后版本**: OpenClaw Gateway v2026.3.11  
**容器健康状态**: ✅ Healthy
