# OpenClaw Docker 热重载开发环境部署指南

> 本文档记录从零开始在 Docker 沙箱环境中搭建 OpenClaw 热重载开发环境的完整流程，支持源代码实时修改和功能开发。

---

## 📋 目录

- [前置要求](#前置要求)
- [环境规划](#环境规划)
- [Step 1: 清理不必要的文件](#step-1-清理不必要的文件)
- [Step 2: 创建开发环境配置](#step-2-创建开发环境配置)
- [Step 3: 配置 Docker 热重载](#step-3-配置 docker 热重载)
- [Step 4: 启动开发环境](#step-4-启动开发环境)
- [Step 5: 验证热重载功能](#step-5-验证热重载功能)
- [Step 6: 开始功能开发](#step-6-开始功能开发)
- [常见问题 FAQ](#常见问题-faq)
- [维护手册](#维护手册)

---

## 前置要求

### 系统要求

- **操作系统**: Windows 10/11 Professional 或更高版本
- **Docker**: Docker Desktop 4.0+ (启用 WSL2 后端)
- **磁盘空间**: 至少 20GB 可用空间
- **内存**: 至少 8GB RAM (推荐 16GB)
- **Git**: 最新版本的 Git for Windows

### 网络要求

- **开放端口**: 
  - `18789` - Gateway WebSocket
  - `18790` - 开发服务器 (可选)
  - `18791` - Browser Control
- **DNS**: 确保能访问外部 API（飞书、Ollama 等）

---

## 环境规划

### 目录结构

```
E:\AI\openclaw_docker\
├── openclaw/                 # 源代码仓库（你已准备好）
│   ├── src/                 # 源代码
│   ├── extensions/          # 插件扩展
│   ├── docker-compose.dev.yml  # 开发环境配置（新建）
│   ├── Dockerfile.dev       # 开发环境镜像（新建）
│   └── .env.dev             # 开发环境变量（新建）
├── data/                    # 持久化数据（自动创建）
│   ├── config/              # 配置文件
│   ├── home/                # 用户数据
│   │   ├── extensions/      # 安装的插件
│   │   ├── skills/          # 技能包
│   │   └── workspace/       # 工作空间
│   └── logs/                # 日志文件
└── backups/                 # 备份目录
```

### 开发模式 vs 生产模式

| 特性 | 开发模式 | 生产模式 |
|------|---------|---------|
| **代码同步** | ✅ 实时挂载（热重载） | ❌ 构建时固化 |
| **调试支持** | ✅ Source Maps | ❌ 优化编译 |
| **日志级别** | debug | info/warn |
| **自动重启** | ✅ 文件变更检测 | ❌ 手动重启 |
| **性能** | 较慢（适合开发） | 最快（适合部署） |

---

## Step 1: 清理不必要的文件

### 1.1 识别临时文件

以下文件是历史部署过程中产生的，可以安全删除：

```powershell
# 切换到 openclaw 目录
cd E:\AI\openclaw_docker\openclaw

# 查看未跟踪的文件
git status --short
```

### 1.2 删除临时配置文件

```powershell
# 删除旧的 .env 文件（这些应该重新生成）
Remove-Item .env.dev -Force -ErrorAction SilentlyContinue
Remove-Item .env.fixed -Force -ErrorAction SilentlyContinue
Remove-Item .env.prod -Force -ErrorAction SilentlyContinue

Write-Host "✓ 已清理旧的 .env 文件" -ForegroundColor Green
```

### 1.3 删除临时测试文件

```powershell
# 删除个人测试和调试文件
$testFiles = @(
    'CODE_DEV_SKILLS_INSTALL.md',
    'ESSENTIAL_PLUGINS_INSTALL.md',
    'ESSENTIAL_SKILLS_COMPLETE_GUIDE.md',
    'INSTALL_SKILLS_MANUAL.md',
    'INSTALL_TIMER.md',
    'QUICK_TEST_GUIDE.md',
    'SANDBOX_VS_TERMINXAL_EXPLAINED.md',
    'SKILLS_INSTALLATION_STATUS.md',
    'SKILLS_IN_DOCKER.md',
    'TEST_CODE_FEATURES.md',
    'TEST_WEATHER_SUMMARIZE.md',
    'WAITING_TASKS.md'
)

foreach($file in $testFiles){
    if(Test-Path $file){
        Remove-Item $file -Force
        Write-Host "✓ 已删除：$file" -ForegroundColor Yellow
    }
}
```

### 1.4 删除临时脚本文件

```powershell
# 删除一次性修复脚本（保留到 scripts 目录的正式脚本）
$scripts = @(
    'bulk-permission-fix.ps1',
    'diagnose-container.ps1',
    'emergency-fix-permissions.ps1',
    'fix-permissions.ps1',
    'install-feishu.ps1',
    'test-feishu-api.ps1',
    'uninstall-feishu.ps1'
)

foreach($script in $scripts){
    if(Test-Path $script){
        Remove-Item $script -Force
        Write-Host "✓ 已删除：$script" -ForegroundColor Yellow
    }
}
```

### 1.5 清理旧的 Docker Compose 配置

```powershell
# 如果有旧的开发配置，先备份再删除
if(Test-Path 'docker-compose.dev.yml'){
    Copy-Item 'docker-compose.dev.yml' 'docker-compose.dev.yml.backup' -Force
    Remove-Item 'docker-compose.dev.yml' -Force
    Write-Host "✓ 已备份并删除旧的 docker-compose.dev.yml" -ForegroundColor Green
}
```

---

## Step 2: 创建开发环境配置

### 2.1 创建 .env.dev 环境变量文件

在 `E:\AI\openclaw_docker\openclaw\.env.dev` 创建：

```bash
# OpenClaw 开发环境变量

# Gateway 配置
OPENCLAW_GATEWAY_MODE=local
OPENCLAW_GATEWAY_BIND=loopback
OPENCLAW_GATEWAY_PORT=18789
OPENCLAW_GATEWAY_TOKEN=dev-token-12345

# 开发模式特殊配置
NODE_ENV=development
DEBUG=*
LOG_LEVEL=debug

# 模型配置（使用本地 Ollama）
OLLAMA_HOST=http://host.docker.internal:11434
DEFAULT_MODEL=ollama/qwen2.5:7b-instruct

# 飞书配置（如果需要测试）
FEISHU_APP_ID=cli_xxxxxxxxxxxxxxxx
FEISHU_APP_SECRET=your-app-secret-here
FEISHU_CONNECTION_MODE=http

# 禁用生产环境特性
DISABLE_TELEMETRY=true
SKIP_ONBOARDING_CHECKS=true
```

**创建命令**：

```powershell
@'
# OpenClaw 开发环境变量

# Gateway 配置
OPENCLAW_GATEWAY_MODE=local
OPENCLAW_GATEWAY_BIND=loopback
OPENCLAW_GATEWAY_PORT=18789
OPENCLAW_GATEWAY_TOKEN=dev-token-12345

# 开发模式特殊配置
NODE_ENV=development
DEBUG=*
LOG_LEVEL=debug

# 模型配置（使用本地 Ollama）
OLLAMA_HOST=http://host.docker.internal:11434
DEFAULT_MODEL=ollama/qwen2.5:7b-instruct

# 飞书配置（如果需要测试）
FEISHU_APP_ID=cli_xxxxxxxxxxxxxxxx
FEISHU_APP_SECRET=your-app-secret-here
FEISHU_CONNECTION_MODE=http

# 禁用生产环境特性
DISABLE_TELEMETRY=true
SKIP_ONBOARDING_CHECKS=true
'@ | Set-Content -Path ".env.dev" -Encoding UTF8

Write-Host "✓ 已创建 .env.dev 文件" -ForegroundColor Green
```

---

### 2.2 创建 Dockerfile.dev 开发镜像

在 `E:\AI\openclaw_docker\openclaw\Dockerfile.dev` 创建：

```dockerfile
# OpenClaw 开发环境 Dockerfile
# 支持热重载和源代码开发

FROM node:22-alpine AS base

# 安装开发工具
RUN apk add --no-cache \
    git \
    python3 \
    py3-pip \
    build-base \
    libc6-compat \
    && rm -rf /var/cache/apk/*

# 设置工作目录
WORKDIR /app

# 复制 package.json 和 pnpm-lock.yaml
COPY package.json pnpm-lock.yaml ./

# 安装依赖（包括 devDependencies）
RUN npm install -g pnpm && \
    pnpm install --frozen-lockfile

# 复制全部源代码（用于初始构建）
COPY . .

# 构建 TypeScript（开发模式，包含 source maps）
RUN pnpm build

# 开发阶段：挂载源代码卷
FROM base AS development

# 安装 nodemon 用于热重载
RUN npm install -g nodemon

# 创建工作目录
WORKDIR /app

# 挂载源代码卷（热重载关键）
VOLUME ["/app/src", "/app/extensions", "/app/ui"]

# 暴露端口
EXPOSE 18789 18790 18791

# 启动开发服务器（热重载）
CMD ["pnpm", "dev"]

# 生产构建阶段（可选）
FROM base AS production

# 只复制构建产物
COPY --from=base /app/dist ./dist
COPY --from=base /app/node_modules ./node_modules
COPY --from=base /app/package.json ./

# 使用 node 用户运行（安全）
USER node

# 暴露端口
EXPOSE 18789

# 启动生产服务器
CMD ["node", "dist/index.js"]
```

**创建命令**：

```powershell
@'
# OpenClaw 开发环境 Dockerfile
# 支持热重载和源代码开发

FROM node:22-alpine AS base

# 安装开发工具
RUN apk add --no-cache \
    git \
    python3 \
    py3-pip \
    build-base \
    libc6-compat \
    && rm -rf /var/cache/apk/*

# 设置工作目录
WORKDIR /app

# 复制 package.json 和 pnpm-lock.yaml
COPY package.json pnpm-lock.yaml ./

# 安装依赖（包括 devDependencies）
RUN npm install -g pnpm && \
    pnpm install --frozen-lockfile

# 复制全部源代码（用于初始构建）
COPY . .

# 构建 TypeScript（开发模式，包含 source maps）
RUN pnpm build

# 开发阶段：挂载源代码卷
FROM base AS development

# 安装 nodemon 用于热重载
RUN npm install -g nodemon

# 创建工作目录
WORKDIR /app

# 挂载源代码卷（热重载关键）
VOLUME ["/app/src", "/app/extensions", "/app/ui"]

# 暴露端口
EXPOSE 18789 18790 18791

# 启动开发服务器（热重载）
CMD ["pnpm", "dev"]

# 生产构建阶段（可选）
FROM base AS production

# 只复制构建产物
COPY --from=base /app/dist ./dist
COPY --from=base /app/node_modules ./node_modules
COPY --from=base /app/package.json ./

# 使用 node 用户运行（安全）
USER node

# 暴露端口
EXPOSE 18789

# 启动生产服务器
CMD ["node", "dist/index.js"]
'@ | Set-Content -Path "Dockerfile.dev" -Encoding UTF8

Write-Host "✓ 已创建 Dockerfile.dev" -ForegroundColor Green
```

---

### 2.3 创建 docker-compose.dev.yml

在 `E:\AI\openclaw_docker\openclaw\docker-compose.dev.yml` 创建：

```yaml
version: '3.8'

services:
  # OpenClaw Gateway（开发模式）
  openclaw-gateway-dev:
    build:
      context: .
      dockerfile: Dockerfile.dev
      target: development  # 使用开发阶段
    container_name: openclaw-gateway-dev
    restart: unless-stopped
    
    # 开发模式：挂载源代码实现热重载
    volumes:
      # 源代码挂载（热重载核心）
      - ./src:/app/src:cached
      - ./extensions:/app/extensions:cached
      - ./ui:/app/ui:cached
      
      # 数据持久化
      - ../data/config:/home/node/.openclaw/config
      - ../data/home:/home/node/.openclaw
      - ../data/logs:/tmp/openclaw
      
      # Node modules 缓存（避免重复安装）
      - node_modules_dev:/app/node_modules
    
    # 环境变量
    env_file:
      - .env.dev
    
    # 端口映射
    ports:
      - "18789:18789"  # Gateway WebSocket
      - "18790:18790"  # 开发服务器
      - "18791:18791"  # Browser Control
    
    # 网络配置
    networks:
      - openclaw-dev-network
    
    # 健康检查
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:18789/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    
    # 开发模式资源限制（放宽限制）
    deploy:
      resources:
        limits:
          cpus: '4.0'  # 更多 CPU 用于编译
          memory: 4G
        reservations:
          cpus: '2.0'
          memory: 2G
    
    # 开发工具
    working_dir: /app
    tty: true
    stdin_open: true
    
    # 允许调试
    cap_add:
      - SYS_PTRACE

  # 可选：Ollama 本地模型服务（如果你有自己的 Ollama）
  ollama:
    image: ollama/ollama:latest
    container_name: ollama-dev
    profiles:
      - ollama  # 按需启动
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    networks:
      - openclaw-dev-network

# 网络配置
networks:
  openclaw-dev-network:
    driver: bridge

# 卷声明
volumes:
  node_modules_dev:  # 开发模式 node_modules 缓存
  ollama_data:       # Ollama 模型数据
```

**创建命令**：

```powershell
@'
version: '3.8'

services:
  # OpenClaw Gateway（开发模式）
  openclaw-gateway-dev:
    build:
      context: .
      dockerfile: Dockerfile.dev
      target: development  # 使用开发阶段
    container_name: openclaw-gateway-dev
    restart: unless-stopped
    
    # 开发模式：挂载源代码实现热重载
    volumes:
      # 源代码挂载（热重载核心）
      - ./src:/app/src:cached
      - ./extensions:/app/extensions:cached
      - ./ui:/app/ui:cached
      
      # 数据持久化
      - ../data/config:/home/node/.openclaw/config
      - ../data/home:/home/node/.openclaw
      - ../data/logs:/tmp/openclaw
      
      # Node modules 缓存（避免重复安装）
      - node_modules_dev:/app/node_modules
    
    # 环境变量
    env_file:
      - .env.dev
    
    # 端口映射
    ports:
      - "18789:18789"  # Gateway WebSocket
      - "18790:18790"  # 开发服务器
      - "18791:18791"  # Browser Control
    
    # 网络配置
    networks:
      - openclaw-dev-network
    
    # 健康检查
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:18789/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    
    # 开发模式资源限制（放宽限制）
    deploy:
      resources:
        limits:
          cpus: '4.0'  # 更多 CPU 用于编译
          memory: 4G
        reservations:
          cpus: '2.0'
          memory: 2G
    
    # 开发工具
    working_dir: /app
    tty: true
    stdin_open: true
    
    # 允许调试
    cap_add:
      - SYS_PTRACE

  # 可选：Ollama 本地模型服务（如果你有自己的 Ollama）
  ollama:
    image: ollama/ollama:latest
    container_name: ollama-dev
    profiles:
      - ollama  # 按需启动
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    networks:
      - openclaw-dev-network

# 网络配置
networks:
  openclaw-dev-network:
    driver: bridge

# 卷声明
volumes:
  node_modules_dev:  # 开发模式 node_modules 缓存
  ollama_data:       # Ollama 模型数据
'@ | Set-Content -Path "docker-compose.dev.yml" -Encoding UTF8

Write-Host "✓ 已创建 docker-compose.dev.yml" -ForegroundColor Green
```

---

## Step 3: 配置 Docker 热重载

### 3.1 创建数据目录并设置权限

```powershell
# 创建持久化数据目录
$dataDirs = @(
    'E:\AI\openclaw_docker\data\config',
    'E:\AI\openclaw_docker\data\home\extensions',
    'E:\AI\openclaw_docker\data\home\skills',
    'E:\AI\openclaw_docker\data\home\workspace',
    'E:\AI\openclaw_docker\data\home\agents',
    'E:\AI\openclaw_docker\data\logs'
)

foreach($dir in $dataDirs){
    if(-not (Test-Path $dir)){
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "✓ 创建目录：$dir" -ForegroundColor Green
    }
}

# 设置 NTFS 权限（Docker 需要）
$aclPath = "E:\AI\openclaw_docker\data"
$acl = Get-Acl $aclPath
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.AddAccessRule($rule)
Set-Acl $aclPath $acl

Write-Host "✓ 已设置 NTFS 权限" -ForegroundColor Green
```

### 3.2 初始化配置文件

```powershell
# 创建基础 openclaw.json 配置
$config = @{
    gateway = @{
        mode = "local"
        bind = "loopback"
        port = 18789
        token = "dev-token-12345"
    }
    channels = @{}
    plugins = @{
        feishu = @{
            enabled = $false  # 开发阶段可先禁用
        }
    }
    agents = @{
        defaults = @{
            model = "ollama/qwen2.5:7b-instruct"
            memorySearch = @{
                enabled = $false
            }
        }
    }
} | ConvertTo-Json -Depth 100

$config | Set-Content "E:\AI\openclaw_docker\data\config\openclaw.json" -Encoding UTF8

Write-Host "✓ 已创建基础配置文件" -ForegroundColor Green
```

---

## Step 4: 启动开发环境

### 4.1 构建开发镜像

```powershell
cd E:\AI\openclaw_docker\openclaw

# 停止任何运行中的容器
docker compose -f docker-compose.dev.yml down

# 构建开发镜像（首次需要几分钟）
docker compose -f docker-compose.dev.yml build

Write-Host "✓ 开发镜像构建完成" -ForegroundColor Green
```

### 4.2 启动开发服务器

```powershell
# 启动所有服务（后台运行）
docker compose -f docker-compose.dev.yml up -d

# 等待启动完成
Start-Sleep -Seconds 15

# 检查容器状态
docker compose ps
```

预期输出：
```
NAME                        STATUS         HEALTH
openclaw-gateway-dev        Up (healthy)   
```

### 4.3 查看实时日志

```powershell
# 监控开发日志
docker compose logs -f openclaw-gateway-dev
```

你应该看到：
```
✓ Development server running
✓ Hot reload enabled
✓ Watching for file changes...
```

---

## Step 5: 验证热重载功能

### 5.1 测试代码修改

1. **打开一个源文件**（例如 `src/gateway.ts`）
2. **添加一行日志**：
   ```typescript
   console.log('[DEV TEST] Hot reload is working!');
   ```
3. **保存文件**

### 5.2 观察自动重启

```powershell
# 在另一个终端查看日志
docker compose logs -f openclaw-gateway-dev | Select-String "restarting|changed"
```

你应该看到：
```
[gateway] File changed: src/gateway.ts
[gateway] Restarting due to file changes...
[gateway] Development server restarted
```

### 5.3 验证功能

```powershell
# 测试 Gateway 是否正常工作
curl http://localhost:18789/healthz

# 如果返回 OK，说明热重载成功！
```

---

## Step 6: 开始功能开发

### 6.1 开发工作流

```mermaid
graph LR
    A[修改源代码] --> B[保存文件]
    B --> C[Docker 检测到变化]
    C --> D[自动重新编译]
    D --> E[重启开发服务器]
    E --> F[测试新功能]
    F --> A
```

### 6.2 常用开发命令

```powershell
# 进入容器进行交互式开发
docker compose exec openclaw-gateway-dev bash

# 在容器内运行测试
pnpm test

# 类型检查
pnpm tsgo

# 代码格式化
pnpm format

# 安装新依赖
pnpm add <package-name>
```

### 6.3 调试技巧

#### 使用 VS Code 远程调试

1. **安装扩展**: "Docker" + "Remote - Containers"
2. **附加到容器**:
   - F1 → "Dev Containers: Attach to Running Container"
   - 选择 `openclaw-gateway-dev`
3. **设置断点**: 在源代码中设置
4. **启动调试**: F5

#### 查看实时日志

```powershell
# 只看 Gateway 日志
docker compose logs -f openclaw-gateway-dev

# 只看错误日志
docker compose logs -f openclaw-gateway-dev | Select-String "error|Error"

# 导出日志到文件
docker compose logs openclaw-gateway-dev > dev-log.txt
```

---

## 常见问题 FAQ

### Q1: 热重载不工作怎么办？

**A**: 按顺序检查：

1. ✅ **确认文件挂载正确**：
   ```powershell
   docker inspect openclaw-gateway-dev | Select-String "Mounts" -Context 5,5
   ```

2. ✅ **检查 nodemon 是否运行**：
   ```powershell
   docker compose exec openclaw-gateway-dev ps aux | grep nodemon
   ```

3. ✅ **手动触发重启**：
   ```powershell
   docker compose restart openclaw-gateway-dev
   ```

---

### Q2: 修改代码后编译失败？

**A**: TypeScript 编译错误的处理：

1. **查看详细错误**：
   ```powershell
   docker compose logs openclaw-gateway-dev | Select-String "error TS" -Context 2,2
   ```

2. **清理并重建**：
   ```powershell
   docker compose exec openclaw-gateway-dev pnpm clean
   docker compose restart openclaw-gateway-dev
   ```

3. **检查类型定义**：
   ```powershell
   docker compose exec openclaw-gateway-dev pnpm tsgo
   ```

---

### Q3: Docker 容器无法启动？

**A**: 常见原因和解决方案：

**原因 1: 端口被占用**
```powershell
# 检查端口占用
netstat -ano | findstr :18789

# 停止占用端口的进程
Stop-Process -Id <PID> -Force
```

**原因 2: 权限问题**
```powershell
# 重新设置 NTFS 权限（见 Step 3.1）
```

**原因 3: 内存不足**
```powershell
# 增加 Docker Desktop 内存限制
# Docker Desktop → Settings → Resources → Memory → 调整为 4GB+
```

---

### Q4: 如何安装新的 npm 依赖？

**A**: 正确方式：

```powershell
# 方式 1: 在容器内安装（推荐）
docker compose exec openclaw-gateway-dev pnpm add <package-name>

# 方式 2: 在宿主机安装（需要同步）
pnpm add <package-name>
docker compose restart openclaw-gateway-dev
```

**注意**：不要直接在 `node_modules` 目录操作！

---

### Q5: 如何退出开发环境？

**A**: 

```powershell
# 停止所有服务
docker compose -f docker-compose.dev.yml down

# 停止并删除容器（保留数据）
docker compose -f docker-compose.dev.yml down

# 完全清理（删除卷）
docker compose -f docker-compose.dev.yml down -v
```

---

## 维护手册

### 日常开发检查

```powershell
# 1. 检查容器状态
docker compose ps

# 2. 查看最近日志
docker compose logs --tail 100 openclaw-gateway-dev

# 3. 检查健康状态
docker inspect openclaw-gateway-dev --format='{{.State.Health.Status}}'

# 4. 监控资源使用
docker stats openclaw-gateway-dev
```

### 清理构建缓存

```powershell
# 清理 Docker 构建缓存
docker builder prune -a -f

# 清理未使用的卷
docker volume prune -f

# 重新构建（干净状态）
docker compose -f docker-compose.dev.yml build --no-cache
```

### 更新依赖

```powershell
# 更新所有依赖
docker compose exec openclaw-gateway-dev pnpm update

# 更新特定依赖
docker compose exec openclaw-gateway-dev pnpm update <package-name>
```

### 备份开发环境

```powershell
# 备份配置文件
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
Copy-Item "E:\AI\openclaw_docker\data\config\openclaw.json" `
          "E:\AI\openclaw_docker\backups\config-backup-$timestamp.json"

# 导出当前镜像
docker save openclaw-gateway-dev -o "E:\AI\openclaw_docker\backups\dev-image-$timestamp.tar"

Write-Host "✓ 开发环境已备份" -ForegroundColor Green
```

---

## 附录：完整命令速查表

### 启动/停止

```powershell
# 启动开发环境
docker compose -f docker-compose.dev.yml up -d

# 停止开发环境
docker compose -f docker-compose.dev.yml down

# 重启单个服务
docker compose restart openclaw-gateway-dev

# 查看日志
docker compose logs -f openclaw-gateway-dev
```

### 进入容器

```powershell
# Bash shell
docker compose exec openclaw-gateway-dev bash

# 运行单条命令
docker compose exec openclaw-gateway-dev pnpm test
```

### 构建相关

```powershell
# 重新构建镜像
docker compose -f docker-compose.dev.yml build

# 无缓存构建
docker compose -f docker-compose.dev.yml build --no-cache

# 只构建不启动
docker compose -f docker-compose.dev.yml build --no-deps
```

---

## 下一步

✅ **开发环境已就绪！** 现在你可以：

1. 开始编写新功能代码
2. 实时测试修改效果
3. 使用完整的开发工具链
4. 随时回滚到稳定版本

**祝你开发顺利！** 🚀

---

**最后更新**: 2026-03-13  
**基于版本**: OpenClaw latest (Git HEAD)  
**维护者**: OpenClaw 开发团队  
**许可证**: MIT
