#!/bin/bash

# ----------------------------
# Jetson系统初始化 
# 基于Ubuntu 20.04 LTS 
# V1.3
# By Snowolf
# Create 2023-09-04
# Update 2024-11-09
# ----------------------------

echo ""
echo "===== Jetson系统初始化 ====="
echo ""
sleep 1

# 函数：根据内存动态设置交换空间
configure_swap() {
    echo ""
    echo "===== 增加交换空间 ====="
    echo ""
    sleep 1

    # 获取机器总内存大小，单位MB
    MEM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    
    # 计算建议的交换空间大小，设定为内存的1倍，最大值16GB
    SWAP_SIZE_MB=$(( MEM_TOTAL / 1024 ))  # 以MB为单位
    SWAP_SIZE_GB=$(( (SWAP_SIZE_MB + 1023) / 1024 ))  # 将MB转换为GB，并四舍五入到整数
    
    # 最大交换空间为16GB
    if [ $SWAP_SIZE_GB -gt 16 ]; then
        SWAP_SIZE_GB=16
    fi

    echo "设置交换空间大小为 ${SWAP_SIZE_GB}GB"
    
    # 创建交换文件
    sudo fallocate -l "${SWAP_SIZE_GB}G" /var/swapfile
    sudo chmod 600 /var/swapfile
    sudo mkswap /var/swapfile
    sudo swapon /var/swapfile
    sudo bash -c 'echo "/var/swapfile swap swap defaults 0 0" >> /etc/fstab'
    sleep 1
}

# 函数：更新系统并安装基本工具
update_system() {
    echo ""
    echo "===== 系统更新 ====="
    echo ""
    sleep 1
    
    sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y

    echo "安装必要系统工具"
    sudo apt install -y net-tools ssh vim apt-utils unrar p7zip-full

    # 配置TensorRT
    echo ""
    echo "===== 配置TensorRT工具 ====="
    echo ""
    sleep 1

    # 确保 export PATH=/usr/src/tensorrt/bin 语句在 ~/.bashrc 中不存在，若不存在则追加
    if ! grep -q "export PATH=\$PATH:/usr/src/tensorrt/bin" ~/.bashrc; then
        echo 'export PATH=$PATH:/usr/src/tensorrt/bin' >> ~/.bashrc
    fi
    
    sleep 1
}

# 函数：安装Python依赖和开发环境
install_python_env() {
    echo ""
    echo "===== 安装Python环境依赖 ====="
    echo ""
    sleep 1

    sudo apt install -y \
        python3-dev \
        python3-pip \
        python3-venv \
        libxml2-dev \
        libxslt1-dev \
        zlib1g-dev \
        libffi-dev \
        libssl-dev \
        libgstrtspserver-1.0-dev \
        v4l-utils


    echo ""
    echo "===== 配置 pip 源 ====="
    echo ""
    sleep 1
    
    mkdir -p ~/.pip

    # 写入配置文件内容
    echo "[global]" > ~/.pip/pip.conf
    echo "index-url = https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple" >> ~/.pip/pip.conf

    echo "升级pip3"
    python3 -m pip install --upgrade pip
    python3 -m pip install wheel==0.35 numpy==1.23.5 protobuf==3.20.2 onnx 
    
    echo ""
    echo "===== 修正Python软链接 ====="
    echo ""
    sleep 1

    sudo rm /usr/bin/python
    sudo ln -s /usr/bin/python3 /usr/bin/python

    # 确保 export PATH 语句在 ~/.bashrc 中不存在，若不存在则追加
    if ! grep -q "export PATH=\$PATH:\$HOME/.local/bin" ~/.bashrc; then
        echo 'export PATH=$PATH:$HOME/.local/bin' >> ~/.bashrc
    fi

    # 安装PyCUDA库
    echo ""
    echo "===== 安装PyCUDA库 ====="
    echo ""
    sleep 1
    python3 -m pip install pycuda
}

# 函数：安装其他工具
install_additional_tools() {
    echo ""
    echo "===== 安装分屏终端工具 ====="
    echo ""
    sleep 1

    sudo apt install terminator -y

    echo ""
    echo "===== 安装监控工具 ====="
    echo ""
    sleep 1

    sudo add-apt-repository ppa:fossfreedom/indicator-sysmonitor -y
    sudo apt-get update
    sudo apt-get install indicator-sysmonitor -y
    indicator-sysmonitor &
    sleep 1

    echo ""
    echo "===== 安装扩容工具 ====="
    echo ""
    sleep 1

    sudo apt install gparted -y
}

# 函数：安装中文语言包
install_language_pack() {
    echo ""
    echo "===== 安装中文语言包 ====="
    echo ""
    sleep 1
    
    sudo apt-get install language-pack-zh-hans* -y
}

# 函数：安装Jetson监控工具
install_jetson_stats() {
    echo ""
    echo "===== 安装JTop ====="
    echo ""
    sleep 1
    
    sudo pip3 install -U jetson-stats
    sudo systemctl restart jetson_stats.service
}

# 主执行逻辑
main() {
    configure_swap
    update_system
    install_python_env
    install_additional_tools
    install_language_pack
    install_jetson_stats
    echo ""
    echo "===== 系统初始化完成 ====="
    echo ""
    sleep 1
}

main
