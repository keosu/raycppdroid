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

-- 添加包依赖
add_requires("raylib 5.5")

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
    
    -- 设置 Android 架构（默认 arm64-v8a）
    set_arch("arm64-v8a")
    
    -- 添加源文件
    add_files("src/*.c")
    
    -- Android 特定编译选项
    add_cflags("-std=c99", "-ffunction-sections", "-funwind-tables")
    add_cflags("-fstack-protector-strong", "-fPIC", "-Wall")
    add_cflags("-Wa,--noexecstack", "-Wformat", "-Werror=format-security")
    add_cflags("-no-canonical-prefixes")
    
    -- Android 预处理器定义
    add_defines("__ANDROID__", "PLATFORM_ANDROID")
    add_defines("__ANDROID_API__=36")
    
    -- 链接选项
    add_ldflags("-Wl,-soname,libmain.so", "-Wl,--exclude-libs,libatomic.a")
    add_ldflags("-Wl,--build-id", "-Wl,--no-undefined", "-Wl,-z,noexecstack")
    add_ldflags("-Wl,-z,relro", "-Wl,-z,now", "-Wl,--warn-shared-textrel")
    add_ldflags("-Wl,--fatal-warnings", "-u ANativeActivity_onCreate")
    
    -- Android 系统库
    add_links("m", "c", "log", "android", "EGL", "GLESv2", "OpenSLES", "dl")
    
    -- raylib 库（需要单独编译）
    add_linkdirs("build/lib/arm64-v8a")
    add_links("raylib")
    
    -- 头文件路径
    add_includedirs("src")
    add_includedirs("build/_deps/raylib-src/src")

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
        
        -- 使用 CMake 构建 raylib
        print("Building raylib for Android (" .. arch .. ")...")
        
        -- 创建构建目录
        os.mkdir("build")
        os.cd("build")
        
        -- 运行 CMake 配置
        os.exec("cmake -S .. -B . -DCMAKE_BUILD_TYPE=Release")
        
        -- 构建 raylib
        os.exec("make -C _deps/raylib-src/src PLATFORM=PLATFORM_ANDROID")
        
        -- 复制库文件到指定位置
        local lib_dir = "lib/" .. arch
        os.mkdir(lib_dir)
        
        local raylib_src = "_deps/raylib-src/src"
        if os.isfile(raylib_src .. "/libraylib.a") then
            os.cp(raylib_src .. "/libraylib.a", lib_dir .. "/")
            print("raylib static library copied to " .. lib_dir)
        end
        
        os.cd("..")
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
        
        -- 确保已构建 native 库
        os.exec("xmake build raylib-android")
        
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
        
        print("APK build structure created successfully!")
        print("Note: You'll need to set up Android SDK/NDK environment variables and complete the build process manually.")
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