package com.huapohen.doubaoinput.android.ime

import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.text.InputType
import android.util.TypedValue
import android.view.Gravity
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.inputmethod.EditorInfo
import android.widget.FrameLayout
import android.widget.HorizontalScrollView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import com.huapohen.doubaoinput.android.ai.AiClient
import com.huapohen.doubaoinput.android.core.ClipboardRepo
import com.huapohen.doubaoinput.android.core.ClipItem
import com.huapohen.doubaoinput.android.core.LexiconEntry
import com.huapohen.doubaoinput.android.core.LexiconRepo
import com.huapohen.doubaoinput.android.core.Prefs
import com.huapohen.doubaoinput.android.core.ToolbarRepo
import com.huapohen.doubaoinput.android.engine.EmojiData
import com.huapohen.doubaoinput.android.engine.HandwritingRecognizer
import com.huapohen.doubaoinput.android.engine.PinyinEngine
import com.huapohen.doubaoinput.android.engine.StrokeData
import com.huapohen.doubaoinput.android.engine.TradData
import com.huapohen.doubaoinput.android.engine.WubiData
import com.huapohen.doubaoinput.android.settings.TextInputActivity
import java.util.UUID
import kotlin.math.max
import kotlin.math.min

internal data class ImeCandidate(
    val text: String,
    val label: String = text,
    val kind: String = "pinyin",
    val pinyin: String = "",
    val freq: Int = 0,
    val payload: String = ""
)

class KeyboardRootView(context: Context, val service: DoubaoImeService) : FrameLayout(context) {

    // ---------- sizing / theme ----------
    private val density = resources.displayMetrics.density
    internal val panelColors: PanelColors
        get() = PanelColors.of(isDark)
    internal var isDark: Boolean = false
        private set
    internal var baseHeightPx: Int = 0
        private set
    internal var contentWidthPx: Int = 0
        private set
    private var theme = KeyboardTheme.light()

    // ---------- views ----------
    private lateinit var content: FrameLayout
    private lateinit var mainColumn: LinearLayout
    private lateinit var toolbarRow: LinearLayout
    private lateinit var toolbarScroll: HorizontalScrollView
    private lateinit var hideButton: TextView
    private lateinit var composeStrip: TextView
    private lateinit var candidateBar: LinearLayout
    private lateinit var composeChip: TextView
    private lateinit var candidateScroll: HorizontalScrollView
    private lateinit var candidateRow: LinearLayout
    private lateinit var body: FrameLayout
    private lateinit var keyboardView: KeyboardView
    private lateinit var handwritingContainer: LinearLayout
    private lateinit var handwritingPad: HandwritingPadView
    private lateinit var handwritingSidebar: LinearLayout
    internal lateinit var panelOverlay: FrameLayout
    private var voiceLayer: FrameLayout? = null

    // ---------- state ----------
    internal var inputMode: String = Prefs.inputMode
        private set
    internal var kbType: String = Prefs.keyboardType
        private set
    private var numberMode = false
    private var symbolMode = false
    private var imposedNumber = false
    private var composing = ""
    private var candidates: MutableList<ImeCandidate> = mutableListOf()
    private var handwritingResults: MutableList<ImeCandidate> = mutableListOf()
    private var shift = false
    private var caps = false
    private var lastShiftTime = 0L
    private var lastSpaceTime = 0L
    private var lastCommitted = ""
    private var sentenceStart = true
    private var editorInfo: EditorInfo? = null
    private var lastActionLabel = ""
    private var lastModeLabel = ""
    private var lastLayoutSignature = ""
    private var oneHand = Prefs.oneHand
    private var floating = Prefs.floating
    private var composeTop = true
    private val undoStack = ArrayDeque<String>()
    private var firstPickerShown = false
    private val handler = Handler(Looper.getMainLooper())
    internal val panels by lazy { KeyboardPanels(this) }
    internal val voice by lazy { VoiceManager(this) }
    private val textCallbacks = LinkedHashMap<String, (String, String) -> Unit>()
    internal var currentPanelOpen = false
        private set

    private val prefListener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
        when (key) {
            Prefs.K_THEME_MODE, Prefs.K_KEYBOARD_HEIGHT, Prefs.K_KEYBOARD_BOTTOM_GAP,
            Prefs.K_ONE_HAND, Prefs.K_FLOATING, Prefs.K_CANDIDATE_FONT_SIZE, Prefs.K_PINYIN_LOCATION,
            Prefs.K_SLIDE_SYMBOLS, Prefs.K_KEY_BUBBLE, Prefs.K_DIGIT_MERGED, Prefs.K_COMMA_PERIOD,
            Prefs.K_TRAD_OUTPUT, Prefs.K_ENTER_SEND, Prefs.K_ZH_EN_POSITION, Prefs.K_SIDEBAR_SYMBOLS -> handler.post { applySettings() }
            Prefs.K_CUSTOM_TOOLBAR -> handler.post { rebuildToolbar() }
            Prefs.K_KEYBOARD_TYPE -> handler.post {
                if (kbType != Prefs.keyboardType) {
                    kbType = Prefs.keyboardType
                    numberMode = false; symbolMode = false; composing = ""; handwritingResults.clear()
                    rebuildKeyboard(); refreshCandidates()
                }
            }
            Prefs.K_INPUT_MODE -> handler.post {
                if (inputMode != Prefs.inputMode) { inputMode = Prefs.inputMode; rebuildKeyboard(); refreshCandidates() }
            }
            Prefs.K_CLIPBOARD_CANDIDATE, Prefs.K_ASSOCIATION, Prefs.K_PRED_EMOJI, Prefs.K_PRED_IMAGE,
            Prefs.K_PRED_KAOMOJI -> handler.post { refreshCandidates() }
            Prefs.K_PERSONAL_LEXICON, Prefs.K_BLACKLIST, Prefs.K_MRU -> handler.post { refreshCandidates() }
        }
    }

    init {
        Prefs.init(context)
        computeTheme()
        buildUi()
        rebuildToolbar()
        rebuildKeyboard()
        refreshCandidates()
        try { Prefs.sp.registerOnSharedPreferenceChangeListener(prefListener) } catch (t: Throwable) { }
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val width = MeasureSpec.getSize(widthMeasureSpec)
        val exactWidth = MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY)
        val exactHeight = MeasureSpec.makeMeasureSpec(baseHeightPx, MeasureSpec.EXACTLY)
        super.onMeasure(exactWidth, exactHeight)
        setMeasuredDimension(width, baseHeightPx)
    }

    private fun computeTheme() {
        val mode = Prefs.themeMode
        isDark = when (mode) {
            "dark" -> true
            "light" -> false
            else -> isSystemDark(context)
        }
        theme = if (isDark) KeyboardTheme.dark() else KeyboardTheme.light()
    }

    private fun baseHeightDp(): Int {
        val override = Prefs.keyboardHeight
        if (override > 0) return override.coerceIn(220, 460)
        val cfg = resources.configuration
        val tablet = cfg.smallestScreenWidthDp >= 600
        return when {
            tablet -> 300
            cfg.orientation == Configuration.ORIENTATION_LANDSCAPE -> 250
            else -> 340
        }
    }

    private fun computeWidthPx(): Int {
        val screenDp = resources.displayMetrics.widthPixels / density
        var w = min(screenDp, 960f)
        if (oneHand != "off") w *= 0.94f
        if (floating) w *= 0.88f
        return (w * density).toInt()
    }

    private fun buildUi() {
        removeAllViews()
        baseHeightPx = (baseHeightDp() * density).toInt()
        contentWidthPx = computeWidthPx()
        composeTop = Prefs.getString(Prefs.K_PINYIN_LOCATION, "top") == "top"

        setBackgroundColor(if (floating) Color.TRANSPARENT else theme.bg)

        content = FrameLayout(context)
        val lp = LayoutParams(contentWidthPx, baseHeightPx, Gravity.CENTER_HORIZONTAL or Gravity.TOP)
        if (floating) {
            lp.height = baseHeightPx - dp(24f)
            lp.topMargin = dp(12f)
        }
        content.layoutParams = lp
        applyContentBackground()
        content.clipToOutline = true
        content.elevation = if (floating) dp(12f).toFloat() else 0f
        addView(content)
        layoutGravity()

        mainColumn = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }
        mainColumn.layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
        content.addView(mainColumn)

        // toolbar
        val toolbarFrame = FrameLayout(context)
        toolbarFrame.layoutParams = LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT, dp(46f))
        toolbarScroll = HorizontalScrollView(context).apply {
            isFillViewport = false
            isHorizontalScrollBarEnabled = false
            clipToPadding = false
            setPadding(dp(4f), 0, dp(42f), 0)
        }
        toolbarRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        toolbarScroll.addView(toolbarRow)
        toolbarFrame.addView(toolbarScroll, FrameLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
        hideButton = TextView(context).apply {
            text = "⌄"
            textSize = 22f
            gravity = Gravity.CENTER
            setTextColor(theme.text)
            background = rippleBackground(Color.TRANSPARENT, colorWithAlpha(theme.action, 60), dp(18f).toFloat())
            contentDescription = "收起键盘"
            setOnClickListener { service.hideKeyboard() }
        }
        toolbarFrame.addView(hideButton, FrameLayout.LayoutParams(dp(36f), dp(36f), Gravity.END or Gravity.CENTER_VERTICAL).apply {
            rightMargin = dp(4f)
        })
        mainColumn.addView(toolbarFrame)

        // composition strip (top mode)
        composeStrip = TextView(context).apply {
            textSize = 12.5f
            setTextColor(if (isDark) Color.parseColor("#9EA4AE") else Color.parseColor("#6E7681"))
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(12f), 0, dp(12f), 0)
            isSingleLine = true
            isClickable = true
            setOnClickListener { showCompositionDetail() }
        }
        composeStrip.layoutParams = LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT, dp(22f))
        mainColumn.addView(composeStrip)

        // candidate bar
        candidateBar = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(4f), 0, dp(2f), 0)
        }
        candidateBar.layoutParams = LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT, dp(42f))
        composeChip = TextView(context).apply {
            textSize = 14f
            setTextColor(theme.action)
            gravity = Gravity.CENTER
            setPadding(dp(8f), 0, dp(8f), 0)
            maxWidth = dp(150f)
            isSingleLine = true
            isClickable = true
            setOnClickListener { showCompositionDetail() }
        }
        candidateBar.addView(composeChip)

        candidateScroll = HorizontalScrollView(context).apply {
            isHorizontalScrollBarEnabled = false
            clipToPadding = false
        }
        candidateRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        candidateScroll.addView(candidateRow, ViewGroup.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.MATCH_PARENT))
        candidateBar.addView(candidateScroll, LinearLayout.LayoutParams(0, LayoutParams.MATCH_PARENT, 1f))

        fun smallButton(label: String, onClick: () -> Unit): TextView = TextView(context).apply {
            text = label
            textSize = 16f
            gravity = Gravity.CENTER
            setTextColor(if (isDark) Color.parseColor("#C9CDD4") else Color.parseColor("#5B6470"))
            background = rippleBackground(Color.TRANSPARENT, colorWithAlpha(theme.action, 50), dp(6f).toFloat())
            setOnClickListener { onClick() }
        }
        val prev = smallButton("‹") { candidateScroll.smoothScrollBy(-dp(220f), 0) }
        val next = smallButton("›") { candidateScroll.smoothScrollBy(dp(220f), 0) }
        val more = smallButton("▾") { panels.showCandidateMore() }
        candidateBar.addView(prev, LinearLayout.LayoutParams(dp(22f), LayoutParams.MATCH_PARENT))
        candidateBar.addView(next, LinearLayout.LayoutParams(dp(22f), LayoutParams.MATCH_PARENT))
        candidateBar.addView(more, LinearLayout.LayoutParams(dp(26f), LayoutParams.MATCH_PARENT))
        mainColumn.addView(candidateBar)

        // body: keyboard or handwriting
        body = FrameLayout(context)
        val bodyLp = LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT, 0, 1f)
        bodyLp.bottomMargin = dp(Prefs.keyboardBottomGap + 24f)
        mainColumn.addView(body, bodyLp)

        keyboardView = KeyboardView(context)
        keyboardView.theme = theme
        keyboardView.layoutParams = FrameLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
        keyboardView.listener = object : KeyboardView.Listener {
            override fun onKey(key: KeySpec, alt: String?) = handleKey(key, alt)
            override fun onLongPress(key: KeySpec, alt: String?) {
                if (key.id == "space") { startVoice(); return }
                if (key.id == "comma") { commitPunctuation("。"); return }
                if (key.id == "backspace") { undoStack.clear(); service.deleteBackward(30); toast("已快速删除，可点撤销恢复最近文字"); return }
                if (key.kind == KeyKind.CHAR && alt != null) return
            }
            override fun onRepeatBackspace() = deleteOne()
            override fun onFeedback() = service.feedback()
            override fun onVoiceGesture() = startVoice()
        }
        body.addView(keyboardView)

        handwritingContainer = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            visibility = View.GONE
        }
        val hsTop = LinearLayout(context).apply { orientation = LinearLayout.HORIZONTAL }
        handwritingPad = HandwritingPadView(context).apply {
            setColors(theme)
            onRecognized = { results ->
                handwritingResults = results.map {
                    ImeCandidate(it.ch, it.ch, "handwriting", "", (1000 - (it.score * 500)).toInt())
                }.toMutableList()
                refreshCandidates()
            }
        }
        hsTop.addView(handwritingPad, LinearLayout.LayoutParams(0, LayoutParams.MATCH_PARENT, 1f))
        handwritingSidebar = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }
        listOf("，", "。", "？", "！").forEach { p ->
            val b = TextView(context).apply {
                text = p
                textSize = 18f
                gravity = Gravity.CENTER
                setTextColor(theme.text)
                background = rippleBackground(theme.func, colorWithAlpha(theme.action, 70), dp(8f).toFloat())
                setOnClickListener { commitPunctuation(p) }
            }
            handwritingSidebar.addView(b, LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT, 0, 1f).apply {
                bottomMargin = dp(3f)
            })
        }
        hsTop.addView(handwritingSidebar, LinearLayout.LayoutParams(dp(42f), LayoutParams.MATCH_PARENT))
        handwritingContainer.addView(hsTop, LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT, 0, 1f))
        val hsBar = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(4f), dp(2f), dp(4f), dp(2f))
        }
        fun hsBtn(text: String, weight: Float, action: () -> Unit) {
            val b = TextView(context).apply {
                this.text = text
                textSize = 13f
                gravity = Gravity.CENTER
                setTextColor(theme.text)
                background = rippleBackground(theme.key, colorWithAlpha(theme.action, 70), dp(8f).toFloat())
                setOnClickListener { action() }
            }
            hsBar.addView(b, LinearLayout.LayoutParams(0, LayoutParams.MATCH_PARENT, weight).apply {
                leftMargin = dp(2f); rightMargin = dp(2f)
            })
        }
        hsBtn("清空", 1f) { handwritingPad.clear(); handwritingResults.clear(); refreshCandidates() }
        hsBtn("撤销", 1f) { handwritingPad.undo() }
        hsBtn("符号", 1f) { symbolMode = true; rebuildKeyboard() }
        hsBtn("空格", 1.6f) { service.commitText(" ") }
        hsBtn("中/英", 1.1f) { toggleInputMode() }
        hsBtn("换行", 1f) { sendNewline() }
        handwritingContainer.addView(hsBar, LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT, dp(46f)))
        body.addView(handwritingContainer)

        panelOverlay = FrameLayout(context).apply {
            visibility = View.GONE
            setBackgroundColor(theme.bg)
        }
        panelOverlay.layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
        content.addView(panelOverlay)
    }

    private fun applyContentBackground() {
        val radius = if (floating) dp(18f).toFloat() else 0f
        content.background = GradientDrawable().apply {
            setColor(theme.bg)
            cornerRadius = radius
        }
    }

    private fun layoutGravity() {
        val lp = content.layoutParams as LayoutParams
        lp.gravity = when {
            oneHand == "left" -> Gravity.START or Gravity.TOP
            oneHand == "right" -> Gravity.END or Gravity.TOP
            else -> Gravity.CENTER_HORIZONTAL or Gravity.TOP
        }
        content.layoutParams = lp
    }

    private fun dp(v: Float): Int = (v * density + 0.5f).toInt()

    private fun applySettings() {
        val oldHeight = baseHeightPx
        val oldWidth = contentWidthPx
        val oldFloating = floating
        val oldOneHand = oneHand
        computeTheme()
        oneHand = Prefs.oneHand
        floating = Prefs.floating
        composeTop = Prefs.getString(Prefs.K_PINYIN_LOCATION, "top") == "top"
        baseHeightPx = (baseHeightDp() * density).toInt()
        contentWidthPx = computeWidthPx()
        setBackgroundColor(if (floating) Color.TRANSPARENT else theme.bg)
        keyboardView.theme = theme
        handwritingPad.setColors(theme)
        panelOverlay.setBackgroundColor(theme.bg)
        applyContentBackground()
        hideButton.setTextColor(theme.text)
        val lp = content.layoutParams as LayoutParams
        lp.width = contentWidthPx
        lp.height = if (floating) baseHeightPx - dp(24f) else baseHeightPx
        lp.topMargin = if (floating) dp(12f) else 0
        content.layoutParams = lp
        content.elevation = if (floating) dp(12f).toFloat() else 0f
        content.translationX = 0f
        content.translationY = 0f
        layoutGravity()
        val bodyLp = body.layoutParams as LinearLayout.LayoutParams
        bodyLp.bottomMargin = dp(Prefs.keyboardBottomGap + 24f)
        body.layoutParams = bodyLp
        try {
            service.window?.window?.setBackgroundDrawable(
                ColorDrawable(if (floating) Color.TRANSPARENT else theme.bg)
            )
        } catch (t: Throwable) { }
        rebuildToolbar()
        rebuildKeyboard()
        refreshCandidates()
        if (oldHeight != baseHeightPx || oldWidth != contentWidthPx || oldFloating != floating || oldOneHand != oneHand) {
            requestLayout()
            handler.postDelayed({ requestLayout() }, 30)
        }
    }

    private fun rebuildToolbar() {
        toolbarRow.removeAllViews()
        if (floating) {
            val drag = TextView(context).apply {
                text = "⠿"
                textSize = 18f
                gravity = Gravity.CENTER
                setTextColor(theme.sub)
                contentDescription = "拖动悬浮键盘"
            }
            var startX = 0f; var startY = 0f; var baseX = 0f; var baseY = 0f
            drag.setOnTouchListener { _, ev ->
                when (ev.actionMasked) {
                    MotionEvent.ACTION_DOWN -> {
                        startX = ev.rawX; startY = ev.rawY
                        baseX = content.translationX; baseY = content.translationY
                        true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val maxX = max(0f, (width - content.width) / 2f)
                        val maxY = max(0f, (height - content.height - dp(12f)).toFloat())
                        content.translationX = (baseX + ev.rawX - startX).coerceIn(-maxX, maxX)
                        content.translationY = (baseY + ev.rawY - startY).coerceIn(0f, maxY)
                        true
                    }
                    else -> true
                }
            }
            toolbarRow.addView(drag, LinearLayout.LayoutParams(dp(30f), dp(36f)))
        }
        ToolbarRepo.current().forEach { id ->
            toolbarRow.addView(makeToolbarButton(id))
        }
    }

    private fun makeToolbarButton(id: String): View {
        val (glyph, label) = when (id) {
            "toolbox", "voice", "clipboard", "translate", "emoji", "phrase", "keyboard",
            "trad", "onehand", "handwrite", "undo", "ai", "hide" -> glyphFor(id) to labelFor(id)
            else -> "•" to ""
        }
        val tv = TextView(context).apply {
            text = if (id == "voice") label else glyph
            textSize = if (id == "voice") 12f else 17f
            gravity = Gravity.CENTER
            setTextColor(if (id == "voice") theme.action else theme.text)
            isSingleLine = true
            contentDescription = labelFor(id)
            if (id == "voice") {
                background = GradientDrawable().apply {
                    setColor(if (isDark) Color.parseColor("#2C2D30") else theme.key)
                    cornerRadius = dp(17f).toFloat()
                }
                setPadding(dp(12f), 0, dp(12f), 0)
            } else {
                background = rippleBackground(Color.TRANSPARENT, colorWithAlpha(theme.action, 60), dp(9f).toFloat())
            }
            setOnClickListener { onToolbarItem(id) }
        }
        val lp = if (id == "voice") {
            LinearLayout.LayoutParams(LayoutParams.WRAP_CONTENT, dp(34f)).apply {
                leftMargin = dp(2f); rightMargin = dp(2f)
            }
        } else {
            LinearLayout.LayoutParams(dp(36f), dp(36f)).apply {
                leftMargin = dp(1f); rightMargin = dp(1f)
            }
        }
        tv.layoutParams = lp
        return tv
    }

    private fun glyphFor(id: String) = when (id) {
        "toolbox" -> "⊞"; "voice" -> "🎤"; "clipboard" -> "📋"; "translate" -> "文A"
        "emoji" -> "☺"; "phrase" -> "💬"; "keyboard" -> "⌨"; "trad" -> "繁"
        "onehand" -> "◧"; "handwrite" -> "✍"; "undo" -> "↶"; "ai" -> "✦"; "hide" -> "⌄"
        else -> "•"
    }

    private fun labelFor(id: String) = when (id) {
        "toolbox" -> "工具箱"; "voice" -> "点击说话"; "clipboard" -> "剪贴板"; "translate" -> "翻译"
        "emoji" -> "表情"; "phrase" -> "常用语"; "keyboard" -> "键盘选择"; "trad" -> "繁简切换"
        "onehand" -> "单手模式"; "handwrite" -> "手写找字"; "undo" -> "撤销"; "ai" -> "AI 写作"; "hide" -> "收起"
        else -> id
    }

    private fun onToolbarItem(id: String) {
        when (id) {
            "toolbox" -> panels.showToolbox()
            "voice" -> startVoice()
            "clipboard" -> panels.showClipboard()
            "translate" -> panels.showTranslate()
            "emoji" -> panels.showEmoji()
            "phrase" -> panels.showPhrases()
            "keyboard" -> panels.showKeyboardSwitcher()
            "trad" -> toggleTraditional()
            "onehand" -> cycleOneHand()
            "handwrite" -> panels.showHandwritingSearch()
            "undo" -> undoLast()
            "ai" -> panels.showAi()
            "hide" -> service.hideKeyboard()
        }
    }

    // ---------- editor lifecycle ----------
    fun onEditorChanged(info: EditorInfo?) {
        editorInfo = info
        val cls = info?.inputType?.and(InputType.TYPE_MASK_CLASS)
        val wasImposed = imposedNumber
        imposedNumber = cls == InputType.TYPE_CLASS_NUMBER || cls == InputType.TYPE_CLASS_PHONE ||
            cls == InputType.TYPE_CLASS_DATETIME
        if (imposedNumber) {
            numberMode = true; symbolMode = false
        } else if (wasImposed) {
            numberMode = false; symbolMode = false
        }
        val action = service.actionLabel()
        if (action != lastActionLabel) {
            lastActionLabel = action
            rebuildKeyboard()
        } else {
            rebuildKeyboard()
        }
        refreshCandidates()
        if (inputMode == "en" && Prefs.getBool(Prefs.K_QUICK_CAPITALIZE)) {
            shift = sentenceStart
            keyboardView.setShift(shift, caps)
        }
    }

    fun onInputFinished() {
        voice.cancel()
        hidePanel()
        composing = ""
        candidates.clear()
        undoStack.clear()
    }

    fun onSelectionChanged() {
        // Selection changes do not affect composing text; clipboard chip may become stale.
    }

    fun onWindowShown() {
        PinyinEngine.ensureLoaded(service)
        refreshCandidates()
        if (!Prefs.getBool(Prefs.K_KEYBOARD_TYPE_CHOSEN) && !firstPickerShown) {
            firstPickerShown = true
            handler.postDelayed({ panels.showKeyboardSwitcher(firstRun = true) }, 280)
        }
        if (Prefs.clipboardHistory) {
            val clip = service.clipboardText().trim()
            if (clip.isNotEmpty() && clip.length < 5000) {
                val last = ClipboardRepo.all().firstOrNull()?.text
                if (last != clip) ClipboardRepo.add(clip)
            }
        }
    }

    fun onWindowHidden() {
        voice.cancel()
        hidePanel()
    }

    fun destroy() {
        voice.destroy()
        handler.removeCallbacksAndMessages(null)
        try { Prefs.sp.unregisterOnSharedPreferenceChangeListener(prefListener) } catch (t: Throwable) { }
    }

    // ---------- keyboard build ----------
    internal fun rebuildKeyboard() {
        if (!numberMode && !symbolMode && !imposedNumber && kbType != Prefs.keyboardType) {
            kbType = Prefs.keyboardType
        }
        val action = service.actionLabel()
        lastActionLabel = action
        val modeLabel = if (inputMode == "zh") "中" else "英"
        lastModeLabel = modeLabel
        val signature = "$action|$modeLabel|$kbType|$numberMode|$symbolMode|$shift|$caps|$inputMode|$isDark|" +
            "${Prefs.getBool(Prefs.K_DIGIT_MERGED)}|${Prefs.getBool(Prefs.K_COMMA_PERIOD)}|" +
            "${Prefs.getString(Prefs.K_ZH_EN_POSITION, "right")}|${Prefs.sidebarSymbols()}"
        if (signature == lastLayoutSignature && keyboardView.layoutCount() > 0) {
            keyboardView.theme = theme
            return
        }
        lastLayoutSignature = signature
        keyboardView.theme = theme
        val layout = when {
            numberMode -> KeyboardLayouts.numbers(action, modeLabel, inputMode == "zh")
            symbolMode -> KeyboardLayouts.symbols(action, modeLabel, inputMode == "zh")
            kbType == "pinyin9" && inputMode == "zh" -> KeyboardLayouts.t9(action, modeLabel, Prefs.sidebarSymbols())
            kbType == "stroke" -> KeyboardLayouts.stroke(action, modeLabel)
            else -> KeyboardLayouts.qwerty(
                inputMode == "zh", action, modeLabel,
                separateSymbols = !Prefs.getBool(Prefs.K_DIGIT_MERGED, true),
                separateCommaPeriod = Prefs.getBool(Prefs.K_COMMA_PERIOD),
                modeOnLeft = Prefs.getString(Prefs.K_ZH_EN_POSITION, "right") == "left"
            )
        }
        keyboardView.setLayout(layout)
        keyboardView.setShift(shift, caps)
        keyboardView.slideEnabled = Prefs.getBool(Prefs.K_SLIDE_SYMBOLS, true)
        val handwriting = kbType == "handwriting" && !numberMode && !symbolMode
        keyboardView.visibility = if (handwriting) View.GONE else View.VISIBLE
        handwritingContainer.visibility = if (handwriting) View.VISIBLE else View.GONE
        handwritingSidebar.setBackgroundColor(theme.bg)
        for (i in 0 until handwritingSidebar.childCount) {
            val child = handwritingSidebar.getChildAt(i) as? TextView ?: continue
            child.setTextColor(theme.text)
            child.background = rippleBackground(theme.func, colorWithAlpha(theme.action, 70), dp(8f).toFloat())
        }
    }

    // ---------- key handling ----------
    private fun handleKey(key: KeySpec, alt: String?) {
        if (alt != null) {
            if (key.kind == KeyKind.T9) {
                commitTopIfComposing()
                service.commitText(alt)
                refreshCandidates()
                return
            }
            if (key.kind == KeyKind.CHAR || key.kind == KeyKind.FUNC || key.kind == KeyKind.SIDEBAR) {
                commitTopIfComposing()
                service.commitText(alt)
                afterDirectCommit(alt)
                return
            }
        }
        when (key.id) {
            "shift" -> handleShift()
            "backspace" -> deleteOne()
            "space" -> handleSpace()
            "action" -> handleAction()
            "enter" -> {
                commitTopIfComposing()
                sendNewline()
            }
            "mode" -> toggleInputMode()
            "num" -> { numberMode = true; symbolMode = false; rebuildKeyboard(); refreshCandidates() }
            "symbol" -> { symbolMode = true; numberMode = false; rebuildKeyboard(); refreshCandidates() }
            "abc" -> { numberMode = false; symbolMode = false; rebuildKeyboard(); refreshCandidates() }
            "comma" -> commitPunctuation("，")
            "period" -> commitPunctuation("。")
            "retry" -> { composing = ""; refreshCandidates(); toast("已清空输入") }
            "keyboard" -> panels.showKeyboardSwitcher()
            "t9_1" -> { symbolMode = true; numberMode = false; rebuildKeyboard() }
            "t9_2", "t9_3", "t9_4", "t9_5", "t9_6", "t9_7", "t9_8", "t9_9" -> {
                appendComposition(key.id.substringAfter("t9_"))
            }
            "stroke_h", "stroke_s", "stroke_p", "stroke_n", "stroke_z", "stroke_any" -> {
                val code = when (key.id) {
                    "stroke_h" -> "h"; "stroke_s" -> "s"; "stroke_p" -> "p"
                    "stroke_n" -> "n"; "stroke_z" -> "z"; else -> "?"
                }
                appendComposition(code)
            }
            "stroke_clear" -> { composing = ""; refreshCandidates() }
            else -> {
                if (key.kind == KeyKind.SIDEBAR) {
                    commitPunctuation(key.label)
                    return
                }
                if (key.kind == KeyKind.FUNC && key.label.isNotEmpty() && key.id.length > 3 && key.id.startsWith("sym")) {
                    commitPunctuation(key.label)
                    return
                }
                if (key.kind == KeyKind.FUNC && key.label.isNotEmpty() && key.label.length <= 3) {
                    commitPunctuation(key.label)
                    return
                }
                if (key.label.length == 1 && key.label[0].isLetter()) {
                    appendLetter(key.label[0])
                } else if (key.label.isNotEmpty() && key.id.startsWith("num")) {
                    commitTopIfComposing(); service.commitText(key.label); refreshCandidates()
                } else if (key.label.isNotEmpty() && key.id.startsWith("sym")) {
                    commitTopIfComposing(); service.commitText(key.label); refreshCandidates()
                }
            }
        }
    }

    private fun handleShift() {
        if (inputMode == "zh") {
            inputMode = "en"
            Prefs.putString(Prefs.K_INPUT_MODE, "en")
            shift = true; caps = false
            composing = ""
            rebuildKeyboard(); refreshCandidates()
            toast("已切换到英文")
            return
        }
        val now = SystemClock.elapsedRealtime()
        if (now - lastShiftTime < 320) {
            caps = !caps
            shift = caps
        } else {
            shift = !shift
            if (caps) shift = true
        }
        lastShiftTime = now
        keyboardView.setShift(shift, caps)
        rebuildKeyboard()
    }

    private fun appendLetter(ch: Char) {
        if (numberMode || symbolMode) return
        lastSpaceTime = 0L
        if (inputMode == "en") {
            val c = if (caps || shift) ch.uppercaseChar() else ch.lowercaseChar()
            composing += c
            if (shift && !caps) { shift = false; keyboardView.setShift(false, caps) }
        } else {
            if (kbType == "wubi") {
                if (composing.length >= 4 && (Prefs.getBool(Prefs.K_WUBI_FIFTH) || Prefs.getBool(Prefs.K_WUBI_UNIQUE))) {
                    val first = candidates.firstOrNull()
                    if (first != null) {
                        commitCandidate(first)
                        composing = ch.lowercaseChar().toString()
                        refreshCandidates()
                        return
                    }
                }
            }
            composing += ch.lowercaseChar()
        }
        refreshCandidates()
        if (kbType == "wubi" && inputMode == "zh" && composing.length == 4 && Prefs.getBool(Prefs.K_WUBI_UNIQUE)) {
            val exact = WubiData.lookup(composing).filter { it.first == composing }
            if (exact.size == 1) {
                commitCandidate(ImeCandidate(exact[0].second, exact[0].second, "wubi", composing))
            }
        }
    }

    private fun appendComposition(s: String) {
        if (inputMode != "zh") {
            if (s.length == 1 && s[0].isLetter()) appendLetter(s[0])
            return
        }
        lastSpaceTime = 0L
        composing += s
        refreshCandidates()
    }

    private fun deleteOne() {
        if (composing.isNotEmpty()) {
            composing = composing.dropLast(1)
            refreshCandidates()
            return
        }
        if (kbType == "handwriting" && !numberMode && !symbolMode) {
            handwritingPad.undo()
            return
        }
        val before = service.textBeforeCursor(4)
        service.deleteBackward(1)
        if (before.isNotEmpty()) {
            val cp = before.codePointBefore(before.length)
            val count = Character.charCount(cp)
            val s = before.substring(before.length - count)
            undoStack.addLast(s)
            while (undoStack.size > 60) undoStack.removeFirst()
        }
        lastSpaceTime = 0L
    }

    private fun handleSpace() {
        val now = SystemClock.elapsedRealtime()
        if (composing.isNotEmpty()) {
            val first = candidates.firstOrNull()
            if (first != null && first.kind != "clipboard") {
                commitCandidate(first, addSpace = inputMode == "en")
            } else {
                val raw = composing
                composing = ""
                service.commitText(raw)
                if (inputMode == "en") service.commitText(" ")
                afterDirectCommit(raw)
            }
            lastSpaceTime = 0L
            return
        }
        if (inputMode == "en" && Prefs.getBool(Prefs.K_QUICK_DOUBLE_SPACE) && now - lastSpaceTime in 1..520) {
            service.replaceBeforeCursor(1, ". ")
            lastSpaceTime = 0L
            sentenceStart = true
            shift = Prefs.getBool(Prefs.K_QUICK_CAPITALIZE)
            keyboardView.setShift(shift, caps)
            return
        }
        service.commitText(" ")
        lastSpaceTime = now
    }

    private fun handleAction() {
        commitTopIfComposing()
        service.performEditorAction()
        composing = ""
        refreshCandidates()
    }

    private fun sendNewline() {
        service.sendDownUpKeyEvents(KeyEvent.KEYCODE_ENTER)
        sentenceStart = true
        lastSpaceTime = 0L
    }

    private fun commitPunctuation(p: String) {
        commitTopIfComposing()
        service.commitText(p)
        afterDirectCommit(p)
    }

    private fun commitTopIfComposing() {
        if (composing.isEmpty()) return
        val first = candidates.firstOrNull()
        if (first != null && first.kind != "clipboard") {
            commitCandidate(first)
        } else {
            val raw = composing
            composing = ""
            service.commitText(raw)
            afterDirectCommit(raw)
            refreshCandidates()
        }
    }

    internal fun commitCandidate(c: ImeCandidate, addSpace: Boolean = false) {
        if (c.kind == "clipboard") {
            service.commitText(c.payload.ifBlank { c.text })
            composing = ""
            refreshCandidates()
            return
        }
        service.commitText(c.text, addSpace)
        if (c.kind == "pinyin" || c.kind == "wubi" || c.kind == "english") {
            Prefs.learnWord(c.text)
        }
        lastCommitted = c.text
        composing = ""
        sentenceStart = c.text.lastOrNull() in listOf('。', '！', '？', '.', '!', '?', '\n')
        if (inputMode == "en") {
            shift = Prefs.getBool(Prefs.K_QUICK_CAPITALIZE) && sentenceStart
            keyboardView.setShift(shift, caps)
        }
        refreshCandidates()
    }

    internal fun insertText(text: String) {
        if (text.isEmpty()) return
        commitTopIfComposing()
        service.commitText(text)
        afterDirectCommit(text)
    }

    private fun afterDirectCommit(text: String) {
        lastCommitted = text
        sentenceStart = text.lastOrNull() in listOf('。', '！', '？', '.', '!', '?', '\n')
        if (inputMode == "en") {
            shift = Prefs.getBool(Prefs.K_QUICK_CAPITALIZE) && sentenceStart
            keyboardView.setShift(shift, caps)
        }
        refreshCandidates()
    }

    // ---------- candidates ----------
    internal fun refreshCandidates(resetScroll: Boolean = true) {
        val list = mutableListOf<ImeCandidate>()
        val mru = Prefs.mru()
        val lexicon: List<LexiconEntry> = LexiconRepo.all()
        val blacklist = Prefs.blacklist()
        val fuzzyInitials = if (Prefs.fuzzyEnabled) Prefs.getStringSet(Prefs.K_FUZZY_INITIALS, defaultInitials) else emptySet()
        val fuzzyFinals = if (Prefs.fuzzyEnabled) Prefs.getStringSet(Prefs.K_FUZZY_FINALS, defaultFinals) else emptySet()
        val fuzzySyllables = if (Prefs.fuzzyEnabled) Prefs.getStringSet(Prefs.K_FUZZY_SYLLABLES, defaultSyllables) else emptySet()

        if (numberMode || symbolMode) {
            candidates = list
            renderCandidates(resetScroll)
            return
        }
        if (kbType == "handwriting" && composing.isEmpty()) {
            list.addAll(handwritingResults)
        } else if (kbType == "stroke") {
            if (composing.isNotEmpty()) {
                StrokeData.lookup(composing).forEachIndexed { i, ch ->
                    list.add(ImeCandidate(ch, ch, "stroke", composing, 1000 - i))
                }
            }
        } else if (composing.isNotEmpty()) {
            when {
                inputMode == "en" -> {
                    PinyinEngine.englishSuggestions(composing, mru, 10).forEach { w ->
                        list.add(ImeCandidate(w, w, "english", "", 0))
                    }
                    if (list.none { it.text.equals(composing, ignoreCase = true) }) {
                        list.add(ImeCandidate(composing, "$composing  ", "english", "", 0))
                    }
                }
                kbType == "pinyin9" -> {
                    PinyinEngine.candidates(
                        composing, true, 45, fuzzyInitials, fuzzyFinals, fuzzySyllables,
                        mru, lexicon, blacklist
                    ).forEach { c ->
                        list.add(ImeCandidate(c.text, c.text, "pinyin", c.pinyin, c.freq))
                    }
                }
                kbType == "wubi" -> {
                    WubiData.lookup(composing, 30).forEach { (code, ch) ->
                        list.add(ImeCandidate(ch, ch, "wubi", code, 500))
                    }
                    if (Prefs.getBool(Prefs.K_WUBI_MIX)) {
                        PinyinEngine.candidates(
                            composing, false, 12, fuzzyInitials, fuzzyFinals, fuzzySyllables,
                            mru, lexicon, blacklist
                        ).forEach { c -> list.add(ImeCandidate(c.text, c.text, "pinyin", c.pinyin, c.freq)) }
                    }
                }
                kbType == "shuangpin" -> {
                    val scheme = Prefs.getString(Prefs.K_DOUBLE_PINYIN, "xiaohe")
                    val full = PinyinEngine.shuangpinToPinyin(composing, scheme)
                    PinyinEngine.candidates(
                        full, false, 45, fuzzyInitials, fuzzyFinals, fuzzySyllables,
                        mru, lexicon, blacklist
                    ).forEach { c -> list.add(ImeCandidate(c.text, c.text, "pinyin", c.pinyin, c.freq)) }
                }
                else -> {
                    PinyinEngine.candidates(
                        composing, false, 60, fuzzyInitials, fuzzyFinals, fuzzySyllables,
                        mru, lexicon, blacklist
                    ).forEach { c -> list.add(ImeCandidate(c.text, c.text, "pinyin", c.pinyin, c.freq)) }
                }
            }
        } else {
            // idle state: associations and prediction candidates
            if (Prefs.associationEnabled && lastCommitted.isNotBlank()) {
                PinyinEngine.associations(lastCommitted, 6).forEach { w ->
                    list.add(ImeCandidate(w, w, "assoc", "", 0))
                }
            }
            if (Prefs.getBool(Prefs.K_PRED_EMOJI)) {
                val emoji = emojiFor(lastCommitted)
                if (emoji != null) list.add(ImeCandidate(emoji, emoji, "emoji"))
            }
            if (Prefs.getBool(Prefs.K_PRED_KAOMOJI) && lastCommitted.isNotBlank()) {
                val groups = EmojiData.kaomoji
                val items = groups[Math.abs(lastCommitted.hashCode()) % groups.size].second
                list.add(ImeCandidate(items[0], items[0], "kaomoji"))
            }
            if (Prefs.getBool(Prefs.K_PRED_IMAGE) && lastCommitted.isNotBlank()) {
                list.add(ImeCandidate("[表情]", "🖼 表情", "image", payload = "[表情]"))
            }
        }

        if (composing.isEmpty() && !numberMode && !symbolMode && Prefs.clipboardCandidate) {
            val clip = service.clipboardText().trim()
            if (clip.isNotEmpty() && clip.length <= 5000 && !isPasswordField()) {
                list.add(
                    ImeCandidate(
                        clip,
                        "📋 " + clip.replace("\n", " ").take(14),
                        "clipboard",
                        payload = clip
                    )
                )
            }
        }
        val seen = HashSet<String>()
        candidates = list.filter { seen.add(it.kind + "\u0001" + it.text) }.take(80).toMutableList()
        renderCandidates(resetScroll)
    }

    private fun isPasswordField(): Boolean {
        val cls = editorInfo?.inputType?.and(InputType.TYPE_MASK_CLASS) ?: return false
        val variation = editorInfo?.inputType?.and(InputType.TYPE_MASK_VARIATION) ?: 0
        return cls == InputType.TYPE_CLASS_TEXT && (variation == InputType.TYPE_TEXT_VARIATION_PASSWORD ||
            variation == InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD ||
            variation == InputType.TYPE_TEXT_VARIATION_WEB_PASSWORD)
    }

    private fun emojiFor(text: String): String? {
        if (text.isBlank()) return "😊"
        return when {
            text.contains("谢谢") || text.contains("感谢") -> "🙏"
            text.contains("开心") || text.contains("好") -> "😄"
            text.contains("爱") || text.contains("喜欢") -> "❤️"
            text.contains("哈") -> "😂"
            text.contains("加油") -> "💪"
            text.contains("恭喜") -> "🎉"
            text.contains("累") -> "😮‍💨"
            text.contains("吃") -> "🍜"
            text.contains("晚安") -> "🌙"
            text.contains("生日") -> "🎂"
            else -> "👍"
        }
    }

    private fun renderCandidates(resetScroll: Boolean) {
        candidateRow.removeAllViews()
        if (candidates.isEmpty()) {
            val hint = when {
                numberMode || symbolMode -> "数字与符号直接上屏"
                kbType == "handwriting" -> "在此处手写，停顿后识别"
                composing.isNotEmpty() -> "无匹配候选，空格可直接上屏"
                else -> "候选会显示在这里 · 长按空格说话"
            }
            val tv = textView(context, hint, 12f, if (isDark) Color.parseColor("#8A8F98") else Color.parseColor("#9AA0A8"), false)
            tv.setPadding(dp(10f), 0, dp(10f), 0)
            candidateRow.addView(tv, LinearLayout.LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.MATCH_PARENT))
        } else {
            candidates.forEach { c ->
                val size = Prefs.candidateFontSize.toFloat().coerceIn(14f, 30f)
                val tv = TextView(context).apply {
                    text = c.label
                    textSize = if (c.kind == "emoji" || c.kind == "kaomoji") size + 2 else size
                    setTextColor(if (c.kind == "assoc" && isDark) Color.parseColor("#D8DCE3") else theme.text)
                    gravity = Gravity.CENTER
                    setPadding(dp(9f), 0, dp(9f), 0)
                    isSingleLine = true
                    maxLines = 1
                    background = rippleBackground(Color.TRANSPARENT, colorWithAlpha(theme.action, 55), dp(7f).toFloat())
                    setOnClickListener { commitCandidate(c) }
                    setOnLongClickListener { panels.showCandidateDetail(c); true }
                    if (c.kind == "clipboard" || c.kind == "assoc") {
                        setTextColor(if (isDark) Color.parseColor("#B9C4D8") else Color.parseColor("#4A5568"))
                        textSize = min(size, 15f)
                    }
                }
                candidateRow.addView(tv, LinearLayout.LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.MATCH_PARENT))
            }
        }
        if (resetScroll) candidateScroll.post { candidateScroll.scrollTo(0, 0) }
        updateComposeRow()
    }

    private fun updateComposeRow() {
        val location = Prefs.getString(Prefs.K_PINYIN_LOCATION, "top")
        val display = displayComposition()
        if (location == "hidden") {
            composeStrip.visibility = View.GONE
            composeChip.visibility = View.GONE
        } else if (location == "bottom") {
            composeStrip.visibility = View.GONE
            composeChip.visibility = View.VISIBLE
            composeChip.text = display.first
        } else {
            composeStrip.visibility = View.VISIBLE
            composeChip.visibility = View.GONE
            composeStrip.text = if (display.first.isBlank()) {
                "轻点输入 · 空格上屏 · 长按空格语音"
            } else display.first
            composeStrip.setTextColor(
                if (display.first.isBlank()) (if (isDark) Color.parseColor("#8A8F98") else Color.parseColor("#9AA0A8"))
                else theme.action
            )
        }
        composeStrip.visibility = if (location == "top") View.VISIBLE else View.GONE
    }

    internal fun displayComposition(): Pair<String, String> {
        if (kbType == "handwriting") return "手写" to "手写"
        if (kbType == "stroke") return if (composing.isEmpty()) "" to "" else "笔画  $composing" to composing
        if (kbType == "wubi") {
            val hint = candidates.firstOrNull { it.kind == "wubi" }?.pinyin ?: ""
            val base = if (composing.isEmpty()) "" else "五笔  $composing${if (hint.isNotBlank()) "  $hint" else ""}"
            return base to (if (composing.isEmpty()) "" else composing)
        }
        if (kbType == "shuangpin") {
            val scheme = Prefs.getString(Prefs.K_DOUBLE_PINYIN, "xiaohe")
            val full = if (composing.isEmpty()) "" else PinyinEngine.shuangpinToPinyin(composing, scheme)
            return if (composing.isEmpty()) "" to "" else "双拼  $composing → $full" to composing
        }
        if (kbType == "pinyin9") return if (composing.isEmpty()) "" to "" else "拼音  $composing" to composing
        if (inputMode == "en") return if (composing.isEmpty()) "" to "" else "英文  $composing" to composing
        return if (composing.isEmpty()) "" to "" else "拼音  ${PinyinEngine.prettyPinyin(composing)}" to composing
    }

    private fun showCompositionDetail() {
        if (composing.isEmpty()) { toast("暂无拼音，直接输入即可"); return }
        panels.showCompositionDetail()
    }

    // ---------- modes / toggles ----------
    internal fun toggleInputMode() {
        inputMode = if (inputMode == "zh") "en" else "zh"
        Prefs.putString(Prefs.K_INPUT_MODE, inputMode)
        composing = ""
        shift = false; caps = false
        if (inputMode == "en" && kbType == "pinyin9") {
            kbType = "pinyin26"
            Prefs.putString(Prefs.K_KEYBOARD_TYPE, "pinyin26")
        }
        keyboardView.setShift(false, false)
        rebuildKeyboard()
        refreshCandidates()
    }

    internal fun setKeyboardType(type: String) {
        kbType = type
        Prefs.putString(Prefs.K_KEYBOARD_TYPE, type)
        Prefs.putBool(Prefs.K_KEYBOARD_TYPE_CHOSEN, true)
        numberMode = false; symbolMode = false; composing = ""; handwritingResults.clear()
        rebuildKeyboard(); refreshCandidates()
        if (type == "handwriting") handwritingPad.clear()
    }

    internal fun cycleOneHand() {
        oneHand = when (oneHand) {
            "off" -> "left"; "left" -> "right"; else -> "off"
        }
        Prefs.putString(Prefs.K_ONE_HAND, oneHand)
        applySettings()
        toast(
            when (oneHand) {
                "left" -> "左手模式"
                "right" -> "右手模式"
                else -> "已关闭单手模式"
            }
        )
    }

    internal fun toggleFloating() {
        floating = !floating
        Prefs.putBool(Prefs.K_FLOATING, floating)
        applySettings()
        toast(if (floating) "悬浮键盘已开启，拖动 ⠿ 移动" else "已恢复标准键盘")
    }

    private fun toggleTraditional() {
        val selected = service.selectedText()
        if (selected.isNotBlank()) {
            val converted = if (Regex("[\\u4E00-\\u9FFF]").containsMatchIn(selected)) {
                val trad = TradData.toTraditional(selected)
                if (trad != selected) trad else TradData.toSimplified(selected)
            } else selected
            service.replaceSelection(converted)
            toast("已转换选中文字")
            return
        }
        val enabled = !Prefs.getBool(Prefs.K_TRAD_OUTPUT)
        Prefs.putBool(Prefs.K_TRAD_OUTPUT, enabled)
        toast(if (enabled) "繁体输出已开启" else "简体输出已开启")
    }

    private fun undoLast() {
        if (undoStack.isEmpty()) { toast("暂无可撤销的删除"); return }
        val text = undoStack.removeLast()
        service.commitText(text)
        toast("已恢复")
    }

    // ---------- panels ----------
    internal fun showPanel(view: View) {
        panelOverlay.removeAllViews()
        panelOverlay.addView(view, FrameLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
        panelOverlay.visibility = View.VISIBLE
        mainColumn.visibility = View.GONE
        currentPanelOpen = true
    }

    internal fun closePanel() {
        panelOverlay.removeAllViews()
        panelOverlay.visibility = View.GONE
        mainColumn.visibility = View.VISIBLE
        currentPanelOpen = false
        refreshCandidates()
    }

    internal fun hidePanel() {
        if (currentPanelOpen) closePanel()
    }

    internal fun toast(msg: String) = toast(context, msg)

    internal fun copyToClipboard(text: String) {
        service.copyToClipboard(text)
        ClipboardRepo.add(text)
        toast("已复制")
    }

    internal fun openSettings(route: String? = null) = service.openSettings(route)

    internal fun currentCandidates(): List<ImeCandidate> = candidates.toList()

    internal fun currentComposition(): String = composing

    internal fun setComposition(value: String) {
        composing = value
        refreshCandidates()
    }

    internal fun selectedText(): String = service.selectedText()

    internal fun inputOrSelection(): String {
        val sel = service.selectedText()
        if (sel.isNotBlank()) return sel
        if (composing.isNotBlank()) return composing
        val before = service.textBeforeCursor(500)
        return before
    }

    internal fun commitTopCandidateIfAny(): Boolean {
        val first = candidates.firstOrNull() ?: return false
        commitCandidate(first)
        return true
    }

    internal fun getEditorInfo(): EditorInfo? = editorInfo

    internal fun insidePasswordField(): Boolean = isPasswordField()

    internal fun openTextInput(
        title: String,
        hint: String,
        initial: String,
        multiline: Boolean,
        extraHint: String? = null,
        extraInitial: String = "",
        onResult: (String, String) -> Unit
    ) {
        val code = UUID.randomUUID().toString()
        textCallbacks[code] = onResult
        try {
            service.startActivity(
                android.content.Intent(service, TextInputActivity::class.java)
                    .addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                    .putExtra(TextInputActivity.EXTRA_TITLE, title)
                    .putExtra(TextInputActivity.EXTRA_HINT, hint)
                    .putExtra(TextInputActivity.EXTRA_INITIAL, initial)
                    .putExtra(TextInputActivity.EXTRA_MULTILINE, multiline)
                    .putExtra(TextInputActivity.EXTRA_EXTRA_HINT, extraHint)
                    .putExtra(TextInputActivity.EXTRA_EXTRA_INITIAL, extraInitial)
                    .putExtra(TextInputActivity.EXTRA_CODE, code)
            )
        } catch (t: Throwable) {
            textCallbacks.remove(code)
            toast("无法打开输入页面")
        }
    }

    fun onTextInputResult(code: String, text: String, extra: String) {
        textCallbacks.remove(code)?.invoke(text, extra)
    }

    // ---------- voice ----------
    internal fun startVoice() {
        if (!Prefs.smartMode) {
            toast("基础输入模式已关闭语音与 AI，请在设置中切换为智能输入模式")
            return
        }
        if (!service.hasMicPermission()) {
            toast("请授予麦克风权限")
            service.requestMicPermission()
            return
        }
        voice.start()
    }

    fun onMicPermissionGranted() {
        toast("麦克风权限已授予，请再次点击语音")
    }

    fun onMicPermissionDenied() {
        toast("麦克风权限被拒绝，可在系统设置中开启")
    }

    // ---------- expose for panels ----------
    internal fun engineStats(): String {
        val count = PinyinEngine.entryCount
        return if (count > 0) "本地词库 $count 条 · 加载 ${PinyinEngine.loadMillis} ms" else "本地词库加载中…"
    }

    internal fun currentTheme(): KeyboardTheme = theme

    internal fun currentPanelColors(): PanelColors = panelColors

    internal fun toggleTradForSelection(): String? {
        val sel = service.selectedText()
        if (sel.isBlank()) return null
        return TradData.toTraditional(sel)
    }

    internal fun setVoiceLayer(view: View) {
        voiceLayer?.let { removeView(it) }
        voiceLayer = FrameLayout(context).apply {
            addView(view, FrameLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
            setBackgroundColor(Color.parseColor("#66000000"))
        }
        addView(voiceLayer, FrameLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
    }

    internal fun removeVoiceLayer() {
        voiceLayer?.let { removeView(it) }
        voiceLayer = null
    }

    companion object {
        val defaultInitials = setOf("z/zh", "c/ch", "s/sh", "n/l", "f/h", "r/l")
        val defaultFinals = setOf("an/ang", "en/eng", "in/ing", "ian/iang", "uan/uang", "un/ong", "eng/ong")
        val defaultSyllables = setOf("hui/fei", "huang/wang")
    }
}
