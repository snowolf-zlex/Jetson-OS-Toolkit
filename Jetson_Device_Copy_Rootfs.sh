#!/bin/bash

####################################
# 脚本名称：Jetson设备系统拷贝脚本
# 脚本用途：备份源磁盘到目标磁盘
# 适用范围：Linux
# 脚本作者：Snowolf
# 创建日期：2024-11-02
####################################

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
