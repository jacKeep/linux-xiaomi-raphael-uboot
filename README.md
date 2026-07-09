<div align="center">

# <img src="https://img.shields.io/badge/Device-Xiaomi_Raphael-FF6900?style=for-the-badge&logo=android&logoColor=white" alt="Device"/> <img src="https://img.shields.io/badge/Linux-Fedora|Ubuntu|Debian-E95420?style=for-the-badge&logo=linux&logoColor=white" alt="Linux"/>

# 📱 小米 Raphael Linux 镜像构建项目

### Redmi K20 Pro · 一键构建 Fedora / Debian / Ubuntu 系统镜像

[![Build](https://img.shields.io/github/actions/workflow/status/GengWei1997/linux-xiaomi-raphael-uboot/build-system.yml?style=flat-square&label=Build&logo=github-actions&logoColor=white)](https://github.com/GengWei1997/linux-xiaomi-raphael-uboot/actions)
[![Release](https://img.shields.io/github/v/release/GengWei1997/linux-xiaomi-raphael-uboot?style=flat-square&label=Release&logo=github&logoColor=white)](https://github.com/GengWei1997/linux-xiaomi-raphael-uboot/releases)
[![Stars](https://img.shields.io/github/stars/GengWei1997/linux-xiaomi-raphael-uboot?style=flat-square&logo=github&logoColor=white)](https://github.com/GengWei1997/linux-xiaomi-raphael-uboot/stargazers)

---

</div>

## ✨ 项目简介

本项目为 **小米 Raphael（Redmi K20 Pro）** 专属 Linux 镜像构建方案，提供完整的 Fedora / Debian / Ubuntu 系统镜像构建脚本与 GitHub Actions 自动化工作流。支持多内核版本、多桌面环境，开箱即用。

## 📋 支持系统类型

| 系统标识 | 桌面环境 | 发行版 | 镜像大小 |
|:---:|:---:|:---:|:---:|
| `debian-server` | 无（纯命令行） | Debian trixie | 3G |
| `debian-gnome` | GNOME | Debian trixie | 6G |
| `debian-phosh` | Phosh 移动端桌面 | Debian trixie | 6G |
| `ubuntu-server` | 无（纯命令行） | Ubuntu resolute | 3G |
| `ubuntu-gnome` | GNOME | Ubuntu resolute | 6G |
| `ubuntu-phosh` | Phosh 移动端桌面 | Ubuntu resolute | 6G |
| `fedora-server` | 无（纯命令行） | Fedora 44 | 3G |
| `fedora-kde` | KDE Plasma（触摸适配） | Fedora 44 | 6G |

## 🖥️ 设备硬件适配

| 分类 | 支持项目 | 状态 |
|:---:|:---|:---:|
| 🌐 **网络** | 2.4G / 5G 双频 Wi-Fi | ✅ |
| 📡 **蓝牙** | 文件传输 · 音频输出 | ✅ |
| 📶 **蜂窝** | 网络支持 | ❌ |
| 🔌 **USB** | NCM 网络共享 · OTG 功能 | ✅ |
| 🖥️ **显示** | 屏幕输出 · GPU 渲染 | ✅ |
| 🔊 **音频** | 扬声器 · 耳机输出 | ✅ |
| 👆 **输入** | 触摸屏 · 闪光灯（手电筒） | ✅ |
| 🔋 **系统** | 电池检测 · 实时时钟 · FDE 加密 | ✅ |

## 🚀 快速上手

### 方式一：下载预构建镜像

前往 [Releases](https://github.com/GengWei1997/linux-xiaomi-raphael-uboot/releases) 页面下载最新镜像，无需本地编译。

> ⚠️ `ubuntu-gnome` 镜像体积超过 2GB，请前往项目 [Actions → Artifacts](https://github.com/GengWei1997/linux-xiaomi-raphael-uboot/actions) 下载。

### 方式二：GitHub Actions 自定义构建（推荐）

1. **Fork** 本仓库至个人 GitHub 账号
2. 进入 **Actions** 页面 → 选择「构建系统镜像」工作流
3. 点击 **Run workflow**，自定义参数：

| 参数 | 说明 | 默认值 |
|:---:|:---|:---:|
| 构建模式 | `parallel` 并行构建 / `single` 单独构建 | `parallel` |
| 系统类型 | 支持逗号分隔，留空则全量构建（含 `fedora-server`、`fedora-kde`） | 全部 |
| 内核版本 | `6.18` 或 `7.0` | `7.0` |
| 构建工具 | `mmdebstrap` / `debootstrap`（Fedora 自动用 dnf，忽略此项） | `mmdebstrap` |
| Phosh 变体 | 仅 Phosh 镜像生效 | `phosh-core` |
| Fedora 版本 | 仅 Fedora 镜像生效 | `44` |

4. 等待构建完成，镜像自动发布至 Releases

## 📦 镜像特性

### 🌐 全版本通用

- 默认配置 **清华软件源**
- 预装简体中文语言包 + 中国标准时区，开箱汉化
- 支持 USB NCM 网络共享，电脑直连设备 SSH
- 内置 SSH 服务，支持 root / 普通用户远程登录
- 支持 **一键内核更新脚本**，在线升级定制内核

| 账户 | 用户名 | 密码 |
|:---:|:---:|:---:|
| 普通用户 | `user` | `1234` |
| 超级用户 | `root` | `1234` |

> 📌 USB NCM 连接时，设备 IP：`172.16.42.1`，SSH 连接：`ssh user@172.16.42.1`

### 🎨 桌面版专属

- GNOME / Phosh / KDE Plasma 三种桌面环境可选，适配桌面、移动两种使用场景
- `fedora-kde` 预装 maliit-keyboard 屏幕键盘并启用触摸适配，适合手机触屏使用

### 🖥️ 服务器版专属

- 内置网络管理器，支持有线、Wi-Fi、USB 多种联网方式
- 开机 15 秒自动熄屏，降低设备功耗
- 自定义快捷命令：`leijun` 关闭屏幕 · `jinfan` 点亮屏幕

## ⬆️ 内核更新

<details>
<summary><b>⚠️ 仅做内核调试用，非必要无需更新</b></summary>

建议 **root 权限** 执行，完成后重启设备即可生效。

| 链接 | 命令 |
|:---:|:---|
| 🌏 国内加速 | `sudo bash -c "$(curl -fsSL https://ghfast.top/https://raw.githubusercontent.com/GengWei1997/kernel-deb/refs/heads/main/ghproxy-Update-kernel.sh)"` |
| 🌐 原始链接 | `sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/GengWei1997/kernel-deb/refs/heads/main/Update-kernel.sh)"` |

</details>

## 🔧 安装教程

### 前置条件

- ✅ 设备已完成 **Bootloader 解锁**
- ✅ 电脑已安装 `adb` / `fastboot` 工具
- ✅ 下载镜像压缩包，解压获取：
  - `rootfs.img` — 系统镜像
  - `xiaomi-k20pro-boot.img` — 内核镜像
  - [u-boot.img](https://github.com/GengWei1997/linux-xiaomi-raphael-uboot/releases/tag/v1.0.0) — U-Boot 引导

### 刷机命令

```bash
# 1. 进入 Fastboot 模式
adb reboot bootloader

# 2. 擦除分区
fastboot erase dtbo
fastboot erase boot
fastboot erase cache
fastboot erase userdata

# 3. 刷入镜像
fastboot flash cache xiaomi-k20pro-boot.img
fastboot flash boot u-boot.img
fastboot flash userdata rootfs.img

# 4. 重启设备
fastboot reboot
```

## ❓ 常见问题

| 问题 | 解决方案 |
|:---|:---|
| 蜂窝网络支持情况 | 联通 / 电信已支持，移动正在修复中 *[@GavinLiuOnline](https://github.com/GavinLiuOnline)* |
| Windows 无法连接设备 | 参考 [NCM 驱动教程](https://www.bilibili.com/video/BV1tW4y1A79V/) |
| Server 版如何联网 | OTG 外接网线自动联网 · OTG 外接键盘输入 `nmtui` 连接 Wi-Fi |

---

## 🙏 致谢

感谢以下开源项目与开发者的支持（排名不分先后）：

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/degdag">
        <img src="https://github.com/degdag.png" width="60" height="60" style="border-radius:50%"><br>
        <sub><b>degdag</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/dabao1955">
        <img src="https://github.com/dabao1955.png" width="60" height="60" style="border-radius:50%"><br>
        <sub><b>dabao1955</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/qaz6750">
        <img src="https://github.com/qaz6750.png" width="60" height="60" style="border-radius:50%"><br>
        <sub><b>qaz6750</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/GavinLiuOnline">
        <img src="https://github.com/GavinLiuOnline.png" width="60" height="60" style="border-radius:50%"><br>
        <sub><b>GavinLiuOnline</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/umeiko">
        <img src="https://github.com/umeiko.png" width="60" height="60" style="border-radius:50%"><br>
        <sub><b>umeiko</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/yuweiyuan8">
        <img src="https://github.com/yuweiyuan8.png" width="60" height="60" style="border-radius:50%"><br>
        <sub><b>yuweiyuan8</b></sub>
      </a>
    </td>
  </tr>
  <tr>
    <td align="center">
      <a href="https://github.com/ccmx200">
        <img src="https://github.com/ccmx200.png" width="60" height="60" style="border-radius:50%"><br>
        <sub><b>璀璨梦星</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/map220v">
        <img src="https://github.com/map220v.png" width="60" height="60" style="border-radius:50%"><br>
        <sub><b>map220v</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/Pc1598">
        <img src="https://github.com/Pc1598.png" width="60" height="60" style="border-radius:50%"><br>
        <sub><b>Pc1598</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/Aospa-raphael-unofficial/linux">
        <img src="https://github.com/Aospa-raphael-unofficial.png" width="60" height="60" style="border-radius:50%"><br>
        <sub><b>Aospa-raphael</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://gitlab.postmarketos.org/soc/qualcomm-sm8150/linux">
        <img src="https://gitlab.postmarketos.org/uploads/-/system/project/avatar/4623/sm8150.png" width="60" height="60" style="border-radius:50%"><br>
        <sub><b>sm8150-mainline</b></sub>
      </a>
    </td>
  </tr>
</table>

<p align="center">
  <i>Linux 内核官方开发团队 · Fedora / Debian / Ubuntu 开源社区 · KDE / Phosh 桌面开发团队 · 以及所有开源贡献者</i>
</p>

---

<div align="center">

**如果这个项目对你有帮助，请给一个 ⭐ Star 支持一下！**

</div>
