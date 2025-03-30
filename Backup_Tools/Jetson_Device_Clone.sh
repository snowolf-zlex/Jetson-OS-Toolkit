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
NC='\033[0m'

# 获取当前操作系统类型
OS_TYPE=$(uname)

# 检查必要命令
function check_requirements() {
    if [[ "$OS_TYPE" == "Linux" && ! -x "$(command -v blockdev)" ]]; then
        echo -e "${YELLOW}警告: 建议安装 util-linux 包以获得更准确的磁盘大小检测${NC}"
    fi
}

# 获取磁盘容量（返回字节数）
function get_disk_size() {
    local DEVICE=$1
    local DISK_SIZE=0
    
    if [[ "$OS_TYPE" == "Linux" ]]; then
        DISK_SIZE=$(blockdev --getsize64 "$DEVICE" 2>/dev/null || 
                   lsblk -b -n -o SIZE "$DEVICE" 2>/dev/null | head -1)
    elif [[ "$OS_TYPE" == "Darwin" ]]; then
        DISK_SIZE=$(diskutil info "$DEVICE" 2>/dev/null | 
                   awk '/Disk Size:|Total Size:/{print $3$4}')
        if [[ "$DISK_SIZE" == *GB ]]; then
            DISK_SIZE=$(echo "${DISK_SIZE%GB} * 1000 * 1000 * 1000" | bc)
        elif [[ "$DISK_SIZE" == *MB ]]; then
            DISK_SIZE=$(echo "${DISK_SIZE%MB} * 1000 * 1000" | bc)
        elif [[ "$DISK_SIZE" == *KB ]]; then
            DISK_SIZE=$(echo "${DISK_SIZE%KB} * 1000" | bc)
        fi
    fi
    
    echo "$DISK_SIZE" | tr -d -c '[:digit:]'
}

# 可读容量显示
function format_size() {
    local SIZE=$1
    if [[ "$SIZE" -gt 0 ]]; then
        if command -v numfmt >/dev/null; then
            numfmt --to=iec "$SIZE"
        else
            echo "$((SIZE/1024/1024)) MB"
        fi
    else
        echo "未知大小"
    fi
}

# 显示磁盘列表
function list_disks() {
    echo -e "\n${YELLOW}=== 可用磁盘列表 ===${NC}"
    if [[ "$OS_TYPE" == "Linux" ]]; then
        lsblk -d -n -e 1,2,7 | grep -v "SWAP" | awk '{printf "%s %s\n", $1, $4}'
    elif [[ "$OS_TYPE" == "Darwin" ]]; then
        diskutil list | grep -A 5 "/dev/disk"
    fi
    echo -e "${YELLOW}====================${NC}\n"
}

# 验证磁盘设备
function validate_device() {
    local DEVICE=$1
    if [[ "$OS_TYPE" == "Linux" ]]; then
        [[ -b "$DEVICE" ]] && return 0
    elif [[ "$OS_TYPE" == "Darwin" ]]; then
        diskutil info "$DEVICE" &>/dev/null && return 0
    fi
    echo -e "${RED}错误: 设备 $DEVICE 不存在${NC}"
    return 1
}

# 主函数
function main() {
    check_requirements
    list_disks
    
    # 获取源磁盘
    while true; do
        read -p "请输入源磁盘设备地址(/dev/sda): " SOURCE_DEVICE
        validate_device "$SOURCE_DEVICE" && break
    done
    
    # 获取目标磁盘
    while true; do
        read -p "请输入目标磁盘设备地址(/dev/nvme0n1): " TARGET_DEVICE
        [[ "$TARGET_DEVICE" != "$SOURCE_DEVICE" ]] && validate_device "$TARGET_DEVICE" && break
        echo -e "${RED}错误: 目标磁盘不能与源磁盘相同${NC}"
    done
    
    # 检查容量
    SOURCE_SIZE=$(get_disk_size "$SOURCE_DEVICE")
    TARGET_SIZE=$(get_disk_size "$TARGET_DEVICE")
    
    echo -e "\n${YELLOW}=== 操作确认 ===${NC}"
    echo -e "源磁盘: $SOURCE_DEVICE ($(format_size "$SOURCE_SIZE"))"
    echo -e "目标磁盘: $TARGET_DEVICE ($(format_size "$TARGET_SIZE"))"
    
    if [[ "$TARGET_SIZE" -lt "$SOURCE_SIZE" ]]; then
        echo -e "${RED}错误: 目标磁盘空间不足${NC}"
        exit 1
    fi
    
    read -p "确认要开始克隆吗? (输入大写YES确认): " CONFIRM
    [[ "$CONFIRM" != "YES" ]] && exit 0
    
    echo -e "\n${GREEN}开始克隆...${NC}"
    if [[ "$OS_TYPE" == "Linux" ]]; then
        sudo dd if="$SOURCE_DEVICE" of="$TARGET_DEVICE" bs=4M status=progress
    else
        sudo dd if="$SOURCE_DEVICE" of="$TARGET_DEVICE" bs=4m
    fi
    sync
    
    echo -e "\n${GREEN}克隆完成!${NC}"
}

main
