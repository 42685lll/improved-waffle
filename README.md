# StarHoshino — 小鸟游星野语音伴侣

> 碧蓝档案 · 小鸟游星野 AI 伴侣 | 圆盘波形 · 三层记忆 · 粘人情绪

---

## 🚀 快速开始（最重要的一步）

拿到本文件夹后，**先跑自检脚本**，确认文件没传丢：

- **Windows**：双击 `verify_project.bat`
- **macOS / Linux**：`./verify_project.sh`
- **GitHub Actions**：push 后自动跑 `build-apk.yml`（内含同样的校验）

全部显示 `OK` / `ALL CHECKS PASSED` 再往下走。

---

## 📁 真实目录结构

```
starhoshino/
├── build.gradle.kts                     # 根 Gradle 配置（Kotlin 1.9.24 / AGP 8.5.2 / KSP）
├── settings.gradle.kts                  # 模块声明
├── gradlew / gradlew.bat               # Gradle Wrapper 启动脚本（Windows 用 .bat）
├── gradle.properties
├── .gitignore
├── README.md
├── verify_project.sh / .bat            # ★ 出包前先跑这个
├── build_apk_windows.bat               # Windows 一键构建
├── build_apk_macos.sh                  # macOS/Linux 一键构建
│
├── .github/workflows/build-apk.yml     # GitHub Actions 自动构建
│
├── gradle/wrapper/gradle-wrapper.properties   # Gradle 8.7
│
└── app/
    ├── build.gradle.kts                # App 依赖、compileSdk 35、minSdk 34
    ├── proguard-rules.pro
    └── src/main/
        ├── AndroidManifest.xml         # 权限 + Activity 注册
        ├── java/com/example/starhoshino/
        │   ├── MainActivity.kt        # WebView + 原生桥接
        │   ├── SettingsActivity.kt     # 设置页
        │   └── view/DiskView.kt       # 圆盘波形自定义 View
        ├── res/
        │   ├── layout/activity_main.xml
        │   ├── layout/activity_settings.xml
        │   ├── values/{strings,styles,colors}.xml
        │   ├── values-night/themes.xml
        │   └── drawable/btn_round_bg.xml
        └── assets/core/                # ★ WebView 加载的前端
            ├── index.html              # 入口（只引 ai_core.js + bridge.js）
            ├── ai_core.js              # ★ 智能核心（记忆/情绪/人格全在这一个文件）
            ├── bridge.js               # ★ JS ↔ 原生桥接（LLM/TTS/VAD/SQL/文件）
            └── prompt_hoshino.txt      # ★ 星野人格 prompt
```

> 标有 ★ 的是运行时真正被加载的文件。`ai_core.js` 已整合了记忆三层、Recall 检索、用户档案、情绪/亲密值——**单文件，稳定**。

---

## 🛠️ 环境准备（电脑上一次性）

| 工具 | 版本 | 安装 |
|------|------|------|
| **JDK** | 17 (Temurin) | https://adoptium.net/temurin/releases/?version=17 |
| **Android SDK** | API 35 | 装 Android Studio → SDK Manager |
| **Android Studio** | 最新 | https://developer.android.com/studio |

**环境变量（Windows）**：
```
ANDROID_HOME = C:\Users\你的用户名\AppData\Local\Android\Sdk
Path 追加：  %ANDROID_HOME%\platform-tools
```

---

## 🔨 三种构建方式（任选其一）

### 方式一：GitHub Actions（零环境，推荐）
1. GitHub 建仓库 → 上传整个 `starhoshino/` 文件夹
2. **Actions** → 选 `Build StarHoshino APK` → `Run workflow`
3. 等 10-15 分钟 → 下载 Artifact `StarHoshino-Debug-APK` → 解压得 `app-debug.apk`

### 方式二：Android Studio（最直观）
1. 打开 Android Studio → **Open** → 选 `starhoshino/` 文件夹
2. 等 **Gradle Sync finished**
3. 手机开 USB 调试连电脑 → 顶部点 **绿色三角 ▶️ Run**
4. 或菜单 **Build → Build APK(s)** → APK 在 `app/build/outputs/apk/debug/`

### 方式三：命令行
```bash
cd starhoshino
./gradlew assembleDebug          # macOS/Linux
gradlew.bat assembleDebug       # Windows
```

---

## 📱 安装到手机

```bash
adb install -r app/build/outputs/apk/debug/app-debug.apk
```
或直接把 `app-debug.apk` 传到手机 → 文件管理器打开 → 允许"安装未知来源" → 安装。

---

## ⚙️ 首版功能状态

| 功能 | 状态 | 说明 |
|------|------|------|
| 圆盘波形动画 | ✅ | DiskView |
| 长按说话 | ⚠️ 占位 | 需接 VAD，首版可点击触发 |
| 星野回复 | ⚠️ 占位 | 回复池随机，接大模型后替换 `callLLM` |
| TTS 播放 | ⚠️ 占位 | 接 TTS 引擎即可 |
| 三层记忆 + 用户档案 | ✅ | localStorage + 原生 saveWarmLayer |
| 粘人情绪 / 亲密值 | ✅ | localStorage 持久化 |
| chat.json 导出 | ✅ | bridge.js exportChatJson |
| 大模型接入 | ❌ | 后续版本 |

---

## 🔧 后续接入

### 接大模型
在 `bridge.js` 的 `callLLM()` 里替换 `A.llm(...)` 的实现，或在 Kotlin 侧实现：
```kotlin
@JavascriptInterface
fun llm(payloadJson: String): String {
    // 调用你的模型 API，返回回复文本（可带 [[EMO:开心|+2]] 标记）
}
```

### 接 TTS / VAD
```kotlin
@JavascriptInterface fun tts(text: String) { /* 系统 TTS */ }
// VAD 检测到用户说完 → webView.evaluateJavascript("onUserEnd('$text')")
```

---

## 📋 已知事项
- `mipmap-*/ic_launcher` 图标如缺失：Android Studio → File → New → Image Asset 生成一个
- `local.properties` 不提交（已 gitignore），本地需指向 SDK
- 首版用 Debug 签名，发布前需配 Release 签名
- `minSdk = 34`（Android 14），老机型需自行调低

---

> 「呼啊~前辈，大叔我会一直在这里等你回来的啦~」
