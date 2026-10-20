package com.huapohen.doubaoinput.flutter

import android.annotation.SuppressLint
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.HapticFeedbackConstants
import android.view.SoundEffectConstants
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView

/** A programmatic 26-key keyboard used by the system IME service. */
@SuppressLint("ViewConstructor")
class ImeKeyboardView(private val service: DoubaoImeService) : LinearLayout(service) {
    private val density = resources.displayMetrics.density
    private val handler = Handler(Looper.getMainLooper())
    private var repeatRunnable: Runnable? = null

    init {
        orientation = VERTICAL
        setPadding(dp(4), dp(4), dp(4), dp(6))
        setBackgroundColor(Color.parseColor("#EBEBEB"))
        build()
    }

    fun refreshKeys() = build()

    private fun dp(v: Int): Int = (v * density).toInt()

    private fun rounded(color: Int, radius: Int = 8): GradientDrawable {
        return GradientDrawable().apply {
            setColor(color)
            cornerRadius = dp(radius).toFloat()
        }
    }

    private fun addKey(
        row: LinearLayout,
        label: String,
        weight: Float,
        style: Int = STYLE_NORMAL,
        textSize: Float = 20f,
        onClick: () -> Unit,
    ) {
        val context = service
        val key = TextView(context).apply {
            text = label
            gravity = Gravity.CENTER
            isClickable = true
            isFocusable = false
            setTextSize(android.util.TypedValue.COMPLEX_UNIT_SP, textSize)
            typeface = Typeface.create("sans-serif", Typeface.NORMAL)
            val bgColor = when (style) {
                STYLE_ACTION -> Color.parseColor("#4F84FF")
                STYLE_FUNC -> Color.parseColor("#BDC2C8")
                else -> Color.WHITE
            }
            background = rounded(bgColor)
            setTextColor(if (style == STYLE_ACTION) Color.WHITE else Color.parseColor("#111111"))
            setOnClickListener {
                if (service.keySound) playSoundEffect(SoundEffectConstants.CLICK)
                if (service.keyVibrate) performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                onClick()
            }
        }
        val lp = LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, weight)
        lp.setMargins(dp(2), dp(2), dp(2), dp(2))
        row.addView(key, lp)
    }

    private fun addSpacer(row: LinearLayout, weight: Float) {
        row.addView(View(service), LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, weight))
    }

    private fun addBackspace(row: LinearLayout, weight: Float) {
        val key = TextView(service).apply {
            text = "⌫"
            gravity = Gravity.CENTER
            isClickable = true
            isFocusable = false
            setTextSize(android.util.TypedValue.COMPLEX_UNIT_SP, 20f)
            setTextColor(Color.parseColor("#111111"))
            background = rounded(Color.parseColor("#BDC2C8"))
            setOnClickListener {
                if (service.keySound) playSoundEffect(SoundEffectConstants.CLICK)
                if (service.keyVibrate) performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                service.onBackspace()
            }
            setOnTouchListener { v, event ->
                when (event.actionMasked) {
                    android.view.MotionEvent.ACTION_DOWN -> {
                        v.isPressed = true
                        val runnable = object : Runnable {
                            override fun run() {
                                service.onBackspace()
                                handler.postDelayed(this, 55)
                            }
                        }
                        repeatRunnable = runnable
                        handler.postDelayed(runnable, 380)
                    }
                    android.view.MotionEvent.ACTION_UP,
                    android.view.MotionEvent.ACTION_CANCEL -> {
                        v.isPressed = false
                        repeatRunnable?.let { handler.removeCallbacks(it) }
                        repeatRunnable = null
                    }
                }
                false
            }
        }
        val lp = LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, weight)
        lp.setMargins(dp(2), dp(2), dp(2), dp(2))
        row.addView(key, lp)
    }

    private fun row(): LinearLayout {
        return LinearLayout(service).apply {
            orientation = HORIZONTAL
            layoutParams = LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f)
        }
    }

    private fun build() {
        removeAllViews()
        if (service.numbersMode) buildNumbers() else buildLetters()
        requestLayout()
    }

    private fun buildLetters() {
        val shift = service.shift || service.caps
        val row1 = row()
        for (c in "qwertyuiop") {
            addKey(row1, if (shift) c.uppercase() else c.toString(), 1f) { service.onLetter(c) }
        }
        addView(row1)

        val row2 = row()
        addSpacer(row2, 0.5f)
        for (c in "asdfghjkl") {
            addKey(row2, if (shift) c.uppercase() else c.toString(), 1f) { service.onLetter(c) }
        }
        addSpacer(row2, 0.5f)
        addView(row2)

        val row3 = row()
        addKey(row3, if (service.caps) "⇪" else "⇧", 1.5f, STYLE_FUNC, 18f) { service.onShift() }
        for (c in "zxcvbnm") {
            addKey(row3, if (shift) c.uppercase() else c.toString(), 1f) { service.onLetter(c) }
        }
        addBackspace(row3, 1.5f)
        addView(row3)

        val row4 = row()
        addKey(row4, "123", 1.3f, STYLE_FUNC, 14f) { service.setNumbersMode(true) }
        addKey(row4, "，", 1f) { service.onSymbol("，") }
        addKey(row4, "空格", 4.2f, STYLE_NORMAL, 13f) { service.onSpace() }
        addKey(row4, if (service.chinese) "中/英" else "英/中", 1.4f, STYLE_NORMAL, 11f) {
            service.onToggleLanguage()
        }
        addKey(row4, if (service.enterSend) "发送" else "换行", 1.6f, STYLE_ACTION, 13f) {
            service.onEnter()
        }
        addView(row4)
    }

    private fun buildNumbers() {
        val rows = listOf(
            "1234567890",
            "-/:;()¥&@\"",
            ".,?!'",
        )
        for ((index, chars) in rows.withIndex()) {
            val r = row()
            for (c in chars) {
                addKey(r, c.toString(), 1f, STYLE_NORMAL, 18f) { service.onSymbol(c.toString()) }
            }
            if (index == rows.lastIndex) {
                addBackspace(r, 2f)
            }
            addView(r)
        }
        val bottom = row()
        addKey(bottom, "ABC", 1.4f, STYLE_FUNC, 13f) { service.setNumbersMode(false) }
        addKey(bottom, "符号", 1.1f, STYLE_FUNC, 12f) { service.onSymbol("！") }
        addKey(bottom, "空格", 3.0f, STYLE_NORMAL, 13f) { service.onSpace() }
        addKey(bottom, "中/英", 1.3f, STYLE_NORMAL, 11f) { service.onToggleLanguage() }
        addKey(bottom, if (service.enterSend) "发送" else "换行", 1.5f, STYLE_ACTION, 13f) {
            service.onEnter()
        }
        addView(bottom)
    }

    companion object {
        const val STYLE_NORMAL = 0
        const val STYLE_FUNC = 1
        const val STYLE_ACTION = 2
    }
}
