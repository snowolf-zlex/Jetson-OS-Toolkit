#!/bin/bash

# 脚本说明：本地编译PyTorch、Torchvision
# 创建时间：2025-02-19

# 配置参数
TORCH_VERSION="v1.8.2"
TORCHVISION_VERSION="v0.9.2"

# 安装系统依赖
install_dependencies() {
    echo "[INFO] 正在安装系统依赖..."
    sudo apt-get update && sudo apt-get install -y \
        cmake \
        ninja-build \
        git \
        g++ \
        python3-dev \
        libopenblas-dev \
        libopenmpi-dev \
        openmpi-bin \
        libjpeg-dev \
        zlib1g-dev \
        libjpeg-dev \
        python3-pip \
        python3-venv
}

# 配置 Python 环境
setup_python() {
    echo "[INFO] 配置 Python 环境..."
    pip install -U setuptools wheel
    pip install -U numpy pyyaml ninja
}

# 编译并安装Torch
build_torch() {
    echo "[INFO] 克隆PyTorch..."
    git clone --recursive https://github.com/pytorch/pytorch
    cd pytorch
    git checkout $TORCH_VERSION  # 切换版本
    git submodule sync
    git submodule update --init --recursive  # 确保子模块正确初始化

    export USE_MKLDNN=1          # 启用 Intel MKL-DNN 加速
    export USE_OPENMP=1          # 启用 OpenMP 并行
    export USE_NINJA=1           # 使用 Ninja 构建系统
    export BUILD_TEST=0          # 跳过测试以加快编译速度

    # 清理历史缓存
    python3 setup.py clean

    echo "[INFO] 编译Torch安装包..."
    # 构建 .whl 文件
    python3 setup.py bdist_wheel

    echo "[INFO] 安装Torch..."
    # 安装 whl 文件
    local whl_file=$(find dist -name "*.whl")
    echo "[INFO] 安装 Torch: $whl_file"
    pip3 install "$whl_file"
}

# 编译并安装Torchvision
build_torchvision() {
    echo "[INFO] 克隆Torchvision..."
    git clone --recursive https://github.com/pytorch/vision torchvision
    cd torchvision
    git checkout $TORCHVISION_VERSION

    # 设置版本环境变量
    export BUILD_VERSION=${TORCHVISION_VERSION#"v"}  # 去掉前缀v

    # 清理历史缓存
    python3 setup.py clean

    echo "[INFO] 编译Torchvision安装包..."
    # 构建 .whl 文件
    python3 setup.py bdist_wheel

    echo "[INFO] 安装Torchvision..."
    # 安装 whl 文件
    local whl_file=$(find dist -name "*.whl")
    echo "[INFO] 安装 TorchVision: $whl_file"
    pip3 install "$whl_file"
}

# 验证安装
verify_installation() {
    echo "[INFO] 验证安装..."
    python3 - <<EOF
import torch, torchvision
print(f"PyTorch 版本: {torch.__version__}")
print(f"TorchVision 版本: {torchvision.__version__}")
print(f"CUDA 可用: {torch.cuda.is_available()}")
if torch.cuda.is_available():
    print(f"[INFO] GPU 设备: {torch.cuda.get_device_name(0)}")
else:
    print("[WARNING] 未检测到 GPU 加速支持！")
EOF
}

# 主执行流程
main() {
    # 初始化环境
    install_dependencies
    setup_python

    # 构建 PyTorch
    build_torch

    # 构建 TorchVision
    build_torchvision

    # 验证结果
    verify_installation

    echo "[SUCCESS] 所有步骤已完成！"
}

# 执行主函数
main
