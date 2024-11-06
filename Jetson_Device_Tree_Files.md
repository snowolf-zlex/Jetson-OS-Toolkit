# Jetson 设备树文件

## Jetson设备树文件简介

Jetson 设备的设备树文件（Device Tree Blob，简称 DTB 文件）通常位于系统的 `/boot/dtb/` 目录下。设备树文件用于在 Linux 内核启动时描述硬件信息，确保系统能够正确识别并初始化硬件组件（如 CPU、GPU、内存、外设等）。

在 Jetson 系统中，设备树文件通常随着系统的启动被加载，它们为内核提供硬件相关的信息，帮助操作系统与硬件进行交互。

## 设备树文件命名结构

Jetson 设备的设备树文件命名遵循一定的结构格式。一般的命名规则如下：

```txt
<chip-name>-<platform-name>-<board-id>-<revision>.dtb
```

### 1. **`<chip-name>`**：硬件平台的芯片型号
   - 例如：
     - `tegra210`：Jetson Nano
     - `tegra186`：Jetson TX2
     - `tegra194`：Jetson Xavier NX 和 Jetson AGX Xavier
     - `tegra234`：Jetson Orin 系列

### 2. **`<platform-name>`**：平台的代号或设备名称
   - 例如：
     - `p2597`：Jetson Nano 2GB
     - `p2598`：Jetson Nano 4GB
     - `p3668`：Jetson Xavier NX
     - `p3737`：Jetson Orin 系列
     - `p2771`：Jetson TX2 系列

### 3. **`<board-id>`**：板卡硬件 ID 或型号
   - 用于标识特定的硬件版本或修订。
   - 例如：
     - `a00-00`：硬件初始版本
     - `a01-00`：硬件修订版本

### 4. **`<revision>`**：设备树文件的修订版本
   - 表示该设备树文件的版本或修订信息，通常以 `-00`、`-01` 等形式出现。

## Jetson 产品线设备树命名

以下是 Jetson 各产品线设备树文件的命名表格：

| **Jetson 设备型号**            | **设备树文件名**                                            |
|-------------------------------|-------------------------------------------------------------|
| **Jetson Nano 2GB**            | `tegra210-p2597-2180-a00-00.dtb`                            |
| **Jetson Nano 4GB**            | `tegra210-p2598-2180-a00-00.dtb`                            |
| **Jetson Xavier NX 8GB**       | `tegra194-p3668-0000-p3509-0000.dtb`                        |
| **Jetson Xavier NX 16GB**      | `tegra194-p3668-0000-p3509-0001.dtb`                        |
| **Jetson AGX Xavier 32GB**     | `tegra194-p3660-0000-p3509-0000.dtb`                        |
| **Jetson TX2 4GB**             | `tegra186-p2771-0000.dtb`                                   |
| **Jetson TX2 8GB**             | `tegra186-p2771-0001.dtb`                                   |
| **Jetson Orin Nano**           | `tegra234-p3668-0000-p3509-0000.dtb`                        |
| **Jetson Orin NX**             | `tegra234-p3668-0000-p3509-0001.dtb`                        |
| **Jetson AGX Orin**            | `tegra234-p3737-0000-p3509-0000.dtb`                        |
| **Jetson Orin 64GB**           | `tegra234-p3737-0000-p3509-0001.dtb`                        |
| **Jetson TX1**                 | `tegra124-p1470-0000.dtb`                                   |
| **Jetson TX2i**                | `tegra186-p2771-0000-p3509-0000.dtb`                        |
| **Jetson Xavier AGX Dev Kit**  | `tegra194-p3660-0000-p3509-0000.dtb`                        |
| **Jetson Orin Dev Kit**        | `tegra234-p3737-0000-p3509-0000.dtb`                        |

## 设备树命名说明

- **`tegra`**：代表 NVIDIA Tegra 系列芯片，用于 Jetson 设备。
- **`<platform-name>`**：表示具体硬件平台的代号，如 `p2597` 表示 Jetson Nano 2GB，`p3668` 表示 Jetson Xavier NX。
- **`<board-id>`**：表示特定硬件板卡的版本，通常通过数字和字母标识硬件的修订或型号。
- **`<revision>`**：设备树文件的版本号，用于区分不同版本的设备树。

设备树文件对于系统的启动过程至关重要，能够确保硬件的正确初始化。不同版本的 Jetson 设备通常会有不同的设备树文件，以适配不同的硬件配置和版本。

## 设备树启动配置

extlinux.conf 是 extlinux bootloader 使用的配置文件，它通常用于 Linux 系统的启动配置，特别是在基于 EXT4 文件系统 或类似文件系统的设备中（如 Jetson 设备）。这个文件与 U-Boot 或其他引导加载程序配合使用，用于定义系统如何引导，包括内核镜像、设备树、启动参数等。

在 Jetson 设备上，extlinux.conf 是用于配置和启动 Linux 内核的关键文件，特别是在 Jetson 使用 L4T（Linux for Tegra）系统时。它主要用来设置系统引导时所需的参数，并通过 extlinux 引导程序来加载内核。

通过配置extlinux.conf可以使得Jetson设备以不同的设备树启动，以便识别不同的硬件环境，如第三方载板的USB设备、Jetson不同的内存等。

设备树dtb文件位于`/boot/dtb/`，`extlinux.conf`文件位于`/boot/extlinux/`路径下。

Jetson通过配置`extlinux.conf`文件加载该设备树文件，注意下文关键字`FDT`。

```txt
TIMEOUT 30
DEFAULT primary

MENU TITLE Jetson Boot Options

LABEL primary
    MENU LABEL Jetson Nano 4GB (Primary Kernel)
    LINUX /boot/Image
    FDT /boot/dtb/tegra210-p3448-0000-p3449-0000-b00.dtb
    INITRD /boot/initrd
    APPEND ${cbootargs} quiet root=/dev/mmcblk0p1 rw rootwait rootfstype=ext4 console=ttyS0,115200n8 console=tty0 fbcon=map:0 net.ifnames=0

```

***如果要使用第三方载板，需要反编译或替换对应的设备树文件***
