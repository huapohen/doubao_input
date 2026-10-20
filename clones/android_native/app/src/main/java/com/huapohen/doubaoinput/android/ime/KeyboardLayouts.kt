package com.huapohen.doubaoinput.android.ime

enum class KeyKind { CHAR, T9, FUNC, SHIFT, BACKSPACE, SPACE, ACTION, MODE, PLACEHOLDER, SIDEBAR }

data class KeySpec(
    val id: String,
    val label: String,
    val subLabel: String = "",
    val kind: KeyKind = KeyKind.CHAR,
    val weight: Float = 1f,
    val alt: String? = null,
    val altLabel: String = ""
)

data class KeyRow(val keys: List<KeySpec>, val heightWeight: Float = 1f)
data class KeyboardLayout(val rows: List<KeyRow>, val kind: String)

object KeyboardLayouts {
    private val qwertyLetters = listOf(
        listOf("q" to "1", "w" to "2", "e" to "3", "r" to "4", "t" to "5", "y" to "6", "u" to "7", "i" to "8", "o" to "9", "p" to "0"),
        listOf("a" to "-", "s" to "/", "d" to "：", "f" to "；", "g" to "（", "h" to "）", "j" to "～", "k" to "“", "l" to "”"),
        listOf("z" to "@", "x" to ".", "c" to "#", "v" to "、", "b" to "？", "n" to "！", "m" to "，")
    )

    fun qwerty(
        chinese: Boolean,
        actionLabel: String,
        modeLabel: String,
        separateSymbols: Boolean = false,
        separateCommaPeriod: Boolean = false,
        modeOnLeft: Boolean = false
    ): KeyboardLayout {
        val rows = mutableListOf<KeyRow>()
        rows.add(KeyRow(qwertyLetters[0].map { (c, alt) ->
            KeySpec(c, c.uppercase(), "", KeyKind.CHAR, 1f, alt, alt)
        }))
        rows.add(KeyRow(qwertyLetters[1].map { (c, alt) ->
            KeySpec(c, c.uppercase(), "", KeyKind.CHAR, 1f, alt, alt)
        }))
        val row3 = mutableListOf<KeySpec>()
        row3.add(KeySpec("shift", "", "", KeyKind.SHIFT, 1.35f))
        qwertyLetters[2].forEach { (c, alt) -> row3.add(KeySpec(c, c.uppercase(), "", KeyKind.CHAR, 1f, alt, alt)) }
        row3.add(KeySpec("backspace", "", "", KeyKind.BACKSPACE, 1.35f))
        rows.add(KeyRow(row3))
        val bottom = mutableListOf<KeySpec>()
        bottom.add(KeySpec("num", "123", "", KeyKind.FUNC, 1.3f))
        if (separateSymbols) bottom.add(KeySpec("symbol", "符", "", KeyKind.FUNC, 0.85f))
        if (modeOnLeft) bottom.add(KeySpec("mode", modeLabel, if (chinese) "英" else "中", KeyKind.MODE, 1.2f))
        bottom.add(KeySpec("comma", "，", if (separateCommaPeriod) "" else "。", KeyKind.FUNC, 0.9f, if (separateCommaPeriod) null else "。", "。"))
        if (separateCommaPeriod) bottom.add(KeySpec("period", "。", "", KeyKind.FUNC, 0.9f))
        bottom.add(KeySpec("space", "", chineseHint(chinese), KeyKind.SPACE, if (modeOnLeft) 3.6f else 4.0f))
        if (!modeOnLeft) bottom.add(KeySpec("mode", modeLabel, if (chinese) "英" else "中", KeyKind.MODE, 1.2f))
        bottom.add(KeySpec("action", actionLabel, "", KeyKind.ACTION, 1.55f))
        rows.add(KeyRow(bottom))
        return KeyboardLayout(rows, if (chinese) "pinyin26" else "english26")
    }

    private fun chineseHint(chinese: Boolean) = if (chinese) "按住说话" else ""

    fun numbers(actionLabel: String, modeLabel: String, chinese: Boolean): KeyboardLayout {
        val rows = mutableListOf<KeyRow>()
        rows.add(KeyRow("1234567890".map { KeySpec(it.toString(), it.toString(), "", KeyKind.FUNC, 1f) }))
        rows.add(KeyRow(listOf("@", "#", "￥", "%", "&", "*", "(", ")", "-", "+").map {
            KeySpec("sym$it", it, "", KeyKind.FUNC, 1f)
        }))
        rows.add(KeyRow(listOf("=", "\"", ":", ";", "!", "?", ",", ".", "/").map {
            KeySpec("sym$it", it, "", KeyKind.FUNC, 1f)
        } + KeySpec("backspace", "", "", KeyKind.BACKSPACE, 1.15f)))
        rows.add(KeyRow(listOf(
            KeySpec("symbol", "符号", "", KeyKind.FUNC, 1.3f),
            KeySpec("abc", "ABC", "", KeyKind.FUNC, 1.3f),
            KeySpec("comma", "，", "", KeyKind.FUNC, 0.9f),
            KeySpec("space", "", "", KeyKind.SPACE, 3.2f),
            KeySpec("mode", modeLabel, if (chinese) "英" else "中", KeyKind.MODE, 1.2f),
            KeySpec("action", actionLabel, "", KeyKind.ACTION, 1.5f)
        )))
        return KeyboardLayout(rows, "number")
    }

    fun symbols(actionLabel: String, modeLabel: String, chinese: Boolean): KeyboardLayout {
        val line1 = listOf("，", "。", "？", "！", "、", "；", "：", "“", "”", "‘", "’")
        val line2 = listOf("（", "）", "【", "】", "《", "》", "…", "—", "～", "·", "〈", "〉")
        val line3 = listOf("@", "#", "￥", "%", "&", "*", "+", "=", "/", "\\", "|", "<", ">")
        val rows = mutableListOf<KeyRow>()
        rows.add(KeyRow(line1.map { KeySpec("sym$it", it, "", KeyKind.FUNC, 1f) }))
        rows.add(KeyRow(line2.map { KeySpec("sym$it", it, "", KeyKind.FUNC, 1f) }))
        rows.add(KeyRow(line3.map { KeySpec("sym$it", it, "", KeyKind.FUNC, 1f) } + KeySpec("backspace", "", "", KeyKind.BACKSPACE, 1.1f)))
        rows.add(KeyRow(listOf(
            KeySpec("num", "123", "", KeyKind.FUNC, 1.2f),
            KeySpec("abc", "ABC", "", KeyKind.FUNC, 1.2f),
            KeySpec("comma", "，", "", KeyKind.FUNC, 0.8f),
            KeySpec("space", "", "", KeyKind.SPACE, 3.4f),
            KeySpec("mode", modeLabel, if (chinese) "英" else "中", KeyKind.MODE, 1.2f),
            KeySpec("action", actionLabel, "", KeyKind.ACTION, 1.5f)
        )))
        return KeyboardLayout(rows, "symbol")
    }

    fun t9(actionLabel: String, modeLabel: String, symbols: List<String> = listOf("，", "。", "？", "！")): KeyboardLayout {
        val syms = symbols.take(4).let { if (it.size == 4) it else listOf("，", "。", "？", "！") }
        fun sidebar(s: String) = KeySpec("punct$s", s, "", KeyKind.SIDEBAR, 0.62f)
        val rows = mutableListOf<KeyRow>()
        rows.add(KeyRow(listOf(
            sidebar(syms[0]), KeySpec("t9_1", "@#", "1", KeyKind.T9, 1f, "1", "1"),
            KeySpec("t9_2", "ABC", "2", KeyKind.T9, 1f, "2", "2"), KeySpec("t9_3", "DEF", "3", KeyKind.T9, 1f, "3", "3"),
            KeySpec("backspace", "", "", KeyKind.BACKSPACE, 0.95f)
        )))
        rows.add(KeyRow(listOf(
            sidebar(syms[1]), KeySpec("t9_4", "GHI", "4", KeyKind.T9, 1f, "4", "4"),
            KeySpec("t9_5", "JKL", "5", KeyKind.T9, 1f, "5", "5"), KeySpec("t9_6", "MNO", "6", KeyKind.T9, 1f, "6", "6"),
            KeySpec("retry", "重输", "", KeyKind.FUNC, 0.95f)
        )))
        rows.add(KeyRow(listOf(
            sidebar(syms[2]), KeySpec("t9_7", "PQRS", "7", KeyKind.T9, 1f, "7", "7"),
            KeySpec("t9_8", "TUV", "8", KeyKind.T9, 1f, "8", "8"), KeySpec("t9_9", "WXYZ", "9", KeyKind.T9, 1f, "9", "9"),
            KeySpec("action", actionLabel, "", KeyKind.ACTION, 0.95f)
        )))
        rows.add(KeyRow(listOf(
            sidebar(syms[3]), KeySpec("symbol", "符号", "", KeyKind.FUNC, 1f),
            KeySpec("num", "123", "", KeyKind.FUNC, 1f), KeySpec("space", "", "", KeyKind.SPACE, 1.9f),
            KeySpec("mode", modeLabel, "英", KeyKind.MODE, 1.05f),
            KeySpec("enter", "换行", "", KeyKind.FUNC, 0.95f)
        )))
        return KeyboardLayout(rows, "pinyin9")
    }

    fun stroke(actionLabel: String, modeLabel: String): KeyboardLayout {
        val rows = mutableListOf<KeyRow>()
        rows.add(KeyRow(listOf(
            KeySpec("stroke_h", "一", "横", KeyKind.CHAR, 1f),
            KeySpec("stroke_s", "丨", "竖", KeyKind.CHAR, 1f),
            KeySpec("stroke_p", "丿", "撇", KeyKind.CHAR, 1f),
            KeySpec("stroke_n", "丶", "捺", KeyKind.CHAR, 1f),
            KeySpec("stroke_z", "乛", "折", KeyKind.CHAR, 1f)
        )))
        rows.add(KeyRow(listOf(
            KeySpec("stroke_any", "？", "通配", KeyKind.CHAR, 1f),
            KeySpec("stroke_clear", "清空", "", KeyKind.FUNC, 1.1f),
            KeySpec("backspace", "", "", KeyKind.BACKSPACE, 1.1f),
            KeySpec("space", "", "", KeyKind.SPACE, 2.2f),
            KeySpec("action", actionLabel, "", KeyKind.ACTION, 1.3f)
        )))
        rows.add(KeyRow(listOf(
            KeySpec("keyboard", "键盘", "", KeyKind.FUNC, 1.2f),
            KeySpec("mode", modeLabel, "英", KeyKind.MODE, 1.1f),
            KeySpec("enter", "换行", "", KeyKind.FUNC, 1.1f)
        )))
        return KeyboardLayout(rows, "stroke")
    }
}
