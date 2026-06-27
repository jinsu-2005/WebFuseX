package com.webnest.webnest.engine

import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.webkit.WebView
import android.webkit.WebViewClient
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.CookieManager
import androidx.webkit.ProfileStore
import androidx.webkit.WebViewCompat
import androidx.webkit.WebViewFeature
import java.io.ByteArrayInputStream
import android.app.DownloadManager
import android.net.Uri
import android.os.Environment
import android.webkit.DownloadListener
import android.webkit.URLUtil
import android.widget.Toast
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import android.app.Activity
import android.content.ContextWrapper
import android.view.ViewGroup
import android.view.View.LAYER_TYPE_HARDWARE
import android.view.View.LAYER_TYPE_SOFTWARE
import android.widget.FrameLayout

fun getActivity(context: Context?): Activity? {
    if (context == null) return null
    if (context is Activity) return context
    if (context is ContextWrapper) return getActivity(context.baseContext)
    return null
}

class WebNestEngineView(
    context: Context,
    viewId: Int,
    creationParams: Map<String?, Any?>?,
    messenger: BinaryMessenger
) : PlatformView, MethodChannel.MethodCallHandler {

    private val webView: WebView = WebView(context)
    private val methodChannel: MethodChannel

    init {
        // ── Profile isolation via Jetpack WebKit Multi-Profile ────────────────
        val profileId = creationParams?.get("profileId") as? String
        if (profileId != null && WebViewFeature.isFeatureSupported(WebViewFeature.MULTI_PROFILE)) {
            try {
                WebViewCompat.setProfile(webView, profileId)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        // ── Creation params ───────────────────────────────────────────────────
        val shieldEnabled      = creationParams?.get("shieldEnabled") as? Boolean ?: true
        val desktopMode        = creationParams?.get("desktopMode") as? Boolean ?: false
        val jsEnabled          = creationParams?.get("jsEnabled") as? Boolean ?: true
        val cookiesEnabled     = creationParams?.get("cookiesEnabled") as? Boolean ?: true
        val thirdPartyCookies  = creationParams?.get("thirdPartyCookiesEnabled") as? Boolean ?: true
        val hwAccelEnabled     = creationParams?.get("hardwareAccelerationEnabled") as? Boolean ?: true
        val forceDarkMode      = creationParams?.get("forceDarkMode") as? Boolean ?: false
        val popupBlocking      = creationParams?.get("popupBlockingEnabled") as? Boolean ?: true
        val customUa           = creationParams?.get("customUserAgent") as? String ?: ""
        val pinchToZoomEnabled = creationParams?.get("pinchToZoomEnabled") as? Boolean ?: true
        val openLinksExternally = creationParams?.get("openLinksExternally") as? Boolean ?: false
        val loadImagesEnabled  = creationParams?.get("loadImagesEnabled") as? Boolean ?: true
        val backgroundPlayback = creationParams?.get("backgroundPlaybackEnabled") as? Boolean ?: false

        // ── Audio focus for background playback ───────────────────────────────────
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        if (backgroundPlayback && audioManager != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_MEDIA)
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .build()
                    )
                    .setAcceptsDelayedFocusGain(true)
                    .setOnAudioFocusChangeListener { focusChange ->
                        // Let the website handle focus changes naturally
                    }
                    .build()
                audioManager.requestAudioFocus(focusRequest)
            } else {
                @Suppress("DEPRECATION")
                audioManager.requestAudioFocus(
                    null,
                    AudioManager.STREAM_MUSIC,
                    AudioManager.AUDIOFOCUS_GAIN
                )
            }
        }

        // ── Hardware acceleration ─────────────────────────────────────────────
        webView.setLayerType(
            if (hwAccelEnabled) LAYER_TYPE_HARDWARE else LAYER_TYPE_SOFTWARE,
            null
        )

        // ── Core WebView settings ─────────────────────────────────────────────
        webView.settings.apply {
            javaScriptEnabled = jsEnabled
            domStorageEnabled = true
            databaseEnabled   = true
            mediaPlaybackRequiresUserGesture = false

            // Zoom settings
            setSupportZoom(pinchToZoomEnabled)
            builtInZoomControls = pinchToZoomEnabled
            displayZoomControls = false

            // Image loading settings
            loadsImagesAutomatically = loadImagesEnabled

            // User-Agent
            when {
                customUa.isNotEmpty() -> userAgentString = customUa
                desktopMode -> userAgentString =
                    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 " +
                    "(KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"
                // else: leave as default Android UA
            }

            // Force dark mode (Android Q+)
            if (forceDarkMode && WebViewFeature.isFeatureSupported(WebViewFeature.ALGORITHMIC_DARKENING)) {
                try {
                    androidx.webkit.WebSettingsCompat.setAlgorithmicDarkeningAllowed(this, true)
                } catch (_: Exception) {}
            }

            // Web Authentication (Credential Manager / Passkeys / Google Sign-in)
            if (WebViewFeature.isFeatureSupported(WebViewFeature.WEB_AUTHENTICATION)) {
                try {
                    androidx.webkit.WebSettingsCompat.setWebAuthenticationSupport(
                        this,
                        androidx.webkit.WebSettingsCompat.WEB_AUTHENTICATION_SUPPORT_FOR_APP
                    )
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }

        // ── Autofill Framework ───────────────────────────────────────────────
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            webView.importantForAutofill = View.IMPORTANT_FOR_AUTOFILL_YES
        }

        // ── Cookies ───────────────────────────────────────────────────────────
        val cookieManager = CookieManager.getInstance()
        cookieManager.setAcceptCookie(cookiesEnabled)
        cookieManager.setAcceptThirdPartyCookies(webView, thirdPartyCookies && cookiesEnabled)

        // ── Shield / resource interception ────────────────────────────────────
        var blockedCount = 0

        webView.webViewClient = object : WebViewClient() {
            private var originalUserAgent: String? = null

            override fun shouldInterceptRequest(
                view: WebView?,
                request: WebResourceRequest?
            ): WebResourceResponse? {
                if (shieldEnabled && request != null) {
                    val url = request.url?.toString()
                    if (WebNestShieldEngine.shouldBlockRequest(url)) {
                        blockedCount++
                        webView.post {
                            methodChannel.invokeMethod(
                                "onResourceBlocked",
                                mapOf("blockedCount" to blockedCount)
                            )
                        }
                        return WebResourceResponse(
                            "text/plain", "UTF-8",
                            ByteArrayInputStream("".toByteArray())
                        )
                    }
                }
                return super.shouldInterceptRequest(view, request)
            }

            override fun shouldOverrideUrlLoading(
                view: WebView?,
                request: WebResourceRequest?
            ): Boolean {
                val url = request?.url?.toString() ?: return false
                return handleUrlOverride(view, url)
            }

            @Deprecated("Deprecated in Java")
            override fun shouldOverrideUrlLoading(view: WebView?, url: String?): Boolean {
                if (url == null) return false
                return handleUrlOverride(view, url)
            }

            private fun handleUrlOverride(view: WebView?, url: String): Boolean {
                if (openLinksExternally) {
                    try {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                        view?.context?.startActivity(intent)
                        return true
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
                return false
            }

            override fun onPageStarted(
                view: WebView?,
                url: String?,
                favicon: android.graphics.Bitmap?
            ) {
                super.onPageStarted(view, url, favicon)
                methodChannel.invokeMethod("onPageStarted", mapOf("url" to url))

                if (url != null && view != null) {
                    if (originalUserAgent == null) {
                        originalUserAgent = view.settings.userAgentString
                    }
                    if (url.contains("accounts.google.com")) {
                        val currentUa = view.settings.userAgentString ?: ""
                        if (currentUa.contains("Version/") || currentUa.contains("wv")) {
                            // Spoof user agent by removing Android WebView components
                            var spoofedUa = currentUa.replace(Regex("Version/[0-9.]+"), "")
                            spoofedUa = spoofedUa.replace("; wv", "")
                            view.settings.userAgentString = spoofedUa
                        }
                    } else {
                        // Restore original User-Agent when leaving google accounts domain
                        originalUserAgent?.let {
                            if (view.settings.userAgentString != it) {
                                view.settings.userAgentString = it
                            }
                        }
                    }
                }
            }

            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                methodChannel.invokeMethod("onPageFinished", mapOf("url" to url))
            }
        }

        // ── Chrome client ─────────────────────────────────────────────────────
        webView.webChromeClient = object : android.webkit.WebChromeClient() {
            private var customView: View? = null
            private var customViewCallback: CustomViewCallback? = null

            override fun onProgressChanged(view: WebView?, newProgress: Int) {
                super.onProgressChanged(view, newProgress)
                methodChannel.invokeMethod(
                    "onProgressChanged",
                    mapOf("progress" to newProgress)
                )
            }

            override fun onCreateWindow(
                view: WebView?,
                isDialog: Boolean,
                isUserGesture: Boolean,
                resultMsg: android.os.Message?
            ): Boolean {
                // Block pop-ups if configured
                if (popupBlocking && !isUserGesture) return false
                return super.onCreateWindow(view, isDialog, isUserGesture, resultMsg)
            }

            override fun onShowCustomView(
                view: View?,
                callback: CustomViewCallback?
            ) {
                if (customView != null) {
                    callback?.onCustomViewHidden()
                    return
                }
                val activity = getActivity(context)
                if (activity != null) {
                    val decorView = activity.window.decorView as FrameLayout
                    view?.let {
                        decorView.addView(
                            it,
                            FrameLayout.LayoutParams(
                                FrameLayout.LayoutParams.MATCH_PARENT,
                                FrameLayout.LayoutParams.MATCH_PARENT
                            )
                        )
                    }
                    // Enter immersive fullscreen
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        val controller = activity.window.insetsController
                        controller?.hide(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
                        controller?.systemBarsBehavior =
                            WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                    } else {
                        @Suppress("DEPRECATION")
                        activity.window.decorView.systemUiVisibility = (
                            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                            or View.SYSTEM_UI_FLAG_FULLSCREEN
                            or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                            or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                            or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                            or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        )
                    }
                }
                customView = view
                customViewCallback = callback
                methodChannel.invokeMethod("onEnterFullscreen", null)
            }

            override fun onHideCustomView() {
                val activity = getActivity(context)
                if (activity != null && customView != null) {
                    val decorView = activity.window.decorView as FrameLayout
                    decorView.removeView(customView)
                    // Restore system UI
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        val controller = activity.window.insetsController
                        controller?.show(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
                    } else {
                        @Suppress("DEPRECATION")
                        activity.window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_VISIBLE
                    }
                }
                customView = null
                customViewCallback?.onCustomViewHidden()
                customViewCallback = null
                methodChannel.invokeMethod("onExitFullscreen", null)
            }

            override fun onPermissionRequest(request: android.webkit.PermissionRequest?) {
                if (request == null) return
                val origin = request.origin?.toString() ?: ""
                val resources = request.resources.toList()
                methodChannel.invokeMethod(
                    "onPermissionRequest",
                    mapOf("origin" to origin, "resources" to resources),
                    object : MethodChannel.Result {
                        override fun success(result: Any?) {
                            if (result == true) {
                                request.grant(request.resources)
                            } else {
                                request.deny()
                            }
                        }
                        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                            request.deny()
                        }
                        override fun notImplemented() {
                            request.deny()
                        }
                    }
                )
            }

            override fun onGeolocationPermissionsShowPrompt(
                origin: String?,
                callback: android.webkit.GeolocationPermissions.Callback?
            ) {
                if (origin == null || callback == null) return
                methodChannel.invokeMethod(
                    "onGeolocationPermission",
                    mapOf("origin" to origin),
                    object : MethodChannel.Result {
                        override fun success(result: Any?) {
                            callback.invoke(origin, result == true, false)
                        }
                        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                            callback.invoke(origin, false, false)
                        }
                        override fun notImplemented() {
                            callback.invoke(origin, false, false)
                        }
                    }
                )
            }
        }

        // ── Native Download Listener ───────────────────────────────────────────
        webView.setDownloadListener { url, userAgent, contentDisposition, mimetype, _ ->
            try {
                val request = DownloadManager.Request(Uri.parse(url))
                request.setMimeType(mimetype)
                val filename = URLUtil.guessFileName(url, contentDisposition, mimetype)
                request.setTitle(filename)
                request.setDescription("Downloading file...")
                request.setNotificationVisibility(
                    DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED
                )
                request.setDestinationInExternalPublicDir(
                    Environment.DIRECTORY_DOWNLOADS,
                    filename
                )
                val dm = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
                dm.enqueue(request)
                Toast.makeText(context, "Downloading $filename...", Toast.LENGTH_SHORT).show()
            } catch (e: Exception) {
                Toast.makeText(
                    context,
                    "Download failed: ${e.message}",
                    Toast.LENGTH_SHORT
                ).show()
            }
        }

        // ── Method channel ────────────────────────────────────────────────────
        methodChannel = MethodChannel(messenger, "com.webnest/engine_$viewId")
        methodChannel.setMethodCallHandler(this)

        // ── Initial URL ────────────────────────────────────────────────────────
        val initialUrl = creationParams?.get("initialUrl") as? String
        if (initialUrl != null) {
            webView.loadUrl(initialUrl)
        }
    }

    override fun getView(): View = webView

    override fun dispose() {
        methodChannel.setMethodCallHandler(null)
        webView.destroy()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "loadUrl" -> {
                val url = call.argument<String>("url")
                if (url != null) {
                    webView.loadUrl(url)
                    result.success(null)
                } else {
                    result.error("INVALID_URL", "URL cannot be null", null)
                }
            }
            "goBack" -> {
                if (webView.canGoBack()) {
                    webView.goBack()
                    result.success(true)
                } else {
                    result.success(false)
                }
            }
            "goForward" -> {
                if (webView.canGoForward()) {
                    webView.goForward()
                    result.success(true)
                } else {
                    result.success(false)
                }
            }
            "reload" -> {
                webView.reload()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}
