#!/bin/bash

# 脚本说明：Jetson Orin系列Super刷机工具
# 创建日期：2025-02-20

# 下载内核
download_kernel() {
    echo "下载内核..."
    wget https://developer.nvidia.com/downloads/embedded/l4t/r36_release_v4.3/release/Jetson_Linux_r36.4.3_aarch64.tbz2
    wget https://developer.nvidia.com/downloads/embedded/l4t/r36_release_v4.3/release/Tegra_Linux_Sample-Root-Filesystem_r36.4.3_aarch64.tbz2
}

# 解压内核
extract_kernel() {
    echo "解压内核..."
    tar xf Jetson_Linux_r36.4.3_aarch64.tbz2 
    sudo tar xpf Tegra_Linux_Sample-Root-Filesystem_r36.4.3_aarch64.tbz2 -C Linux_for_Tegra/rootfs/
    cd Linux_for_Tegra/
}

# 准备依赖包
prepare_dependencies() {
    echo "准备依赖包..."
    sudo ./tools/l4t_flash_prerequisites.sh
}

# 镜像文件准备
apply_binaries() {
    echo "镜像文件准备..."
    sudo ./apply_binaries.sh
}

# 烧录SSD
flash_to_ssd() {
    echo "系统烧录 SSD..."
    sudo ./tools/kernel_flash/l4t_initrd_flash.sh \
        --external-device nvme0n1p1 \
        -c tools/kernel_flash/flash_l4t_t234_nvme.xml \
        -p "-c bootloader/generic/cfg/flash_t234_qspi.xml" \
        --showlogs --network usb0 jetson-orin-nano-devkit-super internal
}

# 烧录USB Disk
flash_to_usb_disk() {
    echo "系统烧录 USB Disk..."
    sudo ./tools/kernel_flash/l4t_initrd_flash.sh \
        --external-device sda1 \
        -c tools/kernel_flash/flash_l4t_t234_nvme.xml \
        -p "-c bootloader/generic/cfg/flash_t234_qspi.xml" \
        --showlogs --network usb0 jetson-orin-nano-devkit-super internal
}

# 主函数，选择烧录目标
main() {
    download_kernel
    extract_kernel
    prepare_dependencies
    apply_binaries

    echo "请选择烧录目标:"
    echo "1. 烧录到 SSD"
    echo "2. 烧录到 USB Disk"
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
