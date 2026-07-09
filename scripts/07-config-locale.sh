#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../config"

. "$CONFIG_DIR/build-config.sh"

SYSTEM_TYPE="${SYSTEM_TYPE:-ubuntu-server}"
DESKTOP_ENV="${DESKTOP_ENV:-}"
DEBIAN_VERSION="${DEBIAN_VERSION:-trixie}"
UBUNTU_VERSION="${UBUNTU_VERSION:-resolute}"
TIMEZONE="${TIMEZONE:-Asia/Shanghai}"
LANG_DEFAULT="${LANG_DEFAULT:-en_US.UTF-8}"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [07] 🌍 配置时区和语言"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [07]   └─ 时区: ${TIMEZONE}"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] [07]   └─ 默认语言: ${LANG_DEFAULT}"

# 设置时区
if [[ "$SYSTEM_TYPE" == *"fedora-"* ]]; then
    # Fedora 无 /etc/timezone，仅用 /etc/localtime 软链
    chroot rootdir ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
else
    echo "${TIMEZONE}" > rootdir/etc/timezone
    chroot rootdir ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
fi

# Fedora 语言配置分支
if [[ "$SYSTEM_TYPE" == *"fedora-"* ]]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [07]   └─ 安装 Fedora 英文语言包 + CJK 字体回退"
    chroot rootdir dnf -y install glibc-langpack-en google-noto-sans-cjk-fonts wqy-microhei-fonts 2>/dev/null || true

    # Fedora 用 /etc/locale.conf，不用 locale.gen
    cat > rootdir/etc/locale.conf << EOF
LANG=${LANG_DEFAULT}
LANGUAGE=en_US:en
EOF
    # 清理可能存在的 locale.gen 残留配置
    rm -f rootdir/etc/locale.gen 2>/dev/null || true

    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [07] ✅ 时区语言配置完成"
    exit 0
fi

# 安装英文语言包（保留 CJK 字体与中文输入法作为可选）
if [[ "$SYSTEM_TYPE" == *"ubuntu-"* ]]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [07]   └─ 安装 Ubuntu 英文语言包"
    chroot rootdir apt-get update

    if [[ "$SYSTEM_TYPE" == *"server"* ]]; then
        # Server 版本只安装基础英文语言包
        chroot rootdir apt-get install -y language-pack-en
    else
        # 桌面版本安装英文语言包 + CJK 字体回退 + 中文输入法
        BASE_EN_PACKAGES="language-pack-en language-pack-gnome-en fonts-noto-cjk fonts-noto-cjk-extra fonts-arphic-uming fonts-arphic-ukai gnome-user-docs-en"
        # 中文输入法（输入工具，与界面语言独立）
        DESKTOP_ZH_PACKAGES="libopencc-data libmarisa0 libopencc1.1 libpinyin-data libpinyin15 ibus-libpinyin ibus-table ibus-table-wubi libchewing3-data libchewing3 ibus-chewing ibus-table-cangjie3 ibus-table-cangjie5 ibus-table-quick-classic"
        # resolute版本不支持libmarisa0包
        if [[ "$UBUNTU_VERSION" == "resolute" ]]; then
            DESKTOP_ZH_PACKAGES="libopencc-data libopencc1.1 libpinyin-data libpinyin15 ibus-libpinyin ibus-table ibus-table-wubi libchewing3-data libchewing3 ibus-chewing ibus-table-cangjie3 ibus-table-cangjie5 ibus-table-quick-classic"
        fi
        chroot rootdir apt-get install -y $BASE_EN_PACKAGES $DESKTOP_ZH_PACKAGES
    fi
elif [[ "$SYSTEM_TYPE" == *"debian-"* ]]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [07]   └─ 安装 Debian locales（含全语言环境）"
    chroot rootdir apt-get update
    chroot rootdir apt-get install -y locales locales-all tzdata fonts-noto-cjk
fi

# 配置语言环境（英文）
cat > rootdir/etc/locale.gen << 'EOF'
en_US.UTF-8 UTF-8
EOF
chroot rootdir locale-gen en_US.UTF-8
chroot rootdir update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [07] ✅ 时区语言配置完成"
