# 🌐 Feishu DNS 问题修复指南

## 🔍 **问题诊断**

### **症状**
```
AxiosError: getaddrinfo EAI_AGAIN open.feishu.cn
curl: (6) Could not resolve host: open.feishu.cn
```

### **根本原因**
Docker 容器无法解析飞书 API 域名 `open.feishu.cn`

---

## ✅ **解决方案（3 种方法）**

### **方案 A: 重启 Docker DNS（推荐）** ⭐⭐⭐

**步骤**:

```powershell
# 1. 重启 Docker Desktop（Windows）
# 右键点击系统托盘的 Docker 图标 → Restart Docker

# 2. 或者重启 Docker 服务（管理员 PowerShell）
Restart-Service Docker

# 3. 然后重启 OpenClaw 容器
docker compose restart openclaw-gateway
```

---

### **方案 B: 配置容器 DNS** ⭐⭐⭐

**修改 docker-compose.prod.yml**:

在 `openclaw-gateway` 服务中添加 DNS 配置：

```yaml
services:
  openclaw-gateway:
    dns:
      - 8.8.8.8
      - 1.1.1.1
      - 223.5.5.5  # 阿里云 DNS（中国用户推荐）
```

**然后重启**:

```powershell
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d
```

---

### **方案 C: 使用 Host 网络模式** ⭐⭐

**修改 docker-compose.prod.yml**:

```yaml
services:
  openclaw-gateway:
    network_mode: "host"
```

**注意**: 
- ✅ 优点：直接使用主机网络，无 DNS 问题
- ⚠️ 缺点：端口冲突风险，安全性略低

---

## 🧪 **验证网络连接**

**修复后执行这些命令验证**:

```bash
# 进入容器
docker compose exec openclaw-gateway bash

# 测试 DNS 解析
nslookup open.feishu.cn

# 或使用 curl 测试
curl -I https://open.feishu.cn

# 测试飞书 API
curl -X GET "https://open.feishu.cn/open-apis/bot/v3/info" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**预期输出**:

```bash
# nslookup 应该返回 IP 地址
Server:         8.8.8.8
Address:        8.8.8.8#53

Non-authoritative answer:
Name:   open.feishu.cn
Address: 180.163.200.113
```

---

## 📋 **完整修复流程**

### **Step 1: 选择并应用一个方案**

**推荐方案 A**（最简单）:
```powershell
# 重启 Docker Desktop
# 然后重启容器
docker compose restart openclaw-gateway
```

---

### **Step 2: 验证网络已通**

```bash
docker compose exec openclaw-gateway sh -c "
echo '=== 测试 DNS 解析 ===' &&
curl -I https://open.feishu.cn 2>&1 | head -3 &&
echo '' &&
echo '=== 如果看到 HTTP 响应，说明网络正常！==='
"
```

**成功标志**:
```
HTTP/2 200 
content-type: application/json
...
```

---

### **Step 3: 测试 Feishu 功能**

**在飞书中给机器人发消息**:
```
你好
```

**查看日志确认收到消息**:
```powershell
docker compose logs -f openclaw-gateway | Select-String "feishu"
```

**预期日志**:
```
[feishu] Incoming message: {"text":"你好",...}
```

---

## 🐛 **如果仍然失败**

### **排查步骤**

#### 1. 检查主机网络

```powershell
# 在 Windows 主机上测试
ping open.feishu.cn
curl -I https://open.feishu.cn
```

如果主机也无法访问，可能是：
- 防火墙阻止
- 网络代理问题
- 地区限制

---

#### 2. 检查防火墙设置

**Windows 防火墙**:
```powershell
# 查看防火墙规则
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*Docker*"}

# 确保 Docker 允许出站连接
```

---

#### 3. 检查代理配置

如果你使用代理上网，需要在容器中配置代理：

**方法 A: 环境变量**

```yaml
# docker-compose.prod.yml
services:
  openclaw-gateway:
    environment:
      - HTTP_PROXY=http://your-proxy:port
      - HTTPS_PROXY=http://your-proxy:port
      - NO_PROXY=localhost,127.0.0.1
```

**方法 B: .env 文件**

```bash
# 在 .env.fixed 中添加
HTTP_PROXY=http://your-proxy:port
HTTPS_PROXY=http://your-proxy:port
```

---

## 💡 **临时解决方案**

如果 DNS 问题暂时无法解决，可以：

### **使用本地测试模式**

```bash
# 在容器中编辑配置
docker compose exec openclaw-gateway bash

# 修改 Feishu API 基础 URL（如果有自定义需求）
openclaw config set feishu.baseUrl https://open.feishu.cn
```

---

## 📊 **网络连通性测试清单**

完成修复后，按顺序测试：

- [ ] **Step 1**: `curl -I https://open.feishu.cn` 返回 HTTP 200
- [ ] **Step 2**: 在飞书中发消息，日志显示收到
- [ ] **Step 3**: 在 Control UI 中看到飞书消息
- [ ] **Step 4**: 可以给机器人发简单消息（如"你好"）
- [ ] **Step 5**: 可以发复杂请求（如"北京天气"）

---

## 🎯 **快速修复命令**

**复制这个一键修复命令**:

```powershell
# 重启 Docker 服务（需要管理员权限）
Restart-Service Docker

# 等待 10 秒
Start-Sleep -Seconds 10

# 重启 OpenClaw 容器
docker compose -f docker-compose.prod.yml restart openclaw-gateway

# 验证网络
docker compose exec openclaw-gateway sh -c "curl -I https://open.feishu.cn 2>&1 | head -3"

echo "修复完成！请在飞书中测试机器人。"
```

---

## 📞 **获取帮助**

如果以上方法都无效，请提供以下信息：

1. **主机网络测试结果**:
   ```powershell
   ping open.feishu.cn
   curl -I https://open.feishu.cn
   ```

2. **容器内测试结果**:
   ```bash
   docker compose exec openclaw-gateway sh -c "curl -I https://open.feishu.cn"
   ```

3. **Docker 版本**:
   ```powershell
   docker --version
   docker compose version
   ```

4. **操作系统和网络环境**:
   - Windows 版本
   - 是否使用代理
   - 公司网络还是家庭网络

---

**下一步**: 选择方案 A 或 B 进行修复，然后告诉我结果！🚀
