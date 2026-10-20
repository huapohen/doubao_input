package com.huapohen.doubaoinput.android.ime

import android.Manifest
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.inputmethodservice.InputMethodService
import android.os.Build
import android.os.SystemClock
import android.view.KeyEvent
import android.view.View
import android.view.ViewGroup
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.FrameLayout
import androidx.core.content.ContextCompat
import com.huapohen.doubaoinput.android.core.Prefs
import com.huapohen.doubaoinput.android.engine.PinyinEngine
import com.huapohen.doubaoinput.android.settings.PermissionProxyActivity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import android.graphics.drawable.ColorDrawable
import android.graphics.Color

class DoubaoImeService : InputMethodService() {
    companion object {
        const val ACTION_MIC_GRANTED = "com.huapohen.doubaoinput.android.MIC_GRANTED"
        const val ACTION_MIC_DENIED = "com.huapohen.doubaoinput.android.MIC_DENIED"
        const val ACTION_TEXT_RESULT = "com.huapohen.doubaoinput.android.TEXT_RESULT"
        const val EXTRA_ROUTE = "route"
    }

    val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var root: KeyboardRootView? = null
    var pendingVoiceAfterPermission = false
        private set

    override fun onCreate() {
        super.onCreate()
        Prefs.init(this)
        PinyinEngine.ensureLoaded(this)
    }

    override fun onCreateInputView(): View {
        val v = KeyboardRootView(this, this)
        root = v
        if (Prefs.floating) {
            window?.window?.setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
        }
        return v
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        root?.onEditorChanged(info)
    }

    override fun onStartInput(info: EditorInfo?, restarting: Boolean) {
        super.onStartInput(info, restarting)
        if (info != null) root?.onEditorChanged(info)
    }

    override fun onFinishInputView(finishingInput: Boolean) {
        root?.onInputFinished()
        super.onFinishInputView(finishingInput)
    }

    override fun onFinishInput() {
        root?.onInputFinished()
        super.onFinishInput()
    }

    override fun onEvaluateFullscreenMode(): Boolean = false

    override fun onUpdateSelection(
        oldSelStart: Int, oldSelEnd: Int, newSelStart: Int, newSelEnd: Int,
        candidatesStart: Int, candidatesEnd: Int
    ) {
        super.onUpdateSelection(oldSelStart, oldSelEnd, newSelStart, newSelEnd, candidatesStart, candidatesEnd)
        root?.onSelectionChanged()
    }

    override fun onWindowShown() {
        super.onWindowShown()
        root?.onWindowShown()
    }

    override fun onWindowHidden() {
        root?.onWindowHidden()
        super.onWindowHidden()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_MIC_GRANTED -> {
                val pending = pendingVoiceAfterPermission
                pendingVoiceAfterPermission = false
                if (pending) root?.onMicPermissionGranted()
            }
            ACTION_MIC_DENIED -> {
                pendingVoiceAfterPermission = false
                root?.onMicPermissionDenied()
            }
            ACTION_TEXT_RESULT -> {
                root?.onTextInputResult(
                    intent.getStringExtra("code").orEmpty(),
                    intent.getStringExtra("text").orEmpty(),
                    intent.getStringExtra("extra").orEmpty()
                )
            }
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        root?.destroy()
        root = null
        scope.cancel()
        super.onDestroy()
    }

    // ---------- Input editing ----------
    fun ic() = currentInputConnection

    fun commitText(text: String, addSpace: Boolean = false) {
        if (text.isEmpty()) return
        var value = text
        if (Prefs.getBool(Prefs.K_TRAD_OUTPUT) && Regex("[\\u4e00-\\u9fff]").containsMatchIn(value)) {
            value = com.huapohen.doubaoinput.android.engine.TradData.toTraditional(value)
        }
        if (Prefs.getBool(Prefs.K_QUICK_SPACE)) {
            val before = ic()?.getTextBeforeCursor(1, 0)?.toString().orEmpty()
            if (before.isNotEmpty() && value.isNotEmpty()) {
                val last = before.last(); val first = value.first()
                val lastCjk = isCjk(last); val firstCjk = isCjk(first)
                val lastLatin = last.isLetterOrDigit() && !lastCjk
                val firstLatin = first.isLetterOrDigit() && !firstCjk
                if ((lastCjk && firstLatin) || (lastLatin && firstCjk)) {
                    value = " $value"
                }
            }
        }
        ic()?.commitText(value, 1)
        if (addSpace) ic()?.commitText(" ", 1)
    }

    private fun isCjk(c: Char): Boolean = c.code in 0x4E00..0x9FFF || c.code in 0x3400..0x4DBF

    fun deleteBackward(count: Int = 1) {
        if (count <= 0) return
        val connection = ic() ?: return
        connection.deleteSurroundingTextInCodePoints(count, 0)
    }

    fun textBeforeCursor(max: Int): String = ic()?.getTextBeforeCursor(max, 0)?.toString().orEmpty()

    fun selectedText(): String {
        val connection = ic() ?: return ""
        return connection.getSelectedText(0)?.toString().orEmpty()
    }

    fun replaceSelection(text: String) {
        val connection = ic() ?: return
        val selected = connection.getSelectedText(0)?.toString().orEmpty()
        if (selected.isNotEmpty()) {
            connection.commitText(text, 1)
        } else {
            connection.commitText(text, 1)
        }
    }

    fun replaceBeforeCursor(chars: Int, text: String) {
        val connection = ic() ?: return
        connection.deleteSurroundingTextInCodePoints(chars, 0)
        connection.commitText(text, 1)
    }

    fun performEditorAction() {
        val info = currentInputEditorInfo ?: return
        val connection = ic() ?: return
        val action = info.imeOptions and EditorInfo.IME_MASK_ACTION
        if (Prefs.enterSend) {
            connection.performEditorAction(if (action == EditorInfo.IME_ACTION_NONE) EditorInfo.IME_ACTION_SEND else action)
            return
        }
        when (action) {
            EditorInfo.IME_ACTION_SEARCH, EditorInfo.IME_ACTION_SEND, EditorInfo.IME_ACTION_GO,
            EditorInfo.IME_ACTION_DONE, EditorInfo.IME_ACTION_NEXT, EditorInfo.IME_ACTION_PREVIOUS ->
                connection.performEditorAction(action)
            else -> {
                val inputType = info.inputType and android.text.InputType.TYPE_MASK_CLASS
                val multiline = (info.inputType and android.text.InputType.TYPE_TEXT_FLAG_MULTI_LINE) != 0
                if (multiline || inputType == android.text.InputType.TYPE_CLASS_TEXT) {
                    sendDownUpKeyEvents(KeyEvent.KEYCODE_ENTER)
                } else {
                    connection.performEditorAction(EditorInfo.IME_ACTION_DONE)
                }
            }
        }
    }

    fun actionLabel(): String {
        val info = currentInputEditorInfo
        if (Prefs.enterSend) return "发送"
        val action = info?.imeOptions?.and(EditorInfo.IME_MASK_ACTION) ?: EditorInfo.IME_ACTION_NONE
        return when (action) {
            EditorInfo.IME_ACTION_SEARCH -> "搜索"
            EditorInfo.IME_ACTION_SEND -> "发送"
            EditorInfo.IME_ACTION_GO -> "前往"
            EditorInfo.IME_ACTION_DONE -> "完成"
            EditorInfo.IME_ACTION_NEXT -> "下一项"
            EditorInfo.IME_ACTION_PREVIOUS -> "上一项"
            else -> {
                val multiline = info?.inputType?.and(android.text.InputType.TYPE_TEXT_FLAG_MULTI_LINE) != 0
                if (multiline) "换行" else "完成"
            }
        }
    }

    fun hideKeyboard() {
        requestHideSelf(0)
    }

    fun showImePicker() {
        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
        if (Build.VERSION.SDK_INT >= 28) imm.showInputMethodPicker()
        else imm.showInputMethodPicker()
    }

    fun clipboardText(): String {
        val cm = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = cm.primaryClip ?: return ""
        if (clip.itemCount == 0) return ""
        return clip.getItemAt(0).coerceToText(this).toString()
    }

    fun copyToClipboard(text: String) {
        val cm = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        cm.setPrimaryClip(ClipData.newPlainText("豆包输入法", text))
    }

    fun openSettings(route: String? = null) {
        val intent = Intent(this, com.huapohen.doubaoinput.android.settings.MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        if (route != null) intent.putExtra(EXTRA_ROUTE, route)
        try { startActivity(intent) } catch (t: Throwable) { toast(this, "无法打开设置") }
    }

    fun hasMicPermission(): Boolean =
        ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED

    fun requestMicPermission() {
        pendingVoiceAfterPermission = true
        try {
            startActivity(Intent(this, PermissionProxyActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_ANIMATION))
        } catch (t: Throwable) {
            pendingVoiceAfterPermission = false
            toast(this, "无法请求麦克风权限，请到系统设置开启")
        }
    }

    fun feedback(strong: Boolean = false) {
        val ctx = this
        try {
            if (Prefs.keyVibrate) {
                val level = Prefs.getInt(Prefs.K_KEY_VIBRATE_LEVEL, 1)
                val vibrator = if (Build.VERSION.SDK_INT >= 31) {
                    val vm = getSystemService(android.os.VibratorManager::class.java)
                    vm?.defaultVibrator
                } else {
                    @Suppress("DEPRECATION")
                    getSystemService(Context.VIBRATOR_SERVICE) as? android.os.Vibrator
                }
                val ms = when (level) { 0 -> 8L; 1 -> 15L; else -> 25L }
                val amp = when (level) { 0 -> 60; 1 -> 130; else -> 220 }
                if (vibrator?.hasVibrator() == true) {
                    if (Build.VERSION.SDK_INT >= 26) {
                        vibrator.vibrate(android.os.VibrationEffect.createOneShot(ms, amp))
                    } else {
                        @Suppress("DEPRECATION")
                        vibrator.vibrate(ms)
                    }
                }
            }
            if (Prefs.keySound) {
                val am = getSystemService(Context.AUDIO_SERVICE) as android.media.AudioManager
                val vol = Prefs.getInt(Prefs.K_KEY_SOUND_VOLUME, 60) / 100f
                am.playSoundEffect(android.media.AudioManager.FX_KEYPRESS_STANDARD, vol)
            }
        } catch (t: Throwable) { /* feedback must never crash typing */ }
    }

    fun deviceDid() = Prefs.did
}
