#!/bin/bash

####################################
# 脚本名称：Jetson设备克隆脚本
# 脚本用途：克隆源磁盘到目标磁盘
# 适用范围：Linux、Unix（MacOS）
# 脚本作者：Snowolf
# 创建日期：2024-10-30
# 更新日期：2025-03-30
####################################

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 获取当前操作系统类型
OS_TYPE=$(uname)

# 检查操作系统类型
function check_os_type() {
    echo -e "${GREEN}当前操作系统为: $OS_TYPE${NC}"
    if [[ "$OS_TYPE" != "Linux" && "$OS_TYPE" != "Darwin" ]]; then
        echo -e "${RED}错误: 不支持的操作系统: $OS_TYPE${NC}"
        exit 1
    fi
}

# 显示磁盘列表（根据操作系统类型）
function list_disks() {
    echo -e "\n${YELLOW}=== 可用磁盘列表 ===${NC}"
    if [[ "$OS_TYPE" == "Linux" ]]; then
        lsblk -d -n -e 1,2,7 | grep -v "SWAP" | awk '{print $1" "$4}'
    elif [[ "$OS_TYPE" == "Darwin" ]]; then
        diskutil list | grep -A 5 "/dev/disk"
    fi
    echo -e "${YELLOW}====================${NC}\n"
}

# 验证磁盘设备是否存在
function validate_device() {
    local DEVICE=$1
    if [[ "$OS_TYPE" == "Linux" ]]; then
        if [[ ! -b "$DEVICE" ]]; then
            echo -e "${RED}错误: 设备 $DEVICE 不存在或不是块设备${NC}"
            return 1
        fi
    elif [[ "$OS_TYPE" == "Darwin" ]]; then
        if ! diskutil info "$DEVICE" &>/dev/null; then
            echo -e "${RED}错误: 设备 $DEVICE 不存在${NC}"
            return 1
        fi
    fi
    return 0
}

# 获取磁盘容量（返回字节数）
function get_disk_size() {
    local DEVICE=$1
    local DISK_SIZE=0
    
    if [[ "$OS_TYPE" == "Linux" ]]; then
        DISK_SIZE=$(lsblk -b -n -o SIZE "$DEVICE" 2>/dev/null | tr -d '\n')
    elif [[ "$OS_TYPE" == "Darwin" ]]; then
        # 获取磁盘总字节数（更精确的方法）
        DISK_SIZE=$(diskutil info "$DEVICE" 2>/dev/null | awk '/Disk Size:/{print $3$4}' | tr -d '\n')
        if [[ "$DISK_SIZE" == *GB ]]; then
            DISK_SIZE=$(echo "${DISK_SIZE%GB} * 1000 * 1000 * 1000" | bc | cut -d. -f1)
        elif [[ "$DISK_SIZE" == *MB ]]; then
            DISK_SIZE=$(echo "${DISK_SIZE%MB} * 1000 * 1000" | bc | cut -d. -f1)
        elif [[ "$DISK_SIZE" == *KB ]]; then
            DISK_SIZE=$(echo "${DISK_SIZE%KB} * 1000" | bc | cut -d. -f1)
        fi
    fi
    
    # 确保返回纯数字
    echo "$DISK_SIZE" | tr -d -c '[:digit:]'
}

# 检查目标磁盘容量是否满足条件
function check_disk_capacity() {
    local SOURCE_DEVICE=$1
    local TARGET_DEVICE=$2
    
    local SOURCE_SIZE=$(get_disk_size "$SOURCE_DEVICE")
    local TARGET_SIZE=$(get_disk_size "$TARGET_DEVICE")
    
    if [[ -z "$SOURCE_SIZE" || -z "$TARGET_SIZE" ]]; then
        echo -e "${RED}错误: 无法获取磁盘大小${NC}"
        exit 1
    fi
    
    if [[ "$TARGET_SIZE" -lt "$SOURCE_SIZE" ]]; then
        echo -e "${RED}错误: 目标磁盘容量 ($(numfmt --to=iec $TARGET_SIZE)) 小于源磁盘容量 ($(numfmt --to=iec $SOURCE_SIZE))${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}容量检查通过: 目标磁盘 ($(numfmt --to=iec $TARGET_SIZE)) >= 源磁盘 ($(numfmt --to=iec $SOURCE_SIZE))${NC}"
}

# 提示用户选择磁盘设备
function get_device_address() {
    local PROMPT=$1
    local DEVICE_ADDRESS
    
    while true; do
        read -p "$PROMPT (例如 /dev/sdb 或 /dev/disk2): " DEVICE_ADDRESS
        if validate_device "$DEVICE_ADDRESS"; then
            break
        fi
    done
    
    echo "$DEVICE_ADDRESS"
}

# 克隆磁盘到目标磁盘
function clone_device() {
    local SOURCE_DEVICE=$1
    local TARGET_DEVICE=$2
    
    echo -e "\n${YELLOW}=== 克隆操作摘要 ===${NC}"
    echo -e "源磁盘: $SOURCE_DEVICE ($(numfmt --to=iec $(get_disk_size "$SOURCE_DEVICE")))"
    echo -e "目标磁盘: $TARGET_DEVICE ($(numfmt --to=iec $(get_disk_size "$TARGET_DEVICE")))"
    echo -e "${YELLOW}====================${NC}\n"
    
    echo -e "${RED}警告: 这将完全覆盖目标磁盘 ${TARGET_DEVICE} 上的所有数据!${NC}"
    read -p "确认要继续吗? (输入大写YES确认): " CONFIRM
    if [[ "$CONFIRM" != "YES" ]]; then
        echo -e "${GREEN}操作已取消。${NC}"
        exit 0
    fi
    
    echo -e "\n${GREEN}开始克隆 ${SOURCE_DEVICE} 到 ${TARGET_DEVICE}...${NC}"
    
    # 计算预计时间（仅供参考）
    local SOURCE_SIZE=$(get_disk_size "$SOURCE_DEVICE")
    local ESTIMATED_TIME=$((SOURCE_SIZE / (50 * 1024 * 1024))) # 假设50MB/s的速度
    
    echo -e "预计需要约 ${ESTIMATED_TIME} 秒 (基于50MB/s的传输速度)"
    echo -e "开始时间: $(date)"
    
    # 执行克隆
    if [[ "$OS_TYPE" == "Linux" ]]; then
        sudo dd if="$SOURCE_DEVICE" of="$TARGET_DEVICE" bs=4M status=progress
    elif [[ "$OS_TYPE" == "Darwin" ]]; then
        sudo dd if="$SOURCE_DEVICE" of="$TARGET_DEVICE" bs=4m
    fi
    
    # 同步磁盘缓存
    sync
    
    echo -e "\n${GREEN}克隆完成! 结束时间: $(date)${NC}"
}

# 主函数
function main() {
    check_os_type
    
    # 显示磁盘列表
    list_disks
    
    # 获取源磁盘和目标磁盘
    local SOURCE_DEVICE=$(get_device_address "请输入源磁盘设备地址")
    local TARGET_DEVICE=$(get_device_address "请输入目标磁盘设备地址")
    
    # 检查是否是同一个设备
    if [[ "$SOURCE_DEVICE" == "$TARGET_DEVICE" ]]; then
        echo -e "${RED}错误: 源磁盘和目标磁盘不能是同一个设备${NC}"
        exit 1
    fi
    
    # 检查磁盘容量
    check_disk_capacity "$SOURCE_DEVICE" "$TARGET_DEVICE"
    
    # 执行克隆
    clone_device "$SOURCE_DEVICE" "$TARGET_DEVICE"
}

# 调用主函数
main
