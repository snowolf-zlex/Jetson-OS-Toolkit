#!/bin/bash

####################################
# Jetson设备镜像备份脚本
#
# 自动检测操作系统，列出磁盘设备并提示用户选择
# 生成镜像及其SHA1校验文件
####################################

# 检查操作系统类型并显示磁盘列表
function list_disks() {
    local OS_TYPE=$(uname)
    echo "当前操作系统为: $OS_TYPE"

    if [[ "$OS_TYPE" == "Linux" ]]; then
        echo "检测到Linux操作系统，以下是当前磁盘列表："
        lsblk -d
    else
        echo "不支持的操作系统: $OS_TYPE"
        exit 1
    fi
}

# 提示用户选择磁盘设备
function get_device_address() {
    read -p "请输入要备份的Jetson设备地址 (例如 /dev/sdb): " DEVICE_ADDRESS
    echo "$DEVICE_ADDRESS"
}

# 提示用户输入备份文件名
function get_backup_name() {
    read -p "请输入备份文件名称 (例如 Jetson_Image_20230402): " BACKUP_NAME
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

# 备份磁盘为镜像文件
function backup_device() {
    local DEVICE_ADDRESS=$1
    local FILE_PATH=$2
    echo "开始将 ${DEVICE_ADDRESS} 备份到 ${FILE_PATH}..."
    sudo dd if=$DEVICE_ADDRESS of=${FILE_PATH} bs=4M status=progress
}

# 根据操作系统选择SHA1命令并生成SHA1校验和
function generate_sha1() {
    local FILE_PATH=$1
    local FILE_NAME=$2
    local SHA1_FILE="${FILE_PATH}.sha1"

    # 检查操作系统并选择合适的SHA1命令
    local OS_TYPE=$(uname)
    local SHA1_CMD

    if [[ "$OS_TYPE" == "Linux" ]]; then
        SHA1_CMD="sha1sum"
    else
        echo "不支持的操作系统: $OS_TYPE"
        exit 1
    fi

    # 计算SHA1校验和并保存到文件
    echo "计算镜像文件的SHA1校验和..."
    local CHECKSUM=$($SHA1_CMD "${FILE_PATH}" | awk '{print $1}')
    echo "${CHECKSUM}  ${FILE_NAME}" > "${SHA1_FILE}"

    echo "SHA1校验文件路径: ${SHA1_FILE}"
}

# 主函数
function main() {
    # 步骤1：列出磁盘列表
    list_disks

    # 步骤2：提示用户输入设备地址和备份文件名
    local DEVICE_ADDRESS=$(get_device_address)
    local BACKUP_NAME=$(get_backup_name)

    # 步骤3：确认备份文件名
    confirm_backup_name "$BACKUP_NAME"

    # 生成带日期的镜像文件名和路径
    local FILE_NAME="${BACKUP_NAME}_$(date +%Y%m%d).img"
    local FILE_PATH=~/${FILE_NAME}

    # 步骤4：开始备份
    backup_device "$DEVICE_ADDRESS" "$FILE_PATH"

    # 步骤5：生成SHA1校验和并保存到文件
    generate_sha1 "$FILE_PATH" "$FILE_NAME"

    # 提示完成
    echo "备份完成，镜像文件路径: ${FILE_PATH}"
}

# 调用主函数
main
