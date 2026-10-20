package com.huapohen.doubaoinput.android.settings

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.text.InputType
import android.view.Gravity
import android.view.ViewGroup
import android.view.WindowManager
import android.view.inputmethod.EditorInfo
import android.widget.Button
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import com.huapohen.doubaoinput.android.ime.DoubaoImeService

/** Dialog-styled activity used by IME panels for free-text entry (the IME cannot edit its own views). */
class TextInputActivity : Activity() {
    companion object {
        const val EXTRA_TITLE = "title"
        const val EXTRA_HINT = "hint"
        const val EXTRA_INITIAL = "initial"
        const val EXTRA_MULTILINE = "multiline"
        const val EXTRA_EXTRA_HINT = "extra_hint"
        const val EXTRA_EXTRA_INITIAL = "extra_initial"
        const val EXTRA_CODE = "code"
    }

    private lateinit var input: EditText
    private lateinit var extraInput: EditText

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val title = intent.getStringExtra(EXTRA_TITLE) ?: "输入"
        val hint = intent.getStringExtra(EXTRA_HINT) ?: ""
        val initial = intent.getStringExtra(EXTRA_INITIAL) ?: ""
        val multiline = intent.getBooleanExtra(EXTRA_MULTILINE, false)
        val extraHint = intent.getStringExtra(EXTRA_EXTRA_HINT)
        val extraInitial = intent.getStringExtra(EXTRA_EXTRA_INITIAL) ?: ""

        val root = FrameLayout(this)
        root.setBackgroundColor(Color.parseColor("#73000000"))
        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(22), dp(20), dp(22), dp(16))
            background = GradientDrawable().apply {
                setColor(Color.WHITE)
                cornerRadius = dp(20).toFloat()
            }
            elevation = dp(12).toFloat()
        }
        val titleView = TextView(this).apply {
            text = title
            textSize = 19f
            setTextColor(Color.parseColor("#111111"))
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
        }
        card.addView(titleView)
        val hintView = TextView(this).apply {
            text = if (hint.isBlank()) "内容只会保存在本机" else hint
            textSize = 12.5f
            setTextColor(Color.parseColor("#7A8290"))
            setPadding(0, dp(4), 0, dp(12))
        }
        card.addView(hintView)

        input = EditText(this).apply {
            setText(initial)
            this.hint = hint
            textSize = 16f
            setTextColor(Color.parseColor("#111111"))
            setHintTextColor(Color.parseColor("#9AA0A8"))
            setPadding(dp(14), dp(12), dp(14), dp(12))
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#F2F4F7"))
                cornerRadius = dp(12).toFloat()
            }
            isSingleLine = !multiline
            if (multiline) {
                minLines = 4
                gravity = Gravity.TOP
                inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_MULTI_LINE
                imeOptions = EditorInfo.IME_FLAG_NO_ENTER_ACTION
            }
            setSelection(text?.length ?: 0)
        }
        card.addView(input, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, if (multiline) dp(150) else dp(50)))

        if (extraHint != null) {
            extraInput = EditText(this).apply {
                setText(extraInitial)
                this.hint = extraHint
                textSize = 15f
                setTextColor(Color.parseColor("#111111"))
                setHintTextColor(Color.parseColor("#9AA0A8"))
                setPadding(dp(14), dp(10), dp(14), dp(10))
                background = GradientDrawable().apply {
                    setColor(Color.parseColor("#F2F4F7"))
                    cornerRadius = dp(12).toFloat()
                }
                isSingleLine = true
            }
            card.addView(extraInput, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(48)).apply {
                topMargin = dp(10)
            })
        }

        val buttons = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.END or Gravity.CENTER_VERTICAL
            setPadding(0, dp(16), 0, 0)
        }
        val cancel = Button(this).apply {
            text = "取消"
            setTextColor(Color.parseColor("#5B6470"))
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#F2F4F7"))
                cornerRadius = dp(22).toFloat()
            }
            setOnClickListener { finish() }
        }
        val save = Button(this).apply {
            text = "保存"
            setTextColor(Color.WHITE)
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#4F84FF"))
                cornerRadius = dp(22).toFloat()
            }
            setOnClickListener { submit() }
        }
        buttons.addView(cancel, LinearLayout.LayoutParams(dp(92), dp(44)).apply { rightMargin = dp(10) })
        buttons.addView(save, LinearLayout.LayoutParams(dp(100), dp(44)))
        card.addView(buttons)

        val lp = FrameLayout.LayoutParams(
            Math.min(resources.displayMetrics.widthPixels - dp(36), dp(560)),
            ViewGroup.LayoutParams.WRAP_CONTENT,
            Gravity.CENTER
        )
        root.addView(card, lp)
        setContentView(root)
        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_ALWAYS_VISIBLE or WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE)
        input.requestFocus()
        input.post { input.setSelection(input.text.length) }
    }

    private fun submit() {
        val value = input.text?.toString()?.trim().orEmpty()
        val extra = if (this::extraInput.isInitialized) extraInput.text?.toString()?.trim().orEmpty() else ""
        if (value.isEmpty()) {
            Toast.makeText(this, "请输入内容", Toast.LENGTH_SHORT).show()
            return
        }
        val code = intent.getStringExtra(EXTRA_CODE) ?: ""
        val action = Intent(this, DoubaoImeService::class.java)
            .setAction(DoubaoImeService.ACTION_TEXT_RESULT)
            .putExtra("code", code)
            .putExtra("text", value)
            .putExtra("extra", extra)
        try { startService(action) } catch (t: Throwable) { }
        finish()
    }

    private fun dp(v: Int): Int = (v * resources.displayMetrics.density + 0.5f).toInt()
}
