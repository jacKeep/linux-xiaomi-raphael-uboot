#!/bin/bash
set -e

DEBIAN_VERSION="${DEBIAN_VERSION:-}"
UBUNTU_VERSION="${UBUNTU_VERSION:-}"
FEDORA_VERSION="${FEDORA_VERSION:-44}"
SYSTEM_TYPE="${SYSTEM_TYPE:-ubuntu-server}"
DEBIAN_TSUNING_MIRROR="${DEBIAN_TSUNING_MIRROR:-https://mirrors.tuna.tsinghua.edu.cn/debian/}"
UBUNTU_TSUNING_MIRROR="${UBUNTU_TSUNING_MIRROR:-https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/}"
FEDORA_BASE_MIRROR="${FEDORA_BASE_MIRROR:-https://mirrors.tuna.tsinghua.edu.cn/fedora/releases/${FEDORA_VERSION}/Everything/aarch64/os/}"
FEDORA_UPDATES_MIRROR="${FEDORA_UPDATES_MIRROR:-https://mirrors.tuna.tsinghua.edu.cn/fedora/updates/${FEDORA_VERSION}/Everything/aarch64/}"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [16] 🧹 清理临时文件"

export DEBIAN_FRONTEND=noninteractive

if [[ "$SYSTEM_TYPE" == *"fedora-"* ]]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [16]   └─ 清理 dnf 缓存"
    chroot rootdir dnf -y clean all
else
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [16]   └─ 清理 apt-get 缓存"
    chroot rootdir apt-get -q clean
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [16]   └─ 重命名内核文件"
mv rootdir/boot/initrd.img-* rootdir/boot/initramfs 2>/dev/null || true
mv rootdir/boot/initramfs-*.img rootdir/boot/initramfs 2>/dev/null || true
mv rootdir/boot/vmlinuz-* rootdir/boot/linux.efi 2>/dev/null || true

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [16]   └─ 清理固件文件"
rm -f rootdir/lib/firmware/reg* 2>/dev/null || true

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [16]   └─ 配置清华源"
if [[ "$SYSTEM_TYPE" == *"fedora-"* ]]; then
    mkdir -p rootdir/etc/yum.repos.d
    cat > rootdir/etc/yum.repos.d/fedora.repo << EOF
[fedora]
name=Fedora ${FEDORA_VERSION} - Base
baseurl=${FEDORA_BASE_MIRROR}
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-${FEDORA_VERSION}-aarch64

[updates]
name=Fedora ${FEDORA_VERSION} - Updates
baseurl=${FEDORA_UPDATES_MIRROR}
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-${FEDORA_VERSION}-aarch64
EOF
elif [[ "$SYSTEM_TYPE" == *"debian-"* ]]; then
    if [ -n "$DEBIAN_VERSION" ]; then
        cat > rootdir/etc/apt/sources.list << EOF
deb $DEBIAN_TSUNING_MIRROR $DEBIAN_VERSION main contrib non-free non-free-firmware
deb $DEBIAN_TSUNING_MIRROR $DEBIAN_VERSION-updates main contrib non-free non-free-firmware
deb $DEBIAN_TSUNING_MIRROR $DEBIAN_VERSION-backports main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security $DEBIAN_VERSION-security main contrib non-free non-free-firmware
EOF
    fi
elif [[ "$SYSTEM_TYPE" == *"ubuntu-"* ]]; then
    if [ -n "$UBUNTU_VERSION" ]; then
        cat > rootdir/etc/apt/sources.list << EOF
deb $UBUNTU_TSUNING_MIRROR $UBUNTU_VERSION main restricted universe multiverse
deb $UBUNTU_TSUNING_MIRROR $UBUNTU_VERSION-updates main restricted universe multiverse
deb $UBUNTU_TSUNING_MIRROR $UBUNTU_VERSION-backports main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports $UBUNTU_VERSION-security main restricted universe multiverse
EOF
    fi
fi

echo ""
echo "========================================== 📋 配置文件预览 =========================================="

echo ""
if [[ "$SYSTEM_TYPE" == *"fedora-"* ]]; then
    echo "[/etc/yum.repos.d/fedora.repo]"
    cat rootdir/etc/yum.repos.d/fedora.repo 2>/dev/null || echo "(文件不存在)"
else
    echo "[/etc/apt/sources.list]"
    cat rootdir/etc/apt/sources.list 2>/dev/null || echo "(文件不存在)"
fi

echo ""
echo "[/etc/netplan/01-network-manager-all.yaml]"
cat rootdir/etc/netplan/01-network-manager-all.yaml 2>/dev/null || echo "(文件不存在)"

echo ""
echo "[/etc/systemd/system/usb-ncm.service]"
cat rootdir/etc/systemd/system/usb-ncm.service 2>/dev/null || echo "(文件不存在)"

echo ""
echo "[/etc/dnsmasq.d/usb-ncm.conf]"
cat rootdir/etc/dnsmasq.d/usb-ncm.conf 2>/dev/null || echo "(文件不存在)"

echo ""
echo "[/etc/fstab]"
cat rootdir/etc/fstab 2>/dev/null || echo "(文件不存在)"

echo ""
echo "[/etc/default/zramswap]"
cat rootdir/etc/default/zramswap 2>/dev/null || echo "(文件不存在)"

echo ""
echo "========================================== 📋 配置文件预览结束 =========================================="

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [16] ✅ 清理完成"
