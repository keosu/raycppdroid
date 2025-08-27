# Xmake 构建系统使用指南

本文档介绍如何使用 xmake 替代原有的 Makefile 和 CMake 构建系统来构建 raylib Android 项目。

## 安装 xmake

### Windows
```bash
# 使用 scoop 安装
scoop install xmake

# 或者下载安装包
# https://github.com/xmake-io/xmake/releases
```

### Linux/macOS
```bash
# 使用安装脚本
curl -fsSL https://xmake.io/shget.text | bash

# 或者使用包管理器
brew install xmake  # macOS
```

## 环境配置

使用 xmake 之前，需要配置以下环境变量（与原 Makefile 要求相同）：

```bash
# Windows 示例
set JAVA_HOME=C:\open-jdk
set ANDROID_HOME=C:\android-sdk
set ANDROID_NDK=C:\android-ndk

# Linux/macOS 示例
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_NDK=$HOME/Android/Sdk/ndk/25.1.8937393
```

## 基本命令

### 1. 构建桌面版本（用于开发调试）
```bash
# 构建桌面版本（默认目标）
xmake

# 或者明确指定目标
xmake build raylib-desktop

# 运行桌面版本
xmake run raylib-desktop
```

### 2. 构建 raylib 库
```bash
# 为 Android 构建 raylib 依赖库
xmake build-raylib

# 指定架构构建
xmake build-raylib --arch=arm64-v8a
xmake build-raylib --arch=armeabi-v7a
xmake build-raylib --arch=x86_64
```

### 3. 构建 Android 版本
```bash
# 配置为 Android 平台
xmake config -p android -a arm64-v8a

# 构建 Android 共享库
xmake build raylib-android

# 构建 APK 包
xmake build-apk

# 指定架构构建
xmake build-apk --arch=arm64-v8a
```

### 4. 部署到 Android 设备
```bash
# 安装 APK 到连接的设备
xmake install-apk

# 监控设备日志
xmake logcat

# 一键部署（构建+安装+日志监控）
xmake deploy
```

### 5. 清理
```bash
# 清理构建文件
xmake clean

# 清理所有文件（包括 raylib）
xmake clean-all
```

## 高级配置

### 支持的架构
- `arm64-v8a` (默认，64位 ARM)
- `armeabi-v7a` (32位 ARM)
- `x86` (32位 x86)
- `x86_64` (64位 x86)

### 构建模式
```bash
# Debug 模式
xmake config -m debug
xmake

# Release 模式（默认）
xmake config -m release
xmake
```

### 多架构构建
```bash
# 为多个架构构建
for arch in arm64-v8a armeabi-v7a x86_64; do
    xmake build-raylib --arch=$arch
    xmake config -a $arch
    xmake build raylib-android
done
```

## 自定义配置

可以在 `xmake.lua` 中修改以下配置：

```lua
-- Android 应用配置
local android_configs = {
    app_name = "your_app_name",        -- 应用显示名称
    company_name = "your_company",     -- 公司名称
    product_name = "your_product",     -- 产品名称
    version_code = 1,                  -- 版本号
    version_name = "1.0",              -- 版本名称
    package_name = "com.company.app",  -- 包名
    min_sdk = 30,                      -- 最小 SDK 版本
    target_sdk = 36,                   -- 目标 SDK 版本
    screen_orientation = "landscape",   -- 屏幕方向
    keystore_pass = "your_password"    -- 密钥库密码
}
```

## 与原 Makefile 的对比

| 功能 | 原 Makefile | xmake |
|------|-------------|-------|
| 构建桌面版 | 无直接支持 | `xmake` |
| 构建 raylib | `cmake + make` | `xmake build-raylib` |
| 构建 Android | `make` | `xmake build raylib-android` |
| 构建 APK | `make` (完整流程) | `xmake build-apk` |
| 安装 APK | `make install` | `xmake install-apk` |
| 监控日志 | `make logcat` | `xmake logcat` |
| 部署 | `make deploy` | `xmake deploy` |
| 清理 | `make clean` | `xmake clean-all` |

## 优势

1. **跨平台支持**：同一配置文件支持 Windows、Linux、macOS
2. **现代化语法**：使用 Lua 语法，比 Makefile 更易读易维护
3. **自动依赖管理**：自动处理 raylib 依赖
4. **增量编译**：智能检测文件变化，提高编译速度
5. **内置包管理**：支持第三方库的自动下载和集成
6. **灵活配置**：支持多种构建模式和目标平台

## 故障排除

### 常见问题

1. **raylib 构建失败**
   ```bash
   # 确保环境变量正确设置
   echo $ANDROID_NDK
   
   # 手动清理后重新构建
   xmake clean-all
   xmake build-raylib
   ```

2. **Android 编译失败**
   ```bash
   # 检查 NDK 工具链
   ls $ANDROID_NDK/toolchains/llvm/prebuilt/
   
   # 重新配置 Android 平台
   xmake config -p android -a arm64-v8a --rebuild
   ```

3. **APK 构建失败**
   ```bash
   # 检查 Android SDK 工具
   which aapt
   which d8
   
   # 确保 JAVA_HOME 正确
   $JAVA_HOME/bin/java -version
   ```

## 迁移指南

如果您想从原 Makefile 系统完全迁移到 xmake：

1. **备份原文件**
   ```bash
   mv Makefile Makefile.backup
   mv CMakeLists.txt CMakeLists.txt.backup
   mv src/Makefile src/Makefile.backup
   ```

2. **使用 xmake**
   ```bash
   # 初始化项目
   xmake build-raylib
   
   # 测试桌面版本
   xmake run raylib-desktop
   
   # 测试 Android 版本
   xmake deploy
   ```

3. **验证功能**
   - 确保桌面版本正常运行
   - 确保 Android APK 可以正常安装和运行
   - 确保资源文件正确加载

通过使用 xmake，您将获得更现代化、更易维护的构建系统，同时保持与原项目相同的功能。