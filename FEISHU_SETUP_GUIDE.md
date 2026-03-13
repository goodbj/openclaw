# 📘 Feishu（飞书）配置与使用指南

## ✅ **当前配置状态**

### **已验证的配置信息**

```json
{
  "feishu": {
    "enabled": true,
    "appId": "cli_a92469612eb85cb2",
    "appSecret": "exUwouagARetdnEvxbraChlkRz7YTcsT",
    "connectionMode": "websocket",
    "domain": "feishu",
    "groupPolicy": "open"
  }
}
```

**安装位置**: `/home/node/.openclaw/extensions/feishu/` ✅  
**版本**: `@openclaw/feishu@2026.3.12` ✅

---

## 🚀 **快速开始**

### **Step 1: 确认 Gateway 正在运行**

```bash
# 检查 Gateway 状态
docker compose ps

# 或者查看日志
docker compose logs openclaw-gateway | tail -20
```

**预期输出**:
```
[plugins] feishu_doc: Registered feishu_doc, feishu_app_scopes
[plugins] feishu_chat: Registered feishu_chat tool
[plugins] feishu_wiki: Registered feishu_wiki tool
[plugins] feishu_drive: Registered feishu_drive tool
[plugins] feishu_bitable: Registered bitable tools
```

---

### **Step 2: 查看通道状态**

```bash
# 进入容器
docker compose exec openclaw-gateway bash

# 查看所有通道
openclaw channels list

# 查看通道详细状态
openclaw channels status
```

**预期输出**:
```
Chat channels:
- Feishu default: configured, enabled

Auth providers (OAuth + API keys):
- ollama:default (api_key)
```

---

### **Step 3: 获取飞书聊天 ID**

#### **方法 A: 通过 Control UI 查看**

1. 打开浏览器访问：http://127.0.0.1:18789
2. 在飞书中给 OpenClaw 发送消息
3. 在 Control UI 中查看会话，会显示聊天 ID

---

#### **方法 B: 通过日志查看**

```bash
# 查看最近的飞书消息日志
docker compose logs openclaw-gateway | grep feishu | tail -20
```

查找类似这样的日志：
```
Incoming message from feishu: chat_id=oc_abc123...
```

---

#### **方法 C: 通过飞书开发者后台**

1. 登录 https://open.feishu.cn/
2. 进入应用管理 → 凭证与基础信息
3. 查看 Tenant Key 或使用 API 查询

---

### **Step 4: 测试发送消息**

```bash
# 替换 YOUR_CHAT_ID 为实际的聊天 ID
openclaw message send --target "YOUR_CHAT_ID" -m "你好，这是 OpenClaw 的测试消息！"
```

**示例**:
```bash
openclaw message send --target "oc_abc123xyz" -m "你好！"
```

---

## 🔧 **常用命令参考**

### **配置管理**

```bash
# 查看 Feishu 配置
openclaw config get feishu

# 修改 App ID
openclaw config set feishu.app_id cli_xxxxx

# 修改 App Secret
openclaw config set feishu.app_secret xxxxx

# 重新加载配置
openclaw config reload
```

---

### **通道管理**

```bash
# 列出所有通道
openclaw channels list

# 查看通道状态
openclaw channels status

# 重启通道
openclaw channels restart feishu

# 禁用通道
openclaw channels disable feishu

# 启用通道
openclaw channels enable feishu
```

---

### **技能管理**

```bash
# 查看已安装的 Feishu 相关技能
openclaw skills list | grep feishu

# 查看 Feishu 技能详情
openclaw skills show feishu-chat

# 重新加载技能
openclaw skills reload
```

---

## 🐛 **故障排查**

### **问题 1: Feishu 插件未加载**

**症状**:
```
[plugins] feishu_*: 没有看到注册日志
```

**解决方案**:
```bash
# 1. 检查扩展是否安装
ls -la /home/node/.openclaw/extensions/feishu/

# 2. 查看扩展日志
docker compose logs openclaw-gateway | grep feishu

# 3. 重启 Gateway
docker compose restart openclaw-gateway
```

---

### **问题 2: 无法接收消息**

**症状**:
- 飞书中发消息，OpenClaw 没反应

**排查步骤**:

```bash
# 1. 检查 WebSocket 连接
openclaw channels status

# 2. 查看实时日志
docker compose logs -f openclaw-gateway

# 3. 在飞书中重新 @OpenClaw 机器人

# 4. 检查飞书应用配置
# - 事件订阅是否启用
# - 接收 URL 是否正确
# - 权限是否足够
```

---

### **问题 3: 无法发送消息**

**症状**:
```
Error: Failed to send message to Feishu
```

**排查步骤**:

```bash
# 1. 验证聊天 ID 格式
# 应该是：oc_xxxxxxxxxx 或 user_openid

# 2. 检查网络连通性
curl -I https://open.feishu.cn

# 3. 验证 App Secret 是否正确
openclaw config get feishu.app_secret

# 4. 测试 API 调用
curl -X POST "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal/" \
  -H "Content-Type: application/json" \
  -d '{
    "app_id": "cli_a92469612eb85cb2",
    "app_secret": "exUwouagARetdnEvxbraChlkRz7YTcsT"
  }'
```

---

## 📊 **飞书应用配置清单**

### **在飞书开发者后台需要配置**

1. **应用类型**: 自建应用
2. **应用首页**: 可留空或填写 Dashboard URL
3. **权限管理**:
   - ✅ 获取用户 userID
   - ✅ 获取群组列表
   - ✅ 发送消息
   - ✅ 读取消息
   - ✅ 管理机器人

4. **事件订阅**:
   - ✅ 启用事件订阅
   - ✅ 接收消息事件：`im.message.receive_v1`
   - ✅ 接收 URL：Gateway 会自动处理

5. **机器人配置**:
   - ✅ 启用机器人
   - ✅ 支持单聊
   - ✅ 支持群聊

---

## 💡 **最佳实践**

### **1. 安全配置**

```bash
# 不要将 Secret 硬编码在脚本中
# 使用环境变量
export FEISHU_APP_SECRET="your-secret-here"
openclaw config set feishu.app_secret "$FEISHU_APP_SECRET"
```

---

### **2. 日志监控**

```bash
# 实时监控 Feishu 相关日志
docker compose logs -f openclaw-gateway | grep -E "(feishu|message)"

# 保存最近 1000 条日志用于分析
docker compose logs openclaw-gateway | tail -1000 > feishu-debug.log
```

---

### **3. 性能优化**

```bash
# 调整 Gateway 并发设置
openclaw config set gateway.maxConcurrentRequests 50

# 启用请求日志
openclaw config set logging.level debug
```

---

## 🎯 **实际使用示例**

### **示例 1: 在飞书中询问天气**

在飞书聊天中发送：
```
北京今天天气怎么样？
```

OpenClaw 会自动：
1. 识别需要天气信息
2. 调用 weather 技能
3. 返回天气预报

---

### **示例 2: 总结网页内容**

在飞书中发送：
```
请总结这篇文章：https://docs.openclaw.ai/start
```

OpenClaw 会：
1. 调用 summarize 技能
2. 抓取网页内容
3. 返回核心要点

---

### **示例 3: GitHub 集成**

在飞书中发送：
```
查看我的 GitHub issue
```

OpenClaw 会：
1. 调用 github 技能
2. 查询你的 issue
3. 返回结果列表

---

## 📞 **获取帮助**

### **遇到问题时**

1. **查看故障排查部分**（本文档上方）
2. **检查 Gateway 日志**: `docker compose logs openclaw-gateway`
3. **验证配置**: `openclaw config get feishu`
4. **查看官方文档**: https://docs.openclaw.ai/channels/feishu

---

## 🔗 **相关资源**

- [飞书开放平台](https://open.feishu.cn/)
- [OpenClaw 飞书通道文档](https://docs.openclaw.ai/channels/feishu)
- [Feishu Bot 开发指南](https://open.feishu.cn/document/ukTMukTMukTM/uYjNwYjLugDM14CM7ATN)
- [OpenClaw 通道配置](https://docs.openclaw.ai/gateway/configuration#channels)

---

## 📝 **配置备份**

### **导出配置**

```bash
# 备份配置文件
docker cp openclaw-gateway:/home/node/.openclaw/config/openclaw.json ./backup-openclaw-config.json
```

### **恢复配置**

```bash
# 还原配置文件
docker cp backup-openclaw-config.json openclaw-gateway:/home/node/.openclaw/config/openclaw.json

# 重启 Gateway
docker compose restart openclaw-gateway
```

---

**最后更新**: 2026-03-13  
**配置验证**: ✅ 已确认 Feishu 配置正确并生效

🎉 **恭喜！你的 Feishu 配置已完成，现在可以在飞书中使用 OpenClaw 了！**
