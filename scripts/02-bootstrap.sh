#!/bin/bash
set -e

DEBIAN_VERSION="${DEBIAN_VERSION:-trixie}"
UBUNTU_VERSION="${UBUNTU_VERSION:-resolute}"
FEDORA_VERSION="${FEDORA_VERSION:-44}"
FEDORA_BASE_MIRROR="${FEDORA_BASE_MIRROR:-https://mirrors.tuna.tsinghua.edu.cn/fedora/releases/${FEDORA_VERSION}/Everything/aarch64/os/}"
FEDORA_UPDATES_MIRROR="${FEDORA_UPDATES_MIRROR:-https://mirrors.tuna.tsinghua.edu.cn/fedora/updates/${FEDORA_VERSION}/Everything/aarch64/}"
BOOT_IMG="${BOOT_IMG:-xiaomi-k20pro-boot.img}"
SYSTEM_TYPE="${SYSTEM_TYPE:-ubuntu-server}"
BOOTSTRAP_TOOL="${BOOTSTRAP_TOOL:-mmdebstrap}"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [02] 🚀 安装基础系统"

if [[ "$SYSTEM_TYPE" == *"fedora-"* ]]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [02]   └─ 使用 dnf installroot 构建 Fedora $FEDORA_VERSION 🎩"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [02]   └─ 开始 bootstrap (这可能需要几分钟...)"
    # dnf 的 --installroot 要求绝对路径
    ROOTDIR="$(pwd)/rootdir"

    # dnf installroot 安装包时会运行 scriptlet（如 systemd-tmpfiles），需要 /proc /sys 才能正常工作，
    # 否则会产生大量 "/proc/ is not mounted" 警告。这里临时 bind-mount /proc /sys（跳过 /dev，避免
    # tmpfiles 操作宿主 /dev 设备节点），dnf 结束后立即 umount，防止 03-mount-dev.sh 重复挂载导致堆叠。
    mkdir -p "${ROOTDIR}/proc" "${ROOTDIR}/sys"

    _fedora_umount_pseudofs() {
        umount "${ROOTDIR}/sys" 2>/dev/null || true
        umount "${ROOTDIR}/proc" 2>/dev/null || true
    }
    # 先注册 trap 再挂载：若某个 mount 失败（set -e 触发退出），trap 仍能清理已挂载项，避免泄漏。
    trap _fedora_umount_pseudofs EXIT

    mount --bind /proc "${ROOTDIR}/proc"
    mount --bind /sys "${ROOTDIR}/sys"

    dnf --installroot="${ROOTDIR}" --releasever="${FEDORA_VERSION}" \
        --setopt=install_weak_deps=False --nogpgcheck \
        --repofrompath=base,"${FEDORA_BASE_MIRROR}" \
        --repofrompath=updates,"${FEDORA_UPDATES_MIRROR}" \
        install -y @core

    # dnf 成功后主动 umount 并解除 trap，避免与后续 03-mount-dev.sh 的挂载堆叠
    _fedora_umount_pseudofs
    trap - EXIT
elif [[ "$SYSTEM_TYPE" == *"debian-"* ]]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [02]   └─ 使用 $BOOTSTRAP_TOOL 构建 Debian $DEBIAN_VERSION 🐧"
    OS_VERSION="$DEBIAN_VERSION"
    MIRROR="http://deb.debian.org/debian/"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [02]   └─ 开始 bootstrap (这可能需要几分钟...)"
    if [ "$BOOTSTRAP_TOOL" = "mmdebstrap" ]; then
        mmdebstrap $OS_VERSION rootdir
    elif [ "$BOOTSTRAP_TOOL" = "debootstrap" ]; then
        debootstrap $OS_VERSION rootdir $MIRROR
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] [02] ❌ 错误: 不支持的构建工具: $BOOTSTRAP_TOOL"
        exit 1
    fi
else
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [02]   └─ 使用 $BOOTSTRAP_TOOL 构建 Ubuntu $UBUNTU_VERSION 🦁"
    OS_VERSION="$UBUNTU_VERSION"
    MIRROR="http://ports.ubuntu.com/ubuntu-ports/"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [02]   └─ 开始 bootstrap (这可能需要几分钟...)"
    if [ "$BOOTSTRAP_TOOL" = "mmdebstrap" ]; then
        mmdebstrap $OS_VERSION rootdir
    elif [ "$BOOTSTRAP_TOOL" = "debootstrap" ]; then
        debootstrap $OS_VERSION rootdir $MIRROR
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] [02] ❌ 错误: 不支持的构建工具: $BOOTSTRAP_TOOL"
        exit 1
    fi
fi

if [ -f "${BOOT_IMG}" ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [02]   └─ 挂载 boot 分区 (${BOOT_IMG}) 📁"
    if mount -o loop ${BOOT_IMG} rootdir/boot 2>&1; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] [02]   └─ Boot 分区挂载成功"
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] [02] ❌ 错误: Boot 分区挂载失败"
        exit 1
    fi
else
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [02] ❌ 错误: ${BOOT_IMG} 不存在"
    exit 1
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [02] ✅ 基础系统安装完成"