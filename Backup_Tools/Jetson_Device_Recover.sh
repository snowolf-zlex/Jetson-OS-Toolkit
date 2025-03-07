#!/bin/bash

#######################################
# 脚本名称：Jetson镜像烧录工具
# 版本：v1.0
# 功能：安全高效的磁盘镜像烧录解决方案
# 支持：Linux/macOS | 压缩/原始镜像
# 作者：Snowolf
# 更新：2024-03-06
#######################################

# 初始化颜色配置
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 操作系统检测
OS_TYPE=$(uname -s)
DD_BS="4M"
declare -A OS_CONFIG=(
    [Linux]="lsblk -d -n -e1,2,7,11-14 | grep -vE '(boot|swap|loop|sr|fd)'"
    [Darwin]="diskutil list external physical"
)

# 错误处理函数
fatal_error() {
    echo -e "${RED}[错误] $1${NC}" >&2
    exit 1
}

# 依赖检查函数
check_dependencies() {
    local required=("dd")
    [[ "$1" == "xz" ]] && required+=("xz")
    
    for cmd in "${required[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            echo -e "${RED}缺少依赖: $cmd${NC}"
            [[ "$OS_TYPE" == "Darwin" ]] && echo "建议: brew install $cmd"
            [[ "$OS_TYPE" == "Linux" ]] && echo "建议: sudo apt install $cmd"
            exit 1
        fi
    done
}

# 磁盘列表显示函数
show_storage_devices() {
    echo -e "\n${BLUE}=== 可用存储设备 ===${NC}"
    case "$OS_TYPE" in
        Linux)
            echo -e "设备\t容量\t型号" 
            lsblk -d -o NAME,SIZE,MODEL | grep -vE 'loop|rom' ;;
        Darwin)
            diskutil list | awk '/disk[0-9]+ /{print $1,$3,$4}' ;;
    esac
    echo -e "${YELLOW}提示：设备路径示例 - Linux: /dev/sdX, macOS: /dev/diskX${NC}"
}

# 智能路径输入函数
smart_path_input() {
    while : ; do
        read -e -p "请输入文件路径（支持Tab补全）: " path
        eval expanded_path="$path"
        
        [ -f "$expanded_path" ] && { echo "$expanded_path"; return; }
        echo -e "${RED}文件不存在！当前目录候选：${NC}"
        ls -lh *.img *.img.xz 2>/dev/null || echo "未找到镜像文件"
    done
}

# 挂载点检查函数
check_mountpoints() {
    local device=$1
    echo -e "${YELLOW}正在检查设备挂载状态...${NC}"
    
    case "$OS_TYPE" in
        Linux)
            local mounts=$(lsblk -n -o MOUNTPOINTS "$device" | grep -v "^$")
            [ -z "$mounts" ] && return
            
            echo -e "${RED}检测到活跃挂载点：${NC}"
            echo "$mounts"
            read -p "是否强制卸载？(y/N): " choice
            [ "$choice" == "y" ] && sudo umount -l "$device"* ;;
        Darwin)
            if diskutil info "$device" | grep -q 'Mounted'; then
                echo -e "${RED}设备已挂载！${NC}"
                diskutil unmountDisk "$device"
            fi ;;
    esac
}

# 校验和验证函数
verify_checksum() {
    local img=$1
    [ ! -f "${img}.sha1" ] && return
    
    echo -e "${BLUE}=== 开始校验验证 ===${NC}"
    local sha_cmd=$( [ "$OS_TYPE" == "Linux" ] && echo "sha1sum" || echo "shasum -a 1")
    local expected=$(awk '{print $1}' "${img}.sha1")
    local actual=$($sha_cmd "$img" | awk '{print $1}')
    
    [ "$expected" != "$actual" ] && fatal_error "校验不匹配！\n期望: $expected\n实际: $actual"
    echo -e "${GREEN}校验验证通过${NC}"
}

# 安全确认函数
safety_confirm() {
    echo -e "\n${RED}=== 最终操作确认 ===${NC}"
    echo -e "目标设备: $1"
    echo -e "镜像文件: $2"
    echo -e "${RED}警告：这将永久擦除目标设备所有数据！${NC}"
    
    read -p "请输入大写的 CONFIRM 确认: " input
    [ "$input" != "CONFIRM" ] && exit 0
}

# 核心烧录函数
perform_flashing() {
    local img=$1
    local dev=$2
    
    if [[ "$img" == *.xz ]] || file "$img" | grep -q 'XZ compressed'; then
        echo -e "${GREEN}检测到压缩镜像，启用并行解压...${NC}"
        check_dependencies xz
        xz -dcT0 "$img" | sudo dd of="$dev" bs="$DD_BS" status=progress
    else
        echo -e "${GREEN}检测到原始镜像，直接烧录...${NC}"
        sudo dd if="$img" of="$dev" bs="$DD_BS" status=progress
    fi
    
    echo -e "${YELLOW}同步写入缓存...${NC}"
    sudo sync
}

# 主流程控制
main() {
    echo -e "${GREEN}=== 智能设备烧录工具 v2.0 ===${NC}"
    
    # 获取镜像路径
    local image_path=$(smart_path_input)
    
    # 显示设备列表
    show_storage_devices
    
    # 获取目标设备
    read -e -p "输入目标设备路径: " device
    [ ! -e "$device" ] && fatal_error "设备不存在！"
    
    # 安全检查
    check_mountpoints "$device"
    verify_checksum "$image_path"
    safety_confirm "$device" "$image_path"
    
    # 执行烧录
    perform_flashing "$image_path" "$device"
    
    echo -e "\n${GREEN}=== 操作成功完成！ ===${NC}"
    [[ "$OS_TYPE" == "Darwin" ]] && diskutil eject "$device"
}

# 脚本入口
main
