#!/bin/bash

####################################
# 脚本名称：Jetson设备系统拷贝脚本
# 脚本用途：备份源磁盘到目标磁盘
# 适用范围：Linux
# 脚本作者：Snowolf
# 创建日期：2024-11-02
# 修改日期：2025-04-07
####################################

set -e  # 遇到错误立即退出

# 颜色定义（用于提示信息）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否以 root 或 sudo 运行
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}错误：此脚本需要 root 权限，请使用 sudo 运行。${NC}" 
   exit 1
fi

# 显示可用的存储设备
echo -e "${GREEN}可用的存储设备:${NC}"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT

# 提示用户输入目标磁盘（如 /dev/sda，注意不是分区）
echo ""
read -p "请输入要作为系统备份的【目标磁盘】（例如 /dev/sda，请注意这将清除磁盘上的所有数据）: " DISK

# 检查磁盘是否存在
if [[ ! -b "$DISK" ]]; then
    echo -e "${RED}错误：磁盘 $DISK 不存在。${NC}"
    exit 1
fi

# 确认操作
echo -e "${YELLOW}警告：您选择的磁盘 $DISK 上的所有数据将被永久删除！${NC}"
read -p "是否继续？(输入 yes 继续，其他任意键退出): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo "操作已取消。"
    exit 0
fi

# 1. 卸载该磁盘上的所有分区
echo -e "${GREEN}正在卸载 $DISK 上的所有分区...${NC}"
for part in $(ls ${DISK}* 2>/dev/null | grep -E "${DISK}[0-9]+"); do
    umount "$part" 2>/dev/null || true
done

# 2. 创建新的 GPT 分区表并建立单一分区
echo -e "${GREEN}正在为 $DISK 创建 GPT 分区表...${NC}"
parted -s "$DISK" mklabel gpt

echo -e "${GREEN}正在创建占满整个磁盘的 ext4 分区...${NC}"
parted -s -a optimal "$DISK" mkpart primary ext4 0% 100%

# 等待分区表更新
sleep 2
partprobe "$DISK" 2>/dev/null || true

# 确定新创建的分区（通常是 ${DISK}1）
PARTITION="${DISK}1"
if [[ ! -b "$PARTITION" ]]; then
    echo -e "${RED}错误：无法找到新创建的分区 $PARTITION。${NC}"
    exit 1
fi

# 3. 格式化为 ext4 文件系统
echo -e "${GREEN}正在格式化分区 $PARTITION 为 ext4...${NC}"
mkfs.ext4 -F "$PARTITION"

# 4. 挂载到 /mnt（如果 /mnt 非空，给出警告）
if mountpoint -q /mnt; then
    echo -e "${YELLOW}警告：/mnt 已经被挂载，将先卸载原挂载点。${NC}"
    umount /mnt
fi
if [ "$(ls -A /mnt)" ]; then
    echo -e "${YELLOW}警告：/mnt 目录非空，可能会影响复制。按 Ctrl+C 取消，或等待 5 秒继续...${NC}"
    sleep 5
fi

echo -e "${GREEN}正在挂载 $PARTITION 到 /mnt...${NC}"
mount "$PARTITION" /mnt

# 可选：设置权限，使普通用户 nvidia 可写（如果存在该用户）
if id "nvidia" &>/dev/null; then
    chown -R nvidia:nvidia /mnt
    echo -e "${GREEN}已将 /mnt 的所有者设为 nvidia 用户。${NC}"
fi

# 5. 开始复制根文件系统
echo -e "${GREEN}开始复制根文件系统到 $PARTITION ...${NC}"
EXCLUDES="--exclude={/dev/,/proc/,/sys/,/tmp/,/run/,/mnt/,/media/*,/lost+found}"
rsync -axHAWX --numeric-ids --info=progress2 $EXCLUDES / /mnt

# 同步并完成
sync
echo -e "${GREEN}系统复制完成！目标磁盘 $DISK 已准备就绪，分区挂载在 /mnt。${NC}"
echo -e "${YELLOW}您可以检查 /mnt 中的内容，然后手动卸载（umount /mnt）并拔出磁盘。${NC}"