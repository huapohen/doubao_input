package com.huapohen.doubaoinput.flutter

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.inputmethodservice.InputMethodService
import android.os.Handler
import android.os.Looper
import android.text.InputType
import android.util.TypedValue
import android.view.Gravity
import android.view.KeyEvent
import android.view.View
import android.view.ViewGroup
import android.view.inputmethod.EditorInfo
import android.widget.FrameLayout
import android.widget.HorizontalScrollView
import android.widget.LinearLayout
import android.widget.TextView
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicInteger

/**
 * Real system IME service. It is a native Android keyboard (no Flutter engine in
 * the IME process) so it remains lightweight and reliable inside the IME window.
 * The in-app Flutter keyboard and this service share the same dictionary asset
 * and a subset of settings from FlutterSharedPreferences.
 */
class DoubaoImeService : InputMethodService() {
    private val engine = PinyinImeEngine()
    private val queryExecutor = Executors.newSingleThreadExecutor()
    private val queryGeneration = AtomicInteger(0)
    private val handler = Handler(Looper.getMainLooper())

    private lateinit var root: LinearLayout
    private lateinit var candidateStrip: LinearLayout
    private lateinit var keyboardView: ImeKeyboardView

    private var composing = ""
    private var candidates: List<PinyinImeEngine.Entry> = emptyList()
    var chinese = true
    var numbersMode = false
        private set
    var shift = false
        private set
    var caps = false
        private set
    var enterSend = false
        private set
    var keySound = true
        private set
    var keyVibrate = true
        private set
    private var lastShiftAt = 0L

    private val density get() = resources.displayMetrics.density
    private fun dp(v: Int): Int = (v * density).toInt()

    override fun onCreate() {
        super.onCreate()
        readPrefs()
        engine.loadAsync(applicationContext)
    }

    private fun readPrefs() {
        try {
            val p = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            keySound = p.getBoolean("flutter.key_sound", true)
            keyVibrate = p.getBoolean("flutter.key_vibrate", true)
            enterSend = p.getBoolean("flutter.enter_send", false)
        } catch (_: Exception) {
        }
    }

    override fun onCreateInputView(): View {
        readPrefs()
        root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#EBEBEB"))
        }

        val toolbar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(10), 0, dp(6), 0)
            setBackgroundColor(Color.parseColor("#F7F9FC"))
        }
        toolbar.addView(TextView(this).apply {
            text = "豆包输入法（复刻）"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
            setTextColor(Color.parseColor("#666666"))
            typeface = Typeface.create("sans-serif", Typeface.NORMAL)
        }, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1f))
        toolbar.addView(TextView(this).apply {
            text = "设置"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
            setTextColor(Color.parseColor("#4F84FF"))
            setPadding(dp(8), 0, dp(8), 0)
            gravity = Gravity.CENTER
            setOnClickListener {
                try {
                    startActivity(
                        Intent(this@DoubaoImeService, MainActivity::class.java)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    )
                } catch (_: Exception) {
                }
            }
        }, LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.MATCH_PARENT))
        toolbar.addView(TextView(this).apply {
            text = "收起"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
            setTextColor(Color.parseColor("#666666"))
            setPadding(dp(8), 0, dp(8), 0)
            gravity = Gravity.CENTER
            setOnClickListener { requestHideSelf(0) }
        }, LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.MATCH_PARENT))
        root.addView(toolbar, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(32)))

        val scroll = HorizontalScrollView(this).apply {
            isHorizontalScrollBarEnabled = false
            setBackgroundColor(Color.parseColor("#EBEBEB"))
        }
        candidateStrip = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(8), 0, dp(8), 0)
        }
        scroll.addView(
            candidateStrip,
            ViewGroup.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.MATCH_PARENT),
        )
        root.addView(scroll, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(48)))

        keyboardView = ImeKeyboardView(this)
        root.addView(keyboardView, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))

        showCandidates()
        val wrapper = object : FrameLayout(this) {
            override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
                val width = MeasureSpec.getSize(widthMeasureSpec)
                super.onMeasure(
                    MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY),
                    MeasureSpec.makeMeasureSpec(dp(300), MeasureSpec.EXACTLY),
                )
            }
        }
        wrapper.addView(
            root,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
        return wrapper
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        readPrefs()
        val inputClass = (info?.inputType ?: 0) and InputType.TYPE_MASK_CLASS
        chinese = inputClass != InputType.TYPE_CLASS_NUMBER
        composing = ""
        candidates = emptyList()
        shift = false
        caps = false
        numbersMode = false
        if (::keyboardView.isInitialized) keyboardView.refreshKeys()
        showCandidates()
    }

    override fun onFinishInput() {
        super.onFinishInput()
        composing = ""
        candidates = emptyList()
    }

    override fun onEvaluateFullscreenMode(): Boolean = false

    override fun onUpdateSelection(
        oldSelStart: Int,
        oldSelEnd: Int,
        newSelStart: Int,
        newSelEnd: Int,
        candidatesStart: Int,
        candidatesEnd: Int,
    ) {
        super.onUpdateSelection(oldSelStart, oldSelEnd, newSelStart, newSelEnd, candidatesStart, candidatesEnd)
        if (composing.isNotEmpty() && (newSelStart != newSelEnd)) {
            composing = ""
            candidates = emptyList()
            showCandidates()
        }
    }

    fun onLetter(letter: Char) {
        val upper = shift || caps
        if (!chinese) {
            val text = if (upper) letter.uppercaseChar().toString() else letter.toString()
            commitText(text)
            if (shift) {
                shift = false
                keyboardView.refreshKeys()
            }
            return
        }
        if (upper) {
            commitText(letter.uppercaseChar().toString())
            shift = false
            keyboardView.refreshKeys()
            return
        }
        composing += letter.lowercaseChar()
        refreshCandidates()
    }

    fun onBackspace() {
        if (composing.isNotEmpty()) {
            composing = composing.dropLast(1)
            refreshCandidates()
            return
        }
        val ic = currentInputConnection ?: return
        val selected = ic.getSelectedText(0)
        if (!selected.isNullOrEmpty()) {
            ic.commitText("", 1)
        } else {
            ic.deleteSurroundingText(1, 0)
        }
    }

    fun onSpace() {
        if (composing.isNotEmpty()) {
            if (candidates.isNotEmpty()) {
                commitCandidate(candidates.first())
            } else {
                commitText(composing)
                composing = ""
                candidates = emptyList()
                showCandidates()
            }
            return
        }
        commitText(" ")
    }

    fun onEnter() {
        val ic = currentInputConnection
        if (enterSend && ic != null) {
            val action = (currentInputEditorInfo?.imeOptions ?: 0) and android.view.inputmethod.EditorInfo.IME_MASK_ACTION
            val handled = action != 0 && ic.performEditorAction(action)
            if (!handled) commitText("\n")
        } else {
            commitText("\n")
        }
    }

    fun onSymbol(symbol: String) {
        if (composing.isNotEmpty()) {
            if (candidates.isNotEmpty()) commitCandidate(candidates.first()) else {
                commitText(composing)
                composing = ""
                candidates = emptyList()
            }
        }
        commitText(symbol)
        showCandidates()
    }

    fun onToggleLanguage() {
        chinese = !chinese
        composing = ""
        candidates = emptyList()
        shift = false
        caps = false
        keyboardView.refreshKeys()
        showCandidates()
    }

    fun onShift() {
        val now = System.currentTimeMillis()
        if (caps) {
            caps = false
            shift = false
        } else if (shift) {
            if (now - lastShiftAt < 360) {
                caps = true
                shift = false
            } else {
                shift = false
            }
        } else {
            shift = true
        }
        lastShiftAt = now
        keyboardView.refreshKeys()
    }

    fun setNumbersMode(enabled: Boolean) {
        numbersMode = enabled
        keyboardView.refreshKeys()
    }

    private fun commitCandidate(candidate: PinyinImeEngine.Entry) {
        commitText(candidate.word)
        engine.learn(candidate.word)
        composing = ""
        candidates = emptyList()
        showCandidates()
    }

    private fun commitText(text: String) {
        if (text.isEmpty()) return
        val ic = currentInputConnection ?: return
        ic.commitText(text, 1)
    }

    private fun refreshCandidates() {
        val query = composing.replace("'", "")
        val generation = queryGeneration.incrementAndGet()
        if (query.isEmpty()) {
            candidates = emptyList()
            showCandidates()
            return
        }
        if (!engine.loaded) {
            showCandidates()
            handler.postDelayed({
                if (composing.replace("'", "") == query) refreshCandidates()
            }, 350)
            return
        }
        queryExecutor.execute {
            val result = engine.query(query, 24)
            if (generation != queryGeneration.get()) return@execute
            handler.post {
                if (composing.replace("'", "") != query) return@post
                candidates = result
                showCandidates()
            }
        }
    }

    private fun showCandidates() {
        if (!::candidateStrip.isInitialized) return
        candidateStrip.removeAllViews()
        val label = TextView(this).apply {
            text = if (composing.isEmpty()) {
                if (chinese) "拼音" else "English"
            } else {
                composing
            }
            setTextSize(TypedValue.COMPLEX_UNIT_SP, if (composing.isEmpty()) 11f else 13f)
            setTextColor(Color.parseColor(if (composing.isEmpty()) "#666666" else "#4F84FF"))
            setPadding(dp(4), 0, dp(10), 0)
            gravity = Gravity.CENTER_VERTICAL
        }
        candidateStrip.addView(
            label,
            LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.MATCH_PARENT),
        )
        if (composing.isNotEmpty() && candidates.isEmpty()) {
            val text = if (!engine.loaded) "词典加载中…" else "无候选"
            candidateStrip.addView(TextView(this).apply {
                this.text = text
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
                setTextColor(Color.parseColor("#888888"))
                gravity = Gravity.CENTER_VERTICAL
                setPadding(dp(6), 0, dp(6), 0)
            })
            return
        }
        if (composing.isEmpty()) {
            val hint = TextView(this).apply {
                text = "点击按键输入 · 空格上屏首选"
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
                setTextColor(Color.parseColor("#888888"))
                gravity = Gravity.CENTER_VERTICAL
                setPadding(dp(6), 0, dp(6), 0)
            }
            candidateStrip.addView(hint)
            return
        }
        candidates.forEachIndexed { index, entry ->
            val item = TextView(this).apply {
                text = entry.word
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
                setTextColor(Color.parseColor(if (index == 0) "#4F84FF" else "#111111"))
                typeface = Typeface.create(
                    "sans-serif",
                    if (index == 0) Typeface.BOLD else Typeface.NORMAL,
                )
                gravity = Gravity.CENTER
                setPadding(dp(10), 0, dp(10), 0)
                setOnClickListener {
                    if (keySound) playSoundEffect(android.view.SoundEffectConstants.CLICK)
                    if (keyVibrate) performHapticFeedback(android.view.HapticFeedbackConstants.KEYBOARD_TAP)
                    commitCandidate(entry)
                }
            }
            candidateStrip.addView(
                item,
                LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.MATCH_PARENT),
            )
        }
    }

    override fun onDestroy() {
        queryExecutor.shutdownNow()
        engine.shutdown()
        super.onDestroy()
    }
}
