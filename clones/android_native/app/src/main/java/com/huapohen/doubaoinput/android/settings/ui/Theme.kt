package com.huapohen.doubaoinput.android.settings.ui

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import androidx.core.view.WindowCompat
import com.huapohen.doubaoinput.android.core.Prefs

val Primary = Color(0xFF4F84FF)
val PrimaryPressed = Color(0xFF3051F2)
val PageBgLight = Color(0xFFF2F7FF)
val PageBgDark = Color(0xFF11151C)
val CardLight = Color(0xFFFFFFFF)
val CardDark = Color(0xFF1B2029)
val TextPrimaryLight = Color(0xFF111111)
val TextPrimaryDark = Color(0xFFF2F4F7)
val TextSecondaryLight = Color(0xFF666666)
val TextSecondaryDark = Color(0xFF9AA3B2)
val DividerLight = Color(0x1A394C5A)
val DividerDark = Color(0x22FFFFFF)
val Danger = Color(0xFFFF5353)

fun resolveDark(context: Context): Boolean {
    return when (Prefs.themeMode) {
        "dark" -> true
        "light" -> false
        else -> {
            (context.resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK) ==
                android.content.res.Configuration.UI_MODE_NIGHT_YES
        }
    }
}

private val typography = Typography(
    displaySmall = TextStyle(fontFamily = FontFamily.SansSerif, fontWeight = FontWeight.SemiBold, fontSize = 26.sp),
    headlineSmall = TextStyle(fontFamily = FontFamily.SansSerif, fontWeight = FontWeight.SemiBold, fontSize = 22.sp),
    titleLarge = TextStyle(fontFamily = FontFamily.SansSerif, fontWeight = FontWeight.SemiBold, fontSize = 19.sp),
    titleMedium = TextStyle(fontFamily = FontFamily.SansSerif, fontWeight = FontWeight.Medium, fontSize = 16.sp),
    bodyLarge = TextStyle(fontFamily = FontFamily.SansSerif, fontSize = 15.sp),
    bodyMedium = TextStyle(fontFamily = FontFamily.SansSerif, fontSize = 13.5.sp),
    labelLarge = TextStyle(fontFamily = FontFamily.SansSerif, fontWeight = FontWeight.Medium, fontSize = 14.sp),
    labelSmall = TextStyle(fontFamily = FontFamily.SansSerif, fontSize = 11.sp)
)

@Composable
fun DoubaoTheme(dark: Boolean, content: @Composable () -> Unit) {
    val scheme = if (dark) darkColorScheme(
        primary = Primary,
        onPrimary = Color.White,
        secondary = Color(0xFF7DA5FF),
        background = PageBgDark,
        onBackground = TextPrimaryDark,
        surface = CardDark,
        onSurface = TextPrimaryDark,
        surfaceVariant = Color(0xFF252B36),
        onSurfaceVariant = TextSecondaryDark,
        outline = DividerDark,
        error = Danger
    ) else lightColorScheme(
        primary = Primary,
        onPrimary = Color.White,
        secondary = PrimaryPressed,
        background = PageBgLight,
        onBackground = TextPrimaryLight,
        surface = CardLight,
        onSurface = TextPrimaryLight,
        surfaceVariant = Color(0xFFEAF0F9),
        onSurfaceVariant = TextSecondaryLight,
        outline = DividerLight,
        error = Danger
    )
    MaterialTheme(colorScheme = scheme, typography = typography) {
        val view = LocalView.current
        if (!view.isInEditMode) {
            SideEffect {
                val window = view.context.findActivity()?.window ?: return@SideEffect
                window.statusBarColor = android.graphics.Color.TRANSPARENT
                window.navigationBarColor = android.graphics.Color.TRANSPARENT
                val controller = WindowCompat.getInsetsController(window, view)
                controller.isAppearanceLightStatusBars = !dark
                controller.isAppearanceLightNavigationBars = !dark
            }
        }
        content()
    }
}

private fun Context.findActivity(): Activity? {
    var ctx: Context? = this
    while (ctx is ContextWrapper) {
        if (ctx is Activity) return ctx
        ctx = ctx.baseContext
    }
    return null
}

@Composable
fun appDark(): Boolean = when (Prefs.themeMode) {
    "dark" -> true
    "light" -> false
    else -> isSystemInDarkTheme()
}
