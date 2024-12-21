#!/bin/bash

# 输入：torch版本（如 1.13.0）
torch_version=$1

# 去除torch版本号的最后一位
# 通过切割版本号，只保留前两位（如 1.13.0 -> 1.13）
torch_version_prefix=$(echo $torch_version | cut -d '.' -f1,2)

# 读取版本依赖关系文件
while IFS=" -> " read -r torch_version_range torchvision_version_range; do
    # 过滤掉注释行
    if [[ "$torch_version_range" =~ ^#.* ]]; then
        continue
    fi

    # 提取torch版本和python版本范围
    torch_version_regex=$(echo $torch_version_range | cut -d ' ' -f1)
    python_range=$(echo $torchvision_version_range | sed 's/.*(\(.*\))/\1/')

    # 检查是否匹配torch版本
    if [[ $torch_version_prefix == $torch_version_regex || $torch_version_prefix == $torch_version_range ]]; then
        # 获取python版本范围
        python_min_version=$(echo $python_range | cut -d ',' -f1 | sed 's/^[ \t]*//g')
        python_max_version=$(echo $python_range | cut -d ',' -f2 | sed 's/^[ \t]*//g')

        echo "For torch $torch_version, install torchvision $torchvision_version_range."
        exit 0
    fi
done < torch_versions.txt

echo "No compatible torchvision version for torch $torch_version."
