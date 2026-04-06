#!/bin/bash

####################################
# 脚本名称：Jetson设备系统拷贝脚本
# 脚本用途：备份源磁盘到目标磁盘
# 适用范围：Linux
# 脚本作者：Snowolf
# 创建日期：2024-11-02
####################################

  # 1. 强制卸载 U 盘所有分区
  #  1 # 卸载所有可能自动挂载的分区
  #  sudo umount /dev/sda*

  # 2. 清除旧分区表并创建单一分区 (GPT)
  # 我们将使用 parted 工具来快速完成：

  #  1 # 1. 创建新的 GPT 分区表（这会清除所有 17 个旧分区）
  #  sudo parted /dev/sda mklabel gpt -s
  #  
  #  # 2. 创建一个使用 100% 空间的 ext4 主分区
  # sudo parted -a optimal /dev/sda mkpart primary ext4 0% 100%

  # 3. 格式化为 ext4 文件系统
  # ext4 是 Linux 的原生系统，支持软链接和权限管理，这对于安装 CUDA 至关重要。
  # # 格式化新创建的分区（通常是 /dev/sda1）
  # sudo mkfs.ext4 -F /dev/sda1

  # 4. 挂载到固定位置
  # 我们创建一个专门的挂载点 /mnt/ext_storage：

  #  1 # 1. 创建挂载点
  # sudo mkdir -p /mnt/ext_storage
  #  3
  #  4 # 2. 挂载分区
  # sudo mount /dev/sda1 /mnt/ext_storage
  #  6
  #  7 # 3. 设置权限（确保你的用户 nvidia 可以写入）
  #  sudo chown -R nvidia:nvidia /mnt/ext_storage

# 显示可用的存储设备
echo "可用的存储设备:"
lsblk

# 提示用户输入要挂载的目标存储设备
read -p "请输入要挂载的目标存储设备（例如/dev/sda1）: " DEVICE

# 挂载目标存储设备
sudo mount "$DEVICE" /mnt

# 默认的排除目录
EXCLUDES="--exclude={/dev/,/proc/,/sys/,/tmp/,/run/,/mnt/,/media/*,/lost+found}"

# 复制根文件系统到目标存储设备
sudo rsync -axHAWX --numeric-ids --info=progress2 $EXCLUDES / /mnt

# 保持目标存储设备挂载以供后续操作
echo "目标存储设备已挂载在/mnt，并已完成文件复制。"
