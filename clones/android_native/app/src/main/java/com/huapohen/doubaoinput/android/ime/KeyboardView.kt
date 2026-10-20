package com.huapohen.doubaoinput.android.ime

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.os.Handler
import android.os.Looper
import android.util.AttributeSet
import android.view.MotionEvent
import android.view.View
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

class KeyboardTheme(
    val bg: Int,
    val key: Int,
    val func: Int,
    val action: Int,
    val text: Int,
    val sub: Int,
    val pressed: Int,
    val pressedFunc: Int,
    val border: Int,
    val dark: Boolean
) {
    companion object {
        fun light() = KeyboardTheme(
            bg = Color.parseColor("#EBEBEB"),
            key = Color.WHITE,
            func = Color.parseColor("#BDC2C8"),
            action = Color.parseColor("#4F84FF"),
            text = Color.parseColor("#111111"),
            sub = Color.parseColor("#7A7A7A"),
            pressed = Color.parseColor("#CCDCFF"),
            pressedFunc = Color.parseColor("#A9AFB6"),
            border = Color.parseColor("#14000000"),
            dark = false
        )

        fun dark() = KeyboardTheme(
            bg = Color.parseColor("#17181A"),
            key = Color.parseColor("#2C2D30"),
            func = Color.parseColor("#3A3B3F"),
            action = Color.parseColor("#4F84FF"),
            text = Color.parseColor("#F5F5F7"),
            sub = Color.parseColor("#A0A0A6"),
            pressed = Color.parseColor("#3D5F9E"),
            pressedFunc = Color.parseColor("#4A4C52"),
            border = Color.parseColor("#22FFFFFF"),
            dark = true
        )
    }
}

class KeyboardView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null
) : View(context, attrs) {

    interface Listener {
        fun onKey(key: KeySpec, alt: String?)
        fun onLongPress(key: KeySpec, alt: String?)
        fun onRepeatBackspace()
        fun onFeedback()
        fun onVoiceGesture()
    }

    var listener: Listener? = null
    var slideEnabled: Boolean = true
    var theme: KeyboardTheme = KeyboardTheme.light()
        set(value) { field = value; invalidate() }

    private var layout: KeyboardLayout? = null
    private val rects = LinkedHashMap<KeySpec, RectF>()
    private var shiftActive = false
    private var capsLock = false

    private val dp = resources.displayMetrics.density
    private val handler = Handler(Looper.getMainLooper())
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        typeface = android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.NORMAL)
        textAlign = Paint.Align.CENTER
    }
    private val subPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        typeface = android.graphics.Typeface.create("sans-serif", android.graphics.Typeface.NORMAL)
        textAlign = Paint.Align.CENTER
    }
    private val path = Path()

    private var downKey: KeySpec? = null
    private var downX = 0f
    private var downY = 0f
    private var pressedKey: KeySpec? = null
    private var slideAlt: String? = null
    private var longPressFired = false
    private var repeatActive = false

    private val longPressRunnable = Runnable {
        val k = downKey ?: return@Runnable
        longPressFired = true
        if (k.kind == KeyKind.BACKSPACE) {
            repeatActive = true
            listener?.onRepeatBackspace()
            handler.postDelayed(repeatRunnable, 55)
        } else {
            if (k.alt != null) {
                slideAlt = k.alt
                invalidate()
            }
            listener?.onLongPress(k, k.alt)
        }
    }

    private val repeatRunnable = object : Runnable {
        override fun run() {
            if (!repeatActive) return
            listener?.onRepeatBackspace()
            handler.postDelayed(this, 55)
        }
    }

    fun layoutCount(): Int = rects.size

    fun setLayout(layout: KeyboardLayout) {
        this.layout = layout
        rects.clear()
        pressedKey = null
        requestLayout()
        invalidate()
    }

    fun setShift(active: Boolean, caps: Boolean) {
        shiftActive = active
        capsLock = caps
        invalidate()
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val h = MeasureSpec.getSize(heightMeasureSpec)
        setMeasuredDimension(MeasureSpec.getSize(widthMeasureSpec), h)
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        computeRects(w.toFloat(), h.toFloat())
    }

    private fun computeRects(w: Float, h: Float) {
        rects.clear()
        val l = layout ?: return
        val padH = 4f * dp
        val padV = 4f * dp
        val gap = 4.5f * dp
        val totalWeight = l.rows.sumOf { it.heightWeight.toDouble() }.toFloat().coerceAtLeast(0.01f)
        val usableH = h - padV * 2
        val rowGapTotal = gap * (l.rows.size - 1).coerceAtLeast(0)
        val rowUnit = (usableH - rowGapTotal) / totalWeight
        var y = padV
        l.rows.forEach { row ->
            val rowH = rowUnit * row.heightWeight
            val visible = row.keys.filter { it.kind != KeyKind.PLACEHOLDER }
            val total = row.keys.sumOf { it.weight.toDouble() }.toFloat().coerceAtLeast(0.01f)
            val usableW = w - padH * 2 - gap * (row.keys.size - 1).coerceAtLeast(0)
            val unit = usableW / total
            var x = padH
            row.keys.forEach { key ->
                val kw = unit * key.weight
                if (key.kind != KeyKind.PLACEHOLDER) {
                    rects[key] = RectF(x, y + gap * 0.12f, x + kw, y + rowH - gap * 0.12f)
                }
                x += kw + gap
            }
            y += rowH + gap
        }
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val l = layout ?: return
        canvas.drawColor(theme.bg)
        for ((key, rect) in rects) {
            drawKey(canvas, key, rect)
        }
        drawPopup(canvas)
    }

    private fun drawKey(canvas: Canvas, key: KeySpec, rect: RectF) {
        val pressed = key == pressedKey
        val fill = when (key.kind) {
            KeyKind.CHAR, KeyKind.T9, KeyKind.SPACE, KeyKind.SIDEBAR -> if (pressed) theme.pressed else if (key.kind == KeyKind.SIDEBAR) theme.func else theme.key
            KeyKind.ACTION -> if (pressed) android.graphics.Color.parseColor("#3051F2") else theme.action
            KeyKind.SHIFT -> if (shiftActive) theme.action else if (pressed) theme.pressedFunc else theme.func
            else -> if (pressed) theme.pressedFunc else theme.func
        }
        paint.color = fill
        paint.style = Paint.Style.FILL
        val radius = min(9f * dp, rect.height() * 0.22f)
        canvas.drawRoundRect(rect, radius, radius, paint)
        if (key.kind == KeyKind.CHAR || key.kind == KeyKind.T9 || key.kind == KeyKind.SPACE) {
            paint.color = theme.border
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = 1f
            canvas.drawRoundRect(rect, radius, radius, paint)
            paint.style = Paint.Style.FILL
        }

        val cx = rect.centerX()
        val cy = rect.centerY()
        val keyW = rect.width()
        val keyH = rect.height()
        val mainColor = when (key.kind) {
            KeyKind.ACTION -> Color.WHITE
            KeyKind.SHIFT -> if (shiftActive) Color.WHITE else theme.text
            else -> theme.text
        }

        when (key.kind) {
            KeyKind.SHIFT -> {
                drawShiftIcon(canvas, cx, cy, keyH, mainColor)
            }
            KeyKind.BACKSPACE -> {
                textPaint.color = theme.text
                textPaint.textSize = min(27f * dp, keyH * 0.44f)
                canvas.drawText("⌫", cx, cy + textPaint.textSize * 0.34f, textPaint)
            }
            KeyKind.SPACE -> {
                drawWaveIcon(canvas, cx, cy, keyH, theme.sub)
                if (key.subLabel.isNotBlank() && keyW > 150f * dp) {
                    subPaint.color = theme.sub
                    subPaint.textSize = 9.5f * dp
                    canvas.drawText(key.subLabel, cx, rect.bottom - 5f * dp, subPaint)
                }
            }
            KeyKind.ACTION -> {
                textPaint.color = mainColor
                textPaint.textSize = min(16f * dp, keyH * 0.34f)
                var label = key.label.ifBlank { "换行" }
                if (label.length > 4) label = label.take(4)
                canvas.drawText(label, cx, cy + textPaint.textSize * 0.34f, textPaint)
            }
            KeyKind.MODE -> {
                textPaint.color = mainColor
                textPaint.textSize = min(20f * dp, keyH * 0.40f)
                canvas.drawText(key.label, cx, cy - 1f * dp, textPaint)
                if (key.subLabel.isNotBlank()) {
                    subPaint.color = theme.sub
                    subPaint.textSize = min(11f * dp, keyH * 0.22f)
                    canvas.drawText(key.subLabel, cx, cy + 13f * dp, subPaint)
                }
            }
            else -> {
                textPaint.color = mainColor
                textPaint.textSize = min(
                    if (key.kind == KeyKind.T9) 23f * dp else 23f * dp,
                    keyH * (if (key.kind == KeyKind.T9) 0.40f else 0.46f)
                )
                if (key.label.isNotEmpty()) {
                    drawCenteredFitted(canvas, key.label, cx, cy + textPaint.textSize * 0.34f, rect.width() - 8f * dp, textPaint)
                }
                if (key.subLabel.isNotBlank()) {
                    subPaint.color = if (key.kind == KeyKind.ACTION) Color.WHITE else theme.sub
                    subPaint.textSize = min(12f * dp, keyH * 0.24f)
                    val anchorX = if (key.kind == KeyKind.T9) rect.right - 9f * dp else cx
                    val align = subPaint.textAlign
                    subPaint.textAlign = if (key.kind == KeyKind.T9) Paint.Align.RIGHT else Paint.Align.CENTER
                    canvas.drawText(key.subLabel, anchorX, rect.top + 16f * dp, subPaint)
                    subPaint.textAlign = align
                }
            }
        }
        if (key.kind == KeyKind.SHIFT && capsLock) {
            paint.color = mainColor
            canvas.drawCircle(rect.left + 10f * dp, rect.top + 9f * dp, 2.5f * dp, paint)
        }
    }

    private fun drawCenteredFitted(canvas: Canvas, text: String, cx: Float, baseline: Float, maxWidth: Float, p: Paint) {
        var size = p.textSize
        val measured = p.measureText(text)
        if (measured > maxWidth && measured > 0) {
            size = size * (maxWidth / measured)
            p.textSize = max(8f * dp, size)
        }
        canvas.drawText(text, cx, baseline, p)
    }

    private fun drawShiftIcon(canvas: Canvas, cx: Float, cy: Float, h: Float, color: Int) {
        val s = min(11f * dp, h * 0.20f)
        paint.color = color
        paint.style = Paint.Style.FILL
        path.reset()
        path.moveTo(cx, cy - s)
        path.lineTo(cx + s, cy)
        path.lineTo(cx + s * 0.42f, cy)
        path.lineTo(cx + s * 0.42f, cy + s * 0.8f)
        path.lineTo(cx - s * 0.42f, cy + s * 0.8f)
        path.lineTo(cx - s * 0.42f, cy)
        path.lineTo(cx - s, cy)
        path.close()
        canvas.drawPath(path, paint)
    }

    private fun drawWaveIcon(canvas: Canvas, cx: Float, cy: Float, h: Float, color: Int) {
        paint.color = color
        paint.strokeWidth = 2.2f * dp
        paint.strokeCap = Paint.Cap.ROUND
        val heights = floatArrayOf(0.10f, 0.20f, 0.30f, 0.18f, 0.08f)
        val gap = 4.2f * dp
        val start = cx - gap * (heights.size - 1) / 2f
        heights.forEachIndexed { i, hf ->
            val hh = h * hf
            canvas.drawLine(start + i * gap, cy - hh, start + i * gap, cy + hh, paint)
        }
        paint.strokeCap = Paint.Cap.BUTT
    }

    private fun drawPopup(canvas: Canvas) {
        val key = pressedKey ?: return
        val alt = slideAlt ?: return
        val rect = rects[key] ?: return
        val popupW = max(48f * dp, rect.width() * 1.1f)
        val popupH = 54f * dp
        var left = rect.centerX() - popupW / 2
        left = left.coerceIn(2f * dp, width - popupW - 2f * dp)
        var top = rect.top - popupH - 6f * dp
        if (top < 0) top = rect.bottom + 4f * dp
        val r = RectF(left, top, left + popupW, top + popupH)
        paint.color = if (theme.dark) Color.parseColor("#3A3B40") else Color.WHITE
        paint.style = Paint.Style.FILL
        canvas.drawRoundRect(r, 10f * dp, 10f * dp, paint)
        paint.color = theme.action
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = 1.5f * dp
        canvas.drawRoundRect(r, 10f * dp, 10f * dp, paint)
        paint.style = Paint.Style.FILL
        textPaint.color = theme.text
        textPaint.textSize = 27f * dp
        canvas.drawText(alt, r.centerX(), r.centerY() + 9f * dp, textPaint)
    }

    @SuppressLint("ClickableViewAccessibility")
    override fun onTouchEvent(event: MotionEvent): Boolean {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                downX = event.x; downY = event.y
                downKey = keyAt(event.x, event.y)
                downKey?.let { k ->
                    pressedKey = k
                    longPressFired = false
                    repeatActive = false
                    slideAlt = null
                    listener?.onFeedback()
                    handler.postDelayed(longPressRunnable, 430)
                    invalidate()
                }
                return downKey != null
            }
            MotionEvent.ACTION_MOVE -> {
                val k = downKey ?: return false
                if (abs(event.x - downX) > (rects[k]?.width() ?: 999f)) {
                    cancelPress()
                    return true
                }
                val dy = downY - event.y
                if (dy > 14f * dp && k.alt != null && slideEnabled && !longPressFired) {
                    slideAlt = k.alt
                    invalidate()
                } else if (dy < 6f * dp && slideAlt != null && !longPressFired) {
                    slideAlt = null
                    invalidate()
                }
                if (event.y < 0 || event.y > height) {
                    // keep pressed while sliding within the keyboard; popup handles visual
                }
                return true
            }
            MotionEvent.ACTION_UP -> {
                val k = downKey
                handler.removeCallbacks(longPressRunnable)
                handler.removeCallbacks(repeatRunnable)
                val wasRepeat = repeatActive
                repeatActive = false
                val alt = slideAlt
                val wasLong = longPressFired
                pressedKey = null
                slideAlt = null
                invalidate()
                downKey = null
                if (k != null) {
                    if (wasRepeat) {
                        // already deleted through repeat
                    } else if (alt != null) {
                        if (k.kind == KeyKind.SPACE) listener?.onVoiceGesture()
                        else listener?.onKey(k, alt)
                    } else if (wasLong) {
                        if (k.kind == KeyKind.CHAR && k.alt != null) listener?.onKey(k, k.alt)
                    } else {
                        listener?.onKey(k, null)
                    }
                }
                return true
            }
            MotionEvent.ACTION_CANCEL -> {
                cancelPress()
                return true
            }
        }
        return super.onTouchEvent(event)
    }

    private fun cancelPress() {
        handler.removeCallbacks(longPressRunnable)
        handler.removeCallbacks(repeatRunnable)
        repeatActive = false
        pressedKey = null
        slideAlt = null
        downKey = null
        invalidate()
    }

    private fun keyAt(x: Float, y: Float): KeySpec? {
        for ((key, rect) in rects) {
            if (rect.contains(x, y)) return key
        }
        return null
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        handler.removeCallbacksAndMessages(null)
    }
}
