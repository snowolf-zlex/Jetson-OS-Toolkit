
⏺ Jetson Nano eMMC 克隆指南

  前提条件

  - 一台 Linux 主机（x86_64，安装了 JetPack/L4T）
  - USB 数据线连接 Jetson Nano 和主机
  - L4T 版本必须匹配（你的是 r32.6）

  ---
  第一步：主机上准备 L4T 工具包

  如果主机上已有 SDK Manager 安装的 L4T：

  # 找到 L4T 目录
```bash
  ls ~/nvidia/nvidia_sdk/JetPack_*/Linux_for_Tegra/flash.sh
```
  # 如果没有，下载对应版本
  # 从 https://developer.nvidia.com/embedded/linux-tegra 下载 L4T 32.6.1
```bash
  tar xf Jetson_Linux_R32.6.1_aarch64.tbz2
  cd Linux_for_Tegra
```
  第二步：Jetson Nano 进入 Recovery 模式

  1. 给 Jetson Nano 断电
  2. 用 USB 线连接 Jetson Nano 的 Micro-USB 口和主机
  3. 短接 Recovery 引脚（或按住 Recovery 键）
  4. 给 Jetson Nano 上电
  5. 松开 Recovery 键

  主机上确认设备已识别：
```bash
  lsusb | grep -i nvidia
```
  # 应该显示: NVIDIA Corp. APX  ID 0955:7f21

  第三步：克隆 eMMC

  在主机上执行：
```bash
  cd Linux_for_Tegra
```
  # 克隆 APP 分区（根文件系统）
```bash  
  sudo ./flash.sh -r -k APP -G backup.img jetson-nano-emmc mmcblk0p1
```
  参数说明：
  - -r — 跳过重建系统镜像
  - -k APP — 只克隆 APP 分区（rootfs）
  - -G backup.img — 输出克隆镜像
  - jetson-nano-emmc — eMMC 版板型标识

  会生成两个文件：
  - backup.img — 稀疏镜像（较小，推荐用于烧录）
  - backup.img.raw — 原始镜像（14GB，完整）

  第四步：烧录到新设备
```bash
  cd Linux_for_Tegra
```
  # 备份原有系统镜像
```bash
  sudo mv bootloader/system.img bootloader/system.img.bak
```
  # 用克隆镜像替换
```bash
  sudo cp backup.img bootloader/system.img
```
  # 新设备进入 Recovery 模式后，执行烧录
```bash
  sudo ./flash.sh -r jetson-nano-emmc mmcblk0p1
```
  注意：烧录时的 -r 不带 -k APP，这样会同时烧录启动分区和设备树。

  ---
  完整流程总结

  源设备 → Recovery 模式 → USB 连主机 → flash.sh -r -k APP -G clone → 得到镜像
  新设备 → Recovery 模式 → USB 连主机 → flash.sh -r → 烧入镜像
