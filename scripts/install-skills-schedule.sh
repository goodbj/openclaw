#!/bin/bash
# OpenClaw 高级开发技能批量安装脚本（Unix/Linux/Mac）
# 每 10 分钟自动安装一个高质量技能

SKILLS=("skill-vetter" "find-skills" "tavily-search" "code-analyzer" "test-generator")
INTERVAL_MINUTES=10
SKIP_COUNTDOWN=false
LOG_FILE="skills-install.log"

# 颜色定义
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

write_header() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${GREEN}  $1${NC}"
    echo -e "${CYAN}========================================${NC}\n"
}

install_skill() {
    local skill_name=$1
    local start_time=$(date +%s)
    
    echo -e "\n${CYAN}[$(date '+%H:%M:%S')] 开始安装：$skill_name${NC}"
    echo "========================================"
    
    # 步骤 1: 查找技能信息
    echo -e "\n${YELLOW}[1/5] 正在查找技能信息...${NC}"
    local skill_info=$(npx clawhub@latest search "$skill_name" --json 2>/dev/null || echo "")
    if [ -n "$skill_info" ]; then
        echo -e "  ${GREEN}✓${NC} 找到技能：$skill_name"
        # TODO: 解析 JSON 显示 stars 和下载量
    else
        echo -e "  ${YELLOW}⚠️  无法获取技能信息，继续安装...${NC}"
    fi
    
    # 步骤 2: 检查依赖
    echo -e "\n${YELLOW}[2/5] 检查依赖关系...${NC}"
    # TODO: 添加依赖检查
    
    # 步骤 3: 执行安装
    echo -e "\n${YELLOW}[3/5] 正在安装 $skill_name ...${NC}"
    if yes | npx clawhub@latest install "$skill_name" 2>&1; then
        echo -e "  ${GREEN}✓ 安装成功${NC}"
        local install_success=true
    else
        echo -e "  ${RED}✗ 安装失败或已存在${NC}"
        local install_success=false
    fi
    
    # 步骤 4: 验证安装
    echo -e "\n${YELLOW}[4/5] 验证安装...${NC}"
    if openclaw skills list 2>&1 | grep -q "$skill_name"; then
        echo -e "  ${GREEN}✓ 验证通过${NC}"
    else
        echo -e "  ${YELLOW}⚠️  验证失败，但可能已安装${NC}"
    fi
    
    # 步骤 5: 记录日志
    echo -e "\n${YELLOW}[5/5] 记录安装日志...${NC}"
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local status=$([ "$install_success" = true ] && echo "成功" || echo "失败")
    
    cat >> "$LOG_FILE" << EOF
[$(date '+%Y-%m-%d %H:%M:%S')] 安装：$skill_name
  状态：$status
  耗时：$duration 秒
---
EOF
    echo -e "  ${GREEN}✓ 日志已记录到 $LOG_FILE${NC}"
}

# 主程序
write_header "OpenClaw 高级开发技能批量安装计划"

echo -e "${YELLOW}📋 安装配置:${NC}"
echo "  技能数量：${#SKILLS[@]}"
echo "  时间间隔：$INTERVAL_MINUTES 分钟"
echo "  预计总耗时：$((${#SKILLS[@]} * $INTERVAL_MINUTES)) 分钟"
echo "  日志文件：$LOG_FILE"
echo ""

read -p "是否开始安装？(y/n): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "已取消安装"
    exit 0
fi

success_count=0
fail_count=0

for skill in "${SKILLS[@]}"; do
    install_skill "$skill"
    
    if [ $? -eq 0 ]; then
        ((success_count++))
    else
        ((fail_count++))
    fi
    
    # 如果不是最后一个技能，等待指定时间
    if [ "$skill" != "${SKILLS[-1]}" ]; then
        if [ "$SKIP_COUNTDOWN" = false ]; then
            wait_seconds=$((INTERVAL_MINUTES * 60))
            echo -e "\n${CYAN}⏱️  等待 $INTERVAL_MINUTES 分钟后安装下一个技能...${NC}"
            echo "   下次安装：$(date -d "+$INTERVAL_MINUTES minutes" '+%H:%M:%S')"
            
            # 倒计时显示
            for ((i=wait_seconds; i>0; i--)); do
                mins=$((i / 60))
                secs=$((i % 60))
                printf "\r   剩余：%02d:%02d" $mins $secs
                sleep 1
            done
            echo ""
        else
            echo -e "\n${CYAN}⏭️  跳过倒计时，直接安装下一个...${NC}"
            sleep 5
        fi
    fi
done

# 最终统计
write_header "安装完成！"
echo -e "${YELLOW}📊 安装统计:${NC}"
echo "  成功：$success_count / ${#SKILLS[@]}"
echo "  失败：$fail_count / ${#SKILLS[@]}"
echo "  成功率：$(awk "BEGIN {printf \"%.2f\", ($success_count/${#SKILLS[@]})*100}")%"
echo ""
echo "📝 详细日志请查看：$LOG_FILE"
echo ""
