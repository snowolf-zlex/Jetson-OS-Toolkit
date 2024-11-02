#!/bin/bash

############
# 镜像加载与卸载工具

# 特殊挂载路径
MOUNT_POINT="/mnt/image_device"

# 检查输入参数
if [ "$#" -ne 2 ]; then
    echo "用法: $0 {mount|umount} /path/to/image.img"
    exit 1
fi

COMMAND=$1
IMAGE_FILE=$2

case $COMMAND in
    mount)
        # 创建挂载目录（如果不存在）
        if [ ! -d "$MOUNT_POINT" ]; then
            sudo mkdir -p "$MOUNT_POINT"
        fi
        
        # 查找空闲的loop设备
        LOOP_DEVICE=$(sudo losetup -f)
        
        # 将镜像文件挂载到loop设备
        sudo losetup -P "$LOOP_DEVICE" "$IMAGE_FILE"
        
        # 获取第一个分区的loop设备（假设只有一个分区）
        PARTITION="${LOOP_DEVICE}p1"
        
        # 挂载分区
        sudo mount "$PARTITION" "$MOUNT_POINT"
        echo "镜像已挂载到 $MOUNT_POINT"

        ;;
    umount)
        # 卸载分区
        sudo umount "$MOUNT_POINT"
        
        # 查找对应的loop设备
        LOOP_DEVICE=$(losetup | grep "$IMAGE_FILE" | awk '{print $1}')
        
        # 解除loop设备的关联
        if [ -n "$LOOP_DEVICE" ]; then
            sudo losetup -d "$LOOP_DEVICE"
        fi
        
        echo "镜像已卸载"
        ;;

    *)
        echo "无效的命令: $COMMAND"
        exit 1
        ;;
esac
