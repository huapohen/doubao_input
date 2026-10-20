package com.huapohen.doubaoinput.android.ime

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.text.InputType
import android.text.TextUtils
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.SeekBar
import android.widget.TextView
import androidx.recyclerview.widget.ItemTouchHelper
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.huapohen.doubaoinput.android.ai.AiClient
import com.huapohen.doubaoinput.android.core.ClipboardRepo
import com.huapohen.doubaoinput.android.core.ClipItem
import com.huapohen.doubaoinput.android.core.DeviceRepo
import com.huapohen.doubaoinput.android.core.FeedbackRepo
import com.huapohen.doubaoinput.android.core.LexiconRepo
import com.huapohen.doubaoinput.android.core.MessageRepo
import com.huapohen.doubaoinput.android.core.Phrase
import com.huapohen.doubaoinput.android.core.PhraseRepo
import com.huapohen.doubaoinput.android.core.Prefs
import com.huapohen.doubaoinput.android.core.ToolbarRepo
import com.huapohen.doubaoinput.android.engine.EmojiData
import com.huapohen.doubaoinput.android.engine.PrefsHelper
import com.huapohen.doubaoinput.android.engine.PinyinEngine
import com.huapohen.doubaoinput.android.engine.StrokeData
import com.huapohen.doubaoinput.android.engine.TradData
import com.huapohen.doubaoinput.android.engine.TranslateData
import com.huapohen.doubaoinput.android.engine.WubiData
import kotlinx.coroutines.launch
import java.util.Collections
import kotlin.math.abs

internal class KeyboardPanels(private val host: KeyboardRootView) {
    private val ctx: Context get() = host.context
    private val pal: PanelColors get() = host.panelColors
    private var tokenCounter = 0

    private fun dp(v: Int): Int = (v * ctx.resources.displayMetrics.density + 0.5f).toInt()
    private fun tone(light: Int, dark: Int): Int = if (pal.dark) dark else light

    // ---------------- shells ----------------
    private fun shell(title: String, subtitle: String? = null, scroll: Boolean = true): Pair<LinearLayout, LinearLayout> {
        tokenCounter++
        val root = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(pal.bg)
        }
        val header = LinearLayout(ctx).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(6), 0, dp(6), 0)
        }
        val back = TextView(ctx).apply {
            text = "‹"
            textSize = 28f
            gravity = Gravity.CENTER
            setTextColor(pal.text)
            background = rippleBackground(Color.TRANSPARENT, pal.pressed, dp(18).toFloat())
            setOnClickListener { host.closePanel() }
        }
        header.addView(back, LinearLayout.LayoutParams(dp(40), dp(44)))
        val titles = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(4), 0, 0, 0)
        }
        titles.addView(TextView(ctx).apply {
            text = title
            textSize = 17f
            setTextColor(pal.text)
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
        })
        if (!subtitle.isNullOrBlank()) {
            titles.addView(TextView(ctx).apply {
                text = subtitle
                textSize = 11.5f
                setTextColor(pal.secondary)
            })
        }
        header.addView(titles, LinearLayout.LayoutParams(0, dp(48), 1f))
        val close = TextView(ctx).apply {
            text = "✕"
            textSize = 18f
            gravity = Gravity.CENTER
            setTextColor(pal.secondary)
            background = rippleBackground(Color.TRANSPARENT, pal.pressed, dp(18).toFloat())
            setOnClickListener { host.closePanel() }
        }
        header.addView(close, LinearLayout.LayoutParams(dp(40), dp(44)))
        root.addView(header, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(48)))
        val divider = View(ctx).apply { setBackgroundColor(pal.divider) }
        root.addView(divider, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 1))

        val column = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(14), dp(8), dp(14), dp(10))
        }
        if (scroll) {
            val sv = ScrollView(ctx).apply {
                isFillViewport = true
                addView(column, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
            }
            root.addView(sv, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))
        } else {
            root.addView(column, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))
        }
        return root to column
    }

    private fun show(root: LinearLayout) { host.showPanel(root) }

    private fun dpF(v: Int): Float = dp(v).toFloat()

    private fun pill(text: String, primary: Boolean = false, onClick: () -> Unit): TextView =
        TextView(ctx).apply {
            this.text = text
            textSize = 13f
            gravity = Gravity.CENTER
            setTextColor(if (primary) Color.WHITE else pal.text)
            background = GradientDrawable().apply {
                setColor(if (primary) pal.primary else (if (pal.dark) Color.parseColor("#33343A") else Color.parseColor("#F0F2F5")))
                cornerRadius = dpF(20)
            }
            setPadding(dp(12), 0, dp(12), 0)
            setOnClickListener { onClick() }
        }

    private fun chip(text: String, active: Boolean, onClick: () -> Unit): TextView =
        TextView(ctx).apply {
            this.text = text
            textSize = 12.5f
            gravity = Gravity.CENTER
            setTextColor(if (active) Color.WHITE else pal.text)
            background = GradientDrawable().apply {
                setColor(if (active) pal.primary else (if (pal.dark) Color.parseColor("#2C2D31") else Color.parseColor("#FFFFFF")))
                cornerRadius = dpF(15)
                if (!active) setStroke(1, pal.divider)
            }
            setPadding(dp(10), 0, dp(10), 0)
            setOnClickListener { onClick() }
        }

    private fun sectionTitle(text: String): TextView =
        TextView(ctx).apply {
            this.text = text
            textSize = 12.5f
            setTextColor(pal.secondary)
            setPadding(dp(4), dp(12), 0, dp(6))
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
        }

    private fun card(padding: Int = 14): LinearLayout =
        LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(padding), dp(padding), dp(padding), dp(padding))
            background = GradientDrawable().apply {
                setColor(pal.card)
                cornerRadius = dpF(16)
            }
        }

    private fun listRow(
        title: String,
        subtitle: String = "",
        trailing: String = "›",
        onClick: () -> Unit,
        onLong: (() -> Unit)? = null
    ): LinearLayout {
        val row = LinearLayout(ctx).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(14), dp(11), dp(12), dp(11))
            background = rippleBackground(pal.card, pal.pressed, dpF(14))
            setOnClickListener { onClick() }
            if (onLong != null) setOnLongClickListener { onLong(); true }
        }
        val col = LinearLayout(ctx).apply { orientation = LinearLayout.VERTICAL }
        col.addView(TextView(ctx).apply {
            text = title
            textSize = 14.5f
            setTextColor(pal.text)
            maxLines = 2
            ellipsize = TextUtils.TruncateAt.END
        })
        if (subtitle.isNotBlank()) {
            col.addView(TextView(ctx).apply {
                text = subtitle
                textSize = 11.5f
                setTextColor(pal.secondary)
                maxLines = 1
                ellipsize = TextUtils.TruncateAt.END
                setPadding(0, dp(2), 0, 0)
            })
        }
        row.addView(col, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
        if (trailing.isNotBlank()) {
            row.addView(TextView(ctx).apply {
                text = trailing
                textSize = if (trailing == "›") 20f else 12f
                setTextColor(pal.secondary)
                setPadding(dp(8), 0, 0, 0)
            })
        }
        return row
    }

    private fun addCardRow(parent: LinearLayout, row: View, top: Int = 8) {
        parent.addView(row, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
            topMargin = dp(top)
        })
    }

    private fun actionRow(vararg buttons: TextView): LinearLayout {
        val row = LinearLayout(ctx).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(0, dp(6), 0, 0)
        }
        buttons.forEach { b ->
            row.addView(b, LinearLayout.LayoutParams(0, dp(40), 1f).apply {
                leftMargin = dp(3); rightMargin = dp(3)
            })
        }
        return row
    }

    private fun gridRows(items: List<*>, columns: Int, cell: (Any?) -> View, rowMargin: Int = 8): LinearLayout {
        val container = LinearLayout(ctx).apply { orientation = LinearLayout.VERTICAL }
        var i = 0
        while (i < items.size) {
            val row = LinearLayout(ctx).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER
            }
            for (c in 0 until columns) {
                val idx = i + c
                if (idx < items.size) {
                    val v = cell(items[idx])
                    row.addView(v, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
                        leftMargin = dp(4); rightMargin = dp(4)
                    })
                } else {
                    row.addView(View(ctx), LinearLayout.LayoutParams(0, 1, 1f).apply {
                        leftMargin = dp(4); rightMargin = dp(4)
                    })
                }
            }
            container.addView(row, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
                bottomMargin = dp(rowMargin)
            })
            i += columns
        }
        return container
    }

    // ---------------- toolbox ----------------
    fun showToolbox() {
        val (root, content) = shell("工具箱", "语音 · 表情 · 效率工具")
        val items = listOf(
            ToolItem("voice", "🎙", "语音输入"),
            ToolItem("emoji", "☺", "表情"),
            ToolItem("keyboard", "⌨", "键盘选择"),
            ToolItem("organize", "✦", "智能整理"),
            ToolItem("phrases", "💬", "常用语"),
            ToolItem("clipboard", "📋", "剪切板"),
            ToolItem("toolbar", "⊞", "定制工具栏"),
            ToolItem("handwrite", "✍", "手写找字"),
            ToolItem("translate", "文A", "翻译"),
            ToolItem("onehand", "◧", "单手"),
            ToolItem("adjust", "⇕", "键盘调节"),
            ToolItem("more", "⚙", "更多设置"),
            ToolItem("help", "?", "帮助与反馈"),
            ToolItem("floating", "◱", "悬浮键盘")
        )
        val pageHost = FrameLayout(ctx)
        val pages = (items.chunked(8)).map { chunk ->
            val page = LinearLayout(ctx).apply { orientation = LinearLayout.VERTICAL }
            var i = 0
            while (i < chunk.size) {
                val row = LinearLayout(ctx).apply {
                    orientation = LinearLayout.HORIZONTAL
                    gravity = Gravity.CENTER
                }
                for (c in 0 until 4) {
                    val idx = i + c
                    if (idx < chunk.size) {
                        row.addView(toolCard(chunk[idx]), LinearLayout.LayoutParams(0, dp(78), 1f).apply {
                            leftMargin = dp(4); rightMargin = dp(4)
                        })
                    } else {
                        row.addView(View(ctx), LinearLayout.LayoutParams(0, 1, 1f).apply {
                            leftMargin = dp(4); rightMargin = dp(4)
                        })
                    }
                }
                page.addView(row, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
                    bottomMargin = dp(8)
                })
                i += 4
            }
            page
        }
        pages.forEachIndexed { idx, p ->
            p.visibility = if (idx == 0) View.VISIBLE else View.GONE
            pageHost.addView(p, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        }
        content.addView(pageHost)
        val nav = LinearLayout(ctx).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(0, dp(8), 0, 0)
        }
        val prev = pill("‹", false) {}
        val dots = TextView(ctx).apply {
            text = "● ○"
            textSize = 10f
            setTextColor(pal.secondary)
            gravity = Gravity.CENTER
            setPadding(dp(14), 0, dp(14), 0)
        }
        val next = pill("›", false) {}
        var page = 0
        fun showPage(p: Int) {
            page = p.coerceIn(0, pages.size - 1)
            pages.forEachIndexed { idx, v -> v.visibility = if (idx == page) View.VISIBLE else View.GONE }
            dots.text = pages.indices.joinToString(" ") { if (it == page) "●" else "○" }
        }
        prev.setOnClickListener { showPage(page - 1) }
        next.setOnClickListener { showPage(page + 1) }
        nav.addView(prev, LinearLayout.LayoutParams(dp(54), dp(36)))
        nav.addView(dots)
        nav.addView(next, LinearLayout.LayoutParams(dp(54), dp(36)))
        content.addView(nav)
        content.addView(TextView(ctx).apply {
            text = host.engineStats()
            textSize = 10.5f
            setTextColor(pal.secondary)
            gravity = Gravity.CENTER
            setPadding(0, dp(8), 0, 0)
        })
        show(root)
    }

    private data class ToolItem(val id: String, val icon: String, val label: String)

    private fun toolCard(item: ToolItem): View {
        val v = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            background = rippleBackground(pal.card, pal.pressed, dpF(16))
            setOnClickListener {
                when (item.id) {
                    "voice" -> { host.closePanel(); host.startVoice() }
                    "emoji" -> showEmoji()
                    "keyboard" -> showKeyboardSwitcher()
                    "organize" -> showOrganize()
                    "phrases" -> showPhrases()
                    "clipboard" -> showClipboard()
                    "toolbar" -> showToolbarCustomize()
                    "handwrite" -> showHandwritingSearch()
                    "translate" -> showTranslate()
                    "onehand" -> showOneHand()
                    "adjust" -> showAdjust()
                    "more" -> { host.closePanel(); host.openSettings("home") }
                    "help" -> { host.closePanel(); host.openSettings("help") }
                    "floating" -> { host.closePanel(); host.toggleFloating() }
                }
            }
        }
        v.addView(TextView(ctx).apply {
            text = item.icon
            textSize = 22f
            gravity = Gravity.CENTER
            setTextColor(pal.text)
        }, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))
        v.addView(TextView(ctx).apply {
            text = item.label
            textSize = 11.5f
            gravity = Gravity.CENTER
            setTextColor(pal.text)
            setPadding(0, 0, 0, dp(8))
        })
        return v
    }

    // ---------------- keyboard switcher ----------------
    fun showKeyboardSwitcher(firstRun: Boolean = false) {
        val (root, content) = shell(
            "选择键盘",
            if (firstRun) "首次使用，请选择一种键盘；之后可在设置中修改" else "切换后立即生效"
        )
        val types = listOf(
            Triple("pinyin9", "9 键", "1 2 3 / ABC DEF"),
            Triple("pinyin26", "26 键", "Q W E R T Y"),
            Triple("handwriting", "手写", "全屏手写 · 停顿识别"),
            Triple("stroke", "笔画", "横 竖 撇 捺 折"),
            Triple("shuangpin", "双拼", "小鹤 / 自然码"),
            Triple("wubi", "五笔", "86 版 · 四码上屏")
        )
        val grid = gridRows(types, 2, { any ->
            val (type, label, preview) = any as Triple<String, String, String>
            val active = host.kbType == type
            LinearLayout(ctx).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER
                setPadding(dp(10), dp(10), dp(10), dp(10))
                background = GradientDrawable().apply {
                    setColor(if (active) (if (pal.dark) Color.parseColor("#263A5C") else Color.parseColor("#EAF1FF")) else pal.card)
                    cornerRadius = dpF(16)
                    if (active) setStroke(dp(2), pal.primary) else setStroke(1, pal.divider)
                }
                setOnClickListener {
                    host.setKeyboardType(type)
                    host.toast("已切换到$label")
                    host.closePanel()
                }
                addView(TextView(ctx).apply {
                    text = preview
                    textSize = 11.5f
                    setTextColor(pal.secondary)
                    gravity = Gravity.CENTER
                    maxLines = 1
                    ellipsize = TextUtils.TruncateAt.END
                }, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(26)))
                addView(TextView(ctx).apply {
                    text = label
                    textSize = 17f
                    setTextColor(if (active) pal.primary else pal.text)
                    gravity = Gravity.CENTER
                    typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
                });
                addView(TextView(ctx).apply {
                    text = if (active) "当前使用" else "点击选择"
                    textSize = 10.5f
                    setTextColor(if (active) pal.primary else pal.secondary)
                    gravity = Gravity.CENTER
                })
            }
        }, rowMargin = 10)
        content.addView(grid)
        val links = LinearLayout(ctx).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER }
        val dbl = pill("双拼设置", false) { host.openSettings("double_pinyin"); host.closePanel() }
        val wubi = pill("五笔设置", false) { host.openSettings("wubi"); host.closePanel() }
        links.addView(dbl, LinearLayout.LayoutParams(0, dp(38), 1f).apply { rightMargin = dp(6) })
        links.addView(wubi, LinearLayout.LayoutParams(0, dp(38), 1f).apply { leftMargin = dp(6) })
        content.addView(links, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
            topMargin = dp(10)
        })
        if (firstRun) {
            content.addView(TextView(ctx).apply {
                text = "提示：之后可从工具栏 ⌨ 或 设置 → 键盘类型 随时切换。手写/笔画/五笔为演示级实现，词典覆盖有限。"
                textSize = 11f
                setTextColor(pal.secondary)
                setPadding(dp(4), dp(12), dp(4), 0)
            })
        }
        show(root)
    }

    // ---------------- emoji ----------------
    fun showEmoji(tab: Int = 0, category: Int = 0) {
        val (root, content) = shell("表情", "Emoji · 颜文字 · 表情图")
        val tabs = LinearLayout(ctx).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER }
        listOf("Emoji", "颜文字", "表情图").forEachIndexed { idx, name ->
            tabs.addView(chip(name, idx == tab) { showEmoji(idx, 0) }, LinearLayout.LayoutParams(0, dp(32), 1f).apply {
                leftMargin = dp(3); rightMargin = dp(3)
            })
        }
        content.addView(tabs)
        when (tab) {
            1 -> {
                val cats = EmojiData.kaomoji
                val catRow = LinearLayout(ctx).apply { orientation = LinearLayout.HORIZONTAL; setPadding(0, dp(10), 0, 0) }
                val sv = android.widget.HorizontalScrollView(ctx).apply { isHorizontalScrollBarEnabled = false }
                val catInner = LinearLayout(ctx).apply { orientation = LinearLayout.HORIZONTAL }
                cats.forEachIndexed { idx, pair ->
                    catInner.addView(chip(pair.first, idx == category) { showEmoji(1, idx) }, LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, dp(30)).apply {
                        leftMargin = dp(3); rightMargin = dp(3)
                    })
                }
                sv.addView(catInner)
                catRow.addView(sv)
                content.addView(catRow)
                val list = cats[category.coerceIn(0, cats.size - 1)].second
                list.forEach { k ->
                    val row = listRow(k, "", "插入", {
                        host.insertText(k)
                    })
                    addCardRow(content, row, 6)
                }
            }
            2 -> {
                val cols = columnsFor(88)
                content.addView(TextView(ctx).apply {
                    text = "原创建模的彩色表情卡，点击插入占位文本 [标签]，可被聊天应用识别为表情图。"
                    textSize = 11f
                    setTextColor(pal.secondary)
                    setPadding(dp(2), dp(10), dp(2), dp(6))
                })
                content.addView(gridRows(EmojiData.stickers, cols, { any ->
                    val (emoji, label) = any as Pair<String, String>
                    LinearLayout(ctx).apply {
                        orientation = LinearLayout.VERTICAL
                        gravity = Gravity.CENTER
                        setPadding(0, dp(6), 0, dp(6))
                        background = GradientDrawable().apply {
                            setColor(if (pal.dark) Color.parseColor("#2A2B30") else Color.parseColor("#FFFFFF"))
                            cornerRadius = dpF(12)
                            setStroke(1, pal.divider)
                        }
                        setOnClickListener { host.insertText("[$label]") }
                        addView(TextView(ctx).apply {
                            text = emoji; textSize = 24f; gravity = Gravity.CENTER
                        })
                        addView(TextView(ctx).apply {
                            text = label; textSize = 10.5f; setTextColor(pal.secondary); gravity = Gravity.CENTER
                        })
                    }
                }, 6))
            }
            else -> {
                val recents = PrefsHelper.recentEmojis()
                if (recents.isNotEmpty()) {
                    content.addView(sectionTitle("最近使用"))
                    content.addView(gridRows(recents.take(24), columnsFor(44), { any ->
                        emojiCell(any as String)
                    }, 4))
                }
                val cats = EmojiData.categories
                val catRow = LinearLayout(ctx).apply { orientation = LinearLayout.HORIZONTAL; setPadding(0, dp(8), 0, 0) }
                val sv = android.widget.HorizontalScrollView(ctx).apply { isHorizontalScrollBarEnabled = false }
                val catInner = LinearLayout(ctx).apply { orientation = LinearLayout.HORIZONTAL }
                cats.forEachIndexed { idx, pair ->
                    catInner.addView(chip(pair.first, idx == category) { showEmoji(0, idx) }, LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, dp(30)).apply {
                        leftMargin = dp(3); rightMargin = dp(3)
                    })
                }
                sv.addView(catInner)
                catRow.addView(sv)
                content.addView(catRow)
                val list = cats[category.coerceIn(0, cats.size - 1)].second
                content.addView(gridRows(list, columnsFor(44), { any ->
                    emojiCell(any as String)
                }, 4))
            }
        }
        show(root)
    }

    private fun columnsFor(cellDp: Int): Int {
        val widthDp = host.contentWidthPx / ctx.resources.displayMetrics.density
        return (widthDp / cellDp).toInt().coerceIn(5, 12)
    }

    private fun emojiCell(emoji: String): View =
        TextView(ctx).apply {
            text = emoji
            textSize = 24f
            gravity = Gravity.CENTER
            background = rippleBackground(Color.TRANSPARENT, pal.pressed, dpF(10))
            setOnClickListener {
                host.insertText(emoji)
                PrefsHelper.addRecentEmoji(emoji)
            }
        }

    // ---------------- clipboard ----------------
    fun showClipboard(tab: Int = 0) {
        val (root, content) = shell("剪切板", "点击插入，长按更多操作")
        val tabs = LinearLayout(ctx).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER }
        tabs.addView(chip("本机", tab == 0) { showClipboard(0) }, LinearLayout.LayoutParams(0, dp(32), 1f).apply { rightMargin = dp(4) })
        tabs.addView(chip("跨设备", tab == 1) { showClipboard(1) }, LinearLayout.LayoutParams(0, dp(32), 1f).apply { leftMargin = dp(4) })
        content.addView(tabs)
        if (tab == 0) {
            val actions = LinearLayout(ctx).apply { orientation = LinearLayout.HORIZONTAL; setPadding(0, dp(10), 0, 0) }
            actions.addView(pill("读取系统剪贴板", true) {
                val text = host.service.clipboardText().trim()
                if (text.isBlank()) host.toast("系统剪贴板为空") else {
                    ClipboardRepo.add(text)
                    host.toast("已加入剪切板历史")
                    showClipboard(0)
                }
            }, LinearLayout.LayoutParams(0, dp(38), 1f).apply { rightMargin = dp(4) })
            actions.addView(pill("清空历史", false) {
                confirm("清空剪切板", "将删除全部本地剪切板历史（置顶项可选择保留）。", "清空") {
                    ClipboardRepo.clear(keepPinned = false)
                    host.toast("剪切板已清空")
                    showClipboard(0)
                }
            }, LinearLayout.LayoutParams(0, dp(38), 1f).apply { leftMargin = dp(4) })
            content.addView(actions)
            val items = ClipboardRepo.all()
            if (items.isEmpty()) {
                content.addView(emptyState("暂无剪切板历史", "复制文字后回到键盘，或点击“读取系统剪贴板”。"))
            } else {
                items.forEach { item ->
                    val row = listRow(
                        item.text.replace("\n", " ").take(80),
                        timeLabel(item.ts) + if (item.pinned) " · 置顶" else "",
                        if (item.kind == "image") "图片" else "插入",
                        { host.insertText(item.text); host.closePanel() },
                        { showClipboardItem(item) }
                    )
                    addCardRow(content, row, 7)
                }
            }
        } else {
            val logged = Prefs.accountLoggedIn
            val enabled = Prefs.getBool(Prefs.K_SUPER_TRANSFER)
            if (!logged || !enabled) {
                content.addView(emptyState(
                    "跨设备剪切板未开启",
                    "登录账号并开启超级互传后，可在手机与电脑之间同步文字和图片。"
                ))
                val b = pill(if (!logged) "去登录" else "去开启", true) { host.openSettings("super_transfer"); host.closePanel() }
                content.addView(b, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(42)).apply { topMargin = dp(10) })
            } else {
                content.addView(TextView(ctx).apply {
                    text = "已连接的设备：\n" + DeviceRepo.devices().joinToString("\n") { "· ${it.name}（${it.kind}）" }
                    textSize = 12.5f
                    setTextColor(pal.secondary)
                    setPadding(dp(2), dp(10), dp(2), dp(8))
                })
                content.addView(pill("发送当前剪贴板到设备", true) {
                    val text = host.service.clipboardText().trim()
                    if (text.isBlank()) host.toast("系统剪贴板为空") else {
                        ClipboardRepo.add(text)
                        host.toast("已发送到已登录设备（演示）")
                    }
                }, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(42)))
                content.addView(TextView(ctx).apply {
                    text = "演示说明：跨设备传输使用本地模拟队列，不连接官方服务。"
                    textSize = 10.5f
                    setTextColor(pal.secondary)
                    setPadding(dp(2), dp(8), dp(2), 0)
                })
            }
        }
        show(root)
    }

    private fun showClipboardItem(item: ClipItem) {
        val (root, content) = shell("剪切板内容", timeLabel(item.ts))
        content.addView(TextView(ctx).apply {
            text = item.text.take(1200)
            textSize = 14f
            setTextColor(pal.text)
            setPadding(dp(14), dp(14), dp(14), dp(14))
            background = GradientDrawable().apply {
                setColor(pal.card); cornerRadius = dpF(14)
            }
        })
        val actions = actionRow(
            pill("插入") { host.insertText(item.text); host.closePanel() },
            pill("复制") { host.copyToClipboard(item.text) },
            pill("拆词") { showSplitWords(item.text) }
        )
        content.addView(actions)
        val row2 = actionRow(
            pill(if (item.pinned) "取消置顶" else "置顶") {
                ClipboardRepo.togglePin(item.id); showClipboard(0)
            },
            pill("删除", false) {
                ClipboardRepo.delete(item.id); host.toast("已删除"); showClipboard(0)
            }
        )
        content.addView(row2)
        show(root)
    }

    private fun showSplitWords(raw: String) {
        val (root, content) = shell("拆词", "点击任一词组插入")
        val chunks = splitText(raw)
        val cols = columnsFor(72)
        content.addView(gridRows(chunks, cols, { any ->
            TextView(ctx).apply {
                this.text = any as String
                textSize = 13f
                gravity = Gravity.CENTER
                setPadding(dp(4), dp(10), dp(4), dp(10))
                background = rippleBackground(pal.card, pal.pressed, dpF(10))
                setOnClickListener { host.insertText(any as String) }
            }
        }, 7))
        show(root)
    }

    private fun splitText(text: String): List<String> {
        val out = mutableListOf<String>()
        val sb = StringBuilder()
        fun flush() {
            if (sb.isNotEmpty()) {
                val chunk = sb.toString()
                if (chunk.any { it.code in 0x4E00..0x9FFF } && chunk.length > 2) {
                    var i = 0
                    while (i < chunk.length) {
                        val end = (i + 2).coerceAtMost(chunk.length)
                        out.add(chunk.substring(i, end)); i = end
                    }
                } else out.add(chunk)
                sb.clear()
            }
        }
        text.forEach { c ->
            if (c.isWhitespace() || c in "，。！？、；：“”‘’（）【】《》…—,.!?;:\"'()[]") {
                flush(); if (!c.isWhitespace()) out.add(c.toString())
            } else sb.append(c)
        }
        flush()
        return out.take(60)
    }

    // ---------------- phrases ----------------
    fun showPhrases(category: String? = null) {
        val (root, content) = shell("常用语", "点击插入，长按管理")
        val all = PhraseRepo.all()
        val cats = listOf("全部") + all.map { it.category }.distinct()
        val selected = category ?: "全部"
        val row = LinearLayout(ctx).apply { orientation = LinearLayout.HORIZONTAL }
        val sv = android.widget.HorizontalScrollView(ctx).apply { isHorizontalScrollBarEnabled = false }
        val inner = LinearLayout(ctx).apply { orientation = LinearLayout.HORIZONTAL }
        cats.forEach { cat ->
            inner.addView(chip(cat, cat == selected) { showPhrases(if (cat == "全部") null else cat) }, LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, dp(30)).apply {
                leftMargin = dp(3); rightMargin = dp(3)
            })
        }
        sv.addView(inner)
        row.addView(sv, LinearLayout.LayoutParams(0, dp(34), 1f))
        row.addView(pill("+ 添加", true) {
            host.openTextInput("添加常用语", "例如：稍等一下，我马上处理。", "", true, "分类", selected.ifBlank { "常用" }) { text, extra ->
                PhraseRepo.add(text, extra.ifBlank { "常用" })
                host.toast("已添加")
                showPhrases(category)
            }
        }, LinearLayout.LayoutParams(dp(82), dp(34)))
        content.addView(row)
        val list = all.filter { selected == "全部" || it.category == selected }
        if (list.isEmpty()) {
            content.addView(emptyState("暂无常用语", "点击右上角添加你的第一条常用语。"))
        } else {
            list.forEach { phrase ->
                val item = listRow(
                    phrase.text,
                    phrase.category,
                    "插入",
                    { host.insertText(phrase.text); host.closePanel() },
                    { showPhraseActions(phrase, selected) }
                )
                addCardRow(content, item, 7)
            }
        }
        show(root)
    }

    private fun showPhraseActions(phrase: Phrase, category: String?) {
        val (root, content) = shell("常用语", phrase.category)
        content.addView(TextView(ctx).apply {
            text = phrase.text
            textSize = 15f
            setTextColor(pal.text)
            setPadding(dp(14), dp(14), dp(14), dp(14))
            background = GradientDrawable().apply { setColor(pal.card); cornerRadius = dpF(14) }
        })
        content.addView(actionRow(
            pill("插入") { host.insertText(phrase.text); host.closePanel() },
            pill("编辑") {
                host.openTextInput("编辑常用语", "修改内容", phrase.text, true, "分类", phrase.category) { text, extra ->
                    PhraseRepo.update(phrase.id, text, extra.ifBlank { "常用" })
                    host.toast("已保存")
                    showPhrases(category)
                }
            },
            pill("删除") {
                confirm("删除常用语", "确定删除这条常用语吗？", "删除") {
                    PhraseRepo.delete(phrase.id); host.toast("已删除"); showPhrases(category)
                }
            }
        ))
        show(root)
    }

    // ---------------- generic ----------------
    private fun emptyState(title: String, subtitle: String): View =
        LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(20), dp(44), dp(20), dp(44))
            addView(TextView(ctx).apply {
                text = title
                textSize = 15f
                setTextColor(pal.text)
                gravity = Gravity.CENTER
            })
            addView(TextView(ctx).apply {
                text = subtitle
                textSize = 12f
                setTextColor(pal.secondary)
                gravity = Gravity.CENTER
                setPadding(0, dp(8), 0, 0)
            })
        }

    private fun confirm(title: String, message: String, confirmLabel: String, onConfirm: () -> Unit) {
        val (root, content) = shell(title, null, false)
        content.addView(TextView(ctx).apply {
            text = message
            textSize = 14f
            setTextColor(pal.text)
            setPadding(dp(6), dp(20), dp(6), dp(20))
        })
        val row = LinearLayout(ctx).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER }
        row.addView(pill("取消", false) { host.closePanel() }, LinearLayout.LayoutParams(0, dp(42), 1f).apply { rightMargin = dp(6) })
        row.addView(pill(confirmLabel, true) { onConfirm() }, LinearLayout.LayoutParams(0, dp(42), 1f).apply { leftMargin = dp(6) })
        content.addView(row)
        show(root)
    }

    private fun timeLabel(ts: Long): String = com.huapohen.doubaoinput.android.ime.timeLabel(ts)

    // ---------------- adjust ----------------
    fun showAdjust() {
        val (root, content) = shell("键盘调节", "拖动即预览，设置会保存")
        val density = ctx.resources.displayMetrics.density
        val currentHeight = if (Prefs.keyboardHeight > 0) Prefs.keyboardHeight else (host.baseHeightPx / density).toInt()
        content.addView(sectionTitle("键盘高度  ${currentHeight} dp"))
        val heightBar = SeekBar(ctx).apply {
            max = 240
            progress = (currentHeight - 220).coerceIn(0, 240)
        }
        val heightLabel = content.getChildAt(content.childCount - 1) as TextView
        heightBar.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                if (fromUser) {
                    val h = 220 + progress
                    heightLabel.text = "键盘高度  $h dp"
                    Prefs.putInt(Prefs.K_KEYBOARD_HEIGHT, h)
                }
            }
            override fun onStartTrackingTouch(seekBar: SeekBar?) {}
            override fun onStopTrackingTouch(seekBar: SeekBar?) {}
        })
        content.addView(heightBar, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(36)))

        content.addView(sectionTitle("候选字大小  ${Prefs.candidateFontSize}"))
        val fontBar = SeekBar(ctx).apply {
            max = 16
            progress = (Prefs.candidateFontSize - 14).coerceIn(0, 16)
        }
        val fontLabel = content.getChildAt(content.childCount - 1) as TextView
        fontBar.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                if (fromUser) {
                    val v = 14 + progress
                    fontLabel.text = "候选字大小  $v"
                    Prefs.putInt(Prefs.K_CANDIDATE_FONT_SIZE, v)
                }
            }
            override fun onStartTrackingTouch(seekBar: SeekBar?) {}
            override fun onStopTrackingTouch(seekBar: SeekBar?) {}
        })
        content.addView(fontBar, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(36)))

        content.addView(sectionTitle("底部间距  ${Prefs.keyboardBottomGap} dp"))
        val gapBar = SeekBar(ctx).apply {
            max = 20
            progress = Prefs.keyboardBottomGap.coerceIn(0, 20)
        }
        val gapLabel = content.getChildAt(content.childCount - 1) as TextView
        gapBar.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                if (fromUser) {
                    gapLabel.text = "底部间距  $progress dp"
                    Prefs.putInt(Prefs.K_KEYBOARD_BOTTOM_GAP, progress)
                }
            }
            override fun onStartTrackingTouch(seekBar: SeekBar?) {}
            override fun onStopTrackingTouch(seekBar: SeekBar?) {}
        })
        content.addView(gapBar, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(36)))

        content.addView(sectionTitle("外观"))
        val themes = listOf("跟随系统" to "system", "浅色" to "light", "深色" to "dark")
        val themeRow = LinearLayout(ctx).apply { orientation = LinearLayout.HORIZONTAL }
        themes.forEach { (label, value) ->
            themeRow.addView(chip(label, Prefs.themeMode == value) {
                Prefs.putString(Prefs.K_THEME_MODE, value)
                showAdjust()
            }, LinearLayout.LayoutParams(0, dp(34), 1f).apply { leftMargin = dp(3); rightMargin = dp(3) })
        }
        content.addView(themeRow)

        content.addView(sectionTitle("拼音显示位置"))
        val locs = listOf("顶部" to "top", "候选栏" to "bottom", "隐藏" to "hidden")
        val locRow = LinearLayout(ctx).apply { orientation = LinearLayout.HORIZONTAL }
        locs.forEach { (label, value) ->
            locRow.addView(chip(label, Prefs.getString(Prefs.K_PINYIN_LOCATION, "top") == value) {
                Prefs.putString(Prefs.K_PINYIN_LOCATION, value)
                showAdjust()
            }, LinearLayout.LayoutParams(0, dp(34), 1f).apply { leftMargin = dp(3); rightMargin = dp(3) })
        }
        content.addView(locRow)

        content.addView(sectionTitle("位置"))
        val posRow = LinearLayout(ctx).apply { orientation = LinearLayout.HORIZONTAL }
        listOf("关闭" to "off", "左手" to "left", "右手" to "right").forEach { (label, value) ->
            posRow.addView(chip(label, Prefs.oneHand == value) {
                Prefs.putString(Prefs.K_ONE_HAND, value); showAdjust()
            }, LinearLayout.LayoutParams(0, dp(34), 1f).apply { leftMargin = dp(3); rightMargin = dp(3) })
        }
        content.addView(posRow)
        val floatRow = LinearLayout(ctx).apply { orientation = LinearLayout.HORIZONTAL; setPadding(0, dp(12), 0, 0) }
        floatRow.addView(TextView(ctx).apply {
            text = "悬浮键盘"
            textSize = 14f
            setTextColor(pal.text)
        }, LinearLayout.LayoutParams(0, dp(36), 1f))
        floatRow.addView(chip(if (Prefs.floating) "已开启" else "已关闭", Prefs.floating) {
            Prefs.putBool(Prefs.K_FLOATING, !Prefs.floating); showAdjust()
        }, LinearLayout.LayoutParams(dp(84), dp(34)))
        content.addView(floatRow)

        content.addView(pill("恢复默认", false) {
            listOf(
                Prefs.K_KEYBOARD_HEIGHT, Prefs.K_KEYBOARD_BOTTOM_GAP, Prefs.K_CANDIDATE_FONT_SIZE,
                Prefs.K_PINYIN_LOCATION, Prefs.K_ONE_HAND, Prefs.K_FLOATING, Prefs.K_THEME_MODE
            ).forEach { Prefs.sp.edit().remove(it).apply() }
            Prefs.bump()
            host.toast("已恢复默认键盘设置")
            showAdjust()
        }, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(42)).apply { topMargin = dp(12) })
        show(root)
    }

    fun showOneHand() {
        val (root, content) = shell("单手模式", "点击选择键盘停靠位置")
        listOf("关闭" to "off", "左手" to "left", "右手" to "right").forEach { (label, value) ->
            val active = Prefs.oneHand == value
            val card = LinearLayout(ctx).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setPadding(dp(16), dp(14), dp(16), dp(14))
                background = GradientDrawable().apply {
                    setColor(if (active) (if (pal.dark) Color.parseColor("#263A5C") else Color.parseColor("#EAF1FF")) else pal.card)
                    cornerRadius = dpF(14)
                    if (active) setStroke(dp(2), pal.primary)
                }
                setOnClickListener {
                    Prefs.putString(Prefs.K_ONE_HAND, value)
                    host.toast(if (value == "off") "已关闭单手模式" else "已开启$label")
                    host.closePanel()
                }
                addView(TextView(ctx).apply {
                    text = label
                    textSize = 15f
                    setTextColor(if (active) pal.primary else pal.text)
                    typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
                }, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
                addView(TextView(ctx).apply {
                    text = if (active) "当前" else "选择"
                    textSize = 12f
                    setTextColor(if (active) pal.primary else pal.secondary)
                })
            }
            addCardRow(content, card, 8)
        }
        content.addView(sectionTitle("悬浮键盘"))
        content.addView(pill(if (Prefs.floating) "关闭悬浮键盘" else "开启悬浮键盘", Prefs.floating) {
            Prefs.putBool(Prefs.K_FLOATING, !Prefs.floating)
            showOneHand()
        }, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(42)))
        content.addView(TextView(ctx).apply {
            text = "悬浮键盘可用工具条左侧 ⠿ 拖动；关闭后恢复标准布局。"
            textSize = 11f
            setTextColor(pal.secondary)
            setPadding(dp(2), dp(10), dp(2), 0)
        })
        show(root)
    }

    // ---------------- toolbar customize ----------------
    fun showToolbarCustomize() {
        val (root, content) = shell("定制工具栏", "拖动 ≡ 排序，点按启用/停用", scroll = false)
        val current = ToolbarRepo.current()
        val items = ArrayList<ToolItemState>()
        current.forEach { id -> items.add(ToolItemState(id, true)) }
        ToolbarRepo.allIds.forEach { id -> if (items.none { it.id == id }) items.add(ToolItemState(id, false)) }
        val rv = RecyclerView(ctx).apply {
            layoutManager = LinearLayoutManager(ctx)
            setPadding(0, dp(4), 0, dp(4))
            clipToPadding = false
        }
        val adapter = object : RecyclerView.Adapter<ToolbarVH>() {
            override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ToolbarVH {
                val row = LinearLayout(ctx).apply {
                    orientation = LinearLayout.HORIZONTAL
                    gravity = Gravity.CENTER_VERTICAL
                    setPadding(dp(12), dp(12), dp(12), dp(12))
                    background = rippleBackground(pal.card, pal.pressed, dpF(12))
                }
                val check = TextView(ctx).apply {
                    textSize = 15f
                    gravity = Gravity.CENTER
                }
                row.addView(check, LinearLayout.LayoutParams(dp(30), dp(30)))
                val name = TextView(ctx).apply {
                    textSize = 14.5f
                    setTextColor(pal.text)
                }
                row.addView(name, LinearLayout.LayoutParams(0, dp(30), 1f).apply { leftMargin = dp(4) })
                val handle = TextView(ctx).apply {
                    text = "≡"
                    textSize = 20f
                    setTextColor(pal.secondary)
                    gravity = Gravity.CENTER
                }
                row.addView(handle, LinearLayout.LayoutParams(dp(32), dp(30)))
                row.setOnClickListener {
                    val pos = (row.tag as? Int) ?: -1
                    if (pos in items.indices) {
                        items[pos].checked = !items[pos].checked
                        notifyItemChanged(pos)
                    }
                }
                return ToolbarVH(row, check, name)
            }

            override fun getItemCount(): Int = items.size

            override fun onBindViewHolder(holder: ToolbarVH, position: Int) {
                val item = items[position]
                holder.row.tag = position
                holder.check.text = if (item.checked) "✓" else "○"
                holder.check.setTextColor(if (item.checked) pal.primary else pal.secondary)
                holder.name.text = toolbarName(item.id)
                holder.name.setTextColor(if (item.checked) pal.text else pal.secondary)
                holder.row.alpha = if (item.checked) 1f else 0.72f
            }
        }
        rv.adapter = adapter
        val touchHelper = ItemTouchHelper(object : ItemTouchHelper.SimpleCallback(
            ItemTouchHelper.UP or ItemTouchHelper.DOWN, 0
        ) {
            override fun onMove(recyclerView: RecyclerView, viewHolder: RecyclerView.ViewHolder, target: RecyclerView.ViewHolder): Boolean {
                val from = viewHolder.bindingAdapterPosition
                val to = target.bindingAdapterPosition
                if (from == RecyclerView.NO_POSITION || to == RecyclerView.NO_POSITION) return false
                Collections.swap(items, from, to)
                adapter.notifyItemMoved(from, to)
                return true
            }
            override fun onSwiped(viewHolder: RecyclerView.ViewHolder, direction: Int) {}
        })
        touchHelper.attachToRecyclerView(rv)
        content.addView(rv, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))
        val bar = LinearLayout(ctx).apply { orientation = LinearLayout.HORIZONTAL; setPadding(0, dp(8), 0, 0) }
        bar.addView(pill("恢复默认", false) {
            items.clear()
            ToolbarRepo.allIds.forEachIndexed { i, id -> items.add(ToolItemState(id, i < 12)) }
            adapter.notifyDataSetChanged()
        }, LinearLayout.LayoutParams(0, dp(42), 1f).apply { rightMargin = dp(5) })
        bar.addView(pill("完成", true) {
            val enabled = items.filter { it.checked }.map { it.id }
            if (enabled.isEmpty()) host.toast("至少保留一个工具栏按钮") else {
                ToolbarRepo.save(enabled)
                host.toast("工具栏已更新")
                host.closePanel()
            }
        }, LinearLayout.LayoutParams(0, dp(42), 1f).apply { leftMargin = dp(5) })
        content.addView(bar)
        show(root)
    }

    private data class ToolItemState(val id: String, var checked: Boolean)
    private class ToolbarVH(val row: LinearLayout, val check: TextView, val name: TextView) : RecyclerView.ViewHolder(row)

    private fun toolbarName(id: String): String = when (id) {
        "toolbox" -> "工具箱"; "voice" -> "点击说话"; "clipboard" -> "剪切板"; "translate" -> "翻译"
        "emoji" -> "表情"; "phrase" -> "常用语"; "keyboard" -> "键盘选择"; "trad" -> "繁简切换"
        "onehand" -> "单手模式"; "handwrite" -> "手写找字"; "undo" -> "撤销"; "ai" -> "AI 写作"
        else -> id
    }

    // ---------------- handwriting search ----------------
    fun showHandwritingSearch(query: String = "") {
        val (root, content) = shell("手写找字", "输入拼音，从本地词库查字")
        content.addView(TextView(ctx).apply {
            text = if (query.isBlank()) "输入拼音或首字母，例如 nihao、nh、zhongguo" else "“$query” 的结果"
            textSize = 13f
            setTextColor(pal.secondary)
            setPadding(dp(2), dp(8), dp(2), dp(10))
        })
        val row = LinearLayout(ctx).apply { orientation = LinearLayout.HORIZONTAL }
        row.addView(pill("输入拼音", true) {
            host.openTextInput("手写找字", "输入拼音或首字母", query, false) { text, _ ->
                showHandwritingSearch(text)
            }
        }, LinearLayout.LayoutParams(0, dp(40), 1f).apply { rightMargin = dp(5) })
        row.addView(pill("清除", false) { showHandwritingSearch("") }, LinearLayout.LayoutParams(0, dp(40), 1f).apply { leftMargin = dp(5) })
        content.addView(row)
        if (query.isNotBlank()) {
            val results = PinyinEngine.candidates(
                query, false, 60, emptySet(), emptySet(), emptySet(),
                Prefs.mru(), LexiconRepo.all(), Prefs.blacklist()
            )
            if (results.isEmpty()) {
                content.addView(emptyState("未找到匹配汉字", "试试完整拼音，或更短的拼音前缀。"))
            } else {
                content.addView(sectionTitle("匹配 ${results.size} 项"))
                content.addView(gridRows(results, columnsFor(64), { any ->
                    val c = any as PinyinEngine.Candidate
                    LinearLayout(ctx).apply {
                        orientation = LinearLayout.VERTICAL
                        gravity = Gravity.CENTER
                        setPadding(0, dp(6), 0, dp(6))
                        background = rippleBackground(pal.card, pal.pressed, dpF(10))
                        setOnClickListener { host.insertText(c.text); }
                        addView(TextView(ctx).apply {
                            text = c.text
                            textSize = 18f
                            setTextColor(pal.text)
                            gravity = Gravity.CENTER
                        })
                        addView(TextView(ctx).apply {
                            text = c.pinyin
                            textSize = 9f
                            setTextColor(pal.secondary)
                            gravity = Gravity.CENTER
                        })
                    }
                }, 6))
            }
        } else {
            content.addView(TextView(ctx).apply {
                text = "覆盖：本地 $(PinyinEngine.entryCount) 条词条。手写识别为演示级模板匹配，复杂字请用拼音查字。"
                textSize = 11f
                setTextColor(pal.secondary)
                setPadding(dp(2), dp(14), dp(2), 0)
            })
        }
        show(root)
    }

    // ---------------- candidate detail ----------------
    fun showCandidateDetail(c: ImeCandidate) {
        val (root, content) = shell("候选详情", sourceLabel(c))
        content.addView(TextView(ctx).apply {
            text = c.text
            textSize = 54f
            gravity = Gravity.CENTER
            setTextColor(pal.text)
            setPadding(0, dp(14), 0, dp(10))
        })
        val info = card()
        info.addView(TextView(ctx).apply {
            text = "拼音：${c.pinyin.ifBlank { "—" }}"
            textSize = 13f
            setTextColor(pal.text)
        })
        info.addView(TextView(ctx).apply {
            text = "词频：${c.freq}    来源：${sourceLabel(c)}"
            textSize = 12f
            setTextColor(pal.secondary)
            setPadding(0, dp(4), 0, 0)
        })
        content.addView(info, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        content.addView(actionRow(
            pill("上屏", true) { host.commitCandidate(c); host.closePanel() },
            pill("复制") { host.copyToClipboard(c.text) },
            pill("删除该词") {
                Prefs.blacklistAdd(c.text)
                host.toast("已删除该候选，不再出现")
                host.refreshCandidates()
                host.closePanel()
            }
        ))
        content.addView(pill("查看更多候选 ›", false) { showCandidateMore() }, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(40)).apply {
            topMargin = dp(8)
        })
        show(root)
    }

    private fun sourceLabel(c: ImeCandidate): String = when (c.kind) {
        "pinyin" -> "拼音词库"
        "english" -> "英文联想"
        "assoc" -> "智能联想"
        "emoji" -> "Emoji 预测"
        "kaomoji" -> "颜文字预测"
        "image" -> "图片表情"
        "clipboard" -> "剪贴板"
        "wubi" -> "五笔词库"
        "stroke" -> "笔画词库"
        "handwriting" -> "手写识别"
        else -> c.kind
    }

    fun showCandidateMore() {
        val (root, content) = shell("更多候选", "全部 / 单字")
        val all = host.currentCandidates()
        if (all.isEmpty()) {
            content.addView(emptyState("暂无候选", "输入拼音或切换键盘后再试。"))
            show(root)
            return
        }
        var onlySingle = false
        val listHost = LinearLayout(ctx).apply { orientation = LinearLayout.VERTICAL }
        fun render() {
            listHost.removeAllViews()
            val list = if (onlySingle) all.filter { it.text.length == 1 } else all
            if (list.isEmpty()) {
                listHost.addView(emptyState("没有单字候选", "切换到“全部”查看词语。"))
            } else {
                listHost.addView(gridRows(list, columnsFor(56), { any ->
                    val c = any as ImeCandidate
                    TextView(ctx).apply {
                        text = c.text
                        textSize = if (c.text.length == 1) 20f else 15f
                        gravity = Gravity.CENTER
                        setTextColor(pal.text)
                        setPadding(dp(2), dp(10), dp(2), dp(10))
                        background = rippleBackground(pal.card, pal.pressed, dpF(10))
                        setOnClickListener { host.commitCandidate(c); host.closePanel() }
                    }
                }, 6))
            }
        }
        val tabs = LinearLayout(ctx).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER }
        tabs.addView(chip("全部", true) { onlySingle = false; render() }, LinearLayout.LayoutParams(0, dp(32), 1f).apply { rightMargin = dp(4) })
        tabs.addView(chip("单字", false) { onlySingle = true; render() }, LinearLayout.LayoutParams(0, dp(32), 1f).apply { leftMargin = dp(4) })
        content.addView(tabs)
        content.addView(listHost)
        render()
        show(root)
    }

    fun showCompositionDetail() {
        val comp = host.currentComposition()
        if (comp.isBlank()) { host.toast("暂无拼音"); return }
        val (root, content) = shell("拼音分词", comp)
        content.addView(TextView(ctx).apply {
            text = "点击音节可从该处上屏；剩余拼音会保留。"
            textSize = 11.5f
            setTextColor(pal.secondary)
            setPadding(dp(2), dp(6), dp(2), dp(8))
        })
        val isDigits = comp.all { it.isDigit() }
        val parts = if (isDigits) comp.map { it.toString() } else PinyinEngine.splitSyllables(comp)
        var prefix = ""
        parts.forEach { part ->
            prefix += part
            val top = if (isDigits) {
                PinyinEngine.candidates(prefix, true, 1, mru = Prefs.mru()).firstOrNull()
            } else {
                PinyinEngine.candidates(prefix, false, 1, mru = Prefs.mru()).firstOrNull()
            }
            val row = listRow(
                "$prefix  →  ${top?.text ?: "—"}",
                if (part.isEmpty()) "" else "点击上屏到该音节",
                "上屏",
                {
                    if (top != null) {
                        host.commitCandidate(ImeCandidate(top.text, top.text, "pinyin", top.pinyin, top.freq))
                        host.setComposition(comp.substring(prefix.length))
                    } else host.toast("该音节暂无候选")
                    host.closePanel()
                }
            )
            addCardRow(content, row, 6)
        }
        content.addView(actionRow(
            pill("全部上屏", true) { host.commitTopCandidateIfAny(); host.closePanel() },
            pill("清空拼音") { host.setComposition(""); host.closePanel() }
        ))
        show(root)
    }

    // ---------------- translate ----------------
    fun showTranslate(initialText: String = "", zhToEn: Boolean = true) {
        val (root, content) = shell("翻译", "本地词库优先，可配置 AI 增强")
        var source = initialText.ifBlank {
            val sel = host.selectedText()
            if (sel.isNotBlank()) sel else host.currentComposition().ifBlank { host.service.clipboardText().trim() }
        }
        var directionZhToEn = if (source.contains(Regex("[\\u4e00-\\u9fff]"))) true else zhToEn
        val sourceView = TextView(ctx).apply {
            text = source.ifBlank { "点击“输入文字”开始翻译" }
            textSize = 15f
            setTextColor(if (source.isBlank()) pal.secondary else pal.text)
            setPadding(dp(14), dp(14), dp(14), dp(14))
            background = GradientDrawable().apply { setColor(pal.card); cornerRadius = dpF(14) }
        }
        content.addView(sourceView, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(90)))
        val dir = pill(if (directionZhToEn) "中 → 英" else "英 → 中", false) {
            directionZhToEn = !directionZhToEn
            showTranslate(source, directionZhToEn)
        }
        val edit = pill("输入文字", false) {
            host.openTextInput("翻译", "输入要翻译的内容", source, true) { text, _ ->
                showTranslate(text, directionZhToEn)
            }
        }
        content.addView(actionRow(dir, edit))
        val resultView = TextView(ctx).apply {
            text = ""
            textSize = 15f
            setTextColor(pal.text)
            setPadding(dp(14), dp(14), dp(14), dp(14))
            background = GradientDrawable().apply { setColor(pal.card); cornerRadius = dpF(14) }
        }
        val status = TextView(ctx).apply {
            text = "离线词库 ${TranslateData.size()} 条"
            textSize = 11f
            setTextColor(pal.secondary)
            setPadding(dp(4), dp(8), dp(4), dp(4))
        }
        val translateBtn = pill("翻译", true) {
            if (source.isBlank()) {
                host.toast("请先输入要翻译的文字")
            } else {
                resultView.text = "翻译中…"
                status.text = "正在处理"
                val token = tokenCounter
                if (Prefs.smartMode && Prefs.hasAiKey()) {
                    host.service.scope.launch {
                        val result = AiClient.generate(AiClient.Action.TRANSLATE, source)
                        if (token != tokenCounter) return@launch
                        resultView.text = result.text.ifBlank { "翻译失败" }
                        status.text = if (result.offline) "离线结果 · ${result.error}" else "AI 翻译（${Prefs.aiModel}）"
                    }
                } else {
                    val local = TranslateData.translate(source, directionZhToEn)
                    if (local.isBlank()) {
                        resultView.text = "离线词库未收录该内容。\n可到 设置 → AI 服务 配置 Key 后使用 AI 翻译。"
                        status.text = "离线词库未命中"
                    } else {
                        resultView.text = local
                        status.text = "离线词库"
                    }
                }
            }
        }
        content.addView(translateBtn, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(42)).apply { topMargin = dp(8) })
        content.addView(resultView, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply { topMargin = dp(8) })
        content.addView(status)
        content.addView(actionRow(
            pill("插入") { if (resultView.text.isNotBlank()) { host.insertText(resultView.text.toString()); host.closePanel() } },
            pill("复制") { if (resultView.text.isNotBlank()) host.copyToClipboard(resultView.text.toString()) },
            pill("替换原文") {
                if (resultView.text.isNotBlank()) {
                    host.insertText(resultView.text.toString())
                    host.closePanel()
                }
            }
        ))
        show(root)
    }

    // ---------------- AI writing / organize / voice result ----------------
    private fun aiBadge(offline: Boolean, error: String): String =
        if (offline) "离线示例" + if (error.isNotBlank()) " · $error" else "" else "AI · ${Prefs.aiModel}"

    fun showAi() {
        val (root, content) = shell("AI 写作", "生成 · 改写 · 总结 · 检查")
        var topic = host.selectedText().ifBlank { host.currentComposition() }
        val topicView = TextView(ctx).apply {
            text = if (topic.isBlank()) "主题 / 上下文（可选，点击输入）" else topic
            textSize = 12.5f
            setTextColor(if (topic.isBlank()) pal.secondary else pal.text)
            setPadding(dp(12), dp(10), dp(12), dp(10))
            background = GradientDrawable().apply {
                setColor(pal.inputBg); cornerRadius = dpF(10)
            }
            isSingleLine = true
            ellipsize = TextUtils.TruncateAt.END
        }
        topicView.setOnClickListener {
            host.openTextInput("AI 写作主题", "想写什么？可留空", topic, false) { text, _ ->
                topic = text
                topicView.text = text
                topicView.setTextColor(pal.text)
            }
        }
        content.addView(topicView, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(40)))

        val actions = listOf(
            AiClient.Action.BLESSING, AiClient.Action.SOCIAL, AiClient.Action.COMMENT, AiClient.Action.INTRO,
            AiClient.Action.INVITATION, AiClient.Action.EMAIL, AiClient.Action.COPYWRITING, AiClient.Action.CHAT
        )
        val result = TextView(ctx).apply {
            text = ""
            textSize = 14f
            setTextColor(pal.text)
            setLineSpacing(dp(3).toFloat(), 1f)
            setPadding(dp(14), dp(14), dp(14), dp(14))
            background = GradientDrawable().apply { setColor(pal.card); cornerRadius = dpF(14) }
        }
        val status = TextView(ctx).apply {
            text = if (Prefs.hasAiKey()) "AI · ${Prefs.aiModel}" else "未配置 API Key，将使用离线示例"
            textSize = 10.5f
            setTextColor(pal.secondary)
            setPadding(dp(4), dp(8), dp(4), dp(4))
        }
        val history = mutableListOf<String>()
        var index = -1
        var lastAction: AiClient.Action? = null
        var lastInput: String = ""
        val historyRow = LinearLayout(ctx).apply { orientation = LinearLayout.HORIZONTAL; visibility = View.GONE }
        val prev = pill("上一条", false) {
            if (index > 0) { index--; result.text = history[index] }
        }
        val next = pill("下一条", false) {
            if (index >= 0 && index < history.size - 1) { index++; result.text = history[index] }
        }
        historyRow.addView(prev, LinearLayout.LayoutParams(0, dp(36), 1f).apply { rightMargin = dp(4) })
        historyRow.addView(next, LinearLayout.LayoutParams(0, dp(36), 1f).apply { leftMargin = dp(4) })

        fun run(action: AiClient.Action, input: String) {
            lastAction = action
            lastInput = input
            result.text = "生成中…"
            status.text = "正在请求 ${Prefs.aiModel}…"
            val token = tokenCounter
            host.service.scope.launch {
                val r = AiClient.generate(action, input, topic)
                if (token != tokenCounter) return@launch
                result.text = r.text
                status.text = aiBadge(r.offline, r.error)
                history.add(r.text)
                index = history.size - 1
                historyRow.visibility = if (history.size > 1) View.VISIBLE else View.GONE
                if (r.offline && !Prefs.hasAiKey()) {
                    status.setOnClickListener {
                        host.openSettings("ai")
                        host.closePanel()
                    }
                }
            }
        }

        val actionGrid = gridRows(actions, 4, { any ->
            val action = any as AiClient.Action
            TextView(ctx).apply {
                text = action.label
                textSize = 12.5f
                gravity = Gravity.CENTER
                setPadding(dp(4), dp(10), dp(4), dp(10))
                setTextColor(pal.text)
                background = rippleBackground(pal.card, pal.pressed, dpF(12))
                setOnClickListener { run(action, topic.ifBlank { "请自由发挥。" }) }
            }
        }, 6)
        content.addView(sectionTitle("选择功能"))
        content.addView(actionGrid)
        content.addView(sectionTitle("结果"))
        content.addView(result, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        content.addView(status)
        content.addView(historyRow, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        content.addView(actionRow(
            pill("重写") { run(AiClient.Action.REWRITE, result.text.toString()) },
            pill("总结") { run(AiClient.Action.SUMMARY, result.text.toString()) },
            pill("关键点") { run(AiClient.Action.KEYPOINTS, result.text.toString()) },
            pill("检查") { run(AiClient.Action.CHECK, result.text.toString()) }
        ))
        content.addView(actionRow(
            pill("复制") { if (result.text.isNotBlank()) host.copyToClipboard(result.text.toString()) },
            pill("插入", true) { if (result.text.isNotBlank()) { host.insertText(result.text.toString()); host.closePanel() } }
        ))
        if (!Prefs.hasAiKey()) {
            content.addView(pill("配置 AI 服务 ›", false) { host.openSettings("ai"); host.closePanel() }, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(38)).apply {
                topMargin = dp(6)
            })
        }
        show(root)
    }

    fun showOrganize() {
        val (root, content) = shell("智能整理", "去口水词 · 补标点 · 分段")
        var source = host.selectedText().ifBlank {
            if (host.currentComposition().isNotBlank()) host.currentComposition() else host.inputOrSelection()
        }
        val sourceView = TextView(ctx).apply {
            text = source.ifBlank { "请选择或输入要整理的文本" }
            textSize = 13.5f
            setTextColor(if (source.isBlank()) pal.secondary else pal.text)
            setPadding(dp(14), dp(12), dp(14), dp(12))
            background = GradientDrawable().apply { setColor(pal.card); cornerRadius = dpF(14) }
        }
        content.addView(TextView(ctx).apply {
            text = "原文"
            textSize = 11.5f
            setTextColor(pal.secondary)
            setPadding(dp(4), dp(8), 0, dp(4))
        })
        content.addView(sourceView, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(100)))
        content.addView(pill("编辑原文", false) {
            host.openTextInput("智能整理", "粘贴或输入要整理的文本", source, true) { text, _ ->
                source = text
                sourceView.text = text
                sourceView.setTextColor(pal.text)
            }
        }, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(38)).apply { topMargin = dp(8) })
        val resultView = TextView(ctx).apply {
            text = ""
            textSize = 14f
            setTextColor(pal.text)
            setLineSpacing(dp(3).toFloat(), 1f)
            setPadding(dp(14), dp(12), dp(14), dp(12))
            background = GradientDrawable().apply { setColor(pal.card); cornerRadius = dpF(14) }
        }
        val status = TextView(ctx).apply {
            text = "离线规则会在本地执行"
            textSize = 10.5f
            setTextColor(pal.secondary)
            setPadding(dp(4), dp(8), dp(4), dp(4))
        }
        var resultText = ""
        fun run() {
            if (source.isBlank()) { host.toast("请先输入或选择文本"); return }
            resultView.text = "整理中…"
            val token = tokenCounter
            if (Prefs.smartMode && Prefs.hasAiKey()) {
                host.service.scope.launch {
                    val r = AiClient.generate(AiClient.Action.ORGANIZE, source)
                    if (token != tokenCounter) return@launch
                    resultText = r.text
                    resultView.text = r.text
                    status.text = aiBadge(r.offline, r.error)
                }
            } else {
                resultText = AiClient.localOrganize(source)
                resultView.text = resultText
                status.text = "离线规则整理"
            }
        }
        content.addView(sectionTitle("结果"))
        content.addView(resultView, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        content.addView(status)
        content.addView(actionRow(
            pill("开始整理", true) { run() },
            pill("重试") { run() }
        ))
        content.addView(actionRow(
            pill("替换原文") {
                if (resultText.isBlank()) host.toast("请先整理") else { host.insertText(resultText); host.closePanel() }
            },
            pill("复制") { if (resultText.isNotBlank()) host.copyToClipboard(resultText) }
        ))
        show(root)
    }

    fun showVoiceResult(recognized: String, partialHint: Boolean = false, example: Boolean = false) {
        val (root, content) = shell("语音识别结果", if (partialHint) "未返回最终结果，已使用最后一次识别" else "可编辑后发送")
        var chosen = recognized
        val original = TextView(ctx).apply {
            this.text = recognized
            textSize = 15f
            setTextColor(pal.text)
            setLineSpacing(dp(3).toFloat(), 1f)
            setPadding(dp(14), dp(12), dp(14), dp(12))
            background = GradientDrawable().apply { setColor(pal.card); cornerRadius = dpF(14) }
        }
        if (example) {
            content.addView(TextView(ctx).apply {
                text = "示例文本：语音服务不可用。"
                textSize = 11f
                setTextColor(pal.danger)
                setPadding(dp(4), 0, dp(4), dp(6))
            })
        }
        content.addView(TextView(ctx).apply {
            text = "识别原文"
            textSize = 11.5f
            setTextColor(pal.secondary)
            setPadding(dp(4), dp(8), 0, dp(4))
        })
        content.addView(original)
        val editRow = actionRow(
            pill("编辑") {
                host.openTextInput("编辑识别结果", "修改识别文本", chosen, true) { t, _ ->
                    chosen = t
                    original.text = t
                }
            },
            pill("复制") { host.copyToClipboard(chosen) }
        )
        content.addView(editRow)
        val organized = TextView(ctx).apply {
            text = ""
            textSize = 14f
            setTextColor(pal.text)
            setLineSpacing(dp(3).toFloat(), 1f)
            setPadding(dp(14), dp(12), dp(14), dp(12))
            background = GradientDrawable().apply { setColor(pal.card); cornerRadius = dpF(14) }
        }
        val orgStatus = TextView(ctx).apply {
            text = ""
            textSize = 10.5f
            setTextColor(pal.secondary)
        }
        var organizedText = ""
        if (Prefs.getBool(Prefs.K_VOICE_SMART_ORGANIZE)) {
            content.addView(TextView(ctx).apply {
                text = "智能整理"
                textSize = 11.5f
                setTextColor(pal.secondary)
                setPadding(dp(4), dp(10), 0, dp(4))
            })
            organized.text = "整理中…"
            content.addView(organized)
            content.addView(orgStatus)
            val token = tokenCounter
            if (Prefs.smartMode && Prefs.hasAiKey()) {
                host.service.scope.launch {
                    val r = AiClient.generate(AiClient.Action.ORGANIZE, recognized)
                    if (token != tokenCounter) return@launch
                    organizedText = r.text
                    organized.text = r.text
                    orgStatus.text = aiBadge(r.offline, r.error)
                }
            } else {
                organizedText = AiClient.localOrganize(recognized)
                organized.text = organizedText
                orgStatus.text = "离线规则整理"
            }
            content.addView(pill("采用整理后", false) {
                if (organizedText.isNotBlank()) {
                    chosen = organizedText
                    original.text = organizedText
                    host.toast("已采用整理后的文本")
                }
            }, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(38)).apply { topMargin = dp(6) })
        }
        val send = pill("发送", true) {
            host.insertText(chosen)
            host.service.performEditorAction()
            host.closePanel()
        }
        content.addView(actionRow(
            pill("插入") { host.insertText(chosen); host.closePanel() },
            send
        ))
        content.addView(actionRow(
            pill("重试") { host.closePanel(); host.startVoice() },
            pill("取消") { host.closePanel() }
        ))
        val trigger = recognized.contains("发送") || recognized.contains("我说完了") || recognized.contains("over over", true)
        if (trigger && Prefs.getBool(Prefs.K_VOICE_ACTION_ENABLED)) {
            content.addView(TextView(ctx).apply {
                text = "检测到语音口令，可直接发送。"
                textSize = 11f
                setTextColor(pal.primary)
                setPadding(dp(4), dp(8), dp(4), 0)
            })
        }
        show(root)
    }
}
