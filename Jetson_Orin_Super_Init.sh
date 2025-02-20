
echo "下载内核"

wget https://developer.nvidia.com/downloads/embedded/l4t/r36_release_v4.3/release/Jetson_Linux_r36.4.3_aarch64.tbz2
wget https://developer.nvidia.com/downloads/embedded/l4t/r36_release_v4.3/release/Tegra_Linux_Sample-Root-Filesystem_r36.4.3_aarch64.tbz2

echo "解压内核"
tar xf Jetson_Linux_r36.4.3_aarch64.tbz2 
sudo tar xpf Tegra_Linux_Sample-Root-Filesystem_r36.4.3_aarch64.tbz2 -C Linux_for_Tegra/rootfs/
cd Linux_for_Tegra/

echo "准备依赖包"
sudo ./tools/l4t_flash_prerequisites.sh

echo "镜像文件准备"
sudo ./apply_binaries.sh

echo "系统烧录 SSD"

sudo ./tools/kernel_flash/l4t_initrd_flash.sh \
  --external-device nvme0n1p1 \
  -c tools/kernel_flash/flash_l4t_t234_nvme.xml \
  -p "-c bootloader/generic/cfg/flash_t234_qspi.xml" \
  --showlogs --network usb0 jetson-orin-nano-devkit-super internal

echo "系统烧录-USB Disk"

flash_to_UDisk(){
sudo ./tools/kernel_flash/l4t_initrd_flash.sh \
  --external-device sda1 \
  -c tools/kernel_flash/flash_l4t_t234_nvme.xml \
  -p "-c bootloader/generic/cfg/flash_t234_qspi.xml" \
  --showlogs --network usb0 jetson-orin-nano-devkit-super internal
}
