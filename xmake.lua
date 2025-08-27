-- xmake.lua for raylib Android project
-- 替代 Makefile 和 CMakeLists.txt 的现代化构建配置

-- 设置项目基本信息
set_project("raylib-android")
set_version("1.0")
set_languages("c99", "cxx20")

-- 设置警告级别
set_warnings("all")

-- 添加构建模式
add_rules("mode.debug", "mode.release")

-- 检查并设置 Android 环境变量
local android_sdk = os.getenv("ANDROID_SDK_ROOT") or "C:\\android-sdk"
local android_ndk = os.getenv("ANDROID_NDK_ROOT") or "C:\\android-ndk"
local java_home = os.getenv("JAVA_HOME") or "C:\\open-jdk"

-- 验证环境
if not os.isdir(android_sdk) then
    print("Warning: Android SDK not found at: " .. android_sdk)
end
if not os.isdir(android_ndk) then
    print("Warning: Android NDK not found at: " .. android_ndk)
end
if not os.isdir(java_home) then
    print("Warning: Java JDK not found at: " .. java_home)
end

-- 桌面版本需要 raylib 包依赖
if is_plat("windows", "linux", "macosx") then
    add_requires("raylib 5.5")
end

-- 配置 Android 相关变量
local android_configs = {
    app_name = "rgame",
    company_name = "raylib", 
    product_name = "rgame",
    version_code = 1,
    version_name = "1.0",
    package_name = "com.raylib.rgame",
    min_sdk = 30,
    target_sdk = 36,
    screen_orientation = "landscape",
    keystore_pass = "raylib"
}

-- 主目标：桌面版本（用于开发调试）
target("raylib-desktop")
    set_kind("binary")
    set_default(true)
    
    -- 添加源文件
    add_files("src/*.c")
    
    -- 添加包依赖
    add_packages("raylib")
    
    -- 添加头文件搜索路径
    add_includedirs("src")
    
    -- 平台特定配置
    if is_plat("windows") then
        add_links("opengl32", "gdi32", "winmm")
        if is_mode("release") then
            add_ldflags("/SUBSYSTEM:WINDOWS", "/ENTRY:mainCRTStartup")
        end
    elseif is_plat("linux") then
        add_links("GL", "m", "pthread", "dl", "rt", "X11")
    elseif is_plat("macosx") then
        add_frameworks("OpenGL", "Cocoa", "IOKit", "CoreAudio", "CoreVideo")
    end
    
    -- 添加资源复制规则
    after_build(function (target)
        local resources_dir = "resources"
        if os.isdir(resources_dir) then
            local targetdir = target:targetdir()
            print("Copying resources to: " .. targetdir)
            os.cp(resources_dir, targetdir)
        end
    end)

-- Android 目标
target("raylib-android")
    set_kind("shared")
    set_plat("android")
    set_targetname("main")
    
    -- 设置 Android 架构（默认 arm64-v8a）
    set_arch("arm64-v8a")
    
    -- 设置 Android NDK 工具链
    set_toolchains("ndk")
    
    -- 添加源文件
    add_files("src/*.c")
    
    -- Android 特定编译选项
    add_cflags("-std=c99", "-ffunction-sections", "-funwind-tables")
    add_cflags("-fstack-protector-strong", "-fPIC", "-Wall", "-Wextra")
    add_cflags("-Wa,--noexecstack", "-Wformat", "-Werror=format-security")
    add_cflags("-no-canonical-prefixes", "-O2")
    
    -- Android 预处理器定义
    add_defines("PLATFORM_ANDROID", "__ANDROID__")
    add_defines("__ANDROID_API__=36", "GRAPHICS_API_OPENGL_ES2")
    
    -- 链接选项
    add_ldflags("-Wl,-soname,libmain.so", "-Wl,--exclude-libs,libatomic.a")
    add_ldflags("-Wl,--build-id", "-Wl,--no-undefined", "-Wl,-z,noexecstack")
    add_ldflags("-Wl,-z,relro", "-Wl,-z,now", "-Wl,--warn-shared-textrel")
    add_ldflags("-Wl,--fatal-warnings", "-u ANativeActivity_onCreate")
    
    -- Android 系统库
    add_syslinks("m", "log", "android", "EGL", "GLESv2", "OpenSLES", "dl")
    
    -- raylib 静态库路径
    add_linkdirs("build/raylib/lib/$(arch)")
    add_links("raylib")
    
    -- 头文件路径
    add_includedirs("src")
    add_includedirs("build/raylib/include")
    
    -- 设置输出目录
    set_targetdir("build/android/lib/$(arch)")
    
    -- 配置 Android NDK
    before_build(function (target)
        if not os.getenv("ANDROID_NDK_ROOT") and not os.getenv("ANDROID_NDK") then
            if os.isdir(android_ndk) then
                os.setenv("ANDROID_NDK_ROOT", android_ndk)
            else
                raise("Android NDK not found. Please set ANDROID_NDK_ROOT environment variable.")
            end
        end
    end)

-- 构建 raylib 的任务
task("build-raylib")
    set_menu {
        usage = "xmake build-raylib [options]",
        description = "Build raylib for Android",
        options = {
            {"a", "arch", "kv", "arm64-v8a", "Android architecture (arm64-v8a, armeabi-v7a, x86, x86_64)"}
        }
    }
    
    on_run(function (option)
        local arch = option.arch or "arm64-v8a"
        
        print("Building raylib for Android (" .. arch .. ")...")
        
        -- 创建构建目录
        local build_dir = "build/raylib"
        os.mkdir(build_dir)
        os.mkdir(build_dir .. "/lib/" .. arch)
        os.mkdir(build_dir .. "/include")
        
        -- 检查是否已经有 raylib 源码
        if not os.isdir("raylib") then
            print("Downloading raylib source...")
            os.exec("git clone --depth 1 --branch 5.5 https://github.com/raysan5/raylib.git")
        end
        
        -- 设置 Android 环境变量
        os.setenv("ANDROID_NDK_ROOT", android_ndk)
        os.setenv("ANDROID_SDK_ROOT", android_sdk)
        
        -- 构建 raylib for Android
        local old_dir = os.curdir()
        os.cd("raylib/src")
        
        -- 使用 make 构建 Android 版本
        local make_cmd = string.format(
            "make PLATFORM=PLATFORM_ANDROID ANDROID_ARCH=%s ANDROID_API_VERSION=36",
            arch
        )
        
        local success = os.exec(make_cmd)
        if not success then
            print("Failed to build raylib for Android")
            os.cd(old_dir)
            return false
        end
        
        -- 复制库文件和头文件
        if os.isfile("libraylib.a") then
            os.cp("libraylib.a", "../../" .. build_dir .. "/lib/" .. arch .. "/")
            print("raylib static library copied to " .. build_dir .. "/lib/" .. arch)
        else
            print("Error: libraylib.a not found after build")
            os.cd(old_dir)
            return false
        end
        
        -- 复制头文件
        os.cp("raylib.h", "../../" .. build_dir .. "/include/")
        os.cp("raymath.h", "../../" .. build_dir .. "/include/")
        os.cp("rlgl.h", "../../" .. build_dir .. "/include/")
        
        os.cd(old_dir)
        print("raylib build completed successfully!")
        return true
    end)

-- APK 构建任务
task("build-apk")
    set_menu {
        usage = "xmake build-apk [options]",
        description = "Build Android APK package",
        options = {
            {"a", "arch", "kv", "arm64-v8a", "Android architecture"},
            {"k", "keystore", "kv", nil, "Keystore file path"},
            {"p", "password", "kv", "raylib", "Keystore password"}
        }
    }
    
    on_run(function (option)
        local arch = option.arch or "arm64-v8a"
        local keystore_pass = option.password or "raylib"
        
        print("Building APK for " .. arch .. "...")
        
        -- 确保已构建 raylib
        print("Building raylib for Android...")
        local build_success = os.exec("xmake build-raylib -a " .. arch)
        if not build_success then
            print("Failed to build raylib")
            return false
        end
        
        -- 构建 native 库
        print("Building native library...")
        local native_success = os.exec("xmake build raylib-android")
        if not native_success then
            print("Failed to build native library")
            return false
        end
        
        -- 创建项目目录结构
        local build_dir = "build/android." .. android_configs.app_name
        local dirs = {
            build_dir,
            build_dir .. "/obj",
            build_dir .. "/src/com/" .. android_configs.company_name .. "/" .. android_configs.product_name,
            build_dir .. "/lib/" .. arch,
            build_dir .. "/bin",
            build_dir .. "/res/drawable-ldpi",
            build_dir .. "/res/drawable-mdpi", 
            build_dir .. "/res/drawable-hdpi",
            build_dir .. "/res/values",
            build_dir .. "/assets/resources"
        }
        
        for _, dir in ipairs(dirs) do
            os.mkdir(dir)
        end
        
        -- 生成 AndroidManifest.xml
        local manifest_content = string.format([[
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
        package="%s"
        android:versionCode="%d" android:versionName="%s">
    <uses-sdk android:minSdkVersion="%d" />
    <uses-feature android:glEsVersion="0x00020000" android:required="true" />
    <application android:allowBackup="false" android:label="@string/app_name" android:icon="@drawable/icon">
        <activity android:name="%s.NativeLoader"
            android:theme="@android:style/Theme.NoTitleBar.Fullscreen"
            android:configChanges="orientation|keyboard|keyboardHidden|screenSize"
            android:screenOrientation="%s" android:launchMode="singleTask"
            android:clearTaskOnLaunch="true" android:exported="true">
            <meta-data android:name="android.app.lib_name" android:value="main" />
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>]], 
            android_configs.package_name,
            android_configs.version_code,
            android_configs.version_name,
            android_configs.min_sdk,
            android_configs.package_name,
            android_configs.screen_orientation)
        
        io.writefile(build_dir .. "/AndroidManifest.xml", manifest_content)
        
        -- 生成 strings.xml
        local strings_content = string.format([[
<?xml version="1.0" encoding="utf-8"?>
<resources><string name="app_name">%s</string></resources>]], android_configs.app_name)
        
        io.writefile(build_dir .. "/res/values/strings.xml", strings_content)
        
        -- 生成 NativeLoader.java
        local java_content = string.format([[
package %s;

public class NativeLoader extends android.app.NativeActivity {
    static {
        System.loadLibrary("main");
    }
}]], android_configs.package_name)
        
        local java_file = build_dir .. "/src/com/" .. android_configs.company_name .. "/" .. android_configs.product_name .. "/NativeLoader.java"
        io.writefile(java_file, java_content)
        
        -- 复制 native 库
        local native_lib = "build/android/lib/" .. arch .. "/libmain.so"
        if os.isfile(native_lib) then
            os.cp(native_lib, build_dir .. "/lib/" .. arch .. "/")
            print("Native library copied")
        else
            print("Warning: Native library not found at " .. native_lib)
        end
        
        -- 复制资源文件
        if os.isdir("src/resources") then
            os.cp("src/resources/*", build_dir .. "/assets/resources/")
            print("Resources copied to assets")
        end
        
        -- 生成或复制应用图标
        local icon_paths = {
            "assets/icon.png",
            "resources/icon.png", 
            "icon.png"
        }
        
        local icon_found = false
        for _, icon_path in ipairs(icon_paths) do
            if os.isfile(icon_path) then
                os.cp(icon_path, build_dir .. "/res/drawable-mdpi/icon.png")
                os.cp(icon_path, build_dir .. "/res/drawable-hdpi/icon.png")
                os.cp(icon_path, build_dir .. "/res/drawable-ldpi/icon.png")
                icon_found = true
                break
            end
        end
        
        if not icon_found then
            print("Warning: No icon found, using default")
        end
        
        -- 编译 Java 代码
        print("Compiling Java code...")
        local java_compile_cmd = string.format(
            '"%s/bin/javac" -cp "%s/platforms/android-%d/android.jar" -d "%s/obj" "%s"',
            java_home, android_sdk, android_configs.target_sdk, build_dir, java_file
        )
        
        local java_success = os.exec(java_compile_cmd)
        if not java_success then
            print("Failed to compile Java code")
            return false
        end
        
        -- 生成 R.java
        print("Generating R.java...")
        local aapt_cmd = string.format(
            '"%s/build-tools/36.0.0/aapt" package -f -m -J "%s/src" -M "%s/AndroidManifest.xml" -S "%s/res" -I "%s/platforms/android-%d/android.jar"',
            android_sdk, build_dir, build_dir, build_dir, android_sdk, android_configs.target_sdk
        )
        
        local aapt_success = os.exec(aapt_cmd)
        if not aapt_success then
            print("Failed to generate R.java")
            return false
        end
        
        -- 编译 R.java
        local r_java_file = build_dir .. "/src/" .. string.gsub(android_configs.package_name, "%.", "/") .. "/R.java"
        if os.isfile(r_java_file) then
            local r_compile_cmd = string.format(
                '"%s/bin/javac" -cp "%s/platforms/android-%d/android.jar" -d "%s/obj" "%s"',
                java_home, android_sdk, android_configs.target_sdk, build_dir, r_java_file
            )
            os.exec(r_compile_cmd)
        end
        
        -- 创建 dex 文件
        print("Creating dex file...")
        local dx_cmd = string.format(
            '"%s/build-tools/36.0.0/dx" --dex --output="%s/bin/classes.dex" "%s/obj"',
            android_sdk, build_dir, build_dir
        )
        
        local dx_success = os.exec(dx_cmd)
        if not dx_success then
            print("Failed to create dex file")
            return false
        end
        
        -- 创建未签名的 APK
        print("Creating unsigned APK...")
        local apk_file = build_dir .. "/bin/" .. android_configs.app_name .. ".unsigned.apk"
        local aapt_apk_cmd = string.format(
            '"%s/build-tools/36.0.0/aapt" package -f -M "%s/AndroidManifest.xml" -S "%s/res" -A "%s/assets" -I "%s/platforms/android-%d/android.jar" -F "%s" "%s/bin"',
            android_sdk, build_dir, build_dir, build_dir, android_sdk, android_configs.target_sdk, apk_file, build_dir
        )
        
        local apk_success = os.exec(aapt_apk_cmd)
        if not apk_success then
            print("Failed to create APK")
            return false
        end
        
        -- 添加 native 库到 APK
        if os.isfile(build_dir .. "/lib/" .. arch .. "/libmain.so") then
            local aapt_lib_cmd = string.format(
                '"%s/build-tools/36.0.0/aapt" add "%s" lib/%s/libmain.so',
                android_sdk, apk_file, arch
            )
            os.cd(build_dir)
            os.exec(aapt_lib_cmd)
            os.cd("../..")
        end
        
        -- 生成密钥库（如果不存在）
        local keystore_file = build_dir .. "/" .. android_configs.app_name .. ".keystore"
        if not os.isfile(keystore_file) then
            print("Generating keystore...")
            local keytool_cmd = string.format(
                '"%s/bin/keytool" -genkeypair -validity 1000 -dname "CN=%s,O=Android,C=ES" -keystore "%s" -storepass %s -keypass %s -alias projectKey -keyalg RSA',
                java_home, android_configs.company_name, keystore_file, keystore_pass, keystore_pass
            )
            os.exec(keytool_cmd)
        end
        
        -- 签名 APK
        print("Signing APK...")
        local final_apk = "build/" .. android_configs.app_name .. ".apk"
        local jarsigner_cmd = string.format(
            '"%s/bin/jarsigner" -keystore "%s" -storepass %s -keypass %s -signedjar "%s" "%s" projectKey',
            java_home, keystore_file, keystore_pass, keystore_pass, final_apk, apk_file
        )
        
        local sign_success = os.exec(jarsigner_cmd)
        if not sign_success then
            print("Failed to sign APK")
            return false
        end
        
        -- 对齐 APK
        print("Aligning APK...")
        local temp_apk = final_apk .. ".temp"
        os.mv(final_apk, temp_apk)
        
        local zipalign_cmd = string.format(
            '"%s/build-tools/36.0.0/zipalign" -f 4 "%s" "%s"',
            android_sdk, temp_apk, final_apk
        )
        
        local align_success = os.exec(zipalign_cmd)
        if align_success then
            os.rm(temp_apk)
            print("APK created successfully: " .. final_apk)
        else
            os.mv(temp_apk, final_apk)
            print("APK alignment failed, but APK is still usable: " .. final_apk)
        end
        
        print("APK build completed!")
        print("APK file: " .. final_apk)
        print("Build directory: " .. build_dir)
    end)

-- 清理任务
task("clean-all")
    set_menu {
        usage = "xmake clean-all",
        description = "Clean all build artifacts including raylib"
    }
    
    on_run(function ()
        os.exec("xmake clean")
        if os.isdir("build") then
            os.rmdir("build")
            print("Build directory removed")
        end
    end)

-- 安装任务（安装 APK 到设备）
task("install-apk")
    set_menu {
        usage = "xmake install-apk",
        description = "Install APK to connected Android device"
    }
    
    on_run(function ()
        local apk_file = "build/" .. android_configs.app_name .. ".apk"
        if os.isfile(apk_file) then
            os.exec("adb install " .. apk_file)
            print("APK installed successfully")
        else
            print("APK file not found: " .. apk_file)
            print("Please build APK first with: xmake build-apk")
        end
    end)

-- 日志监控任务
task("logcat")
    set_menu {
        usage = "xmake logcat",
        description = "Monitor Android device logs (raylib only)"
    }
    
    on_run(function ()
        print("Starting logcat for raylib...")
        os.exec("adb logcat -c")
        os.exec("adb logcat raylib:V *:S")
    end)

-- 部署任务（构建、安装、监控日志）
task("deploy")
    set_menu {
        usage = "xmake deploy",
        description = "Build APK, install to device and monitor logs"
    }
    
    on_run(function ()
        print("Deploying raylib Android app...")
        os.exec("xmake build-apk")
        os.exec("xmake install-apk")
        os.exec("xmake logcat")
    end)