#!/bin/bash
# VMware共享文件夹挂载脚本

echo "=== 设置VMware共享文件夹 ==="
echo ""

# 检查是否已挂载
if mount | grep -q "hgfs.*Desktop"; then
    echo "✓ 共享文件夹已挂载"
    mount | grep "hgfs.*Desktop"
    exit 0
fi

# 创建挂载点
echo "创建挂载点..."
sudo mkdir -p /mnt/hgfs/Desktop

# 挂载共享文件夹
echo "挂载共享文件夹..."
sudo vmhgfs-fuse .host:/Desktop /mnt/hgfs/Desktop -o subtype=vmhgfs-fuse,allow_other

# 检查是否成功
if [ $? -eq 0 ]; then
    echo "✓ 共享文件夹挂载成功！"
    echo ""
    echo "挂载路径: /mnt/hgfs/Desktop"
    echo "Windows路径映射: C:\\Users\\Lenovo\\Desktop -> /mnt/hgfs/Desktop/Users/Lenovo/Desktop"
    echo ""
    echo "现在可以运行 'make sim' 自动同步波形文件了"
else
    echo "✗ 挂载失败，请检查："
    echo "  1. VMware Tools 是否已安装"
    echo "  2. 共享文件夹是否已在VMware中配置"
    echo "  3. 是否有sudo权限"
fi

