package com.webnest.webnest.shortcut

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.os.Build
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import com.webnest.webnest.MainActivity
import java.net.URL

/**
 * Manages Android home screen shortcuts for WebFuseX WebApps.
 *
 * Each WebApp can be pinned to the Android launcher as an independent shortcut.
 * Tapping the shortcut launches MainActivity with the WebApp's ID, bypassing the
 * Website Library and opening directly into the WebApp session.
 *
 * Uses ShortcutManagerCompat for backwards compatibility with Android 7.1+.
 * On Android 8.0+, the system shows a confirmation dialog to the user.
 * On older versions, it falls back to a broadcast (launcher-dependent).
 */
object ShortcutHandler {

    const val EXTRA_APP_ID = "streamnest_app_id"
    private const val SHORTCUT_ACTION = "com.webnest.webnest.LAUNCH_APP"

    /**
     * Request the launcher to pin a shortcut for a WebApp.
     *
     * @param context     Application context
     * @param appId       The WebApp's unique ID (used to route to /session/:appId)
     * @param appName     Display label shown under the shortcut icon
     * @param themeColor  Hex color string used as fallback icon background (e.g. "#6366F1")
     * @param faviconUrl  URL of the website's favicon (downloaded on a background thread)
     * @return            true if the system accepted the pin request; false if unsupported
     */
    fun requestPinShortcut(
        context: Context,
        appId: String,
        appName: String,
        themeColor: String,
        faviconUrl: String
    ): String {
        if (!ShortcutManagerCompat.isRequestPinShortcutSupported(context)) {
            return "NOT_SUPPORTED"
        }

        // Build the Intent that fires when the shortcut is tapped.
        // FLAG_ACTIVITY_NEW_DOCUMENT and FLAG_ACTIVITY_MULTIPLE_TASK ensure each WebApp has its own Recents task.
        // The data URI unique per appId prevents Android from grouping them under the same launcher task.
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            action = SHORTCUT_ACTION
            data = android.net.Uri.parse("streamnest://app/$appId")
            putExtra(EXTRA_APP_ID, appId)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                addFlags(Intent.FLAG_ACTIVITY_NEW_DOCUMENT)
            } else {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
        }

        // Build the shortcut icon — attempt to download the favicon, fallback to
        // a colored rounded-square with the first letter of the app name.
        val icon = buildIcon(context, appName, themeColor, faviconUrl)

        val shortcut = ShortcutInfoCompat.Builder(context, "app_$appId")
            .setShortLabel(appName.take(25))          // Max 25 chars for short label
            .setLongLabel(appName.take(50))           // Max 50 chars for long label
            .setIcon(icon)
            .setIntent(launchIntent)
            .build()

        return try {
            val success = ShortcutManagerCompat.requestPinShortcut(context, shortcut, null)
            if (success) "SUCCESS" else "FAILED"
        } catch (e: Exception) {
            e.printStackTrace()
            "ERROR_${e.message ?: "unknown"}"
        }
    }

    /**
     * Build the shortcut icon.
     *
     * Priority:
     *   1. Download the favicon from faviconUrl (network)
     *   2. If download fails or URL is empty → generate a colored letter icon
     */
    private fun buildIcon(
        context: Context,
        appName: String,
        themeColorHex: String,
        faviconUrl: String
    ): IconCompat {
        if (faviconUrl.isNotEmpty()) {
            try {
                val bitmap = downloadBitmap(faviconUrl)
                if (bitmap != null) {
                    val rounded = toRoundedBitmap(bitmap, 128)
                    return IconCompat.createWithBitmap(rounded)
                }
            } catch (_: Exception) {}
        }
        // Fallback: generate a colored letter icon
        return IconCompat.createWithBitmap(generateLetterIcon(appName, themeColorHex))
    }

    /** Download a bitmap from a URL synchronously (call on a background thread). */
    private fun downloadBitmap(url: String): Bitmap? {
        return try {
            val connection = URL(url).openConnection()
            connection.connectTimeout = 5000
            connection.readTimeout = 5000
            connection.connect()
            BitmapFactory.decodeStream(connection.getInputStream())
        } catch (_: Exception) {
            null
        }
    }

    /** Render a bitmap as a rounded square. */
    private fun toRoundedBitmap(src: Bitmap, size: Int): Bitmap {
        val output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        val rect = RectF(0f, 0f, size.toFloat(), size.toFloat())
        val radius = size * 0.22f

        val scaled = Bitmap.createScaledBitmap(src, size, size, true)
        canvas.drawRoundRect(rect, radius, radius, paint)

        paint.xfermode =
            android.graphics.PorterDuffXfermode(android.graphics.PorterDuff.Mode.SRC_IN)
        canvas.drawBitmap(scaled, 0f, 0f, paint)
        scaled.recycle()
        return output
    }

    /**
     * Generate a fallback icon: a solid rounded square in the app's theme color
     * with the first letter of the app name centered in white.
     */
    private fun generateLetterIcon(appName: String, themeColorHex: String): Bitmap {
        val size = 128
        val output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)

        val bgColor = try {
            Color.parseColor(themeColorHex)
        } catch (_: Exception) {
            Color.parseColor("#6366F1")
        }

        // Background rounded square
        val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = bgColor }
        canvas.drawRoundRect(
            RectF(0f, 0f, size.toFloat(), size.toFloat()),
            size * 0.22f, size * 0.22f,
            bgPaint
        )

        // Letter
        val letter = appName.firstOrNull()?.uppercaseChar()?.toString() ?: "?"
        val isLight = androidx.core.graphics.ColorUtils.calculateLuminance(bgColor) > 0.6
        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = if (isLight) Color.BLACK else Color.WHITE
            textSize = size * 0.48f
            textAlign = Paint.Align.CENTER
            isFakeBoldText = true
        }
        val yPos = (canvas.height / 2f) - ((textPaint.descent() + textPaint.ascent()) / 2f)
        canvas.drawText(letter, size / 2f, yPos, textPaint)

        return output
    }
}
