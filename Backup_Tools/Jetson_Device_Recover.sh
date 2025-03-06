#!/bin/bash

####################################
# 脚本名称：Jetson设备镜像恢复脚本
# 脚本版本：v1.1
# 脚本用途：从镜像文件恢复到指定磁盘
# 适用范围：Linux、Unix（MacOS）
# 脚本作者：Snowolf
# 创建日期：2025-03-06
# 更新日期：2025-03-06
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

# 检查必需命令是否存在
function check_commands() {
    local COMMANDS=("dd")
    for cmd in "${COMMANDS[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "错误：所需的命令 $cmd 未安装。"
            if [[ "$OS_TYPE" == "Darwin" ]]; then
                echo "请使用 Homebrew 安装：brew install $cmd"
            else
                echo "请使用系统包管理器安装。"
            fi
            exit 1
        fi
    done
}

# 检查xz命令（仅在需要时）
function check_xz_command() {
    if ! command -v xz &>/dev/null; then
        echo "错误：所需的命令 xz 未安装，无法处理压缩镜像。"
        if [[ "$OS_TYPE" == "Darwin" ]]; then
            echo "请使用 Homebrew 安装：brew install xz"
        else
            echo "请使用系统包管理器安装。"
        fi
        exit 1
    fi
}

# 列出磁盘设备
function list_disks() {
    echo "以下是当前磁盘列表："
    if [[ "$OS_TYPE" == "Linux" ]]; then
        lsblk -d -n -e 1,2,7 | grep -v "SWAP"
    elif [[ "$OS_TYPE" == "Darwin" ]]; then
        diskutil list
    fi
}

# 提示用户输入镜像文件路径
function get_image_path() {
    while true; do
        read -e -p "请输入镜像文件路径 (支持.img或.xz格式): " IMAGE_PATH
        if [[ -f "$IMAGE_PATH" ]]; then
            break
        else
            echo "错误：文件不存在，请重新输入。"
        fi
    done
    echo "$IMAGE_PATH"
}

# 提示用户选择目标设备地址
function get_device_address() {
    read -e -p "请输入目标设备地址 (例如 /dev/sdb): " DEVICE_ADDRESS
    echo "$DEVICE_ADDRESS"
}

# 检查设备挂载状态（仅Linux）
function check_mounted() {
    if [[ "$OS_TYPE" == "Linux" ]]; then
        local MOUNT_POINTS
        MOUNT_POINTS=$(lsblk -n -o MOUNTPOINTS "$DEVICE_ADDRESS" | grep -v "^$")
        if [[ -n "$MOUNT_POINTS" ]]; then
            echo "警告：目标设备存在挂载的分区："
            echo "$MOUNT_POINTS"
            read -p "必须卸载所有分区才能继续，是否立即卸载？(y/n): " UNMOUNT_CONFIRM
            if [[ "$UNMOUNT_CONFIRM" == "y" ]]; then
                for mount in $MOUNT_POINTS; do
                    sudo umount "$mount"
                done
                echo "已卸载所有分区。"
            else
                echo "请手动卸载后重新运行脚本。"
                exit 1
            fi
        fi
    else
        echo "MacOS用户请确保目标设备未挂载。"
    fi
}

# 验证SHA1校验和
function verify_sha1() {
    local IMAGE_PATH=$1
    local SHA1_FILE="${IMAGE_PATH}.sha1"
    
    if [[ ! -f "$SHA1_FILE" ]]; then
        echo "未找到SHA1校验文件，跳过验证。"
        return 0
    fi

    echo "正在验证SHA1校验和..."
    
    local SHA1_CMD
    if [[ "$OS_TYPE" == "Linux" ]]; then
        SHA1_CMD="sha1sum"
    else
        SHA1_CMD="shasum -a 1"
    fi

    local EXPECTED_CHECKSUM=$(awk '{print $1}' "$SHA1_FILE")
    local ACTUAL_CHECKSUM=$($SHA1_CMD "$IMAGE_PATH" | awk '{print $1}')

    if [[ "$EXPECTED_CHECKSUM" == "$ACTUAL_CHECKSUM" ]]; then
        echo "SHA1校验通过。"
    else
        echo "错误：SHA1校验不匹配！"
        echo "预期: $EXPECTED_CHECKSUM"
        echo "实际: $ACTUAL_CHECKSUM"
        exit 1
    fi
}

# 确认恢复操作
function confirm_restore() {
    local DEVICE_ADDRESS=$1
    local IMAGE_PATH=$2
    echo "即将恢复以下镜像到设备："
    echo "源镜像: $IMAGE_PATH"
    echo "目标设备: $DEVICE_ADDRESS"
    echo "警告：此操作将完全覆盖目标设备的所有数据！"
    read -p "确认要继续吗？(输入大写的YES确认): " CONFIRM
    if [[ "$CONFIRM" != "YES" ]]; then
        echo "操作已取消。"
        exit 0
    fi
}

# 执行恢复操作
function restore_image() {
    local IMAGE_PATH=$1
    local DEVICE_ADDRESS=$2

    if [[ "$IMAGE_PATH" == *.xz ]]; then
        echo "开始解压并恢复压缩镜像..."
        xz -dcT0 "$IMAGE_PATH" | sudo dd of="$DEVICE_ADDRESS" bs=4M status=progress
    else
        echo "开始恢复原始镜像..."
        sudo dd if="$IMAGE_PATH" of="$DEVICE_ADDRESS" bs=4M status=progress
    fi

    echo "同步写入缓存..."
    sudo sync
}

# 主函数
function main() {
    check_os_type
    check_commands

    # 获取镜像路径
    local IMAGE_PATH
    IMAGE_PATH=$(get_image_path)

    # 检查是否需要xz命令
    if [[ "$IMAGE_PATH" == *.xz ]]; then
        check_xz_command
    fi

    list_disks
    # 获取目标设备地址
    local DEVICE_ADDRESS
    DEVICE_ADDRESS=$(get_device_address)

    # 检查设备挂载状态
    check_mounted

    # 验证SHA1校验和
    verify_sha1 "$IMAGE_PATH"

    # 最终确认
    confirm_restore "$DEVICE_ADDRESS" "$IMAGE_PATH"

    # 执行恢复
    restore_image "$IMAGE_PATH" "$DEVICE_ADDRESS"

    echo "恢复完成！请安全移除设备。"
}

# 执行主函数
main
