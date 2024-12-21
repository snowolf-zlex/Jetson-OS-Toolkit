#!/bin/bash

#######################################################
# Install PyTorch And TensorFlow For Jetson Ubuntu20.04
# Date: 2024-04-28
#######################################################

# Function to install system dependencies
install_dependencies() {
  echo ""
  echo "Install Dependencies"
  echo ""
  sudo apt-get update
  sudo apt-get install -y \
    python3-pip \
    pkg-config
  sudo -H pip3 install --upgrade pip
}

# Function to fix file dependencies and install ONNX
fix_dependencies() {
  echo ""
  echo "Fix File Dependencies"
  echo ""
  sleep 1
  python -m pip install onnx
}

# Function to install PyTorch
install_pytorch() {
  echo ""
  echo "Step 2/4 Install PyTorch"
  echo ""
  sleep 1
  sudo apt install -y libopenblas-dev
  echo ""
  echo "Download PyTorch package"
  echo ""
  cd ~/Downloads
  wget --no-check-certificate https://developer.download.nvidia.cn/compute/redist/jp/v512/pytorch/torch-2.1.0a0+41361538.nv23.06-cp38-cp38-linux_aarch64.whl
  echo ""
  echo "Install PyTorch"
  echo ""
  sleep 1
  python3 -m pip install --verbose --no-cache-dir torch-2.1.0a0+41361538.nv23.06-cp38-cp38-linux_aarch64.whl
}

# Function to install TorchVision
install_torchvision() {
  echo ""
  echo "Complie And Install TorchVision"
  echo ""
  sleep 1
  python3 -m pip install --user setuptools wheel
  git clone --branch v0.16.0 https://github.com/pytorch/vision torchvision
  cd torchvision
  export BUILD_VERSION=0.16.0
  python3 setup.py bdist_wheel
  python3 -m pip install dist/torchvision-0.16.0-cp38-cp38-linux_aarch64.whl
  #python3 setup.py install --user
}

# Function to install TensorFlow
install_tensorflow() {
  echo ""
  echo "Step 3/4 Install TensorFlow"
  echo ""
  sleep 1
  echo "Install Dependencies For TensorFlow"
  sudo apt install -y \
    libhdf5-serial-dev \
    hdf5-tools \
    libhdf5-dev \
    zlib1g-dev \
    zip \
    libjpeg8-dev \
    liblapack-dev \
    libblas-dev \
    gfortran
  # Clean up unused packages
  sudo apt autoremove -y
  # Install Python dependencies
  python -m pip install h5py onnx
  echo "Download TensorFlow package"
  cd ~/Downloads
  wget --no-check-certificate https://developer.download.nvidia.cn/compute/redist/jp/v512/tensorflow/tensorflow-2.12.0+nv23.06-cp38-cp38-linux_aarch64.whl
  echo "Install TensorFlow"
  python3 -m pip install --verbose tensorflow-2.12.0+nv23.06-cp38-cp38-linux_aarch64.whl
}

# Function to verify installations
verify_installation() {
  echo ""
  echo "Step 4/4 Verify"
  echo ""
  sleep 1
  echo "Verify PyTorch"
  python3 -c "import torch; print('PyTorch GPU Available: ', torch.cuda.is_available())"
  echo ""
  echo "Verify TensorFlow"
  python3 -c "import os; os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'; import tensorflow as tf; print('TensorFlow GPU Available: ', len(tf.config.list_physical_devices('GPU')) > 0)"
}

# Main installation workflow
main() {
  echo ""
  echo "Step 1/4 Prepare PyTorch And TensorFlow"
  echo ""
  sleep 1
  install_dependencies
  fix_dependencies
  install_pytorch
  install_torchvision
  install_tensorflow
  verify_installation
}

# Call the main function
main
