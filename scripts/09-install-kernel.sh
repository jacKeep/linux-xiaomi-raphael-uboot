#!/bin/bash
set -e

KERNEL_DEBS_DIR="${KERNEL_DEBS_DIR:-.}"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [09] 🧠 安装内核"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [09]   └─ 内核包目录: ${KERNEL_DEBS_DIR}"

# ───────────────────────── Fedora 分支 ─────────────────────────
# 内核仅以 .deb 分发，但内核二进制（vmlinuz/modules/firmware）与包格式无关。
# 用 dpkg-deb -x 提取后放入 rootfs 对应目录，再用 chroot 内的 dracut 生成 initramfs。
if [[ "$SYSTEM_TYPE" == *"fedora-"* ]]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [09]   └─ 提取内核 .deb 到临时目录"
    TMP_KEXTRACT=$(mktemp -d)
    for deb in ${KERNEL_DEBS_DIR}/*-xiaomi-raphael.deb; do
        [ -f "$deb" ] || continue
        dpkg-deb -x "$deb" "$TMP_KEXTRACT"
    done

    # 复制 vmlinuz -> /boot
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [09]   └─ 安装 linux-image (vmlinuz)..."
    cp $TMP_KEXTRACT/boot/vmlinuz-* rootdir/boot/ 2>/dev/null || true

    # 复制 modules -> /lib/modules
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [09]   └─ 安装内核模块..."
    mkdir -p rootdir/lib/modules
    cp -a $TMP_KEXTRACT/lib/modules/* rootdir/lib/modules/ 2>/dev/null || true

    # 复制 firmware -> /lib/firmware
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [09]   └─ 安装 firmware..."
    mkdir -p rootdir/lib/firmware
    cp -a $TMP_KEXTRACT/lib/firmware/* rootdir/lib/firmware/ 2>/dev/null || true

    rm -rf "$TMP_KEXTRACT"

    # 解析内核版本号
    KVER=$(ls rootdir/lib/modules/ | head -n1)
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [09]   └─ 内核版本: ${KVER}"

    # 创建 dracut 配置以包含 Qualcomm 固件（对应 Debian 的 initramfs hook）
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [09]   └─ 添加 dracut 配置..."
    mkdir -p rootdir/etc/dracut.conf.d
    FW_ITEMS=""
    for fw in rootdir/lib/firmware/qcom/a6* \
              rootdir/lib/firmware/qcom/sm8150/Xiaomi/raphael/a6* \
              rootdir/lib/firmware/qcom/sm8150/Xiaomi/raphael/ad* \
              rootdir/lib/firmware/qcom/sm8150/Xiaomi/raphael/cd* \
              rootdir/lib/firmware/qcom/sm8150/Xiaomi/raphael/ipa*; do
        [ -e "$fw" ] && FW_ITEMS="$FW_ITEMS ${fw#rootdir}"
    done
    # 生成 dracut 配置。注意：
    # - 仅当 FW_ITEMS 非空时才写 install_items+=，避免空值触发
    #   "<values> should have surrounding white spaces" 警告。
    # - mss_q6v5 在主线内核中不存在，正确模块名为 qcom_q6v5_mss
    #   （drivers/remoteproc/qcom_q6v5_mss.c）。
    {
        echo "# Xiaomi raphael 早期启动所需 Qualcomm 固件与驱动"
        if [ -n "$FW_ITEMS" ]; then
            echo "install_items+=\"${FW_ITEMS} \""
        fi
        echo "add_drivers+=\" ath10k_core ath10k_snoc qcom_q6v5 qcom_q6v5_mss \""
    } > rootdir/etc/dracut.conf.d/raphael.conf

    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [09]   └─ 生成 initramfs (dracut)..."
    chroot rootdir dracut --kver "$KVER" --force

    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [09] ✅ 内核安装完成"
    exit 0
fi
# ───────────────────────── Fedora 分支结束 ─────────────────────────

cp ${KERNEL_DEBS_DIR}/*-xiaomi-raphael.deb rootdir/tmp/

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [09]   └─ 安装 linux-image..."
chroot rootdir dpkg -i /tmp/linux-image-xiaomi-raphael.deb

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [09]   └─ 安装 linux-headers..."
chroot rootdir dpkg -i /tmp/linux-headers-xiaomi-raphael.deb

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [09]   └─ 安装 firmware..."
chroot rootdir dpkg -i /tmp/firmware-xiaomi-raphael.deb

rm rootdir/tmp/*-xiaomi-raphael.deb

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [09]   └─ 添加 initramfs hooks..."
chroot rootdir tee /etc/initramfs-tools/hooks/raphael << 'EOF'
#!/bin/sh
PREREQS=""
case $1 in
prereqs) echo "$PREREQS"; exit 0;;
esac
. /usr/share/initramfs-tools/hook-functions

for fw in /lib/firmware/qcom/a6*; do
    [ -e "$fw" ] && copy_file firmware "$fw"
done

for fw in /lib/firmware/qcom/sm8150/Xiaomi/raphael/a6*; do
    [ -e "$fw" ] && copy_file firmware "$fw"
done

for fw in /lib/firmware/qcom/sm8150/Xiaomi/raphael/ad*; do
    [ -e "$fw" ] && copy_file firmware "$fw"
done

for fw in /lib/firmware/qcom/sm8150/Xiaomi/raphael/cd*; do
    [ -e "$fw" ] && copy_file firmware "$fw"
done

for fw in /lib/firmware/qcom/sm8150/Xiaomi/raphael/ipa*; do
    [ -e "$fw" ] && copy_file firmware "$fw"
done
EOF

chroot rootdir chmod +x /etc/initramfs-tools/hooks/raphael

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [09]   └─ 更新 initramfs..."
chroot rootdir update-initramfs -c -k all

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [09] ✅ 内核安装完成"
