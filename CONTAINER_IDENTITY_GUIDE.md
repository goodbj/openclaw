# 🎯 OpenClaw 容器身份使用指南（重要！）

## ⚠️ **血的教训**

**问题根源**: 用 root 用户修改配置文件 → 权限错误 → 容器重启循环

---

## 👥 **两种用户身份**

### **1. node 用户（默认 ✅）**

**提示符**: `node@...:/app$` （蓝色或普通色）

**进入方式**:
```bash
docker compose exec openclaw-gateway bash
```

**适用场景** (90% 的情况):
- ✅ 日常使用 OpenClaw
- ✅ 测试技能
- ✅ 查看日志
- ✅ 配置管理
- ✅ 发送消息

**特点**:
- ✅ 安全
- ✅ 权限正确
- ✅ 不会破坏系统

---

### **2. root 用户（特殊 ⚠️）**

**提示符**: `root@...:/app#` （红色或警告色）

**进入方式**:
```bash
docker compose exec openclaw-gateway sh
```

**仅用于以下情况**:
- ⚠️ 修复文件权限 (`chown`)
- ⚠️ 安装系统包 (`apt-get`)
- ⚠️ 诊断网络问题
- ⚠️ 查看系统日志

**禁忌** (绝对不要做):
- ❌ 不要用 root 编辑配置文件
- ❌ 不要用 root 安装 npm 包
- ❌ 不要用 root 运行 Gateway
- ❌ 不要用 root 修改 `.openclaw` 目录

---

## 📋 **命令标注规范**

### **✅ 标准格式示例**

```bash
# 【身份：node | 进入方式：bash】
docker compose exec openclaw-gateway bash

# 然后执行
openclaw skills check
openclaw message send -m "你好"
```

```bash
# 【身份：root | 仅用于修复权限】
docker compose exec openclaw-gateway sh

# 然后执行
chown -R node:node /home/node/.openclaw
```

---

## 🎯 **决策树**

```
我要做什么？
    │
    ├─ 日常使用/测试/配置
    │   └─→ 用 node (bash) ✅
    │
    ├─ 修权限/装系统包
    │   └─→ 用 root (sh) ⚠️
    │       修完后记得改权限！
    │
    └─ 不确定
        └─→ 默认用 node (bash) ✅
```

---

## 💡 **最佳实践**

### **1. 优先在 Windows 上操作** ⭐⭐⭐⭐⭐

修改配置文件时：
```powershell
# ✅ 推荐：在 Windows 上用编辑器打开
code E:\AI\openclaw_docker\data\config\openclaw.json

# ✅ 或者删除重建（重置权限）
Remove-Item "E:\AI\openclaw_docker\data\config\openclaw.json" -Force
New-Item -ItemType File -Path "E:\AI\openclaw_docker\data\config\openclaw.json"
```

---

### **2. 必须在容器内时的操作** ⭐⭐⭐⭐

```bash
# ✅ 第一步：用 node 进入
docker compose exec openclaw-gateway bash

# ✅ 第二步：正常操作
openclaw config get feishu
openclaw skills check

# ⚠️ 如果必须用 root（比如修权限）
# 先退出
exit

# 然后用 root 进入
docker compose exec openclaw-gateway sh

# 修权限
chown -R node:node /home/node/.openclaw

# 退出
exit

# 再用 node 进入继续使用
docker compose exec openclaw-gateway bash
```

---

### **3. 遇到问题时的处理流程** ⭐⭐⭐⭐⭐

```
权限问题？
    │
    ├─ 方案 A: 在 Windows 上删除重建文件 ✅
    │   1. Remove-Item 文件
    │   2. New-Item 新建文件
    │   3. 恢复内容
    │
    ├─ 方案 B: 临时用 root 修复 ⚠️
    │   1. docker compose exec ... sh
    │   2. chown -R node:node ...
    │   3. exit
    │   4. docker compose restart
    │
    └─ 方案 C: 询问 AI 助手 🤖
        提供完整错误信息
```

---

## 🚨 **常见错误案例**

### **❌ 错误 1: 用 root 编辑配置**

```bash
# 错误做法
docker compose exec openclaw-gateway sh
root@...:/app# vi /home/node/.openclaw/config/openclaw.json
# 结果：文件所有者变成 root，node 无法读取 ❌
```

**正确做法**:
```bash
# 方案 A: 在 Windows 上编辑
code E:\AI\openclaw_docker\data\config\openclaw.json

# 方案 B: 用 node 编辑
docker compose exec openclaw-gateway bash
node@...:/app$ nano ~/.openclaw/config/openclaw.json
```

---

### **❌ 错误 2: 用 root 安装技能**

```bash
# 错误做法
docker compose exec openclaw-gateway sh
root@...:/app# npx clawhub@latest install skill-vetter
# 结果：技能安装在 root 目录，node 无法使用 ❌
```

**正确做法**:
```bash
# 始终用 node 安装
docker compose exec openclaw-gateway bash
node@...:/app$ npx clawhub@latest install skill-vetter
```

---

### **❌ 错误 3: 混淆 bash 和 sh**

```bash
# 错误做法
docker compose exec openclaw-gateway sh  # ← 这是 root！
# 然后期望是 node 用户 ❌
```

**正确理解**:
```bash
docker compose exec openclaw-gateway bash  # ← node 用户 ✅
docker compose exec openclaw-gateway sh    # ← root 用户 ⚠️
```

---

## 📝 **快速参考表**

| 你要做的事 | 用户身份 | 进入命令 | 注意事项 |
|-----------|---------|---------|---------|
| **日常使用** | **node** | `bash` | ✅ 最安全 |
| 测试技能 | **node** | `bash` | ✅ |
| 查看应用日志 | **node** | `bash` | ✅ |
| 配置 Feishu | **node** | `bash` | ✅ |
| | | | |
| **系统维护** | | | |
| 修复权限 | **root** | `sh` | ⚠️ 修完要改回来 |
| 装系统包 | **root** | `sh` | ⚠️ |
| 诊断网络 | **root** | `sh` | ⚠️ |
| | | | |
| **绝对禁止** | | | |
| root 改配置 | ❌ | - | 会权限错误 |
| root 装 npm 包 | ❌ | - | node 无法使用 |
| root 跑 Gateway | ❌ | - | 安全风险 |

---

## 🎯 **黄金法则**

### **三个永远记住**

1. ✅ **90% 时间用 node** - 默认就是安全的
2. ✅ **root 用完立即改权限** - `chown node:node`
3. ✅ **优先在 Windows 上操作** - 避免权限问题

---

### **一句话口诀**

> **"平时 bash 最安全，root 只在维修用，Windows 上改文件，权限永远不会乱！"**

---

## 🔖 **承诺书签名**

我，_______________（用户名），郑重承诺：

- [ ] 以后谨慎使用 root 权限
- [ ] 默认使用 `docker compose exec openclaw-gateway bash` 进入容器
- [ ] 只在必要时才用 root，并立即修复权限
- [ ] 优先在 Windows 宿主机上操作配置文件

**签署日期**: ___________

---

**最后更新**: 2026-03-13  
**版本**: v1.0  
**重要性**: ⭐⭐⭐⭐⭐（5 星最高）
