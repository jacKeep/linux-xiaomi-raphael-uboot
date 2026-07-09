#!/bin/bash
set -e

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [14] 🧠 配置 ZRAM Swap"

# Fedora 分支：使用 systemd-zram-generator（Fedora 内置），而非 zram-tools
if [[ "$SYSTEM_TYPE" == *"fedora-"* ]]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [14]   └─ 配置 zram-generator"
    mkdir -p rootdir/etc/systemd
    cat > rootdir/etc/systemd/zram-generator.conf << EOF
[zram0]
zram-size = 10240
compression-algorithm = zstd
swap-priority = 100
EOF
    chroot rootdir systemctl enable systemd-zram-setup@zram0.service 2>/dev/null || true

    echo ""
    echo "[/etc/systemd/zram-generator.conf]"
    cat rootdir/etc/systemd/zram-generator.conf
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [14] ✅ ZRAM 配置完成"
    exit 0
fi

if [ ! -f rootdir/etc/default/zramswap ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [14]   └─ 未找到 /etc/default/zramswap，跳过配置"
    exit 0
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [14]   └─ 调整 zramswap 默认参数"
sed -i \
    -e 's/^ALGO=.*/ALGO=zstd/' \
    -e 's/^PERCENT=.*/# &/' \
    -e 's/^SIZE=.*/SIZE=10240/' \
    rootdir/etc/default/zramswap

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [14]   └─ 启用 zramswap 服务"
chroot rootdir systemctl enable zramswap

echo ""
echo "[/etc/default/zramswap]"
cat rootdir/etc/default/zramswap

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [14] ✅ ZRAM 配置完成"
