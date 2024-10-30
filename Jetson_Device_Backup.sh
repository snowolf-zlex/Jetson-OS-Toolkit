#!/bin/bash

####################################
# Jetson设备镜像备份和克隆脚本
#
# 支持生成镜像备份或克隆磁盘
####################################

# 检查操作系统类型并显示磁盘列表
function list_disks() {
    local OS_TYPE=$(uname)
    echo "当前操作系统为: $OS_TYPE"

    if [[ "$OS_TYPE" == "Linux" ]]; then
        echo "检测到Linux操作系统，以下是当前磁盘列表："
        lsblk -d
    elif [[ "$OS_TYPE" == "Darwin" ]]; then
        echo "检测到macOS操作系统，以下是当前磁盘列表："
        diskutil list
    else
        echo "不支持的操作系统: $OS_TYPE"
        exit 1
    fi
}

# 提示用户选择操作模式（备份或克隆）
function select_mode() {
    echo "请选择操作模式："
    echo "1) 备份磁盘为镜像文件"
    echo "2) 克隆磁盘到另一块磁盘"
    read -p "请输入选择 (1 或 2): " MODE
    if [[ "$MODE" != "1" && "$MODE" != "2" ]]; then
        echo "无效选择，退出脚本"
        exit 1
    fi
    echo "$MODE"
}

# 提示用户选择磁盘设备
function get_device_address() {
    read -p "请输入源磁盘设备地址 (例如 /dev/sdb 或 /dev/disk2): " DEVICE_ADDRESS
    echo "$DEVICE_ADDRESS"
}

# 提示用户选择目标磁盘设备（用于克隆）
function get_target_device_address() {
    read -p "请输入目标磁盘设备地址 (例如 /dev/sdc 或 /dev/disk3): " TARGET_DEVICE_ADDRESS
    echo "$TARGET_DEVICE_ADDRESS"
}

# 提示用户输入备份文件存储路径
function get_backup_path() {
    read -p "请输入备份文件存储路径 (例如 /home/user/backups): " BACKUP_PATH
    # 检查路径是否存在，如果不存在则创建
    if [[ ! -d "$BACKUP_PATH" ]]; then
        mkdir -p "$BACKUP_PATH"
        echo "创建存储路径: $BACKUP_PATH"
    fi
    echo "$BACKUP_PATH"
}

# 提示用户输入备份文件名
function get_backup_name() {
    read -p "请输入备份文件名称 (例如 jetson_orin_nx_backup): " BACKUP_NAME
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

# 克隆磁盘到目标磁盘
function clone_device() {
    local SOURCE_DEVICE=$1
    local TARGET_DEVICE=$2
    echo "开始将 ${SOURCE_DEVICE} 克隆到 ${TARGET_DEVICE}..."
    sudo dd if=$SOURCE_DEVICE of=$TARGET_DEVICE bs=4M status=progress
}

# 压缩备份文件
function compress_backup() {
    local FILE_PATH=$1
    echo "开始压缩备份文件 ${FILE_PATH}..."
    xz -zvkT 5 "${FILE_PATH}"
}

# 生成SHA1校验和
function generate_sha1() {
    local FILE_PATH=$1
    local FILE_NAME=$2
    local SHA1_FILE="${FILE_PATH}.sha1"

    # 检查操作系统并选择合适的SHA1命令
    local OS_TYPE=$(uname)
    local SHA1_CMD

    if [[ "$OS_TYPE" == "Linux" ]]; then
        SHA1_CMD="sha1sum"
    elif [[ "$OS_TYPE" == "Darwin" ]]; then
        SHA1_CMD="shasum -a 1"
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

# 备份处理函数
function backup_process() {
    local DEVICE_ADDRESS=$(get_device_address)
    local BACKUP_PATH=$(get_backup_path)
    local BACKUP_NAME=$(get_backup_name)

    confirm_backup_name "$BACKUP_NAME"

    local FILE_NAME="${BACKUP_NAME}_$(date +%Y%m%d).img"
    local FILE_PATH="${BACKUP_PATH}/${FILE_NAME}"

    # 开始备份
    backup_device "$DEVICE_ADDRESS" "$FILE_PATH"

    # 提示用户选择压缩和SHA1选项
    read -p "是否压缩备份文件？(y/n): " COMPRESS_OPTION
    read -p "是否生成SHA1校验和？(y/n): " SHA1_OPTION

    if [[ "$COMPRESS_OPTION" == "y" ]]; then
        compress_backup "$FILE_PATH"
        FILE_PATH="${FILE_PATH}.xz"  # 更新文件路径为压缩后的文件
    fi

    if [[ "$SHA1_OPTION" == "y" ]]; then
        generate_sha1 "$FILE_PATH" "$(basename "$FILE_PATH" .xz)"
    fi

    echo "备份完成，镜像文件路径: ${FILE_PATH}"
}

# 克隆处理函数
function clone_process() {
    local DEVICE_ADDRESS=$(get_device_address)
    local TARGET_DEVICE_ADDRESS=$(get_target_device_address)

    # 开始克隆磁盘
    clone_device "$DEVICE_ADDRESS" "$TARGET_DEVICE_ADDRESS"

    echo "克隆完成，从 ${DEVICE_ADDRESS} 到 ${TARGET_DEVICE_ADDRESS}"
}

# 主函数
function main() {
    list_disks
    local MODE=$(select_mode)

    if [[ "$MODE" == "1" ]]; then
        backup_process
    elif [[ "$MODE" == "2" ]]; then
        clone_process
    fi
}

# 调用主函数
main
