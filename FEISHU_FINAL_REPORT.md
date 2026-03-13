# OpenClaw 飞书问题最终诊断报告

## 📊 问题总结

### 当前状态
- ✅ Docker 容器正常运行 (healthy)
- ✅ 飞书插件代码完整加载
- ✅ 所有工具已注册 (feishu_chat, feishu_doc, etc.)
- ❌ API 认证失败 (code: 9499, status: 400)
- ❌ Bot info 超时 (bot open_id resolved: unknown)
- ❌ 配置模式错误 (websocket 而非 http)

### 根本原因
**App Secret 不正确或应用未发布**

证据链:
1. API 能访问飞书服务器 (不是网络问题)
2. 但返回 400 Bad Request (认证参数错误)
3. Bot info 无法获取 (应用权限问题)

## 🛠️ 解决方案

### 选项 A: 重置 App Secret (推荐) ⭐⭐⭐⭐⭐

**步骤**:
1. 登录飞书开发者后台
2. 找到你的应用 (cli_a92469612eb85cb2)
3. 凭证管理 → App Secret → 重置
4. 复制新的 App Secret
5. 更新配置并重启 Gateway

**优点**:
- ✅ 最快 (5 分钟)
- ✅ 最可靠 (全新密钥)
- ✅ 无需改动其他配置

### 选项 B: 检查应用配置

**需要确认**:
- [ ] 应用状态：已发布 (不是开发中)
- [ ] 机器人功能：已启用
- [ ] 权限配置：已申请并通过

### 选项 C: 切换到 HTTP 模式

**说明**:
WebSocket 模式需要公网回调地址，Docker 环境无法满足。
HTTP 模式下，OpenClaw 主动轮询飞书 API，更适合容器部署。

## 📝 执行计划

### Step 1: 获取正确的 App Secret
路径：https://open.feishu.cn/app → 你的应用 → 凭证管理

### Step 2: 更新配置
```powershell
# PowerShell 命令
$config = Get-Content "E:\AI\openclaw_docker\data\config\openclaw.json" -Raw | ConvertFrom-Json
$config.channels.feishu.appSecret = "<新的 App Secret>"
$config.channels.feishu.connectionMode = "http"
$config | ConvertTo-Json -Depth 100 | Set-Content "E:\AI\openclaw_docker\data\config\openclaw.json" -Encoding UTF8
```

### Step 3: 重启 Gateway
```powershell
docker compose restart openclaw-gateway
Start-Sleep -Seconds 15
```

### Step 4: 验证
```powershell
docker compose logs openclaw-gateway --tail 50 | Select-String "feishu"
```

预期输出:
- ✓ starting feishu[default] (mode: http)
- ✓ bot open_id resolved: ou_xxxxxx (具体 ID)
- ✓ 没有 failed to obtain token 错误

### Step 5: 测试
在飞书中给机器人发消息："你好"

## ⚠️ 重要提示

1. **不要重装插件** - 代码已经完整
2. **不要删除容器** - 容器运行正常
3. **只需修复认证** - App Secret 是关键

## 📞 下一步行动

请提供以下任一信息:

A. **新的 App Secret** (从开发者后台重置)
B. **应用配置截图** (确认已发布/已启用)
C. **继续诊断** (如果需要进一步帮助)

---

生成时间：2026-03-13T20:19:32+00:00
诊断结论：App Secret 认证失败
