#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../config"

. "$CONFIG_DIR/build-config.sh"

SYSTEM_TYPE="${SYSTEM_TYPE:-ubuntu-server}"
DESKTOP_ENV="${DESKTOP_ENV:-}"
DEBIAN_VERSION="${DEBIAN_VERSION:-trixie}"
UBUNTU_VERSION="${UBUNTU_VERSION:-resolute}"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06] 📦 安装软件包"

export DEBIAN_FRONTEND=noninteractive

# ───────────────────────── Fedora 分支 ─────────────────────────
if [[ "$SYSTEM_TYPE" == *"fedora-"* ]]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06]   └─ 更新系统包 (dnf)..."
    chroot rootdir dnf -y upgrade

    BASE_PACKAGES="bash-completion sudo nano openssh-server NetworkManager chrony curl wget tzdata iproute nftables dnsmasq dracut filesystem glibc-langpack-en google-noto-sans-cjk-fonts wqy-microhei-fonts zram-generator"

    DESKTOP_PACKAGES=""
    if [[ "$SYSTEM_TYPE" != *"server"* ]]; then
        case "$DESKTOP_ENV" in
            "kde")
                DESKTOP_PACKAGES="@kde-desktop maliit-keyboard plasma-workspace-wayland sddm"
                ;;
            *)
                DESKTOP_PACKAGES=""
                ;;
        esac
    fi

    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06]   └─ 基础包: $(echo "$BASE_PACKAGES" | tr ' ' ', ')"
    if [ -n "$DESKTOP_PACKAGES" ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06]   └─ 桌面包: $(echo "$DESKTOP_PACKAGES" | tr ' ' ', ')"
    fi

    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06]   └─ 开始安装（这可能需要几分钟...）"
    chroot rootdir dnf -y install $BASE_PACKAGES
    if [ -n "$DESKTOP_PACKAGES" ]; then
        chroot rootdir dnf -y group install kde-desktop 2>/dev/null || chroot rootdir dnf -y install @kde-desktop
        chroot rootdir dnf -y install maliit-keyboard plasma-workspace-wayland sddm
    fi

    # 设备调制解调器包（rmtfs/pd-mapper/tqftpserv）为 postmarketOS/Debian 专属，Fedora 仓库暂无对应包
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06]   └─ 跳过调制解调器包（rmtfs/pd-mapper/tqftpserv，Fedora 暂不可用）"

    # 安装 ALSA 配置（从 .deb 提取配置文件，非 dpkg -i）
    if [ -f "alsa-xiaomi-raphael.deb" ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06]   └─ 安装 ALSA 配置（提取自 .deb）"
        TMP_ALSA=$(mktemp -d)
        dpkg-deb -x alsa-xiaomi-raphael.deb "$TMP_ALSA"
        # 复制 etc 与 usr 下的配置文件到 rootfs
        if [ -d "$TMP_ALSA/etc" ]; then
            cp -a "$TMP_ALSA/etc/." rootdir/etc/
        fi
        if [ -d "$TMP_ALSA/usr" ]; then
            cp -a "$TMP_ALSA/usr/." rootdir/usr/
        fi
        rm -rf "$TMP_ALSA"
    fi

    # 修改服务配置（pd-mapper 在 Fedora 下不存在，跳过 sed）
    sed -i '/ConditionKernelVersion/d' rootdir/lib/systemd/system/pd-mapper.service 2>/dev/null || true

    # 桌面版启用显示管理器
    if [[ "$SYSTEM_TYPE" != *"server"* ]]; then
        if [[ "$DESKTOP_ENV" == "kde" ]]; then
            echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06]   └─ 启用 SDDM 显示管理器"
            chroot rootdir systemctl enable sddm
        fi
    fi

    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06] ✅ 软件包安装完成"
    exit 0
fi
# ───────────────────────── Fedora 分支结束 ─────────────────────────

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06]   └─ 更新系统包..."
chroot rootdir apt-get update
chroot rootdir apt-get upgrade -y

BASE_PACKAGES="bash-completion sudo apt-utils ssh openssh-server nano network-manager initramfs-tools chrony curl wget locales tzdata iproute2 zram-tools"

if [[ "$SYSTEM_TYPE" == *"debian-"* ]]; then 
    BASE_PACKAGES="bash-completion sudo apt-utils ssh openssh-server nano network-manager initramfs-tools chrony curl wget locales tzdata fonts-wqy-microhei dnsmasq nftables iproute2 zram-tools"
elif [[ "$SYSTEM_TYPE" == *"ubuntu-"* ]]; then
    if [[ "$SYSTEM_TYPE" == *"server"* ]]; then
        BASE_PACKAGES="bash-completion sudo apt-utils ssh openssh-server nano network-manager initramfs-tools chrony curl wget locales tzdata dnsmasq nftables iproute2 zram-tools"
    else
        BASE_PACKAGES="bash-completion sudo apt-utils ssh openssh-server nano network-manager initramfs-tools chrony curl wget locales tzdata dnsmasq nftables iproute2 zram-tools"
    fi
fi

DEVICE_PACKAGES="rmtfs protection-domain-mapper tqftpserv"

if [[ "$SYSTEM_TYPE" != *"server"* ]]; then
    case "$DESKTOP_ENV" in
        "gnome")
            if [[ "$SYSTEM_TYPE" == *"ubuntu-"* ]]; then
                DESKTOP_PACKAGES="ubuntu-desktop"
            elif [[ "$SYSTEM_TYPE" == *"debian-"* ]]; then
                DESKTOP_PACKAGES="gnome"
            fi
            ;;
        "phosh-core")
            DESKTOP_PACKAGES="phosh-core"
            ;;
        "phosh-full")
            DESKTOP_PACKAGES="phosh-full"
            ;;
        "phosh-phone")
            DESKTOP_PACKAGES="phosh-phone"
            ;;
        *)
            DESKTOP_PACKAGES=""
            ;;
    esac
else
    DESKTOP_PACKAGES=""
fi

ALL_PACKAGES="$BASE_PACKAGES $DEVICE_PACKAGES $DESKTOP_PACKAGES"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06]   └─ 基础包: $(echo "$BASE_PACKAGES" | tr ' ' ', ')"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06]   └─ 设备包: $(echo "$DEVICE_PACKAGES" | tr ' ' ', ')"
if [ -n "$DESKTOP_PACKAGES" ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06]   └─ 桌面包: $(echo "$DESKTOP_PACKAGES" | tr ' ' ', ')"
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06]   └─ 开始安装（这可能需要几分钟...）"
chroot rootdir apt-get install -y $ALL_PACKAGES

if [[ "$SYSTEM_TYPE" == *"debian-"* ]]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06]   └─ 修复 Debian dpkg 错误"
    chroot rootdir dpkg --remove --force-remove-reinstreq shim-signed 2>/dev/null || true
    chroot rootdir dpkg --purge shim-signed 2>/dev/null || true
    chroot rootdir dpkg --configure -a 2>/dev/null || true
    chroot rootdir apt-get -f install -y 2>/dev/null || true
fi

# 修改服务配置
sed -i '/ConditionKernelVersion/d' rootdir/lib/systemd/system/pd-mapper.service 2>/dev/null || true

if [ -f "alsa-xiaomi-raphael.deb" ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06]   └─ 安装 ALSA 配置"
    cp alsa-xiaomi-raphael.deb rootdir/tmp/
    chroot rootdir dpkg -i /tmp/alsa-xiaomi-raphael.deb
    rm rootdir/tmp/alsa-xiaomi-raphael.deb
fi

if [[ "$SYSTEM_TYPE" != *"server"* ]]; then
    if [[ "$DESKTOP_ENV" == phosh* ]]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06]   └─ 启用 Phosh 服务"
        chroot rootdir systemctl enable phosh
    fi
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06] ✅ 软件包安装完成"
