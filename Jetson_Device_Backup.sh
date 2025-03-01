#!/bin/bash

####################################
# 脚本名称：Jetson设备镜像备份脚本
# 脚本用途：备份源磁盘到镜像文件
# 适用范围：Linux、Unix（MacOS）
# 脚本作者：Snowolf
# 创建日期：2024-09-30
# 更新日期：2025-03-01
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
    # 检查路径是否存在，如果不存在则创建
    if [[ ! -d "$BACKUP_PATH" ]]; then
        mkdir -p "$BACKUP_PATH"
        echo "创建存储路径: $BACKUP_PATH"
    fi
    echo "$BACKUP_PATH"
}

# 提示用户输入备份文件名
function get_backup_name() {
    read -e -p "请输入备份文件名称 (例如 jetson_orin_nx_jp5.1.4_opencv4.10.0withcuda_torch2.1.0_torchvison0.16.0_tensorflow2.12.0): " BACKUP_NAME
    echo "$BACKUP_NAME"
}

# 确认备份文件名
function confirm_backup_name() {
    local BACKUP_NAME=$1
    local CONFIRM
    read -p "确认备份文件名为：${BACKUP_NAME}_$(date +%Y%m%d).img，是否继续？(y/n): " CONFIRM
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

# 备份磁盘为镜像文件
function backup_device() {
    local DEVICE_ADDRESS=$1
    local FILE_PATH=$2
    echo "开始将 ${DEVICE_ADDRESS} 备份到 ${FILE_PATH}..."
    sudo dd if=$DEVICE_ADDRESS of=${FILE_PATH} bs=4M status=progress
}

# 压缩备份文件
function compress_backup() {
    local FILE_PATH=$1
    echo "开始压缩备份文件 ${FILE_PATH}..."
    xz -zvkT 5 "${FILE_PATH}"
}

# 根据操作系统选择SHA1命令并生成SHA1校验和
function generate_sha1() {
    local FILE_PATH=$1
    local FILE_NAME=$2
    local SHA1_FILE="${FILE_PATH}.sha1"

    # 检查操作系统并选择合适的SHA1命令
    local SHA1_CMD
    if [[ "$OS_TYPE" == "Linux" ]]; then
        SHA1_CMD="sha1sum"
    elif [[ "$OS_TYPE" == "Darwin" ]]; then
        SHA1_CMD="shasum -a 1"
    fi

    # 计算SHA1校验和并保存到文件
    echo "计算镜像文件的SHA1校验和..."
    local CHECKSUM=$($SHA1_CMD "${FILE_PATH}" | awk '{print $1}')
    echo "${CHECKSUM}  ${FILE_NAME}" > "${SHA1_FILE}"

    echo "SHA1校验文件路径: ${SHA1_FILE}"
}

# 主函数
function main() {
    # 步骤1：检查操作系统类型
    check_os_type

    # 步骤2：列出磁盘列表
    list_disks

    # 步骤3：提示用户输入设备地址和存储路径
    local DEVICE_ADDRESS=$(get_device_address)
    local BACKUP_PATH=$(get_backup_path)

    # 步骤4：提示用户输入备份文件名
    local BACKUP_NAME=$(get_backup_name)

    # 步骤5：确认备份文件名
    confirm_backup_name "$BACKUP_NAME"

    # 生成带日期的镜像文件名和路径
    local FILE_NAME="${BACKUP_NAME}_$(date +%Y%m%d).img"
    local FILE_PATH="${BACKUP_PATH}/${FILE_NAME}"

    # 步骤6：开始备份
    backup_device "$DEVICE_ADDRESS" "$FILE_PATH"

    # 步骤7：提示用户选择压缩和SHA1选项
    local OPTIONS=$(prompt_options)
    IFS=',' read -r COMPRESS_OPTION SHA1_OPTION <<< "$OPTIONS"

    # 步骤8：压缩备份文件（如果选择压缩）
    if [[ "$COMPRESS_OPTION" == "y" ]]; then
        compress_backup "$FILE_PATH"
        FILE_PATH="${FILE_PATH}.xz"  # 更新文件路径为压缩后的文件
    fi

    # 步骤9：生成SHA1校验和（如果选择生成SHA1）
    if [[ "$SHA1_OPTION" == "y" ]]; then
        generate_sha1 "$FILE_PATH" "$(basename "$FILE_PATH" .xz)"
    fi

    # 提示完成
    echo "备份完成，镜像文件路径: ${FILE_PATH}"
}

# 调用主函数
main
