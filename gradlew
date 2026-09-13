#!/bin/sh
# gradlew - Gradle Wrapper 启动脚本
# 优先使用随工程附带的 gradle/wrapper/gradle-wrapper.jar；
# 若 jar 不存在则回退到系统已安装的 gradle 命令。
DIR="$(cd "$(dirname "$0")" && pwd)"
WRAPPER_JAR="$DIR/gradle/wrapper/gradle-wrapper.jar"
if [ -f "$WRAPPER_JAR" ]; then
    exec java -classpath "$WRAPPER_JAR" org.gradle.wrapper.GradleWrapperMain "$@"
else
    exec gradle "$@"
fi
