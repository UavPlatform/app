package com.fuwaki.app

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import com.amap.api.maps.model.BitmapDescriptor
import com.amap.api.maps.model.BitmapDescriptorFactory

/** View-only static marker material; the geographic anchor and click identity are unchanged. */
internal object OrderMapMarkerRenderer {
    private val cache = android.util.LruCache<String, BitmapDescriptor>(16)

    @Synchronized
    fun icon(label: String, selected: Boolean, density: Float): BitmapDescriptor {
        val key = "${label.take(24)}:$selected:${density.coerceIn(1f, 2f)}"
        cache.get(key)?.let { return it }
        val icon = render(label, selected, density, .35f)
        cache.put(key, icon)
        return icon
    }

    private fun render(label: String, selected: Boolean, density: Float, phase: Float): BitmapDescriptor {
        val scale = density.coerceIn(1f, 2f)
        val text = label.take(24)
        val amber = Color.rgb(242, 107, 29)
        val charcoal = Color.rgb(30, 34, 41)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textSize = 11f * scale
            typeface = android.graphics.Typeface.DEFAULT_BOLD
        }
        val width = (paint.measureText(text) + 50 * scale).toInt()
        val bitmap = Bitmap.createBitmap(width, (76 * scale).toInt(), Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val center = width / 2f
        val dotY = 58 * scale
        paint.color = amber
        paint.alpha = ((1 - phase) * 65).toInt()
        canvas.drawCircle(center, dotY, (6 + 11 * phase) * scale, paint)
        paint.alpha = ((1 - phase) * 110).toInt()
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = scale
        canvas.drawCircle(center, dotY, (6 + 11 * phase) * scale, paint)
        paint.style = Paint.Style.FILL
        paint.alpha = 255
        paint.color = Color.WHITE
        canvas.drawCircle(center, dotY, 6 * scale, paint)
        paint.color = amber
        canvas.drawCircle(center, dotY, 4.5f * scale, paint)
        paint.color = charcoal
        paint.setShadowLayer(3 * scale, 0f, 2 * scale, 0x35000000)
        canvas.drawRoundRect(RectF(4 * scale, 3 * scale, width - 4 * scale, 32 * scale), 15 * scale, 15 * scale, paint)
        paint.clearShadowLayer()
        val pointer = Path().apply {
            moveTo(center - 5 * scale, 31 * scale)
            lineTo(center, 39 * scale)
            lineTo(center + 5 * scale, 31 * scale)
            close()
        }
        canvas.drawPath(pointer, paint)
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = scale
        paint.color = if (selected) amber else 0x33ffffff
        canvas.drawRoundRect(RectF(4 * scale, 3 * scale, width - 4 * scale, 32 * scale), 15 * scale, 15 * scale, paint)
        // Miniature package glyph, drawn directly to keep the marker asset independent.
        paint.color = amber
        canvas.drawRoundRect(RectF(13 * scale, 12 * scale, 24 * scale, 23 * scale), 2 * scale, 2 * scale, paint)
        canvas.drawLine(13 * scale, 16 * scale, 24 * scale, 16 * scale, paint)
        canvas.drawLine(18.5f * scale, 12 * scale, 18.5f * scale, 18 * scale, paint)
        paint.style = Paint.Style.FILL
        canvas.drawText(text, 30 * scale, 18 * scale - (paint.ascent() + paint.descent()) / 2, paint)
        return BitmapDescriptorFactory.fromBitmap(bitmap)
    }
}
