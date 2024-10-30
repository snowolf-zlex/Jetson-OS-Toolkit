#!/bin/bash

####################################
# 脚本名称：Jetson设备克隆脚本
# 脚本用途：克隆源磁盘到目标磁盘
# 适用范围：Linux、Unix（MacOS）
# 脚本作者：Snowolf
# 创建日期：2024-10-30
####################################

# 获取当前操作系统类型
OS_TYPE=$(uname)

# 检查操作系统类型
function check_os_type() {
    echo "当前操作系统为: $OS_TYPE"
    if [[ "$OS_TYPE" != "Linux" && "$OS_TYPE" != "Darwin" ]]; then
        echo "不支持的操作系统: $OS_TYPE"
        exit 1
    fi
}

# 显示磁盘列表（根据操作系统类型）
function list_disks() {
    if [[ "$OS_TYPE" == "Linux" ]]; then
        echo "以下是当前磁盘列表："
        lsblk -d
    elif [[ "$OS_TYPE" == "Darwin" ]]; then
        echo "以下是当前磁盘列表："
        diskutil list
    fi
}

# 提示用户选择源磁盘设备
function get_source_device_address() {
    read -p "请输入源磁盘设备地址 (例如 /dev/sdb 或 /dev/disk2): " DEVICE_ADDRESS
    echo "$DEVICE_ADDRESS"
}

# 提示用户选择目标磁盘设备（用于克隆）
function get_target_device_address() {
    read -p "请输入目标磁盘设备地址 (例如 /dev/sdc 或 /dev/disk3): " TARGET_DEVICE_ADDRESS
    echo "$TARGET_DEVICE_ADDRESS"
}

# 获取磁盘容量
function get_disk_size() {
    local DEVICE=$1
    if [[ "$OS_TYPE" == "Linux" ]]; then
        DISK_SIZE=$(lsblk -b -n -o SIZE "$DEVICE")
    elif [[ "$OS_TYPE" == "Darwin" ]]; then
        DISK_SIZE=$(diskutil info "$DEVICE" | grep "Disk Size" | awk '{print $3}')
        # 转换到字节
        DISK_SIZE=$(($DISK_SIZE * 1024 * 1024))
    fi
    echo "$DISK_SIZE"
}

# 检查目标磁盘容量是否满足条件
function check_disk_capacity() {
    local SOURCE_DEVICE=$1
    local TARGET_DEVICE=$2
    local SOURCE_SIZE=$(get_disk_size "$SOURCE_DEVICE")
    local TARGET_SIZE=$(get_disk_size "$TARGET_DEVICE")

    if [[ "$TARGET_SIZE" -lt "$SOURCE_SIZE" ]]; then
        echo "错误: 目标磁盘容量 (${TARGET_SIZE} 字节) 小于源磁盘容量 (${SOURCE_SIZE} 字节)。"
        exit 1
    fi
}

# 克隆磁盘到目标磁盘
function clone_device() {
    local SOURCE_DEVICE=$1
    local TARGET_DEVICE=$2
    echo "开始将 ${SOURCE_DEVICE} 克隆到 ${TARGET_DEVICE}..."
    sudo dd if=$SOURCE_DEVICE of=$TARGET_DEVICE bs=4M status=progress
}

# 克隆处理函数
function clone_process() {
    local DEVICE_ADDRESS=$(get_source_device_address)
    local TARGET_DEVICE_ADDRESS=$(get_target_device_address)

    # 检查磁盘容量
    check_disk_capacity "$DEVICE_ADDRESS" "$TARGET_DEVICE_ADDRESS"

    # 开始克隆磁盘
    clone_device "$DEVICE_ADDRESS" "$TARGET_DEVICE_ADDRESS"

    echo "克隆完成，从 ${DEVICE_ADDRESS} 到 ${TARGET_DEVICE_ADDRESS}"
}

# 主函数
function main() {
    check_os_type
    # 显示磁盘列表
    list_disks

    clone_process
}

# 调用主函数
main
