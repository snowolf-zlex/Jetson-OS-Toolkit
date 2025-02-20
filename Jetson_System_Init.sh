#!/bin/bash

# 输出信息
print_message() {
    length=20  # 设置分隔线的长度
    echo $(printf '=%.0s' {1..20})
    echo "$1"
    echo $(printf '=%.0s' $(seq 1 $length))
    sleep 1
}

# 系统更新
system_update() {
    print_message "系统更新"

    # 更新软件源
    sudo apt update

    # 系统全面更新
    sudo apt full-upgrade -y

    # 卸载office等工具
    sudo apt purge -y \
        libreoffice* \
        gnome-mahjongg \
        gnome-sudoku \
        aisleriot \
        gnome-mines

    # 清理过期软件
    sudo apt autoremove -y
}

# 检查系统版本
check_ubuntu_version() {
    # 获取Ubuntu版本号
    UBUNTU_VERSION=$(lsb_release -r | awk '{print $2}')

    print_message "系统版本：Ubuntu $UBUNTU_VERSION"

    # 判断系统版本是否是18或20
    if [[ "$UBUNTU_VERSION" == "18.04" || "$UBUNTU_VERSION" == "20.04" ]]; then
        echo "支持VNC配置"
    else
        echo "当前系统版本 $UBUNTU_VERSION 不支持自动VNC配置，仅支持Ubuntu 18.04 和 20.04。"
        exit 1
    fi
}

# 分配交换空间
allocate_swap() {
    # 获取系统的内存大小（单位：MB）
    RAM_SIZE_MB=$(free -m | awk '/^Mem:/ {print $2}')

    # 如果RAM大于1GB
    if [ "$RAM_SIZE_MB" -gt 1024 ]; then
        # 计算最小Swap大小（单位：MB），为RAM的平方根，并进行上取整
        MIN_SWAP_SIZE_MB=$(echo "scale=1; sqrt($RAM_SIZE_MB)" | bc)
        MIN_SWAP_SIZE_MB=$(printf "%.0f" "$MIN_SWAP_SIZE_MB")  # 四舍五入
        MIN_SWAP_SIZE_MB=$((MIN_SWAP_SIZE_MB + 1))  # 上取整
        
        # 计算最大Swap大小（单位：MB），为RAM的两倍
        MAX_SWAP_SIZE_MB=$((RAM_SIZE_MB * 2))
        
        # 设置Swap文件的大小
        SWAP_SIZE_MB=$MIN_SWAP_SIZE_MB  # 最小Swap大小为内存平方根（上取整）
        SWAP_SIZE_MB=$((SWAP_SIZE_MB < MAX_SWAP_SIZE_MB ? SWAP_SIZE_MB : MAX_SWAP_SIZE_MB))  # 最大不超过两倍内存
        
        print_message "建议的Swap大小为：$SWAP_SIZE_MB MB"
        
    else
        # 如果RAM小于1GB，Swap大小固定为2GB（2048MB）
        SWAP_SIZE_MB=2048
        
        print_message "系统内存小于1GB，建议的Swap大小为：$SWAP_SIZE_MB MB"
    fi

    # 创建Swap文件（如果文件已经存在，先删除它）
    SWAP_FILE="/swapfile"
    if [ -f "$SWAP_FILE" ]; then
        print_message "Swap文件已经存在，删除现有的文件..."
        sudo swapoff "$SWAP_FILE"  # 先关闭当前的swap文件
        sudo rm "$SWAP_FILE"  # 删除旧文件
    fi

    # 创建新的Swap文件
    print_message "正在创建$SWAP_SIZE_MB MB大小的Swap文件..."
    sudo fallocate -l "${SWAP_SIZE_MB}M" "$SWAP_FILE"

    # 设置正确的权限
    sudo chmod 600 "$SWAP_FILE"

    # 格式化Swap文件
    sudo mkswap "$SWAP_FILE"

    # 启用Swap
    sudo swapon "$SWAP_FILE"

    # 确保开机时自动挂载Swap文件
    if ! grep -q "$SWAP_FILE" /etc/fstab; then
        echo "$SWAP_FILE none swap sw 0 0" | sudo tee -a /etc/fstab
    fi

    print_message "Swap文件已启用，并且会在启动时自动挂载。"
}

# 配置VNC
install_vnc() {
    print_message "VNC Install V1.0"

    # ----- 1. 安装并配置VNC服务 -----
    print_message "Step 1: Install vino(1/5)"
    sudo apt install vino -y 

    # -----  2. 开启Vino使能开关 -----
    print_message "Step 2: Enable VNC Server(2/5)"
    sudo ln -s /usr/lib/systemd/user/vino-server.service /usr/lib/systemd/user/graphical-session.target.wants/vino-server.service
    sudo ln -s ../vino-server.service /usr/lib/systemd/user/graphical-session.target.wants

    # 配置VNC server:
    gsettings set org.gnome.Vino prompt-enabled false
    gsettings set org.gnome.Vino require-encryption false

    # 末尾`<\schema>`插入
    sudo sed -i '/<\/schema>/i\<key name='"'"'enabled'"'"' type='"'"'b'"'"'>  \
    <summary>Enable remote access to the desktop</summary>  \
    <description>  \
        If true, allows remote access to the desktop via the RFB  \
        protocol. Users on remote machines may then connect to the  \
        desktop using a VNC viewer.  \
    </description>  \
    <default>false</default>  \
    </key> \ 
    ' /usr/share/glib-2.0/schemas/org.gnome.Vino.gschema.xml

    # ----- 完成替换org.gnome.Vino.gschema.xml文件 -----
    # 重新编译
    sudo glib-compile-schemas /usr/share/glib-2.0/schemas

    # 开启VINO
    gsettings set org.gnome.Vino enabled true

    # ----- 3. 设置VNC登录密码 -----
    print_message "Step 3: Set VNC Password(3/5)"
    PASSWORD=$(whiptail --title "VNC Password Input" --passwordbox "Enter your password and choose Ok to continue." 10 60 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
        gsettings set org.gnome.Vino authentication-methods "['vnc']"
        gsettings set org.gnome.Vino vnc-password "$(echo -n "$PASSWORD" | base64)"
        print_message "Your VNC password is:" $PASSWORD
    else
        print_message "You Chose Cancel."
    fi

    # ----- 4. 设置开机自启动VNC Server -----
    print_message "Step 4: Set VNC Autorun(4/5)"
    mkdir -p ~/.config/autostart

    # 使用echo按行写入
    echo "[Desktop Entry]" > ~/.config/autostart/vino-server.desktop
    echo "Type=Application" >> ~/.config/autostart/vino-server.desktop
    echo "Name=Vino VNC server" >> ~/.config/autostart/vino-server.desktop
    echo "Exec=/usr/lib/vino/vino-server" >> ~/.config/autostart/vino-server.desktop

    # ----- 5. 完成安装 -----
    print_message "Step 5: VNC Setup Completed(5/5)"
    print_message "VNC server has been installed and configured."
    print_message "You can now connect to your machine remotely using a VNC viewer."
}

# 配置系统工具
install_system_tools() {
    print_message "安装系统工具"

    # 安装JTOP
    sudo -H pip3 install jetson-stats

    # 安装Indicator Sysmonitor
    sudo add-apt-repository ppa:fossfreedom/indicator-sysmonitor -y
    sudo apt-get update
    sudo apt-get install indicator-sysmonitor -y

    # 安装磁盘工具GParted
    sudo apt install -y gparted

    # 安装终端工具Terminator
    sudo add-apt-repository ppa:gnome-terminator -y
    sudo apt update
    sudo apt install -y terminator

    # 设置为默认终端
    # gsettings set org.gnome.desktop.default-applications.terminal exec /usr/bin/terminator
    # gsettings set org.gnome.desktop.default-applications.terminal exec-arg "-x"

    # 换回默认设置
    # gsettings reset org.gnome.desktop.default-applications.terminal exec
    # gsettings reset org.gnome.desktop.default-applications.terminal exec-arg
}

# 安装Jetson Fan Control（仅针对Jetson Nano或Jetson TX2）
install_jetson_fan_control() {
    # 获取当前设备的型号
    device_model=$(cat /sys/firmware/devicetree/base/model)

    # 检查是否为 Jetson Nano 或 Jetson TX2
    if [[ "$device_model" == *"NVIDIA Jetson Nano"* ]] || [[ "$device_model" == *"NVIDIA Jetson TX2"* ]]; then
        echo "当前设备是 $device_model，执行Jetson风扇控制安装"

        # 安装Jetson Fan Control
        git clone https://github.com/Pyrestone/jetson-fan-ctl.git ~/jetson-fan-ctl
        cd jetson-fan-ctl
        sudo ./install.sh
        # 重启服务
        sudo service automagic-fan restart
        # 查看服务状态
        # sudo service automagic-fan status
        # 删除安装包
        rm -rf ~/jetson-fan-ctl
        # 开机调速风扇开启
        # sudo sh -c 'echo 255 > /sys/devices/pwm-fan/target_pwm'

        # 开机调速风扇关闭
        # sudo sh -c 'echo 0 > /sys/devices/pwm-fan/target_pwm'

    else
        echo "当前设备不是Jetson Nano或Jetson TX2，跳过风扇控制安装"
    fi
}

# 主菜单
main_menu() {
    MENU_OPTIONS="1 系统初始化 2 配置VNC（仅限Ubuntu18/20）3 安装系统工具 4 安装风扇驱动（仅限JetsonNano/TX2）0 退出"
    OPTION=$(whiptail --title "Installation Options" --menu "Choose an option" 15 60 5 $MENU_OPTIONS 3>&1 1>&2 2>&3)

    case $OPTION in
        1)
            # 系统初始化
            system_update
            check_ubuntu_version
            allocate_swap
            ;;
        2)
            # 配置VNC（仅限Ubuntu 18 / 20）
            check_ubuntu_version
            install_vnc
            ;;
        3)
            # 安装系统工具
            install_system_tools
            ;;
        4)
            # 安装风扇驱动（仅限Jetson Nano / TX2）
            install_jetson_fan_control
            ;;
        *)
            print_message "无效选项"
            exit 1
            ;;
    esac
}

# 调用主菜单函数
main_menu
