# 系统类型配置
SYSTEM_TYPES="
  debian-server
  debian-gnome
  debian-phosh
  ubuntu-server
  ubuntu-gnome
  ubuntu-phosh
  fedora-server
  fedora-kde
"

# 系统类型到基础设置的映射
system_config() {
  case "$1" in
    "debian-server")
      echo "DEBIAN_VERSION=${DEBIAN_VERSION:-trixie}"
      echo "IMAGE_SIZE=3G"
      echo "IS_DESKTOP=false"
      echo "DESKTOP_ENV="
      ;;
    "debian-gnome")
      echo "DEBIAN_VERSION=${DEBIAN_VERSION:-trixie}"
      echo "IMAGE_SIZE=6G"
      echo "IS_DESKTOP=true"
      echo "DESKTOP_ENV=gnome"
      ;;
    "debian-phosh")
      echo "DEBIAN_VERSION=${DEBIAN_VERSION:-trixie}"
      echo "IMAGE_SIZE=6G"
      echo "IS_DESKTOP=true"
      echo "DESKTOP_ENV=$2"
      ;;
    "ubuntu-server")
      echo "UBUNTU_VERSION=${UBUNTU_VERSION:-resolute}"
      echo "IMAGE_SIZE=3G"
      echo "IS_DESKTOP=false"
      echo "DESKTOP_ENV="
      ;;
    "ubuntu-gnome")
      echo "UBUNTU_VERSION=${UBUNTU_VERSION:-resolute}"
      echo "IMAGE_SIZE=6G"
      echo "IS_DESKTOP=true"
      echo "DESKTOP_ENV=gnome"
      ;;
    "ubuntu-phosh")
      echo "UBUNTU_VERSION=${UBUNTU_VERSION:-resolute}"
      echo "IMAGE_SIZE=6G"
      echo "IS_DESKTOP=true"
      echo "DESKTOP_ENV=$2"
      ;;
    "fedora-server")
      echo "FEDORA_VERSION=${FEDORA_VERSION:-44}"
      echo "IMAGE_SIZE=3G"
      echo "IS_DESKTOP=false"
      echo "DESKTOP_ENV="
      ;;
    "fedora-kde")
      echo "FEDORA_VERSION=${FEDORA_VERSION:-44}"
      echo "IMAGE_SIZE=6G"
      echo "IS_DESKTOP=true"
      echo "DESKTOP_ENV=kde"
      ;;
  esac
}

# 镜像源配置
sources_config() {
  if [[ "$1" == *"debian-"* ]]; then
    local version="${DEBIAN_VERSION:-trixie}"
    echo "DEBIAN_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/debian/"
    echo "DEBIAN_SECURITY_MIRROR=http://security.debian.org/debian-security"
  elif [[ "$1" == *"ubuntu-"* ]]; then
    local version="${UBUNTU_VERSION:-resolute}"
    echo "UBUNTU_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/"
    echo "UBUNTU_SECURITY_MIRROR=http://ports.ubuntu.com/ubuntu-ports/"
  elif [[ "$1" == *"fedora-"* ]]; then
    local version="${FEDORA_VERSION:-44}"
    echo "FEDORA_BASE_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/fedora/releases/${version}/Everything/aarch64/os/"
    echo "FEDORA_UPDATES_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/fedora/updates/${version}/Everything/aarch64/"
  fi
}

# 软件包配置
get_packages() {
  local system_type="$1"
  local desktop_env="$2"

  if [[ "$system_type" == *"fedora-"* ]]; then
    base_packages="bash-completion sudo nano openssh-server NetworkManager chrony curl wget tzdata iproute nftables dracut filesystem glibc-langpack-en google-noto-sans-cjk-fonts wqy-microhei-fonts"
  else
    base_packages="bash-completion sudo apt-utils ssh openssh-server nano network-manager initramfs-tools chrony curl wget locales tzdata dnsmasq nftables iproute2"

    if [[ "$system_type" == *"debian-"* ]]; then
      base_packages="$base_packages fonts-wqy-microhei"
    elif [[ "$system_type" == *"ubuntu-"* ]]; then
      base_packages="$base_packages language-pack-en"
    fi
  fi

  if [[ "$system_type" == *"server"* ]]; then
    echo "$base_packages"
  else
    case "$desktop_env" in
      "gnome")
        echo "$base_packages gnome gnome-terminal gdm3"
        ;;
      "kde")
        echo "$base_packages @kde-desktop maliit-keyboard plasma-workspace-wayland sddm"
        ;;
      "phosh-core")
        if [[ "$system_type" == *"ubuntu-"* ]]; then
          echo "$base_packages phosh phoc onboard"
        elif [[ "$system_type" == *"debian-"* ]]; then
          echo "$base_packages phosh phoc squeekboard"
        fi
        ;;
      "phosh-full")
        if [[ "$system_type" == *"ubuntu-"* ]]; then
          echo "$base_packages phosh phoc onboard gnome-settings-daemon gnome-control-center"
        elif [[ "$system_type" == *"debian-"* ]]; then
          echo "$base_packages phosh phoc squeekboard gnome-settings-daemon gnome-control-center"
        fi
        ;;
      "phosh-phone")
        echo "$base_packages phosh phoc squeekboard gnome-settings-daemon gnome-control-center ofono mobian-tweaks"
        ;;
      *)
        # 默认返回基础包
        echo "$base_packages"
        ;;
    esac
  fi
}