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
lsblk -d

# 提示用户输入要挂载的SSD分区
read -p "请输入要挂载的SSD分区（例如/dev/sda1）: " SSD_PART

# 挂载SSD
sudo mount "$SSD_PART" /mnt

# 默认的排除目录
EXCLUDES="--exclude={/dev/,/proc/,/sys/,/tmp/,/run/,/mnt/,/media/*,/lost+found}"

# 复制根文件系统到SSD
sudo rsync -axHAWX --numeric-ids --info=progress2 $EXCLUDES / /mnt

# 保持SSD挂载以供后续操作
echo "SSD已挂载在/mnt，并已完成文件复制。"
