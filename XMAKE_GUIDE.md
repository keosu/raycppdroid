# XMake Android 构建指南

本项目现在支持使用 XMake 作为现代化的构建系统，用于构建 Android APK。

## 环境准备

### 1. 安装 XMake

从官方网站下载并安装 XMake：https://xmake.io/

或使用 PowerShell 安装：
```powershell
Invoke-Expression (Invoke-WebRequest 'https://xmake.io/psget.txt' -UseBasicParsing).Content
```

### 2. 检查环境

运行环境检查脚本：
```cmd
xmake-setup.bat
```

### 3. 安装 Android 工具（如果需要）

如果缺少 Android SDK/NDK，运行：
```cmd
get-android-tools\get-android-tools.bat
```

## 构建步骤

### 桌面版本（开发调试）

```cmd
# 构建桌面版本
xmake build raylib-desktop

# 运行桌面版本
xmake run raylib-desktop
```

### Android APK

```cmd
# 1. 构建 raylib for Android
xmake build-raylib

# 2. 构建 native 库
xmake build raylib-android

# 3. 构建完整 APK
xmake build-apk

# 或者一键构建所有内容
xmake deploy
```

## 部署到设备

```cmd
# 安装 APK 到设备
xmake install-apk

# 监控日志
xmake logcat

# 构建 + 安装 + 监控（一键部署）
xmake deploy
```

## 清理

```cmd
# 清理构建文件
xmake clean

# 清理所有文件（包括 raylib）
xmake clean-all
```

## 项目配置

可以在 `xmake.lua` 文件顶部修改 Android 应用配置：

```lua
local android_configs = {
    app_name = "rgame",           -- 应用名称
    company_name = "raylib",      -- 公司名称
    product_name = "rgame",       -- 产品名称
    version_code = 1,             -- 版本号
    version_name = "1.0",         -- 版本名称
    package_name = "com.raylib.rgame",  -- 包名
    min_sdk = 30,                 -- 最低 SDK
    target_sdk = 36,              -- 目标 SDK
    screen_orientation = "landscape",   -- 屏幕方向
    keystore_pass = "raylib"      -- 密钥库密码
}
```

## 支持的架构

默认构建 arm64-v8a 架构，可以指定其他架构：

```cmd
# 构建其他架构
xmake build-raylib -a armeabi-v7a
xmake build-apk -a armeabi-v7a
```

支持的架构：
- arm64-v8a（默认）
- armeabi-v7a
- x86
- x86_64

## 故障排除

### 1. 环境变量问题

确保设置了以下环境变量（或使用默认路径）：
- `JAVA_HOME=C:\open-jdk`
- `ANDROID_SDK_ROOT=C:\android-sdk`
- `ANDROID_NDK_ROOT=C:\android-ndk`

### 2. 权限问题

确保 `xmake-setup.bat` 和 `get-android-tools.bat` 以管理员身份运行。

### 3. 网络问题

如果下载 raylib 源码失败，可以手动克隆：
```cmd
git clone --depth 1 --branch 5.5 https://github.com/raysan5/raylib.git
```

### 4. 构建失败

如果构建失败，尝试清理后重新构建：
```cmd
xmake clean-all
xmake build-raylib
xmake build-apk
```

## 与原 Makefile 的区别

| 功能 | Makefile | XMake |
|------|----------|-------|
| 跨平台支持 | Windows only | 跨平台 |
| 依赖管理 | 手动 | 自动 |
| 构建速度 | 慢 | 快 |
| 配置复杂度 | 高 | 低 |
| IDE 集成 | 有限 | 良好 |

## 高级用法

### 自定义构建选项

```cmd
# 调试模式构建
xmake config -m debug
xmake build

# 发布模式构建
xmake config -m release
xmake build
```

### 并行构建

```cmd
# 使用多线程构建
xmake build -j 4
```

### 详细输出

```cmd
# 查看详细构建过程
xmake build -v
```