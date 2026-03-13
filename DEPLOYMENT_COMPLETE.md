# OpenClaw Docker 生产环境部署完成

## ✅ 部署状态

**Gateway 服务**: 运行中 - `http://localhost:18789`  
**认证 Token**: `openclaw-prod-token-2026-change-me` (请修改此默认值)

## 📁 数据持久化位置

所有数据已持久化到 `E:\AI\openclaw_docker` 目录，**不会因删除镜像而丢失**：

```
E:\AI\openclaw_docker\
├── data\
│   ├── home\              # 核心运行时数据
│   │   ├── identity\      # 身份认证信息
│   │   ├── agents\        # Agent 配置和会话
│   │   ├── memory\        # 记忆库（训练数据）
│   │   ├── skills\        # 安装的技能
│   │   └── workspace\     # 工作空间文件
│   ├── config\            # 配置文件 (openclaw.json)
│   ├── workspace\         # 用户工作区
│   └── skills\            # 技能包存储
└── logs\                  # 应用日志
```

## 🔒 磁盘权限配置

已完成 NTFS 权限设置：
- ✅ Docker Service (`NT SERVICE\com.docker.service`) - 完全控制
- ✅ 当前用户 - 完全控制

这确保 Docker 容器可以正常读写持久化数据。

## 🛠️ 管理命令

### 查看服务状态
```powershell
docker compose -f docker-compose.prod.yml ps
```

### 查看实时日志
```powershell
docker compose -f docker-compose.prod.yml logs -f openclaw-gateway
```

### 重启服务
```powershell
docker compose -f docker-compose.prod.yml restart
```

### 停止服务
```powershell
docker compose -f docker-compose.prod.yml down
```

### 进入 CLI 容器
```powershell
docker compose -f docker-compose.prod.yml exec openclaw-cli node dist/index.js
```

### 查看安装的技能和记忆库
```powershell
# 在 CLI 容器中执行
node dist/index.js skills list
node dist/index.js memory status
```

## 🔄 热重载开发（可选）

如需启用源代码热重载，编辑 `.env.prod`：
```bash
OPENCLAW_EXTRA_MOUNTS=./src:/app/src,./extensions:/app/extensions,./packages:/app/packages,./ui:/app/ui,./skills:/app/skills
```

然后重启：
```powershell
docker compose -f docker-compose.prod.yml restart
```

## ⚠️ 重要提示

1. **修改默认 Token**: 立即更改 `.env.prod` 中的 `OPENCLAW_GATEWAY_TOKEN`
2. **定期备份**: 建议定期备份 `E:\AI\openclaw_docker\data` 目录
3. **不要删除**: 删除 `data` 目录将丢失所有训练数据和配置
4. **安全加固**: 生产环境建议配置防火墙规则

## 📊 容器挂载验证

确认所有卷正确挂载：
```powershell
docker inspect openclaw-openclaw-gateway-1 --format '{{json .Mounts}}' | ConvertFrom-Json
```

应显示以下挂载点：
- `E:\AI\openclaw_docker\data\home` → `/home/node/.openclaw`
- `E:\AI\openclaw_docker\data\config` → `/home/node/.openclaw/config`
- `E:\AI\openclaw_docker\data\workspace` → `/home/node/.openclaw/workspace`
- `E:\AI\openclaw_docker\data\skills` → `/home/node/.openclaw/skills`
- `E:\AI\openclaw_docker\logs` → `/app/logs`

## 🎯 下一步操作

1. **登录配置**: 访问 `http://localhost:18789` 并修改默认 Token
2. **安装技能**: 使用 CLI 安装需要的技能包
3. **配置通道**: 添加 Telegram、Discord 等消息通道
4. **测试功能**: 验证记忆库和技能是否正常工作

---

**部署时间**: 2026-03-13  
**部署模式**: 生产环境（完整持久化）  
**数据存储**: E:\AI\openclaw_docker
