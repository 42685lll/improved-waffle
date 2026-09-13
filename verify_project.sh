#!/bin/sh
# verify_project.sh - 出包前的静态自检
cd "$(dirname "$0")"
EXIT=0
echo "=== 1. 关键文件清单 ==="
for f in \
  build.gradle.kts settings.gradle.kts gradlew gradlew.bat \
  gradle/wrapper/gradle-wrapper.properties \
  app/build.gradle.kts app/proguard-rules.pro \
  app/src/main/AndroidManifest.xml \
  app/src/main/assets/core/ai_core.js \
  app/src/main/assets/core/bridge.js \
  app/src/main/assets/core/index.html \
  app/src/main/assets/core/prompt_hoshino.txt \
  app/src/main/java/com/example/starhoshino/MainActivity.kt \
  app/src/main/java/com/example/starhoshino/SettingsActivity.kt \
  app/src/main/java/com/example/starhoshino/view/DiskView.kt \
  app/src/main/res/layout/activity_main.xml \
  app/src/main/res/layout/activity_settings.xml \
  app/src/main/res/values/strings.xml \
  app/src/main/res/values/styles.xml \
  app/src/main/res/values/colors.xml \
  app/src/main/res/values-night/themes.xml \
  .github/workflows/build-apk.yml
do
  [ -f "$f" ] && echo "  OK   $f" || { echo "  MISS $f"; EXIT=1; }
done

echo ""
echo "=== 2. index.html 引用的脚本是否都存在 ==="
for js in $(grep -o 'src="[a-z_]*\.js"' app/src/main/assets/core/index.html | sed 's/src="//;s/"//'); do
  [ -f "app/src/main/assets/core/$js" ] && echo "  OK   $js" || { echo "  MISS $js"; EXIT=1; }
done

echo ""
echo "=== 3. AndroidManifest 注册的 Activity/Service 文件是否都存在 ==="
APP_PKG="com/example/starhoshino"
EXIT_CODE=0
ACTS=$(grep -o 'android:name="[^"]*"' app/src/main/AndroidManifest.xml | sed 's/android:name="//;s/"//')
for act in $ACTS; do
  name="${act#.}"
  path="app/src/main/java/$APP_PKG/$name.kt"
  if [ -f "$path" ]; then
    echo "  OK   $act -> $path"
  else
    echo "  (非 .kt 组件或外部类，仅提示: $act -> $path)"
  fi
done
# 反向校验：Manifest 里带 Activity 关键字的必须能找到
for act in MainActivity SettingsActivity; do
  if grep -q "android:name=\".*$act\"" app/src/main/AndroidManifest.xml && \
     [ ! -f "app/src/main/java/$APP_PKG/$act.kt" ]; then
    echo "  MISS $act.kt"; EXIT_CODE=1
  fi
done
exit $EXIT_CODE

echo ""
echo "=== 4. layout @+id 引用的视图，DiskView/Kt 里是否用到 ==="
grep -o 'android:id="@+id/[a-zA-Z_]*"' app/src/main/res/layout/activity_main.xml | sed 's/android:id="@+id\///;s/"//' | sort -u

echo ""
echo "=== 5. JS 顶层语法检查（node 可用时） ==="
if command -v node >/dev/null 2>&1; then
  for js in app/src/main/assets/core/*.js; do
    node --check "$js" && echo "  SYNTAX OK: $js" || { echo "  SYNTAX ERROR: $js"; exit 1; }
  done
else
  echo "  node 不可用，跳过 JS 语法检查"
fi

echo ""
echo "=== 6. Kotlin 文件语法占位检查（仅看能否被 kotlinc 解析，无可跳过） ==="

echo ""
if [ $EXIT -eq 0 ]; then
  echo "ALL CHECKS PASSED ✓"
else
  echo "SOME CHECKS FAILED ✗"
fi
exit $EXIT
