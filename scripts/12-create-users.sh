#!/bin/bash
set -e

ROOT_PASS="${ROOT_PASS:-1234}"
USER_NAME="${USER_NAME:-user}"
USER_PASS="${USER_PASS:-1234}"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [12] 👤 创建用户和配置 SSH"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [12]   └─ 创建用户: ${USER_NAME}"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] [12]   └─ 启用 SSH 密码登录"

echo "root:${ROOT_PASS}" | chroot rootdir chpasswd
# Fedora 用 wheel 组，Debian/Ubuntu 用 sudo 组
if [[ "$SYSTEM_TYPE" == *"fedora-"* ]]; then
    USER_GROUPS="wheel"
else
    USER_GROUPS="sudo"
fi
chroot rootdir useradd -m -G "$USER_GROUPS" -s /bin/bash ${USER_NAME}
echo "${USER_NAME}:${USER_PASS}" | chroot rootdir chpasswd

echo "PermitRootLogin yes" >> rootdir/etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> rootdir/etc/ssh/sshd_config

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [12] ✅ 用户创建完成"
