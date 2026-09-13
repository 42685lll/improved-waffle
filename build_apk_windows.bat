@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ============================================
echo   StarHoshino - 本地 APK 构建脚本 (Windows)
echo ============================================
echo.

REM === 1. 检查环境变量 ===
echo [1/6] 检查环境...

if "%ANDROID_HOME%"=="" (
    if "%ANDROID_SDK_ROOT%"=="" (
        echo [ERROR] 未找到 ANDROID_HOME 或 ANDROID_SDK_ROOT
        echo 请设置环境变量：
        echo   ANDROID_HOME = C:\Users\%USERNAME%\AppData\Local\Android\Sdk
        echo   或
        echo   ANDROID_SDK_ROOT = C:\Users\%USERNAME%\AppData\Local\Android\Sdk
        echo.
        echo 或者通过 Android Studio 安装 SDK 后自动配置。
        pause
        exit /b 1
    ) else (
        set ANDROID_HOME=%ANDROID_SDK_ROOT%
    )
)

echo   ANDROID_HOME = %ANDROID_HOME%

REM 检查 Java
where java >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] 未安装 Java JDK 17
    echo 请从以下地址下载安装：
    echo   https://adoptium.net/temurin/releases/?version=17
    pause
    exit /b 1
)

java -version 2>&1 | findstr /i "17" >nul
if %ERRORLEVEL% neq 0 (
    echo [WARN] 当前 Java 版本可能不是 17，构建可能失败
)

REM === 2. 检查/安装 SDK 组件 ===
echo.
echo [2/6] 检查 SDK 组件...
"%ANDROID_HOME%\cmdline-tools\latest\bin\sdkmanager.bat" "platforms;android-35" "build-tools;35.0.0" "platform-tools"
if %ERRORLEVEL% neq 0 (
    REM 尝试旧路径
    "%ANDROID_HOME%\tools\bin\sdkmanager" "platforms;android-35" "build-tools;35.0.0" "platform-tools"
)

REM === 3. 检查/生成 gradle wrapper ===
echo.
echo [3/6] 检查 Gradle Wrapper...
if not exist "gradlew" (
    echo 未找到 gradlew，尝试生成...
    where gradle >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        gradle wrapper --gradle-version 8.7
    ) else (
        echo [WARN] 未安装 Gradle，尝试下载...
        call :downloadGradle
    )
)

REM === 4. 授予执行权限 ===
echo.
echo [4/6] 准备构建...
if exist "gradlew" (
    echo 使用 Gradle Wrapper
) else (
    echo 使用系统 Gradle
)

REM === 5. 构建 APK ===
echo.
echo [5/6] 开始构建 APK...
echo 选择构建类型：
echo   1) Debug (推荐首版测试)
echo   2) Release (需要签名配置)
echo.
set /p BUILD_CHOICE="请输入选项 (默认 1): "

if "%BUILD_CHOICE%"=="2" (
    echo 构建 Release APK...
    if exist "gradlew" (
        call gradlew.bat assembleRelease --no-daemon --stacktrace
    ) else (
        gradle assembleRelease --no-daemon --stacktrace
    )
) else (
    echo 构建 Debug APK...
    if exist "gradlew" (
        call gradlew.bat assembleDebug --no-daemon --stacktrace
    ) else (
        gradle assembleDebug --no-daemon --stacktrace
    )
)

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] 构建失败！请检查错误信息。
    pause
    exit /b 1
)

REM === 6. 显示结果 ===
echo.
echo [6/6] 构建完成！
echo ============================================
echo APK 输出位置：
echo.

if "%BUILD_CHOICE%"=="2" (
    if exist "app\build\outputs\apk\release" (
        dir /b "app\build\outputs\apk\release\*.apk"
    )
) else (
    if exist "app\build\outputs\apk\debug" (
        dir /b "app\build\outputs\apk\debug\*.apk"
    )
)

echo.
echo ============================================
echo 安装到设备：
echo   adb install -r app\build\outputs\apk\debug\app-debug.apk
echo.
pause
exit /b 0

REM === 下载 Gradle ===
:downloadGradle
echo 正在下载 Gradle 8.7...
set GRADLE_ZIP=gradle-8.7-bin.zip
set GRADLE_URL=https://services.gradle.org/distributions/%GRADLE_ZIP%

where curl >nul 2>&1
if %ERRORLEVEL% equ 0 (
    curl -L -o "%GRADLE_ZIP%" "%GRADLE_URL%"
) else (
    where powershell >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        powershell -Command "Invoke-WebRequest -Uri '%GRADLE_URL%' -OutFile '%GRADLE_ZIP%'"
    ) else (
        echo [ERROR] 无法下载 Gradle，请手动安装：
        echo   https://gradle.org/install/
        pause
        exit /b 1
    )
)

echo 解压 Gradle...
if not exist "gradle" mkdir gradle
tar -xf "%GRADLE_ZIP%" -C "gradle"
set PATH=%CD%\gradle\gradle-8.7\bin;%PATH%
echo Gradle 已准备好。
goto :eof
