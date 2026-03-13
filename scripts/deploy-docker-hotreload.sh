#!/usr/bin/env bash
set -euo pipefail

# OpenClaw Docker 热重载部署脚本
# 基于官方 docker-setup.sh 改进，支持源代码热重载

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

echo "=========================================="
echo "OpenClaw Docker 热重载部署"
echo "=========================================="
echo ""

# 检查依赖
if ! command -v docker &> /dev/null; then
    echo "错误：Docker 未安装"
    exit 1
fi

if ! docker compose version &> /dev/null; then
    echo "错误：Docker Compose 未安装"
    exit 1
fi

echo "✓ Docker 和 Docker Compose 已安装"
echo ""

# 设置默认值
export OPENCLAW_CONFIG_DIR="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw}"
export OPENCLAW_WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-$HOME/.openclaw/workspace}"
export OPENCLAW_GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"
export OPENCLAW_BRIDGE_PORT="${OPENCLAW_BRIDGE_PORT:-18790}"
export OPENCLAW_GATEWAY_BIND="${OPENCLAW_GATEWAY_BIND:-lan}"
export OPENCLAW_IMAGE="${OPENCLAW_IMAGE:-openclaw:local}"

# 热重载特定配置
# 挂载源代码目录以实现热重载
export OPENCLAW_EXTRA_MOUNTS="${OPENCLAW_EXTRA_MOUNTS:-./src:/app/src:cached,./extensions:/app/extensions:cached,./packages:/app/packages:cached,./ui:/app/ui:cached,./skills:/app/skills:cached}"

# 可选：持久化整个 /home/node
# export OPENCLAW_HOME_VOLUME="openclaw_home"

# 可选：安装额外的 apt 包
# export OPENCLAW_DOCKER_APT_PACKAGES="git curl vim"

# 可选：启用沙箱支持
# export OPENCLAW_INSTALL_DOCKER_CLI=1
# export OPENCLAW_SANDBOX=1

echo "配置："
echo "  - 配置目录：$OPENCLAW_CONFIG_DIR"
echo "  - 工作空间：$OPENCLAW_WORKSPACE_DIR"
echo "  - Gateway 端口：$OPENCLAW_GATEWAY_PORT"
echo "  - Gateway 绑定：$OPENCLAW_GATEWAY_BIND"
echo "  - 镜像：$OPENCLAW_IMAGE"
echo "  - 热重载挂载：$OPENCLAW_EXTRA_MOUNTS"
echo ""

# 创建配置目录
mkdir -p "$OPENCLAW_CONFIG_DIR"
mkdir -p "$OPENCLAW_CONFIG_DIR/identity"
mkdir -p "$OPENCLAW_CONFIG_DIR/agents/main/agent"
mkdir -p "$OPENCLAW_CONFIG_DIR/agents/main/sessions"
mkdir -p "$OPENCLAW_WORKSPACE_DIR"

# 生成或复用 Gateway Token
if [[ -z "${OPENCLAW_GATEWAY_TOKEN:-}" ]]; then
    EXISTING_CONFIG_TOKEN=""
    CONFIG_FILE="$OPENCLAW_CONFIG_DIR/openclaw.json"
    
    if [[ -f "$CONFIG_FILE" ]]; then
        # 从现有配置读取 token
        if command -v python3 &> /dev/null; then
            EXISTING_CONFIG_TOKEN=$(python3 -c "
import json
try:
    cfg = json.load(open('$CONFIG_FILE'))
    token = cfg.get('gateway', {}).get('auth', {}).get('token')
    if token: print(token)
except: pass
" 2>/dev/null || true)
        fi
    fi
    
    if [[ -n "$EXISTING_CONFIG_TOKEN" ]]; then
        OPENCLAW_GATEWAY_TOKEN="$EXISTING_CONFIG_TOKEN"
        echo "✓ 复用现有 Gateway Token"
    else
        # 生成新 token
        if command -v openssl &> /dev/null; then
            OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)
        else
            OPENCLAW_GATEWAY_TOKEN=$(python3 -c "import secrets; print(secrets.token_hex(32))")
        fi
        echo "✓ 生成新的 Gateway Token"
    fi
else
    echo "✓ 使用提供的 Gateway Token"
fi

export OPENCLAW_GATEWAY_TOKEN

# 写入 .env 文件
ENV_FILE="$ROOT_DIR/.env.hotreload"
cat > "$ENV_FILE" <<EOF
# OpenClaw 热重载开发环境配置
# 由 deploy-docker-hotreload.sh 自动生成

OPENCLAW_CONFIG_DIR=$OPENCLAW_CONFIG_DIR
OPENCLAW_WORKSPACE_DIR=$OPENCLAW_WORKSPACE_DIR
OPENCLAW_GATEWAY_PORT=$OPENCLAW_GATEWAY_PORT
OPENCLAW_BRIDGE_PORT=$OPENCLAW_BRIDGE_PORT
OPENCLAW_GATEWAY_BIND=$OPENCLAW_GATEWAY_BIND
OPENCLAW_GATEWAY_TOKEN=$OPENCLAW_GATEWAY_TOKEN
OPENCLAW_IMAGE=$OPENCLAW_IMAGE
OPENCLAW_EXTRA_MOUNTS=$OPENCLAW_EXTRA_MOUNTS
EOF

echo "✓ 配置文件已写入：$ENV_FILE"
echo ""

# 构建镜像
echo "=========================================="
echo "构建 OpenClaw 镜像"
echo "=========================================="
echo ""

docker build \
    --build-arg "OPENCLAW_DOCKER_APT_PACKAGES=${OPENCLAW_DOCKER_APT_PACKAGES:-}" \
    --build-arg "OPENCLAW_EXTENSIONS=${OPENCLAW_EXTENSIONS:-}" \
    --build-arg "OPENCLAW_INSTALL_DOCKER_CLI=${OPENCLAW_INSTALL_DOCKER_CLI:-}" \
    -t "$OPENCLAW_IMAGE" \
    -f "$ROOT_DIR/Dockerfile" \
    "$ROOT_DIR"

echo "✓ 镜像构建完成：$OPENCLAW_IMAGE"
echo ""

# 停止旧容器
echo "正在停止现有容器..."
docker compose -f "$ENV_FILE" -f docker-compose.yml down --remove-orphans 2>/dev/null || true
echo "✓ 容器已停止"
echo ""

# 修复权限（Linux）
if [[ "$(uname -s)" == "Linux" ]]; then
    echo "正在修复数据目录权限..."
    sudo chown -R 1000:1000 "$OPENCLAW_CONFIG_DIR" "$OPENCLAW_WORKSPACE_DIR" 2>/dev/null || true
    echo "✓ 权限已修复"
    echo ""
fi

# 运行新手引导（如果配置不存在）
CONFIG_FILE="$OPENCLAW_CONFIG_DIR/openclaw.json"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "=========================================="
    echo "运行新手引导"
    echo "=========================================="
    echo ""
    
    docker compose -f "$ENV_FILE" -f docker-compose.yml run --rm openclaw-cli onboard --mode local --no-install-daemon
    
    echo "✓ 新手引导完成"
    echo ""
fi

# 启动服务
echo "=========================================="
echo "启动 OpenClaw Gateway"
echo "=========================================="
echo ""

docker compose -f "$ENV_FILE" -f docker-compose.yml up -d openclaw-gateway

echo ""
echo "等待服务启动..."
sleep 10

# 健康检查
echo ""
echo "=========================================="
echo "服务状态"
echo "=========================================="
echo ""

docker compose -f "$ENV_FILE" -f docker-compose.yml ps

echo ""
echo "=========================================="
echo "部署完成！"
echo "=========================================="
echo ""
echo "访问信息："
echo "  - Gateway API: http://localhost:${OPENCLAW_GATEWAY_PORT}"
echo "  - Control UI: http://localhost:${OPENCLAW_GATEWAY_PORT}/control-ui"
echo "  - Gateway Token: ${OPENCLAW_GATEWAY_TOKEN}"
echo ""
echo "管理命令："
echo "  - 查看日志：docker compose logs -f openclaw-gateway"
echo "  - 重启服务：docker compose restart openclaw-gateway"
echo "  - 停止服务：docker compose down"
echo "  - 进入 CLI:  docker compose exec openclaw-cli node dist/index.js"
echo ""
echo "热重载说明："
echo "  - 源代码修改后，重启容器以应用更改"
echo "  - 命令：docker compose restart openclaw-gateway"
echo ""
echo "数据存储："
echo "  - 配置：$OPENCLAW_CONFIG_DIR"
echo "  - 工作空间：$OPENCLAW_WORKSPACE_DIR"
echo ""
