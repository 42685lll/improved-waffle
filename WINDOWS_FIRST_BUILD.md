# 首次构建须知（Windows 用户必读）

## 关于 `gradlew` 和 `gradle-wrapper.jar`

本工程**故意没有**包含 `gradle/wrapper/gradle-wrapper.jar`（二进制文件），
它在**你的电脑上首次构建时自动生成**，方式二选一：

### 方式 A：用 Android Studio 打开（最省心，推荐）
1. 安装 Android Studio（会自带 Gradle）
2. Open → 选 `starhoshino/` 文件夹
3. AS 自动同步时**会生成** `gradle-wrapper.jar` 和 `gradlew`
4. 之后就能用命令行 `gradlew.bat assembleDebug` 了

### 方式 B：命令行手动生成
1. 安装 Gradle（`choco install gradle` 或官网下载）
2. 在工程根目录执行：
   ```
   gradle wrapper --gradle-version 8.7
   ```
3. 会自动生成 `gradle/wrapper/gradle-wrapper.jar` 和完整的 `gradlew`

---

## 最简单的路径（强烈推荐新手）

**不要折腾命令行。** 直接：

1. 装 Android Studio
2. Open 本工程
3. 等 Gradle Sync 完成
4. 点绿色三角 ▶️ Run

这是 Google 官方支持的方式，遇到问题 AS 会给出明确的错误提示，
比命令行红字好懂一百倍。

---

## 如果你坚持用命令行

确保已设置：
```
ANDROID_HOME = C:\Users\你的用户名\AppData\Local\Android\Sdk
Path 追加：  %ANDROID_HOME%\platform-tools
```
且 `java -version` 显示 17。

然后：
```
cd starhoshino
gradlew.bat assembleDebug
```

APK 输出：`app\build\outputs\apk\debug\app-debug.apk`
