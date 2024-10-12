# Jetson系统备份

因为**磁盘安全备份需要1:1复刻**，所以需要准备空闲容量大于Jetson存储设备的磁盘。

### 支持范围

- 所有Jetson可移动存储设备及不可移动存储设备

### 准备须知

以下两种方案任选其一：
- 预装Ubuntu的PC主机，使用本机硬盘或外置硬盘备份
- Jetson主机，使用外置硬盘或使用内置副硬盘备份

### 存储要求

1. 硬盘容量需要大于Jetson存储设备容量
2. 磁盘格式最好是linux能写入的格式，如ext4
3. 使用USB3.0接口与Jetson设备连接，保证速度

### 备份方案

1. Jetson设备自备份：在Jetson设备上执行脚本，将系统盘镜像备份至其它硬盘，如外置硬盘上。
2. Jetson设备存储卡外接Ubuntu主机备份：将Jetson设备存储卡（SD卡、SSD硬盘）外接至Ubuntu上，执行脚本备份。

### 脚本执行

#### 1. 克隆脚本，并赋予执行权限

``` shell
git clone https://github.com/snowolf-zlex/Jetson-OS-Toolkit#:~:text=2%20Commits-,Jetson_Device_Backup.sh,-Create%20Jetson_Device_Backup.sh
chmod +x Jetson_Device_Backup.sh
```

#### 2. 执行脚本，确认要备份的磁盘

``` shell
./Jetson_Device_Backup.sh
```

> 检测到Linux操作系统，以下是当前磁盘列表：  
> NAME    MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT  
> loop0     7:0    0    16M  1 loop  
> sda       8:0    1  59.8G  0 disk 
> zram0   251:0    0 968.9M  0 disk [SWAP]  
> zram1   251:1    0 968.9M  0 disk [SWAP]  
> zram2   251:2    0 968.9M  0 disk [SWAP]  
> zram3   251:3    0 968.9M  0 disk [SWAP]  
> zram4   251:4    0 968.9M  0 disk [SWAP]  
> zram5   251:5    0 968.9M  0 disk [SWAP]  
> zram6   251:6    0 968.9M  0 disk [SWAP]  
> zram7   251:7    0 968.9M  0 disk [SWAP]  
> nvme0n1 259:0    0 931.5G  0 disk  

接下来需要选择要备份的磁盘，假如如果我们要备份nvme，可以根据提示，键入完成磁盘路径（/dev/nvme0n1）。

> 请输入要备份的Jetson设备地址 (例如 /dev/sdb): /dev/nvme0n1

#### 3. 确认备份镜像文件名

现在需要根据提示键入镜像文件名称，如Jetson_Orin_Nano_JP514_20231010.img，并键入y确认

> 请输入备份文件名称 (例如 Jetson_Image_20230402): Jetson_Orin_Nano_JP514_20231010
> 确认备份文件名为：Jetson_Orin_Nano_JP514_20231010.img，是否继续？(y/n): y

**注意：镜像文件将存储在当前脚本所在路径下**

#### 4. 进行镜像备份动作

> 开始将 /dev/nvme0n1 备份到 ./Jetson_Orin_Nano_JP514_20231010.img ...

#### 5. 计算SHA1

> 计算镜像文件的SHA1校验和...

#### 6. 完成备份

> 备份完成，镜像文件路径: ./Jetson_Orin_Nano_JP514_20231010.img 
