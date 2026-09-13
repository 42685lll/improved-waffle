package com.example.starhoshino

import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.util.Log
import android.view.WindowManager
import android.webkit.JavascriptInterface
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.appcompat.app.AppCompatActivity
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkRequest
import com.example.starhoshino.permission.PermissionHelper
import com.example.starhoshino.push.HoshinoPushWorker
import com.example.starhoshino.utils.FileUtil
import com.example.starhoshino.view.DiskView
import java.util.concurrent.TimeUnit

class MainActivity : AppCompatActivity() {

    companion object {
        const val TAG = "StarHoshino"
    }

    lateinit var diskView: DiskView
    lateinit var webView: WebView
    private lateinit var permissionHelper: PermissionHelper
    private lateinit var sp: SharedPreferences

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        diskView = findViewById(R.id.disk_view)
        webView = findViewById(R.id.web_core)
        permissionHelper = PermissionHelper(this)
        sp = getSharedPreferences("hoshino_sp", MODE_PRIVATE)

        if (!permissionHelper.checkAllPermissions()) {
            permissionHelper.showRationaleDialog {
                permissionHelper.requestPermissions()
            }
        }

        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            loadWithOverviewMode = true
            useWideViewPort = true
        }
        webView.webViewClient = object : WebViewClient() {
            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                injectPrompt()
            }
        }
        webView.loadUrl("file:///android_asset/core/index.html")
        webView.addJavascriptInterface(NativeBridge(), "AndroidBridge")

        diskView.onDoubleTap = {
            startActivity(Intent(this, SettingsActivity::class.java))
        }

        diskView.setSilentWave()
        schedulePushWorker()
    }

    private fun injectPrompt() {
        try {
            val prompt = assets.open("core/prompt_hoshino.txt")
                .bufferedReader(Charsets.UTF_8)
                .use { it.readText() }
            val escaped = prompt.replace("'", "\\'").replace("\n", "\\n")
            webView.evaluateJavascript(
                "window.HOSHINO_PROMPT = '$escaped'; if(window.HoshinoCore) window.HoshinoCore.init();",
                null
            )
        } catch (e: Exception) {
            Log.w(TAG, "Prompt injection failed", e)
        }
    }

    private fun schedulePushWorker() {
        val delayHour = (4..5).random().toLong()
        val work: WorkRequest = OneTimeWorkRequestBuilder<HoshinoPushWorker>()
            .setInitialDelay(delayHour, TimeUnit.HOURS)
            .build()
        WorkManager.getInstance(this).enqueue(work)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PermissionHelper.PERMISSION_REQ_CODE) {
            permissionHelper.onRequestResult(permissions, grantResults)
        }
    }

    inner class NativeBridge {

        @JavascriptInterface
        fun updateWave(ampJson: String) {
            runOnUiThread {
                try {
                    val cleanJson = ampJson.trim().removeSurrounding("[", "]")
                    val arr = cleanJson.split(",").map { it.trim().toFloat() }.toFloatArray()
                    diskView.setWaveAmplitude(arr)
                } catch (e: Exception) {
                    Log.w(TAG, "updateWave error: $ampJson", e)
                }
            }
        }

        @JavascriptInterface
        fun setWave(mode: String) {
            runOnUiThread { diskView.setSilentWave() }
        }

        @JavascriptInterface
        fun setWaveAmp(ampsJson: String) {
            updateWave(ampsJson)
        }

        @JavascriptInterface
        fun playTTS(text: String) {
            runOnUiThread {
                diskView.startSpeakingAnimation()
                diskView.postDelayed({ diskView.stopSpeakingAnimation() }, 3000)
            }
        }

        @JavascriptInterface
        fun saveWarmLayer(jsonStr: String) {
            getSharedPreferences("hoshino_memory", MODE_PRIVATE)
                .edit().putString("warm_layer", jsonStr).apply()
        }

        @JavascriptInterface
        fun exportChatJson(jsonStr: String) {
            FileUtil.saveJsonToExternal(this@MainActivity, jsonStr, "chat.json")
        }

        @JavascriptInterface
        fun fileRead(fileName: String): String {
            return FileUtil.readExternalFile(this@MainActivity, fileName) ?: ""
        }

        @JavascriptInterface
        fun fileWrite(fileName: String, text: String) {
            FileUtil.saveJsonToExternal(this@MainActivity, text, fileName)
        }

        @JavascriptInterface
        fun exec(sql: String): String? {
            Log.d(TAG, "SQL exec: $sql")
            return null
        }

        @JavascriptInterface
        fun query(sql: String): String {
            Log.d(TAG, "SQL query: $sql")
            return "[]"
        }

        @JavascriptInterface
        fun vadState(): String = "idle"

        @JavascriptInterface
        fun llm(payloadJson: String): String = ""

        @JavascriptInterface
        fun onMemoryRestored(result: String) {
            runOnUiThread { Log.d(TAG, "Memory restored: $result") }
        }

        @JavascriptInterface
        fun onCoreReady(status: String) {
            runOnUiThread {
                Log.d(TAG, "AI Core ready: $status")
                diskView.setSilentWave()
            }
        }
    }

    override fun onStop() {
        super.onStop()
        sp.edit().putLong("last_quit_ts", System.currentTimeMillis()).apply()
        webView.evaluateJavascript("if(window.HoshinoCore) HoshinoCore.onAppExit();", null)
    }

    override fun onPause() {
        super.onPause()
        diskView.setSilentWave()
    }

    override fun onResume() {
        super.onResume()
        diskView.setSilentWave()
        val lastQuit = sp.getLong("last_quit_ts", 0L)
        val awayMs = if (lastQuit > 0) System.currentTimeMillis() - lastQuit else 0
        webView.evaluateJavascript(
            "if(window.HoshinoCore) HoshinoCore.onAppForeground($awayMs);", null
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        webView.removeJavascriptInterface("AndroidBridge")
    }
}
