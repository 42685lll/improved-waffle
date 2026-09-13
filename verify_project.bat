@echo off
REM verify_project.bat - Windows 版出包前自检
cd /d "%~dp0"
echo === 检查关键文件 ===
for %%f in (
  build.gradle.kts settings.gradle.kts gradlew gradlew.bat
  gradle\wrapper\gradle-wrapper.properties
  app\build.gradle.kts app\proguard-rules.pro
  app\src\main\AndroidManifest.xml
  app\src\main\assets\core\ai_core.js
  app\src\main\assets\core\bridge.js
  app\src\main\assets\core\emotion.js
  app\src\main\assets\core\index.html
  app\src\main\assets\core\prompt_hoshino.txt
  app\src\main\java\com\example\starhoshino\MainActivity.kt
  app\src\main\java\com\example\starhoshino\SettingsActivity.kt
  app\src\main\java\com\example\starhoshino\view\DiskView.kt
  app\src\main\res\layout\activity_main.xml
  app\src\main\res\layout\activity_settings.xml
  .github\workflows\build-apk.yml
) do (
  if exist "%%f" (echo   OK   %%f) else (echo   MISS %%f && exit /b 1)
)
echo.
echo === index.html 引用的脚本 ===
findstr /r /c:"src=\"[a-z_]*\.js\"" app\src\main\assets\core\index.html
echo.
echo 所有关键文件存在，可以打开 Android Studio 构建。
echo 若需要 JS 语法检查，请安装 Node.js 后运行: node --check app\src\main\assets\core\ai_core.js
