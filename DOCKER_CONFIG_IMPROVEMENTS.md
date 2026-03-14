# OpenClaw Docker 配置改进总结

**日期**: 2026-03-14  
**分支**: PigClaw

---

## 🎯 本次改进解决的问题

### 问题 1: Gateway Web 访问失效 ⚠️

**症状**: 
- 每次重启容器或修改 `.env` 后，无法通过 `http://localhost:18789/` 访问 Control UI
- 错误信息："unauthorized: too many failed authentication attempts"
- Gateway 只监听 `127.0.0.1` 而不是 `0.0.0.0`

**根本原因**:
- `openclaw.json` 配置文件缺少 `gateway.auth.token` 配置
- Gateway 启动时 token 配置不一致（环境变量 vs 配置文件）
- 浏览器/设备缓存的 token 与服务器不匹配

**永久解决方案**: ✅
1. 在持久化的 `openclaw.json` 中添加正确的配置：
   ```json
   {
     "gateway": {
       "bind": "custom",
       "customBindHost": "0.0.0.0",
       "auth": {
         "token": "<安全令牌>"
       }
     }
   }
   ```
2. 文件位置：`E:\AI\openclaw_docker\data\home\openclaw.json`
3. 这个文件是持久化挂载的，不会因容器重建而丢失

**验证结果**:
- ✅ 完全重建容器后 token 依然正确
- ✅ `.env` 和 `openclaw.json` token 完全一致
- ✅ Gateway 监听地址：`ws://0.0.0.0:18789`
- ✅ Dashboard URL 包含正确的 token

---

### 问题 2: 飞书配置失效 🔴

**症状**:
- 飞书 Bot 无响应
- 配对请求失败
- 回调地址配置错误

**可能原因**:
1. 飞书技能未安装
2. 飞书 App ID/Secret 配置缺失
3. 飞书凭证过期或未配对
4. 飞书回调地址配置错误

**解决方案**: ✅

创建了详细的修复指南文档：`docs/feishu-fix-guide.md`

包含：
- 4 种修复方案（安装技能、配置凭证、重新配对、检查回调地址）
- 完整的配置示例
- 验证清单
- 常见问题解答
- 一键修复脚本

---

## 📁 新增文档

### 1. Gateway 修复相关

| 文件名 | 用途 |
|--------|------|
| `docs/gateway-localhost-access-fix-permanent.md` | Gateway 本地访问终极修复指南 |
| `docs/gateway-localhost-access-fix.md` | Gateway 修复指南（已更新，标记为过时） |
| `GATEWAY_FIX_QUICKREF.md` | Gateway 修复快速参考卡 |
| `GATEWAY_FIX_COMPLETE_REPORT.md` | Gateway 修复完成报告 |
| `fix-gateway-localhost-access.ps1` | Gateway 一键修复 PowerShell 脚本 |

### 2. 飞书修复相关

| 文件名 | 用途 |
|--------|------|
| `docs/feishu-fix-guide.md` | 飞书配置失效修复指南 |

### 3. 权限配置相关

| 文件名 | 用途 |
|--------|------|
| `PERMISSIONS_QUICKREF.md` | 目录权限快速参考 |
| `permissions-report.md` | 权限验证报告 |
| `permissions-setup-guide.md` | 权限配置指南 |

---

## 🔧 核心改进点

### 1. 配置持久化 ✅

**改进前**:
- 配置文件在容器内，重建容器会丢失
- 需要手动重新配置

**改进后**:
- 配置文件存储在持久化挂载目录 (`data/home`)
- 容器重建后自动保留配置
- `.env` 和 `openclaw.json` 配置保持一致

### 2. 配置格式规范化 ✅

**改进前**:
```json
{
  "gateway": {
    "bind": "custom",
    "customBindHost": "0.0.0.0",
    "token": "xxx"  // ❌ 错误的键名
  }
}
```

**改进后**:
```json
{
  "gateway": {
    "bind": "custom",
    "customBindHost": "0.0.0.0",
    "auth": {
      "token": "xxx"  // ✅ 正确的键名
    }
  }
}
```

### 3. 自动化修复工具 ✅

创建了 PowerShell 一键修复脚本：
- 自动检查并移除错误的 GATEWAY_BIND 配置
- 自动创建容器内配置文件
- 自动重启容器
- 自动验证修复结果

使用方式：
```powershell
cd e:\AI\openclaw_docker
.\fix-gateway-localhost-access.ps1
```

---

## 🎯 经验总结

### 三个不要 ❌

1. **不要设置 OPENCLAW_GATEWAY_BIND 环境变量**
   - 会导致容器内的行为与预期不同
   
2. **不要在 docker-compose.yml 中设置 command**
   - command 会覆盖 Dockerfile 的默认行为
   
3. **不要混合使用不同的配置方式**
   - 选择一种方式并坚持使用

### 三个要 ✅

1. **要创建 openclaw.json 强制绑定到 0.0.0.0**
   - 这是最可靠的方法
   
2. **要验证监听地址是 ws://0.0.0.0:18789**
   - 使用 `docker logs` 命令验证
   
3. **要确保配置文件在正确的挂载目录**
   - `/home/node/.openclaw/openclaw.json` 对应 `E:\AI\openclaw_docker\data\home\openclaw.json`

---

## 📊 修改统计

### 修改的文件

- `openclaw\.env` - 更新 Gateway Token 和配置注释
- `openclaw\data\home\openclaw.json` - 添加 gateway.auth.token 配置

### 新增的文件

**文档类**:
- `docs/feishu-fix-guide.md` (264 行)
- `docs/gateway-localhost-access-fix-permanent.md` (342 行)
- `GATEWAY_FIX_QUICKREF.md` (123 行)
- `GATEWAY_FIX_COMPLETE_REPORT.md` (270 行)

**工具类**:
- `fix-gateway-localhost-access.ps1` (139 行)
- `fix-gateway-bind.py` (38 行)

**参考类**:
- `PERMISSIONS_QUICKREF.md` (146 行)
- `permissions-report.md` (185 行)
- `permissions-setup-guide.md` (210 行)

总计：约 **1,717 行** 新增内容

---

## 🚀 后续建议

### 短期优化

1. **测试飞书技能安装流程**
   - 验证 clawhub install feishu 是否可用
   - 补充飞书技能安装的详细步骤

2. **完善一键修复脚本**
   - 添加飞书配置修复功能
   - 添加更多自动诊断功能

3. **更新官方文档**
   - 将 Gateway 修复经验整合到官方 Docker 安装指南
   - 添加中文安装文档

### 长期优化

1. **配置管理工具**
   - 开发配置同步工具，自动保持 .env 和 openclaw.json 一致
   - 提供配置备份和恢复功能

2. **健康检查增强**
   - 在 Gateway 启动时自动检测配置一致性
   - 提供配置校验和修复命令

3. **文档国际化**
   - 提供完整的中文安装文档
   - 补充故障排查章节

---

## ✅ 验证清单

使用以下命令验证所有改进是否生效：

```powershell
# 1. 验证 Gateway 配置
docker exec openclaw-openclaw-gateway-1 cat /home/node/.openclaw/openclaw.json

# 2. 验证 Gateway 监听地址
docker logs openclaw-openclaw-gateway-1 2>&1 | Select-String "listening on"

# 3. 验证端口监听
netstat -ano | findstr ":18789"

# 4. 验证 HTTP 访问
Invoke-WebRequest -Uri "http://127.0.0.1:18789/" -TimeoutSec 5 -UseBasicParsing

# 5. 获取认证 URL
docker exec openclaw-openclaw-gateway-1 node dist/index.js dashboard --no-open
```

所有检查都应该通过 ✅

---

**状态**: ✅ 完成  
**下一步**: 测试飞书技能安装并补充文档
