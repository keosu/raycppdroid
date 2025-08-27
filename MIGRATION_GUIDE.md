# 从 Makefile 迁移到 Xmake 指南

本文档将帮助您从传统的 Makefile/CMake 构建系统迁移到现代化的 xmake 构建系统。

## 快速开始

### 1. 安装 xmake

**Windows:**
```bash
# 使用 scoop (推荐)
scoop install xmake

# 或者下载安装包
# https://github.com/xmake-io/xmake/releases
```

**Linux/macOS:**
```bash
curl -fsSL https://xmake.io/shget.text | bash
```

### 2. 验证项目

运行项目验证脚本：
```bash
# Windows
validate-project.bat

# Linux/macOS  
chmod +x validate-project.sh
./validate-project.sh
```

### 3. 快速构建

使用快速开始脚本：
```bash
# Windows
xmake-quickstart.bat

# 或者手动执行
xmake build-raylib
xmake config -p windows
xmake build raylib-desktop
xmake run raylib-desktop
```

## 功能对比表

| 操作 | 原 Makefile 命令 | xmake 命令 | 说明 |
|------|-----------------|------------|------|
| 构建桌面版 | 无 | `xmake` | 新功能，便于调试 |
| 构建 raylib | `cmake + make` | `xmake build-raylib` | 简化的单命令 |
| 构建 Android | `make` | `xmake build raylib-android` | 更清晰的目标 |
| 生成 APK | `make` (完整流程) | `xmake build-apk` | 结构化的 APK 构建 |
| 安装到设备 | `make install` | `xmake install-apk` | 相同功能 |
| 监控日志 | `make logcat` | `xmake logcat` | 相同功能 |
| 完整部署 | `make deploy` | `xmake deploy` | 相同功能 |
| 清理构建 | `make clean` | `xmake clean-all` | 更彻底的清理 |

## 迁移步骤

### 步骤 1：备份原文件

```bash
# 备份原构建文件（可选）
copy Makefile Makefile.backup
copy CMakeLists.txt CMakeLists.txt.backup
copy src\Makefile src\Makefile.backup
```

### 步骤 2：设置环境变量

确保以下环境变量已正确设置（与原项目相同）：

```bash
# Windows 示例
set JAVA_HOME=C:\open-jdk
set ANDROID_HOME=C:\android-sdk  
set ANDROID_NDK=C:\android-ndk
```

### 步骤 3：测试桌面版本

首先测试桌面版本以确保项目正常工作：

```bash
xmake config -p windows
xmake build raylib-desktop
xmake run raylib-desktop
```

### 步骤 4：构建 Android 版本

```bash
# 构建 raylib 依赖
xmake build-raylib --arch=arm64-v8a

# 配置 Android 平台
xmake config -p android -a arm64-v8a

# 构建 Android 共享库
xmake build raylib-android

# 构建 APK 结构
xmake build-apk
```

### 步骤 5：验证功能

```bash
# 检查生成的文件
ls build/

# 如果有 Android 设备，测试安装
adb devices
xmake install-apk
xmake logcat
```

## 配置定制

### 修改应用信息

编辑 `xmake.lua` 中的 `android_configs` 部分：

```lua
local android_configs = {
    app_name = "您的应用名称",
    company_name = "您的公司名", 
    product_name = "您的产品名",
    version_code = 1,
    version_name = "1.0",
    package_name = "com.yourcompany.yourapp",
    min_sdk = 30,
    target_sdk = 36,
    screen_orientation = "landscape",
    keystore_pass = "您的密码"
}
```

### 支持多架构

```bash
# 为不同架构构建
xmake build-raylib --arch=arm64-v8a
xmake build-raylib --arch=armeabi-v7a
xmake build-raylib --arch=x86_64

# 切换架构
xmake config -a arm64-v8a
xmake build raylib-android
```

### 调试模式

```bash
# 启用调试模式
xmake config -m debug
xmake build
```

## 优势总结

### 与原 Makefile 相比的优势：

1. **统一构建系统**：一个配置文件支持所有平台
2. **现代化语法**：Lua 语法比 Makefile 更易读
3. **自动依赖管理**：自动处理第三方库
4. **增量编译**：智能检测变化，提高编译速度
5. **跨平台支持**：Windows、Linux、macOS 使用相同配置
6. **内置任务系统**：自定义构建任务更简单
7. **更好的错误提示**：清晰的错误信息和建议
8. **包管理集成**：支持现代包管理器

### 功能增强：

1. **桌面版本支持**：便于快速测试和调试
2. **模块化构建**：清晰分离不同构建目标  
3. **智能配置**：自动检测平台和工具链
4. **扩展性强**：易于添加新的构建目标

## 故障排除

### 常见问题

**1. xmake 找不到 Android NDK**
```bash
# 检查环境变量
echo %ANDROID_NDK%

# 重新设置
set ANDROID_NDK=C:\path\to\your\ndk
xmake config -p android --rebuild
```

**2. raylib 构建失败**
```bash
# 清理后重建
xmake clean-all
xmake build-raylib
```

**3. Java 版本不兼容**
```bash
# 检查 Java 版本
%JAVA_HOME%\bin\java -version

# 确保使用 JDK 11 或更高版本
```

**4. 权限问题**
```bash
# Windows 上以管理员身份运行
# Linux/macOS 检查文件权限
chmod +x validate-project.sh
```

## 回退方案

如果需要回退到原 Makefile 系统：

```bash
# 恢复原文件
copy Makefile.backup Makefile
copy CMakeLists.txt.backup CMakeLists.txt
copy src\Makefile.backup src\Makefile

# 删除 xmake 文件
del xmake.lua
del xmake-quickstart.bat
del validate-project.bat
del XMAKE_README.md
rmdir /s /q build
```

## 获取帮助

- **xmake 官方文档**: https://xmake.io
- **查看可用命令**: `xmake --help`
- **查看任务列表**: `xmake show -l tasks`
- **查看构建目标**: `xmake show -l targets`
- **项目验证**: 运行 `validate-project.bat`

通过这个迁移指南，您应该能够顺利从传统的 Makefile 系统迁移到现代化的 xmake 构建系统，享受更高效、更易维护的开发体验。