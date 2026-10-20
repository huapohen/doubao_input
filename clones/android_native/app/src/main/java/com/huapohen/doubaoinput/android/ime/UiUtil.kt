package com.huapohen.doubaoinput.android.ime

import android.content.Context
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.RippleDrawable
import android.os.Build
import android.view.Gravity
import android.view.View
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

fun Context.dp(v: Float): Int = (v * resources.displayMetrics.density + 0.5f).toInt()
fun Context.dp(v: Int): Int = dp(v.toFloat())
fun Context.sp(v: Float): Float = v * resources.displayMetrics.scaledDensity

fun rounded(color: Int, radiusDp: Float = 12f, strokeColor: Int = 0, strokeWidth: Int = 0): GradientDrawable =
    GradientDrawable().apply {
        shape = GradientDrawable.RECTANGLE
        setColor(color)
        cornerRadius = radiusDp * 3f // caller passes dp; 3x only used for very small? keep direct below
        cornerRadius = radiusDp
        if (strokeWidth > 0) setStroke(strokeWidth, strokeColor)
    }

fun rippleBackground(color: Int, pressed: Int, radiusPx: Float): RippleDrawable {
    val content = GradientDrawable().apply {
        setColor(color)
        cornerRadius = radiusPx
    }
    return RippleDrawable(ColorStateList.valueOf(pressed), content, null)
}

fun View.dp(v: Float): Int = context.dp(v)

fun toast(context: Context, msg: String) {
    Toast.makeText(context, msg, Toast.LENGTH_SHORT).show()
}

fun timeLabel(ts: Long): String {
    val fmt = SimpleDateFormat("MM-dd HH:mm", Locale.CHINA)
    return fmt.format(Date(ts))
}

fun isSystemDark(context: Context): Boolean =
    (context.resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK) ==
        android.content.res.Configuration.UI_MODE_NIGHT_YES

data class PanelColors(
    val bg: Int,
    val card: Int,
    val text: Int,
    val secondary: Int,
    val primary: Int,
    val divider: Int,
    val pressed: Int,
    val inputBg: Int,
    val danger: Int,
    val dark: Boolean
) {
    companion object {
        fun of(dark: Boolean): PanelColors = if (dark) PanelColors(
            bg = Color.parseColor("#17181A"),
            card = Color.parseColor("#242529"),
            text = Color.parseColor("#F2F2F4"),
            secondary = Color.parseColor("#A0A0A6"),
            primary = Color.parseColor("#6E9BFF"),
            divider = Color.parseColor("#26FFFFFF"),
            pressed = Color.parseColor("#334F84FF"),
            inputBg = Color.parseColor("#2E2F33"),
            danger = Color.parseColor("#FF6B6B"),
            dark = true
        ) else PanelColors(
            bg = Color.parseColor("#F2F3F5"),
            card = Color.WHITE,
            text = Color.parseColor("#111111"),
            secondary = Color.parseColor("#707070"),
            primary = Color.parseColor("#4F84FF"),
            divider = Color.parseColor("#1A394C5A"),
            pressed = Color.parseColor("#1A4F84FF"),
            inputBg = Color.parseColor("#F2F4F7"),
            danger = Color.parseColor("#FF5353"),
            dark = false
        )
    }
}

fun textView(
    ctx: Context,
    text: String,
    sizeSp: Float,
    color: Int,
    bold: Boolean = false,
    gravity: Int = Gravity.CENTER_VERTICAL
): TextView = TextView(ctx).apply {
    this.text = text
    textSize = sizeSp
    setTextColor(color)
    this.gravity = gravity
    includeFontPadding = false
    typeface = Typeface.create("sans-serif", if (bold) Typeface.BOLD else Typeface.NORMAL)
}

fun LinearLayout.horizontal(ctx: Context, gravity: Int = Gravity.CENTER_VERTICAL): LinearLayout = this.apply {
    orientation = LinearLayout.HORIZONTAL
    this.gravity = gravity
}

fun LinearLayout.vertical(ctx: Context): LinearLayout = this.apply {
    orientation = LinearLayout.VERTICAL
}

fun addRipple(view: View, color: Int, radiusPx: Float) {
    val bg = GradientDrawable().apply {
        setColor(Color.TRANSPARENT)
        cornerRadius = radiusPx
    }
    view.background = RippleDrawable(ColorStateList.valueOf(color), bg, null)
}

fun colorWithAlpha(color: Int, alpha: Int): Int = Color.argb(alpha, Color.red(color), Color.green(color), Color.blue(color))
