#!/bin/bash
# VMware共享文件夹挂载脚本

echo "=== 设置VMware共享文件夹 ==="
echo ""

# 检查是否已挂载
if mount | grep -q "hgfs.*Desktop"; then
    echo "✓ 共享文件夹已挂载"
    mount | grep "hgfs.*Desktop"
    echo ""
    # 即使已挂载，也检查并创建 waveform_check 文件夹
    if [ -d /mnt/hgfs/Desktop ]; then
        echo "检查波形文件同步目录..."
        if [ ! -d /mnt/hgfs/Desktop/waveform_check ]; then
            if sudo mkdir -p /mnt/hgfs/Desktop/waveform_check 2>/dev/null; then
                sudo chmod 777 /mnt/hgfs/Desktop/waveform_check 2>/dev/null || true
                echo "✓ waveform_check 文件夹已创建"
                echo "  路径: /mnt/hgfs/Desktop/waveform_check"
                echo "  Windows路径: C:\\Users\\Lenovo\\Desktop\\waveform_check"
            else
                echo "⚠️  无法创建 waveform_check 文件夹（需要sudo权限）"
                echo "  请运行: sudo mkdir -p /mnt/hgfs/Desktop/waveform_check"
                echo "  或手动在Windows中创建: C:\\Users\\Lenovo\\Desktop\\waveform_check"
            fi
        else
            echo "✓ waveform_check 文件夹已存在"
        fi
    fi
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
    echo "Windows路径映射: C:\\Users\\Lenovo\\Desktop -> /mnt/hgfs/Desktop"
    echo ""
    
    # 创建波形文件同步目录
    echo "创建波形文件同步目录..."
    if sudo mkdir -p /mnt/hgfs/Desktop/waveform_check 2>/dev/null; then
        sudo chmod 777 /mnt/hgfs/Desktop/waveform_check 2>/dev/null || true
        echo "✓ waveform_check 文件夹已创建"
        echo "  路径: /mnt/hgfs/Desktop/waveform_check"
        echo "  Windows路径: C:\\Users\\Lenovo\\Desktop\\waveform_check"
    else
        echo "⚠️  无法创建 waveform_check 文件夹（可能需要手动创建）"
        echo "  请在Windows中手动创建: C:\\Users\\Lenovo\\Desktop\\waveform_check"
    fi
    
    echo ""
    echo "现在可以运行 'make sim' 自动同步波形文件了"
else
    echo "✗ 挂载失败，请检查："
    echo "  1. VMware Tools 是否已安装"
    echo "  2. 共享文件夹是否已在VMware中配置"
    echo "  3. 是否有sudo权限"
fi

