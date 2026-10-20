package com.huapohen.doubaoinput.android.ime

import android.content.Context
import android.content.Intent
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import com.huapohen.doubaoinput.android.core.Prefs
import kotlin.math.sin

internal class VoiceManager(private val root: KeyboardRootView) {
    private val ctx: Context get() = root.context
    private var recognizer: SpeechRecognizer? = null
    private var overlay: VoiceOverlay? = null
    private var partial = ""
    private var listening = false
    private var finishing = false
    private var startAt = 0L
    private val handler = Handler(Looper.getMainLooper())
    private val ticker = object : Runnable {
        override fun run() {
            val o = overlay ?: return
            o.setSeconds(((SystemClock.elapsedRealtime() - startAt) / 1000).toInt())
            handler.postDelayed(this, 200)
        }
    }
    private val stopFallback = Runnable {
        if (finishing) {
            if (partial.isNotBlank()) deliver(partial, partialHint = true) else showError("没听清，请重新开始")
        }
    }

    fun start() {
        if (listening || overlay != null) return
        if (!SpeechRecognizer.isRecognitionAvailable(ctx)) {
            showUnavailable()
            return
        }
        partial = ""
        finishing = false
        startAt = SystemClock.elapsedRealtime()
        val o = VoiceOverlay(ctx, PanelColors.of(root.isDark))
        overlay = o
        o.onCancel = { cancel() }
        o.onFinish = { finishListening() }
        o.onRetry = { retry() }
        o.onExample = { useExample() }
        o.onOpenSettings = {
            cancel()
            root.openSettings("permissions")
        }
        o.setListening()
        root.setVoiceLayer(o)
        handler.post(ticker)
        createRecognizer()
    }

    private fun createRecognizer() {
        destroyRecognizer()
        val r = try { SpeechRecognizer.createSpeechRecognizer(ctx) } catch (t: Throwable) {
            showUnavailable(); return
        }
        recognizer = r
        r.setRecognitionListener(listener)
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "zh-CN")
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, "zh-CN")
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 3)
            putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, Prefs.getBool(Prefs.K_VOICE_OFFLINE))
        }
        try {
            r.startListening(intent)
            listening = true
        } catch (t: Throwable) {
            showError("语音识别启动失败：${t.javaClass.simpleName}")
        }
    }

    private val listener = object : RecognitionListener {
        override fun onReadyForSpeech(params: Bundle?) {
            overlay?.setStatus("正在倾听，请说话")
        }

        override fun onBeginningOfSpeech() {
            overlay?.setStatus("正在倾听")
        }

        override fun onRmsChanged(rmsdB: Float) {
            val level = ((rmsdB + 2f) / 12f).coerceIn(0f, 1f)
            overlay?.setLevel(level)
        }

        override fun onBufferReceived(buffer: ByteArray?) {}

        override fun onEndOfSpeech() {
            if (!finishing) overlay?.setStatus("识别优化中…")
        }

        override fun onError(error: Int) {
            if (overlay == null) return
            listening = false
            finishing = false
            handler.removeCallbacks(stopFallback)
            if (partial.isNotBlank() && (error == SpeechRecognizer.ERROR_NO_MATCH || error == SpeechRecognizer.ERROR_SPEECH_TIMEOUT)) {
                deliver(partial, partialHint = true)
                return
            }
            val (msg, permission) = when (error) {
                SpeechRecognizer.ERROR_AUDIO -> "麦克风被占用，请检查其他应用" to false
                SpeechRecognizer.ERROR_CLIENT -> "识别客户端异常，请重试" to false
                SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "需要麦克风权限" to true
                SpeechRecognizer.ERROR_NETWORK -> "请连接网络后再试" to false
                SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "网络超时，请重试" to false
                SpeechRecognizer.ERROR_NO_MATCH -> "没听清，请重新开始" to false
                SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "识别服务忙碌，请稍后重试" to false
                SpeechRecognizer.ERROR_SERVER -> "服务端异常，请稍后重试" to false
                SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "没有检测到语音，请重试" to false
                SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED -> "当前设备不支持中文语音识别" to false
                SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE -> "中文语音服务不可用" to false
                else -> "识别失败（错误码 $error），请重试" to false
            }
            showError(msg, permission)
        }

        override fun onResults(results: Bundle?) {
            handler.removeCallbacks(stopFallback)
            val list = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            val text = list?.firstOrNull { it.isNotBlank() } ?: partial
            if (text.isBlank()) {
                showError("没听清，请重新开始")
            } else {
                deliver(text, partialHint = false)
            }
        }

        override fun onPartialResults(partialResults: Bundle?) {
            val list = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            val text = list?.firstOrNull { it.isNotBlank() } ?: return
            partial = text
            overlay?.setTranscript(text)
        }

        override fun onEvent(eventType: Int, params: Bundle?) {}
    }

    private fun finishListening() {
        if (overlay == null) return
        if (!listening) {
            cancel()
            return
        }
        finishing = true
        overlay?.setStatus("识别优化中…")
        overlay?.showProcessing()
        try { recognizer?.stopListening() } catch (t: Throwable) { }
        handler.removeCallbacks(stopFallback)
        handler.postDelayed(stopFallback, 2600)
    }

    private fun deliver(text: String, partialHint: Boolean) {
        cleanup()
        root.panels.showVoiceResult(text, partialHint)
    }

    private fun showError(message: String, permission: Boolean = false) {
        listening = false
        finishing = false
        handler.removeCallbacks(stopFallback)
        val o = overlay ?: run {
            val n = VoiceOverlay(ctx, PanelColors.of(root.isDark))
            overlay = n
            n.onCancel = { cancel() }
            n.onRetry = { retry() }
            n.onExample = { useExample() }
            n.onOpenSettings = { cancel(); root.openSettings("permissions") }
            root.setVoiceLayer(n)
            n
        }
        if (permission) o.setPermissionError(message) else o.setError(message, allowRetry = true)
    }

    private fun showUnavailable() {
        if (overlay != null) return
        val o = VoiceOverlay(ctx, PanelColors.of(root.isDark))
        overlay = o
        o.onCancel = { cancel() }
        o.onRetry = { retry() }
        o.onExample = { useExample() }
        o.onOpenSettings = { cancel(); root.openSettings("permissions") }
        root.setVoiceLayer(o)
        o.setError("设备未提供语音识别服务（模拟器可能缺少语音服务）。可安装 Google 语音服务，或使用示例文本。", allowRetry = true)
    }

    private fun retry() {
        cleanup()
        partial = ""
        handler.postDelayed({ start() }, 120)
    }

    private fun useExample() {
        cleanup()
        root.panels.showVoiceResult(
            "这是一段离线示例文本：语音服务当前不可用时，你仍然可以编辑、整理并发送这段文字。",
            true,
            example = true
        )
    }

    fun cancel() {
        listening = false
        finishing = false
        handler.removeCallbacks(stopFallback)
        cleanup()
    }

    fun destroy() {
        cancel()
    }

    private fun cleanup() {
        handler.removeCallbacks(ticker)
        destroyRecognizer()
        root.removeVoiceLayer()
        overlay = null
    }

    private fun destroyRecognizer() {
        try {
            recognizer?.cancel()
            recognizer?.destroy()
        } catch (t: Throwable) { }
        recognizer = null
    }
}

internal class VoiceOverlay(context: Context, private val pal: PanelColors) : FrameLayout(context) {
    var onCancel: (() -> Unit)? = null
    var onFinish: (() -> Unit)? = null
    var onRetry: (() -> Unit)? = null
    var onExample: (() -> Unit)? = null
    var onOpenSettings: (() -> Unit)? = null

    private val wave = WaveView(context)
    private val status = TextView(context)
    private val transcript = TextView(context)
    private val timer = TextView(context)
    private val buttons = LinearLayout(context)
    private val card = LinearLayout(context)

    init {
        setBackgroundColor(Color.parseColor("#66000000"))
        card.orientation = LinearLayout.VERTICAL
        card.gravity = Gravity.CENTER_HORIZONTAL
        card.setPadding(dp(22), dp(18), dp(22), dp(16))
        card.background = GradientDrawable().apply {
            setColor(pal.card)
            cornerRadius = dp(24).toFloat()
        }
        card.elevation = dp(14).toFloat()

        val title = TextView(context).apply {
            text = "语音输入"
            textSize = 16f
            setTextColor(pal.text)
            typeface = android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.NORMAL)
            gravity = Gravity.CENTER
        }
        card.addView(title, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        timer.setTextColor(pal.secondary)
        timer.textSize = 12f
        timer.gravity = Gravity.CENTER
        timer.text = "00:00"
        card.addView(timer, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))

        wave.layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(62)).apply {
            topMargin = dp(6)
        }
        wave.setColor(pal.primary)
        card.addView(wave)

        status.textSize = 16f
        status.setTextColor(pal.text)
        status.gravity = Gravity.CENTER
        status.text = "正在倾听，请说话"
        card.addView(status, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
            topMargin = dp(4)
        })

        transcript.textSize = 13f
        transcript.setTextColor(pal.secondary)
        transcript.gravity = Gravity.CENTER
        transcript.maxLines = 3
        transcript.setPadding(dp(4), dp(8), dp(4), dp(4))
        card.addView(transcript, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))

        buttons.orientation = LinearLayout.HORIZONTAL
        buttons.gravity = Gravity.CENTER
        card.addView(buttons, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
            topMargin = dp(10)
        })

        addView(card, LayoutParams(
            Math.min(resources.displayMetrics.widthPixels - dp(28), dp(520)),
            ViewGroup.LayoutParams.WRAP_CONTENT,
            Gravity.CENTER
        ))
        setListening()
    }

    private fun dp(v: Int): Int = (v * resources.displayMetrics.density + 0.5f).toInt()

    private fun button(text: String, primary: Boolean, onClick: () -> Unit): TextView =
        TextView(context).apply {
            this.text = text
            textSize = 14f
            gravity = Gravity.CENTER
            setTextColor(if (primary) Color.WHITE else pal.text)
            background = GradientDrawable().apply {
                setColor(if (primary) pal.primary else (if (pal.dark) Color.parseColor("#33343A") else Color.parseColor("#F0F2F5")))
                cornerRadius = dp(20).toFloat()
            }
            setOnClickListener { onClick() }
            layoutParams = LinearLayout.LayoutParams(dp(98), dp(40)).apply {
                leftMargin = dp(4); rightMargin = dp(4)
            }
        }

    private fun rebuildButtons(mode: String) {
        buttons.removeAllViews()
        when (mode) {
            "listening", "processing" -> {
                buttons.addView(button("取消", false) { onCancel?.invoke() })
                buttons.addView(button("完成", true) { onFinish?.invoke() })
            }
            "error" -> {
                buttons.addView(button("取消", false) { onCancel?.invoke() })
                buttons.addView(button("重试", false) { onRetry?.invoke() })
                buttons.addView(button("示例文本", true) { onExample?.invoke() })
            }
            "permission" -> {
                buttons.addView(button("取消", false) { onCancel?.invoke() })
                buttons.addView(button("去设置", true) { onOpenSettings?.invoke() })
            }
        }
    }

    fun setListening() {
        status.text = "正在倾听，请说话"
        transcript.text = "说完点“完成”，或稍作停顿等待识别"
        timer.text = "00:00"
        wave.start()
        rebuildButtons("listening")
    }

    fun showProcessing() {
        status.text = "识别优化中…"
        wave.stop()
        rebuildButtons("processing")
    }

    fun setStatus(text: String) {
        status.text = text
    }

    fun setSeconds(s: Int) {
        timer.text = String.format("%02d:%02d", s / 60, s % 60)
    }

    fun setLevel(level: Float) {
        wave.setLevel(level)
    }

    fun setTranscript(text: String) {
        transcript.text = text
    }

    fun setError(message: String, allowRetry: Boolean) {
        wave.stop()
        status.text = if (allowRetry) "识别未完成" else "提示"
        transcript.text = message
        timer.text = ""
        rebuildButtons("error")
        if (!allowRetry) {
            buttons.removeAllViews()
            buttons.addView(button("取消", false) { onCancel?.invoke() })
            buttons.addView(button("示例文本", true) { onExample?.invoke() })
        }
    }

    fun setPermissionError(message: String) {
        wave.stop()
        status.text = "需要麦克风权限"
        transcript.text = message
        timer.text = ""
        rebuildButtons("permission")
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        wave.stop()
    }
}

internal class WaveView(context: Context) : View(context) {
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
        color = Color.parseColor("#4F84FF")
    }
    private var level = 0.15f
    private var phase = 0f
    private var running = false
    private val bars = 27
    private val random = FloatArray(bars) { (Math.random().toFloat() * 0.5f + 0.45f) }
    private val rect = RectF()
    private val dp = resources.displayMetrics.density

    fun setColor(color: Int) { paint.color = color; invalidate() }

    fun setLevel(value: Float) {
        level = value.coerceIn(0f, 1f)
    }

    fun start() {
        if (running) return
        running = true
        postOnAnimation(anim)
    }

    fun stop() {
        running = false
    }

    private val anim = object : Runnable {
        override fun run() {
            if (!running) return
            phase += 0.16f
            invalidate()
            postOnAnimationDelayed(this, 55)
        }
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val w = width.toFloat()
        val h = height.toFloat()
        val barW = 3.2f * dp
        val gap = (w - bars * barW) / (bars + 1)
        for (i in 0 until bars) {
            val base = 0.22f + 0.55f * level
            val wave = (sin(phase + i * 0.55).toFloat() + 1f) / 2f
            val factor = (0.28f + 0.72f * wave) * random[i]
            val bh = (h * (base * factor)).coerceIn(3f * dp, h)
            val x = gap + i * (barW + gap)
            rect.set(x, (h - bh) / 2f, x + barW, (h + bh) / 2f)
            canvas.drawRoundRect(rect, barW / 2f, barW / 2f, paint)
        }
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        running = false
    }
}
