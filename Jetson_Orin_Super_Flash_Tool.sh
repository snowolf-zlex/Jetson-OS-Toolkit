#!/bin/bash

# 脚本说明：Jetson Orin系列Super刷机工具
# 创建日期：2025-02-20

# 启用错误处理
set -e  # 一旦发生错误，脚本会立即终止执行

# 设置下载链接和文件名
KERNEL_URL="https://developer.nvidia.com/downloads/embedded/l4t/r36_release_v4.3/release/Jetson_Linux_r36.4.3_aarch64.tbz2"
ROOTFS_URL="https://developer.nvidia.com/downloads/embedded/l4t/r36_release_v4.3/release/Tegra_Linux_Sample-Root-Filesystem_r36.4.3_aarch64.tbz2"
KERNEL_FILE="Jetson_Linux_r36.4.3_aarch64.tbz2"
ROOTFS_FILE="Tegra_Linux_Sample-Root-Filesystem_r36.4.3_aarch64.tbz2"

# 下载内核
download_kernel() {
    echo "检查内核文件是否已下载..."

    # 检查文件是否存在，若不存在则下载
    if [ ! -f "$KERNEL_FILE" ]; then
        echo "$KERNEL_FILE 文件未找到，开始下载..."
        wget "$KERNEL_URL" || { echo "下载失败: $KERNEL_FILE"; exit 1; }
    else
        echo "$KERNEL_FILE 文件已存在，跳过下载。"
    fi

    if [ ! -f "$ROOTFS_FILE" ]; then
        echo "$ROOTFS_FILE 文件未找到，开始下载..."
        wget "$ROOTFS_URL" || { echo "下载失败: $ROOTFS_FILE"; exit 1; }
    else
        echo "$ROOTFS_FILE 文件已存在，跳过下载。"
    fi
}

# 解压内核
extract_kernel() {
    echo "解压内核..."
    tar xf "$KERNEL_FILE" || { echo "解压失败: $KERNEL_FILE"; exit 1; }
    sudo tar xpf "$ROOTFS_FILE" -C Linux_for_Tegra/rootfs/ || { echo "解压失败: $ROOTFS_FILE"; exit 1; }
    cd Linux_for_Tegra/ || { echo "进入目录失败: Linux_for_Tegra"; exit 1; }
}

# 准备依赖包
prepare_dependencies() {
    echo "准备依赖包..."
    sudo ./tools/l4t_flash_prerequisites.sh || { echo "准备依赖包失败"; exit 1; }
}

# 镜像文件准备
apply_binaries() {
    echo "镜像文件准备..."
    sudo ./apply_binaries.sh || { echo "镜像文件准备失败"; exit 1; }
}

# 烧录SSD
flash_to_ssd() {
    echo "系统烧录 SSD..."
    sudo ./tools/kernel_flash/l4t_initrd_flash.sh \
        --external-device nvme0n1p1 \
        -c tools/kernel_flash/flash_l4t_t234_nvme.xml \
        -p "-c bootloader/generic/cfg/flash_t234_qspi.xml" \
        --showlogs --network usb0 jetson-orin-nano-devkit-super internal || { echo "烧录到SSD失败"; exit 1; }
}

# 烧录USB Disk
flash_to_usb_disk() {
    echo "系统烧录 USB Disk..."
    sudo ./tools/kernel_flash/l4t_initrd_flash.sh \
        --external-device sda1 \
        -c tools/kernel_flash/flash_l4t_t234_nvme.xml \
        -p "-c bootloader/generic/cfg/flash_t234_qspi.xml" \
        --showlogs --network usb0 jetson-orin-nano-devkit-super internal || { echo "烧录到USB Disk失败"; exit 1; }
}

# 主函数，选择烧录目标
main() {
    download_kernel
    extract_kernel
    prepare_dependencies
    apply_binaries

    echo "请选择烧录目标:"
    echo "1. 烧录到 SSD"
    echo "2. 烧录到 U-Disk"
    read -p "请输入数字选择 (1 或 2): " choice

    case $choice in
        1)
            flash_to_ssd
            ;;
        2)
            flash_to_usb_disk
            ;;
        *)
            echo "无效选择，请重新运行脚本并选择有效选项。"
            exit 1
            ;;
    esac
}

# 调用主函数
main

