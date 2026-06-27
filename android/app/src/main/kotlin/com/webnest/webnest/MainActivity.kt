package com.webnest.webnest

import android.app.ActivityManager
import android.app.PictureInPictureParams
import android.content.Intent
import android.net.Uri
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Bundle
import android.webkit.CookieManager
import android.webkit.WebStorage
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.webnest.webnest.engine.WebNestEngineFactory
import com.webnest.webnest.engine.WebNestShieldEngine
import com.webnest.webnest.shortcut.ShortcutHandler

class MainActivity : FlutterActivity() {
    private val PIP_CHANNEL      = "com.webnest/pip"
    private val SHORTCUT_CHANNEL = "com.webnest/shortcut"
    private val SHIELD_CHANNEL   = "com.webnest/shield"
    private val SETTINGS_CHANNEL = "com.webnest/settings"

    private var shortcutChannel: MethodChannel? = null
    private var pendingShortcutAppId: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        if ("com.webnest.webnest.LAUNCH_APP" == intent.action) {
            val appId = intent.getStringExtra(ShortcutHandler.EXTRA_APP_ID)
                ?: intent.data?.lastPathSegment
            if (appId != null) {
                pendingShortcutAppId = appId
                shortcutChannel?.invokeMethod("onLaunchApp", appId)
                intent.data = null
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Register native WebView factory ───────────────────────────────────
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "webnest_webview",
            WebNestEngineFactory(flutterEngine.dartExecutor.binaryMessenger)
        )

        // ── PiP + Share + Task Description ───────────────────────────────────
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PIP_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "enterPiP" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val params = PictureInPictureParams.Builder().build()
                        val success = enterPictureInPictureMode(params)
                        result.success(success)
                    } else {
                        result.error(
                            "UNAVAILABLE",
                            "PiP not supported on this Android version.",
                            null
                        )
                    }
                }
                "shareUrl" -> {
                    val url   = call.argument<String>("url") ?: ""
                    val title = call.argument<String>("title") ?: ""
                    val intent = Intent(Intent.ACTION_SEND).apply {
                        type = "text/plain"
                        putExtra(Intent.EXTRA_TEXT, url)
                        putExtra(Intent.EXTRA_SUBJECT, title)
                    }
                    startActivity(Intent.createChooser(intent, "Share Link"))
                    result.success(true)
                }
                "updateTaskDescription" -> {
                    val label         = call.argument<String>("label") ?: "WebFuseX"
                    val themeColorHex = call.argument<String>("themeColor") ?: "#6366F1"
                    val faviconUrl    = call.argument<String>("faviconUrl") ?: ""

                    val color = try {
                        android.graphics.Color.parseColor(themeColorHex)
                    } catch (_: Exception) {
                        android.graphics.Color.parseColor("#6366F1")
                    }

                    Thread {
                        var bitmap: Bitmap? = null
                        if (faviconUrl.isNotEmpty()) {
                            try {
                                val conn = java.net.URL(faviconUrl).openConnection()
                                conn.connectTimeout = 5000
                                conn.readTimeout    = 5000
                                conn.connect()
                                bitmap = BitmapFactory.decodeStream(conn.getInputStream())
                            } catch (_: Exception) {}
                        }
                        runOnUiThread {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                                @Suppress("DEPRECATION")
                                val desc = ActivityManager.TaskDescription(label, bitmap, color)
                                setTaskDescription(desc)
                            }
                        }
                    }.start()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // ── Shortcut Channel ──────────────────────────────────────────────────
        shortcutChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SHORTCUT_CHANNEL
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "pinShortcut" -> {
                        val appId      = call.argument<String>("appId") ?: ""
                        val appName    = call.argument<String>("appName") ?: ""
                        val themeColor = call.argument<String>("themeColor") ?: ""
                        val faviconUrl = call.argument<String>("faviconUrl") ?: ""

                        Thread {
                            val status = ShortcutHandler.requestPinShortcut(
                                this@MainActivity,
                                appId,
                                appName,
                                themeColor,
                                faviconUrl
                            )
                            runOnUiThread { result.success(status) }
                        }.start()
                    }
                    "getInitialAppId" -> {
                        result.success(pendingShortcutAppId)
                        pendingShortcutAppId = null
                    }
                    else -> result.notImplemented()
                }
            }
        }

        // ── Shield Channel (filter list loading) ──────────────────────────────
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SHIELD_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "loadFilterList" -> {
                    val filePath = call.argument<String>("filePath") ?: ""
                    Thread {
                        val success = WebNestShieldEngine.loadFromFile(filePath)
                        runOnUiThread { result.success(success) }
                    }.start()
                }
                "clearRules" -> {
                    WebNestShieldEngine.clearRules()
                    result.success(null)
                }
                "getRuleCount" -> {
                    result.success(WebNestShieldEngine.getRuleCount())
                }
                else -> result.notImplemented()
            }
        }

        // ── Settings Channel (clear cache / cookies / storage) ────────────────
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SETTINGS_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "clearCache" -> {
                    Thread {
                        // Clear WebView cache via a temporary WebView instance
                        val wv = android.webkit.WebView(this)
                        wv.clearCache(true)
                        wv.destroy()
                        runOnUiThread { result.success(true) }
                    }.start()
                }
                "clearCookies" -> {
                    val cm = CookieManager.getInstance()
                    cm.removeAllCookies { success ->
                        cm.flush()
                        result.success(success)
                    }
                }
                "clearWebStorage" -> {
                    WebStorage.getInstance().deleteAllData()
                    result.success(true)
                }
                "clearAllData" -> {
                    // Clear cookies
                    val cm = CookieManager.getInstance()
                    cm.removeAllCookies(null)
                    cm.flush()
                    // Clear web storage
                    WebStorage.getInstance().deleteAllData()
                    // Clear cache
                    Thread {
                        val wv = android.webkit.WebView(this)
                        wv.clearCache(true)
                        wv.clearHistory()
                        wv.destroy()
                        runOnUiThread { result.success(true) }
                    }.start()
                }
                "openUrl" -> {
                    val url = call.argument<String>("url") ?: ""
                    if (url.isNotEmpty()) {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", e.localizedMessage, null)
                        }
                    } else {
                        result.error("BAD_ARGS", "URL is empty", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
