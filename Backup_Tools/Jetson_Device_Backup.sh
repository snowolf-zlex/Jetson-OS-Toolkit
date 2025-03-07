#!/bin/bash

####################################
# 脚本名称：Jetson设备镜像备份脚本（优化版）
# 脚本版本：v1.2
# 脚本用途：并行备份并压缩源磁盘到镜像文件
# 适用范围：Linux、Unix（MacOS）
# 脚本作者：Snowolf
# 创建日期：2024-09-30
# 更新日期：2025-03-03
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
    local COMMANDS=("dd" "xz")
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

# 检查操作系统类型并显示磁盘列表
function list_disks() {
    echo "检测到${OS_TYPE}操作系统，以下是当前磁盘列表："
    if [[ "$OS_TYPE" == "Linux" ]]; then
        lsblk -d -n -e 1,2,7 | grep -v "SWAP"
    elif [[ "$OS_TYPE" == "Darwin" ]]; then
        diskutil list
    fi
}

# 提示用户选择磁盘设备
function get_device_address() {
    read -e -p "请输入要备份的Jetson设备地址 (例如 /dev/sdb): " DEVICE_ADDRESS
    echo "$DEVICE_ADDRESS"
}

# 提示用户输入备份文件存储路径
function get_backup_path() {
    read -e -p "请输入备份文件存储路径 (例如 /home/user/backups): " BACKUP_PATH
    if [[ ! -d "$BACKUP_PATH" ]]; then
        mkdir -p "$BACKUP_PATH"
        echo "创建存储路径: $BACKUP_PATH"
    fi
    echo "$BACKUP_PATH"
}

# 提示用户输入备份文件名
function get_backup_name() {
    read -e -p "请输入备份文件名称 (例如 jetson_orin_nx_jp514): " BACKUP_NAME
    echo "$BACKUP_NAME"
}

# 确认备份操作
function confirm_backup() {
    local BACKUP_NAME=$1
    local COMPRESS_OPTION=$2
    local EXTENSION=$3
    local CONFIRM

    read -p "确认备份文件名为：${BACKUP_NAME}_$(date +%Y%m%d).${EXTENSION}，是否继续？(y/n): " CONFIRM
    if [[ "$CONFIRM" != "y" ]]; then
        echo "取消操作"
        exit 1
    fi
}

# 提示用户选择是否压缩和生成SHA1
function prompt_options() {
    read -p "是否压缩备份文件？(y/n): " COMPRESS_OPTION
    read -p "是否生成SHA1校验和？(y/n): " SHA1_OPTION
    echo "$COMPRESS_OPTION,$SHA1_OPTION"
}

# 备份磁盘为镜像文件（非压缩）
function backup_device() {
    local DEVICE_ADDRESS=$1
    local FILE_PATH=$2
    echo "开始将 ${DEVICE_ADDRESS} 备份到 ${FILE_PATH}..."
    sudo dd if="$DEVICE_ADDRESS" of="$FILE_PATH" bs=4M status=progress
}

# 并行备份并压缩磁盘镜像
function backup_device_compress() {
    local DEVICE_ADDRESS=$1
    local FILE_PATH=$2
    echo "开始并行备份并压缩 ${DEVICE_ADDRESS} 到 ${FILE_PATH}..."
    sudo dd if="$DEVICE_ADDRESS" bs=4M status=progress | xz -9vT5 > "$FILE_PATH"
}

# 生成SHA1校验和文件
function generate_sha1() {
    local FILE_PATH=$1
    local FILE_NAME=$2
    local SHA1_FILE="${FILE_PATH}.sha1"

    local SHA1_CMD
    if [[ "$OS_TYPE" == "Linux" ]]; then
        SHA1_CMD="sha1sum"
    elif [[ "$OS_TYPE" == "Darwin" ]]; then
        SHA1_CMD="shasum -a 1"
    fi

    echo "计算镜像文件的SHA1校验和..."
    local CHECKSUM=$($SHA1_CMD "$FILE_PATH" | awk '{print $1}')
    echo "${CHECKSUM}  ${FILE_NAME}" > "$SHA1_FILE"
    echo "SHA1校验文件路径: ${SHA1_FILE}"
}

# 主函数
function main() {
    check_os_type
    check_commands
    list_disks

    local DEVICE_ADDRESS
    DEVICE_ADDRESS=$(get_device_address)

    local BACKUP_PATH
    BACKUP_PATH=$(get_backup_path)

    local BACKUP_NAME
    BACKUP_NAME=$(get_backup_name)

    local OPTIONS
    OPTIONS=$(prompt_options)
    IFS=',' read -r COMPRESS_OPTION SHA1_OPTION <<< "$OPTIONS"

    local EXTENSION
    if [[ "$COMPRESS_OPTION" == "y" ]]; then
        EXTENSION="img.xz"
    else
        EXTENSION="img"
    fi

    local FILE_NAME="${BACKUP_NAME}_$(date +%Y%m%d).${EXTENSION}"
    local FILE_PATH="${BACKUP_PATH}/${FILE_NAME}"

    confirm_backup "$BACKUP_NAME" "$COMPRESS_OPTION" "$EXTENSION"

    if [[ "$COMPRESS_OPTION" == "y" ]]; then
        backup_device_compress "$DEVICE_ADDRESS" "$FILE_PATH"
    else
        backup_device "$DEVICE_ADDRESS" "$FILE_PATH"
    fi

    if [[ "$SHA1_OPTION" == "y" ]]; then
        generate_sha1 "$FILE_PATH" "$FILE_NAME"
    fi

    echo "备份完成，镜像文件路径: ${FILE_PATH}"
}

# 执行主函数
main
