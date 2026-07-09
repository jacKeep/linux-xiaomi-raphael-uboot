#!/bin/bash
set -e

FEDORA_VERSION="${FEDORA_VERSION:-44}"
FEDORA_BASE_MIRROR="${FEDORA_BASE_MIRROR:-https://mirrors.tuna.tsinghua.edu.cn/fedora/releases/${FEDORA_VERSION}/Everything/aarch64/os/}"
FEDORA_UPDATES_MIRROR="${FEDORA_UPDATES_MIRROR:-https://mirrors.tuna.tsinghua.edu.cn/fedora/updates/${FEDORA_VERSION}/Everything/aarch64/}"

# Fedora 分支：配置 dnf 软件源
if [[ "$SYSTEM_TYPE" == *"fedora-"* ]]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [05] 📡 配置 Fedora $FEDORA_VERSION dnf 源并更新缓存"

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

    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [05]   └─ 执行 dnf makecache..."
    chroot rootdir dnf -y makecache

    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [05] ✅ dnf 源配置完成"
    exit 0
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [05] 📡 更新 apt 源并更新缓存"

export DEBIAN_FRONTEND=noninteractive

cp rootdir/etc/apt/sources.list rootdir/etc/apt/sources.list.bak

if [[ "$SYSTEM_TYPE" == *"ubuntu-"* ]]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [05]   └─ 配置 Ubuntu $UBUNTU_VERSION 源"
    cat > rootdir/etc/apt/sources.list << EOF
deb http://ports.ubuntu.com/ubuntu-ports/ $UBUNTU_VERSION main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ $UBUNTU_VERSION-updates main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ $UBUNTU_VERSION-backports main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ $UBUNTU_VERSION-security main restricted universe multiverse
EOF
else
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [05]   └─ 配置 Debian $DEBIAN_VERSION 源"
    cat > rootdir/etc/apt/sources.list << EOF
deb http://deb.debian.org/debian/ $DEBIAN_VERSION main contrib non-free non-free-firmware
deb http://deb.debian.org/debian/ $DEBIAN_VERSION-updates main contrib non-free non-free-firmware
deb http://deb.debian.org/debian/ $DEBIAN_VERSION-backports main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security $DEBIAN_VERSION-security main contrib non-free non-free-firmware
EOF
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [05]   └─ 执行 apt-get update..."
chroot rootdir apt-get -q update

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [05] ✅ apt 配置完成"