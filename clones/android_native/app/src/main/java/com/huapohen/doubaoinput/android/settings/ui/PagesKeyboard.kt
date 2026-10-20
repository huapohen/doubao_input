package com.huapohen.doubaoinput.android.settings.ui

import android.content.Context
import android.media.AudioManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ArrowDownward
import androidx.compose.material.icons.outlined.ArrowUpward
import androidx.compose.material.icons.outlined.AutoAwesome
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.EmojiEmotions
import androidx.compose.material.icons.outlined.FormatSize
import androidx.compose.material.icons.outlined.Height
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Palette
import androidx.compose.material.icons.outlined.Spellcheck
import androidx.compose.material.icons.outlined.Speed
import androidx.compose.material.icons.outlined.TextFields
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.material.icons.outlined.Vibration
import androidx.compose.material.icons.outlined.VolumeUp
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.huapohen.doubaoinput.android.core.Prefs

@Composable
fun LayoutPage(rev: Int, onBack: () -> Unit) {
    val context = LocalContext.current
    var candidateSize by remember { mutableIntStateOf(Prefs.candidateFontSize) }
    var keyboardHeight by remember { mutableIntStateOf(if (Prefs.keyboardHeight > 0) Prefs.keyboardHeight else 340) }
    var bottomGap by remember { mutableIntStateOf(Prefs.keyboardBottomGap) }
    var symbols by remember { mutableStateOf(Prefs.sidebarSymbols()) }
    var addSymbol by remember { mutableStateOf(false) }
    ScreenScaffold("布局与显示", "所有修改实时生效", onBack) {
        SectionTitle("候选字")
        Box(
            Modifier.fillMaxWidth().background(MaterialTheme.colorScheme.surface, RoundedCornerShape(18.dp)).padding(16.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                Text("你", fontSize = candidateSize.sp, color = MaterialTheme.colorScheme.onSurface)
                Text("好", fontSize = candidateSize.sp, color = MaterialTheme.colorScheme.onSurface)
                Text("你好", fontSize = candidateSize.sp, color = MaterialTheme.colorScheme.onSurface)
                Text("候选", fontSize = (candidateSize - 4).coerceAtLeast(12).sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        Spacer(Modifier.height(8.dp))
        SettingsSlider(
            "候选字大小",
            candidateSize.toFloat(),
            14f..30f,
            "${candidateSize}sp"
        ) { v ->
            candidateSize = v.toInt()
            Prefs.putInt(Prefs.K_CANDIDATE_FONT_SIZE, candidateSize)
        }
        Spacer(Modifier.height(8.dp))
        SectionTitle("拼音显示位置")
        ChoiceChips(
            listOf("顶部" to "top", "候选栏" to "bottom", "隐藏" to "hidden"),
            Prefs.getString(Prefs.K_PINYIN_LOCATION, "top")
        ) { v ->
            Prefs.putString(Prefs.K_PINYIN_LOCATION, v)
            toast(context, "拼音显示位置已更新")
        }
        Spacer(Modifier.height(8.dp))
        SectionTitle("26 键布局")
        SwitchRow(
            "数字符号合并",
            "关闭后，123 与符号分为两个按键",
            checked = Prefs.getBool(Prefs.K_DIGIT_MERGED, true)
        ) { on ->
            Prefs.putBool(Prefs.K_DIGIT_MERGED, on)
            toast(context, if (on) "数字与符号合并" else "数字与符号分开")
        }
        Spacer(Modifier.height(8.dp))
        SwitchRow(
            "逗号句号分开",
            "关闭时逗号键长按/上滑输入句号",
            checked = Prefs.getBool(Prefs.K_COMMA_PERIOD)
        ) { on ->
            Prefs.putBool(Prefs.K_COMMA_PERIOD, on)
            toast(context, if (on) "逗号句号已分开" else "逗号句号已合并")
        }
        Spacer(Modifier.height(8.dp))
        SectionTitle("中英切换位置")
        ChoiceChips(listOf("左侧" to "left", "右侧" to "right"), Prefs.getString(Prefs.K_ZH_EN_POSITION, "right")) { v ->
            Prefs.putString(Prefs.K_ZH_EN_POSITION, v)
            toast(context, "中英切换已移到${if (v == "left") "左" else "右"}侧")
        }
        Spacer(Modifier.height(10.dp))
        SectionTitle("外观")
        ChoiceChips(
            listOf("跟随系统" to "system", "浅色" to "light", "深色" to "dark"),
            Prefs.themeMode
        ) { v ->
            Prefs.putString(Prefs.K_THEME_MODE, v)
            toast(context, "外观已切换")
        }
        Spacer(Modifier.height(8.dp))
        SwitchRow(
            "上滑输入数字符号",
            "26 键字母上滑输入对应数字/符号",
            icon = Icons.Outlined.TextFields,
            checked = Prefs.getBool(Prefs.K_SLIDE_SYMBOLS, true)
        ) { on ->
            Prefs.putBool(Prefs.K_SLIDE_SYMBOLS, on)
            toast(context, "上滑输入已${if (on) "开启" else "关闭"}")
        }
        Spacer(Modifier.height(8.dp))
        SwitchRow(
            "回车发送",
            "回车动作键优先发送而不是换行",
            icon = Icons.Outlined.Tune,
            checked = Prefs.enterSend
        ) { on ->
            Prefs.putBool(Prefs.K_ENTER_SEND, on)
            toast(context, "回车发送已${if (on) "开启" else "关闭"}")
        }
        Spacer(Modifier.height(10.dp))
        SectionTitle("9 键侧边栏符号", trailing = {
            TextButton(onClick = { addSymbol = true }) { Text("添加", fontSize = 13.sp) }
        })
        GroupCard {
            symbols.forEachIndexed { index, symbol ->
                if (index > 0) DividerLine()
                Row(Modifier.fillMaxWidth().padding(start = 16.dp, end = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(symbol, fontSize = 18.sp, modifier = Modifier.weight(1f))
                    if (index < 4) ValuePill("槽位 ${index + 1}")
                    IconButton(onClick = {
                        if (index > 0) {
                            val list = symbols.toMutableList()
                            val tmp = list[index]; list[index] = list[index - 1]; list[index - 1] = tmp
                            symbols = list; Prefs.setSidebarSymbols(list); toast(context, "已上移")
                        }
                    }) { Icon(Icons.Outlined.ArrowUpward, "上移", tint = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.size(17.dp)) }
                    IconButton(onClick = {
                        if (index < symbols.size - 1) {
                            val list = symbols.toMutableList()
                            val tmp = list[index]; list[index] = list[index + 1]; list[index + 1] = tmp
                            symbols = list; Prefs.setSidebarSymbols(list); toast(context, "已下移")
                        }
                    }) { Icon(Icons.Outlined.ArrowDownward, "下移", tint = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.size(17.dp)) }
                    IconButton(onClick = {
                        if (symbols.size > 1) {
                            val list = symbols.toMutableList(); list.removeAt(index)
                            symbols = list; Prefs.setSidebarSymbols(list); toast(context, "已删除符号")
                        } else toast(context, "至少保留一个符号")
                    }) { Icon(Icons.Outlined.Delete, "删除", tint = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.size(17.dp)) }
                }
            }
        }
        Spacer(Modifier.height(6.dp))
        Text("9 键侧栏使用前 4 个符号；可添加最多 6 个。", fontSize = 10.5.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Spacer(Modifier.height(10.dp))
        SectionTitle("键盘尺寸")
        SettingsSlider("键盘高度", keyboardHeight.toFloat(), 220f..460f, "${keyboardHeight}dp") { v ->
            keyboardHeight = v.toInt()
            Prefs.putInt(Prefs.K_KEYBOARD_HEIGHT, keyboardHeight)
        }
        Spacer(Modifier.height(8.dp))
        SettingsSlider("底部间距", bottomGap.toFloat(), 0f..20f, "${bottomGap}dp") { v ->
            bottomGap = v.toInt()
            Prefs.putInt(Prefs.K_KEYBOARD_BOTTOM_GAP, bottomGap)
        }
        Spacer(Modifier.height(12.dp))
        SecondaryAction("恢复默认布局") {
            listOf(
                Prefs.K_CANDIDATE_FONT_SIZE, Prefs.K_PINYIN_LOCATION, Prefs.K_DIGIT_MERGED,
                Prefs.K_COMMA_PERIOD, Prefs.K_ZH_EN_POSITION, Prefs.K_SLIDE_SYMBOLS,
                Prefs.K_ENTER_SEND, Prefs.K_SIDEBAR_SYMBOLS, Prefs.K_KEYBOARD_HEIGHT,
                Prefs.K_KEYBOARD_BOTTOM_GAP, Prefs.K_THEME_MODE, Prefs.K_ONE_HAND, Prefs.K_FLOATING
            ).forEach { Prefs.sp.edit().remove(it).apply() }
            Prefs.bump()
            candidateSize = Prefs.candidateFontSize
            keyboardHeight = 340
            bottomGap = 0
            symbols = Prefs.sidebarSymbols()
            toast(context, "已恢复默认布局")
        }
    }
    if (addSymbol) {
        TextFieldDialog("添加侧边栏符号", "输入一个符号", onDismiss = { addSymbol = false }) { text, _ ->
            if (symbols.size >= 6) toast(context, "最多 6 个符号") else {
                symbols = symbols + text
                Prefs.setSidebarSymbols(symbols)
                addSymbol = false
                toast(context, "已添加")
            }
        }
    }
}

@Composable
fun FuzzyPinyinPage(rev: Int, onBack: () -> Unit) {
    val context = LocalContext.current
    val initials = listOf("z/zh", "c/ch", "s/sh", "n/l", "f/h", "r/l")
    val finals = listOf("an/ang", "en/eng", "in/ing", "ian/iang", "uan/uang", "un/ong", "eng/ong")
    val syllables = listOf("hui/fei", "huang/wang")
    var initialSet by remember { mutableStateOf(Prefs.getStringSet(Prefs.K_FUZZY_INITIALS)) }
    var finalSet by remember { mutableStateOf(Prefs.getStringSet(Prefs.K_FUZZY_FINALS)) }
    var syllableSet by remember { mutableStateOf(Prefs.getStringSet(Prefs.K_FUZZY_SYLLABLES)) }
    val enabled = Prefs.fuzzyEnabled
    ScreenScaffold("模糊拼音", "按你的口音扩展候选", onBack) {
        SwitchRow(
            "启用模糊拼音",
            "允许相近声母/韵母互相匹配",
            icon = Icons.Outlined.Spellcheck,
            checked = enabled
        ) { on ->
            Prefs.putBool(Prefs.K_FUZZY_ENABLED, on)
            toast(context, "模糊拼音已${if (on) "开启" else "关闭"}")
        }
        Spacer(Modifier.height(10.dp))
        FuzzyGroup(
            title = "声母",
            items = initials,
            selected = initialSet,
            enabled = enabled,
            onAll = {
                initialSet = initials.toSet(); Prefs.putStringSet(Prefs.K_FUZZY_INITIALS, initialSet); toast(context, "已全选声母")
            },
            onClear = {
                initialSet = emptySet(); Prefs.putStringSet(Prefs.K_FUZZY_INITIALS, initialSet); toast(context, "已清空声母")
            },
            onToggle = { item, on ->
                val next = initialSet.toMutableSet()
                if (on) next.add(item) else next.remove(item)
                initialSet = next
                Prefs.putStringSet(Prefs.K_FUZZY_INITIALS, next)
            }
        )
        Spacer(Modifier.height(10.dp))
        FuzzyGroup(
            title = "韵母",
            items = finals,
            selected = finalSet,
            enabled = enabled,
            onAll = { finalSet = finals.toSet(); Prefs.putStringSet(Prefs.K_FUZZY_FINALS, finalSet); toast(context, "已全选韵母") },
            onClear = { finalSet = emptySet(); Prefs.putStringSet(Prefs.K_FUZZY_FINALS, finalSet); toast(context, "已清空韵母") },
            onToggle = { item, on ->
                val next = finalSet.toMutableSet()
                if (on) next.add(item) else next.remove(item)
                finalSet = next
                Prefs.putStringSet(Prefs.K_FUZZY_FINALS, next)
            }
        )
        Spacer(Modifier.height(10.dp))
        FuzzyGroup(
            title = "音节",
            items = syllables,
            selected = syllableSet,
            enabled = enabled,
            onAll = { syllableSet = syllables.toSet(); Prefs.putStringSet(Prefs.K_FUZZY_SYLLABLES, syllableSet); toast(context, "已全选音节") },
            onClear = { syllableSet = emptySet(); Prefs.putStringSet(Prefs.K_FUZZY_SYLLABLES, syllableSet); toast(context, "已清空音节") },
            onToggle = { item, on ->
                val next = syllableSet.toMutableSet()
                if (on) next.add(item) else next.remove(item)
                syllableSet = next
                Prefs.putStringSet(Prefs.K_FUZZY_SYLLABLES, next)
            }
        )
        Spacer(Modifier.height(12.dp))
        InfoNote("模糊规则只扩展候选，不会改变你实际输入的拼音串。关闭总开关后所有规则暂停；选择会立即持久化。")
    }
}

@Composable
private fun FuzzyGroup(
    title: String,
    items: List<String>,
    selected: Set<String>,
    enabled: Boolean,
    onAll: () -> Unit,
    onClear: () -> Unit,
    onToggle: (String, Boolean) -> Unit
) {
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        Text(title, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
        TextButton(onClick = onAll, enabled = enabled) { Text("全选", fontSize = 12.sp) }
        TextButton(onClick = onClear, enabled = enabled) { Text("清空", fontSize = 12.sp) }
    }
    GroupCard {
        items.forEachIndexed { index, item ->
            if (index > 0) DividerLine()
            CheckRow(
                title = item.replace("/", "  =  "),
                checked = item in selected,
                enabled = enabled
            ) { on -> onToggle(item, on) }
        }
    }
}

@Composable
fun AssociationPage(rev: Int, onBack: () -> Unit) {
    val context = LocalContext.current
    ScreenScaffold("智能联想", "根据上文推荐词语与符号", onBack) {
        SwitchRow(
            "智能联想",
            "上屏后推荐可能与上词搭配的内容",
            icon = Icons.Outlined.AutoAwesome,
            checked = Prefs.associationEnabled
        ) { on ->
            Prefs.putBool(Prefs.K_ASSOCIATION, on)
            toast(context, "智能联想已${if (on) "开启" else "关闭"}")
        }
        Spacer(Modifier.height(12.dp))
        SectionTitle("示例")
        GroupCard {
            val pairs = listOf(
                "你好" to listOf("好的", "呀", "吗"),
                "谢谢" to listOf("你", "啦", "！"),
                "今天" to listOf("天气", "晚上", "下午"),
                "工作" to listOf("顺利", "安排", "内容")
            )
            pairs.forEachIndexed { index, (word, next) ->
                if (index > 0) DividerLine()
                Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(word, fontSize = 14.sp, modifier = Modifier.width(60.dp))
                    Text("→", fontSize = 13.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Spacer(Modifier.width(10.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        next.forEach { ValuePill(it) }
                    }
                }
            }
        }
        Spacer(Modifier.height(12.dp))
        InfoNote("联想由本地词库的高频词与最近使用记录生成，不发送输入内容。开启“输入预测类型”还会追加 Emoji、表情图与颜文字候选。")
    }
}

@Composable
fun PredictionPage(rev: Int, onBack: () -> Unit) {
    val context = LocalContext.current
    ScreenScaffold("输入预测类型", "候选栏中的额外推荐", onBack) {
        SwitchRow(
            "Emoji",
            "根据上屏内容推荐一个表情",
            icon = Icons.Outlined.EmojiEmotions,
            checked = Prefs.getBool(Prefs.K_PRED_EMOJI, true)
        ) { on -> Prefs.putBool(Prefs.K_PRED_EMOJI, on); toast(context, "Emoji 预测已${if (on) "开启" else "关闭"}") }
        Spacer(Modifier.height(6.dp))
        Row(
            Modifier.fillMaxWidth().background(MaterialTheme.colorScheme.surface, RoundedCornerShape(14.dp)).padding(14.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            listOf("😊", "👍", "❤️", "🎉", "😂").forEach { Text(it, fontSize = 22.sp) }
        }
        Spacer(Modifier.height(10.dp))
        SwitchRow(
            "图片表情",
            "插入本地彩色表情卡占位 [表情]",
            icon = Icons.Outlined.Palette,
            checked = Prefs.getBool(Prefs.K_PRED_IMAGE)
        ) { on -> Prefs.putBool(Prefs.K_PRED_IMAGE, on); toast(context, "图片表情已${if (on) "开启" else "关闭"}") }
        Spacer(Modifier.height(6.dp))
        Row(
            Modifier.fillMaxWidth().background(MaterialTheme.colorScheme.surface, RoundedCornerShape(14.dp)).padding(14.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            listOf("🎉 恭喜", "🌹 送你花", "☕ 喝咖啡").forEach {
                androidx.compose.material3.Surface(shape = RoundedCornerShape(10.dp), color = MaterialTheme.colorScheme.primary.copy(alpha = 0.08f)) {
                    Text(it, fontSize = 12.sp, color = MaterialTheme.colorScheme.primary, modifier = Modifier.padding(horizontal = 10.dp, vertical = 8.dp))
                }
            }
        }
        Spacer(Modifier.height(10.dp))
        SwitchRow(
            "颜文字",
            "推荐一个分类下的经典颜文字",
            icon = Icons.Outlined.TextFields,
            checked = Prefs.getBool(Prefs.K_PRED_KAOMOJI)
        ) { on -> Prefs.putBool(Prefs.K_PRED_KAOMOJI, on); toast(context, "颜文字预测已${if (on) "开启" else "关闭"}") }
        Spacer(Modifier.height(6.dp))
        Row(
            Modifier.fillMaxWidth().background(MaterialTheme.colorScheme.surface, RoundedCornerShape(14.dp)).padding(14.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            listOf("(｡･ω･｡)", "(*/ω＼*)", "(ง •_•)ง").forEach { Text(it, fontSize = 13.sp) }
        }
        Spacer(Modifier.height(12.dp))
        InfoNote("预测候选显示在空闲候选栏中，点击即可上屏。关闭后不会影响拼音候选与联想词。")
    }
}

@Composable
fun KeyFeedbackPage(rev: Int, onBack: () -> Unit) {
    val context = LocalContext.current
    var volume by remember { mutableIntStateOf(Prefs.getInt(Prefs.K_KEY_SOUND_VOLUME, 60)) }
    ScreenScaffold("按键反馈", "声音、振动与响应", onBack) {
        SectionTitle("响应速度")
        GroupCard {
            RadioRow("跟手优先", "降低绘制开销，适合快速输入", Prefs.getString(Prefs.K_KEY_RESPONSE, "fast") == "fast") {
                Prefs.putString(Prefs.K_KEY_RESPONSE, "fast"); toast(context, "已选择跟手优先")
            }
            DividerLine()
            RadioRow("质量优先", "更精细的键帽与动画", Prefs.getString(Prefs.K_KEY_RESPONSE, "fast") == "quality") {
                Prefs.putString(Prefs.K_KEY_RESPONSE, "quality"); toast(context, "已选择质量优先")
            }
        }
        Spacer(Modifier.height(10.dp))
        SwitchRow(
            "按键声音",
            "按下按键时播放系统点击音",
            icon = Icons.Outlined.VolumeUp,
            checked = Prefs.keySound
        ) { on -> Prefs.putBool(Prefs.K_KEY_SOUND, on); toast(context, "按键声音已${if (on) "开启" else "关闭"}") }
        Spacer(Modifier.height(8.dp))
        SettingsSlider("音量", volume.toFloat(), 0f..100f, "${volume}%") { v ->
            volume = v.toInt(); Prefs.putInt(Prefs.K_KEY_SOUND_VOLUME, volume)
        }
        Spacer(Modifier.height(6.dp))
        SecondaryAction("试听按键音") {
            try {
                val am = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                am.playSoundEffect(AudioManager.FX_KEYPRESS_STANDARD, volume / 100f)
                toast(context, "已播放按键音")
            } catch (t: Throwable) { toast(context, "当前设备无法播放按键音") }
        }
        Spacer(Modifier.height(12.dp))
        SwitchRow(
            "按键振动",
            "按下按键时触发短振动",
            icon = Icons.Outlined.Vibration,
            checked = Prefs.keyVibrate
        ) { on -> Prefs.putBool(Prefs.K_KEY_VIBRATE, on); toast(context, "按键振动已${if (on) "开启" else "关闭"}") }
        Spacer(Modifier.height(8.dp))
        SectionTitle("振动强度")
        ChoiceChips(
            listOf("轻" to "0", "中" to "1", "强" to "2"),
            Prefs.getInt(Prefs.K_KEY_VIBRATE_LEVEL, 1).toString()
        ) { v ->
            Prefs.putInt(Prefs.K_KEY_VIBRATE_LEVEL, v.toInt())
            vibrate(context, v.toInt())
            toast(context, "振动强度已更新")
        }
        Spacer(Modifier.height(6.dp))
        SecondaryAction("试振") { vibrate(context, Prefs.getInt(Prefs.K_KEY_VIBRATE_LEVEL, 1)) }
        Spacer(Modifier.height(12.dp))
        SwitchRow(
            "26 键气泡",
            "长按/上滑时显示键帽气泡",
            icon = Icons.Outlined.Info,
            checked = Prefs.keyBubble
        ) { on -> Prefs.putBool(Prefs.K_KEY_BUBBLE, on); toast(context, "键帽气泡已${if (on) "开启" else "关闭"}") }
        Spacer(Modifier.height(12.dp))
        InfoNote("按键反馈由系统 AudioManager / Vibrator 提供；模拟器可能没有振动马达，试振会给出提示。")
    }
}

private fun vibrate(context: Context, level: Int) {
    try {
        val vibrator = if (Build.VERSION.SDK_INT >= 31) {
            val vm = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            vm?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
        if (vibrator?.hasVibrator() == true) {
            val ms = when (level) { 0 -> 10L; 1 -> 20L; else -> 35L }
            val amp = when (level) { 0 -> 60; 1 -> 130; else -> 230 }
            if (Build.VERSION.SDK_INT >= 26) {
                vibrator.vibrate(VibrationEffect.createOneShot(ms, amp))
            }
            toast(context, "已试振")
        } else toast(context, "当前设备没有振动马达")
    } catch (t: Throwable) {
        toast(context, "振动不可用")
    }
}

@Composable
fun QuickFormatPage(rev: Int, onBack: () -> Unit) {
    val context = LocalContext.current
    ScreenScaffold("快捷格式输入", "让中英数混排更顺手", onBack) {
        SwitchRow(
            "中英数之间加空格",
            "中文与英文/数字相邻时自动补一个空格",
            icon = Icons.Outlined.Spellcheck,
            checked = Prefs.getBool(Prefs.K_QUICK_SPACE, true)
        ) { on -> Prefs.putBool(Prefs.K_QUICK_SPACE, on); toast(context, "中英数空格已${if (on) "开启" else "关闭"}") }
        Spacer(Modifier.height(8.dp))
        SwitchRow(
            "英文首字母大写",
            "句首自动切换大写状态",
            icon = Icons.Outlined.TextFields,
            checked = Prefs.getBool(Prefs.K_QUICK_CAPITALIZE, true)
        ) { on -> Prefs.putBool(Prefs.K_QUICK_CAPITALIZE, on); toast(context, "首字母大写已${if (on) "开启" else "关闭"}") }
        Spacer(Modifier.height(8.dp))
        SwitchRow(
            "双击空格输入句号",
            "英文模式连续两次空格变为 “. ”",
            icon = Icons.Outlined.FormatSize,
            checked = Prefs.getBool(Prefs.K_QUICK_DOUBLE_SPACE, true)
        ) { on -> Prefs.putBool(Prefs.K_QUICK_DOUBLE_SPACE, on); toast(context, "双击空格句号已${if (on) "开启" else "关闭"}") }
        Spacer(Modifier.height(12.dp))
        InfoNote("这些规则只在英文输入或提交文本时生效，不改变中文候选排序。示例：输入 hello 后双击空格 → hello. ")
    }
}
