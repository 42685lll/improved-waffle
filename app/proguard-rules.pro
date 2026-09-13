# 首版不混淆，后续发布时再配置
-dontobfuscate

# WebView JavascriptInterface 保留
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Kotlin 反射
-keep class kotlin.** { *; }
-keep class com.example.starhoshino.** { *; }
