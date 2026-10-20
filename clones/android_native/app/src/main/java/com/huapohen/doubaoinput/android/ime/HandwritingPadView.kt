package com.huapohen.doubaoinput.android.ime

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.DashPathEffect
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PointF
import android.graphics.RectF
import android.os.Handler
import android.os.Looper
import android.util.AttributeSet
import android.view.MotionEvent
import android.view.View
import com.huapohen.doubaoinput.android.engine.HandwritingRecognizer

class HandwritingPadView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null
) : View(context, attrs) {

    var onRecognized: ((List<HandwritingRecognizer.Result>) -> Unit)? = null

    private val strokes = ArrayList<HandwritingRecognizer.Stroke>()
    private var current = ArrayList<Pair<Float, Float>>()
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeCap = Paint.Cap.ROUND
        strokeJoin = Paint.Join.ROUND
    }
    private val guide = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        pathEffect = DashPathEffect(floatArrayOf(6f, 8f), 0f)
    }
    private val text = Paint(Paint.ANTI_ALIAS_FLAG).apply { textAlign = Paint.Align.CENTER }
    private val handler = Handler(Looper.getMainLooper())
    private var dark = false
    private var colorsSet = false
    private val dp = resources.displayMetrics.density

    private val recognizeRunnable = Runnable {
        val copy = strokes.toList()
        if (copy.isEmpty()) return@Runnable
        val results = HandwritingRecognizer.recognize(copy)
        onRecognized?.invoke(results)
    }

    fun setColors(theme: KeyboardTheme) {
        dark = theme.dark
        paint.color = theme.text
        paint.strokeWidth = 5.5f * dp
        guide.color = if (theme.dark) Color.parseColor("#33FFFFFF") else Color.parseColor("#1F394C5A")
        guide.strokeWidth = 1.2f * dp
        text.color = if (theme.dark) Color.parseColor("#777D87") else Color.parseColor("#A5ABB4")
        text.textSize = 14f * resources.displayMetrics.scaledDensity
        colorsSet = true
        invalidate()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        if (!colorsSet) setColors(KeyboardTheme.light())
        canvas.drawColor(Color.TRANSPARENT)
        val pad = 18f * dp
        canvas.drawRoundRect(RectF(pad, pad, width - pad, height - pad), 14f * dp, 14f * dp, guide)
        if (strokes.isEmpty() && current.isEmpty()) {
            canvas.drawText("在此处手写，停顿后自动识别", width / 2f, height / 2f, text)
            canvas.drawText("支持手写找字：拼音查字", width / 2f, height / 2f + 22f * dp, text)
        }
        strokes.forEach { drawStroke(canvas, it.points) }
        if (current.size > 1) drawStroke(canvas, current)
    }

    private fun drawStroke(canvas: Canvas, points: List<Pair<Float, Float>>) {
        if (points.size < 2) return
        val path = Path()
        path.moveTo(points[0].first, points[0].second)
        for (i in 1 until points.size) path.lineTo(points[i].first, points[i].second)
        canvas.drawPath(path, paint)
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                handler.removeCallbacks(recognizeRunnable)
                current = ArrayList()
                current.add(event.x to event.y)
                invalidate()
                return true
            }
            MotionEvent.ACTION_MOVE -> {
                val p = event.x to event.y
                val last = current.lastOrNull()
                if (last == null || Math.hypot((p.first - last.first).toDouble(), (p.second - last.second).toDouble()) > 1.2 * dp) {
                    current.add(p)
                    invalidate()
                }
                return true
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                if (current.size >= 2) {
                    strokes.add(HandwritingRecognizer.Stroke(current.toList()))
                    current = ArrayList()
                    handler.removeCallbacks(recognizeRunnable)
                    handler.postDelayed(recognizeRunnable, 480)
                } else {
                    current = ArrayList()
                }
                invalidate()
                return true
            }
        }
        return super.onTouchEvent(event)
    }

    fun undo() {
        handler.removeCallbacks(recognizeRunnable)
        if (strokes.isNotEmpty()) strokes.removeAt(strokes.size - 1)
        if (current.isNotEmpty()) current = ArrayList()
        invalidate()
        if (strokes.isNotEmpty()) handler.postDelayed(recognizeRunnable, 120)
    }

    fun clear() {
        handler.removeCallbacks(recognizeRunnable)
        strokes.clear()
        current = ArrayList()
        invalidate()
    }

    fun hasStrokes(): Boolean = strokes.isNotEmpty() || current.isNotEmpty()

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        handler.removeCallbacksAndMessages(null)
    }
}
