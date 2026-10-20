package com.huapohen.doubaoinput.android.settings.ui

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
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
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.CloudOff
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Headphones
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Keyboard
import androidx.compose.material.icons.outlined.Mic
import androidx.compose.material.icons.outlined.Spellcheck
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.material.icons.outlined.Wifi
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.huapohen.doubaoinput.android.core.Prefs
import com.huapohen.doubaoinput.android.engine.PinyinEngine
import com.huapohen.doubaoinput.android.engine.WubiData
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

private val defaultActions = listOf("帮我发送", "我说完了", "立即发送", "发送发送", "over over")

@Composable
fun VoiceSettingsPage(rev: Int, onBack: () -> Unit, onNavigate: (Route) -> Unit) {
    val context = LocalContext.current
    ScreenScaffold("语音转文字", "标点、整理与离线语音", onBack) {
        SectionTitle("识别与整理")
        SwitchRow(
            "智能文字整理",
            "识别后自动去口水词、补标点并分段",
            icon = Icons.Outlined.Spellcheck,
            checked = Prefs.getBool(Prefs.K_VOICE_SMART_ORGANIZE, true)
        ) { on ->
            Prefs.putBool(Prefs.K_VOICE_SMART_ORGANIZE, on)
            toast(context, "智能文字整理已${if (on) "开启" else "关闭"}")
        }
        Spacer(Modifier.height(8.dp))
        SectionTitle("分段方式")
        GroupCard {
            RadioRow("分段后空行", "段落之间插入空行", Prefs.getString(Prefs.K_VOICE_SEGMENT, "blank") == "blank") {
                Prefs.putString(Prefs.K_VOICE_SEGMENT, "blank"); toast(context, "已设置为分段后空行")
            }
            DividerLine()
            RadioRow("分段后不空行", "段落之间直接换行", Prefs.getString(Prefs.K_VOICE_SEGMENT, "blank") == "none") {
                Prefs.putString(Prefs.K_VOICE_SEGMENT, "none"); toast(context, "已设置为分段后不空行")
            }
        }
        Spacer(Modifier.height(8.dp))
        SectionTitle("标点展示")
        GroupCard {
            listOf(
                "智能标点" to "smart",
                "无标点" to "none",
                "中文标点" to "zh",
                "英文标点" to "en"
            ).forEachIndexed { index, (label, value) ->
                if (index > 0) DividerLine()
                RadioRow(label, null, Prefs.getString(Prefs.K_VOICE_PUNCTUATION, "smart") == value) {
                    Prefs.putString(Prefs.K_VOICE_PUNCTUATION, value)
                    toast(context, "标点风格：$label")
                }
            }
        }
        Spacer(Modifier.height(8.dp))
        SectionTitle("口水词处理")
        GroupCard {
            RadioRow("正常", "保留少量语气词，更接近原话", Prefs.getString(Prefs.K_VOICE_FILLER, "normal") == "normal") {
                Prefs.putString(Prefs.K_VOICE_FILLER, "normal"); toast(context, "口水词：正常")
            }
            DividerLine()
            RadioRow("激进", "尽量删除“嗯、那个、就是”等词", Prefs.getString(Prefs.K_VOICE_FILLER, "normal") == "aggressive") {
                Prefs.putString(Prefs.K_VOICE_FILLER, "aggressive"); toast(context, "口水词：激进")
            }
        }
        Spacer(Modifier.height(8.dp))
        SectionTitle("语音入口")
        SwitchRow(
            "候选栏语音键",
            "在候选栏与工具条显示语音入口",
            icon = Icons.Outlined.Mic,
            checked = Prefs.getBool(Prefs.K_VOICE_KEY, true)
        ) { on ->
            Prefs.putBool(Prefs.K_VOICE_KEY, on)
            toast(context, "候选栏语音键已${if (on) "显示" else "隐藏"}")
        }
        Spacer(Modifier.height(8.dp))
        SettingRow(
            "语音口令",
            "“帮我发送 / 我说完了 / over over”等",
            icon = Icons.Outlined.Tune,
            showChevron = true,
            onClick = { onNavigate(Route.VoiceAction) }
        )
        Spacer(Modifier.height(8.dp))
        SettingRow(
            "离线语音",
            if (Prefs.getInt(Prefs.K_VOICE_OFFLINE_PROGRESS) >= 100) "已下载（演示）" else "无网也能说话（演示下载）",
            icon = Icons.Outlined.CloudOff,
            showChevron = true,
            onClick = { onNavigate(Route.OfflineVoice) }
        )
        Spacer(Modifier.height(8.dp))
        SwitchRow(
            "WiFi 弱网切换流量",
            "识别不稳定时允许使用移动网络",
            icon = Icons.Outlined.Wifi,
            checked = Prefs.getBool(Prefs.K_VOICE_WIFI, true)
        ) { on ->
            Prefs.putBool(Prefs.K_VOICE_WIFI, on)
            toast(context, "弱网切换流量已${if (on) "开启" else "关闭"}")
        }
        Spacer(Modifier.height(8.dp))
        SwitchRow(
            "耳机麦克风优先",
            "连接耳机时优先使用耳机麦克风",
            icon = Icons.Outlined.Headphones,
            checked = Prefs.getBool(Prefs.K_VOICE_HEADSET, true)
        ) { on ->
            Prefs.putBool(Prefs.K_VOICE_HEADSET, on)
            toast(context, "耳机麦克风已${if (on) "开启" else "关闭"}")
        }
        Spacer(Modifier.height(14.dp))
        InfoNote("语音由 Android SpeechRecognizer 提供。无语音服务或没有网络时会显示明确错误，并可插入示例文本。离线下载为演示进度，不会下载官方 177MB 模型。")
    }
}

@Composable
fun VoiceActionPage(rev: Int, onBack: () -> Unit) {
    val context = LocalContext.current
    var showAdd by remember { mutableStateOf(false) }
    var actions by remember { mutableStateOf(Prefs.getStringSet(Prefs.K_VOICE_ACTIONS, defaultActions.toSet())) }
    ScreenScaffold("语音口令", "说出口令即可执行操作", onBack) {
        SwitchRow(
            "启用语音口令",
            "识别结果命中口令时提示发送",
            checked = Prefs.getBool(Prefs.K_VOICE_ACTION_ENABLED, false)
        ) { on ->
            Prefs.putBool(Prefs.K_VOICE_ACTION_ENABLED, on)
            toast(context, "语音口令已${if (on) "开启" else "关闭"}")
        }
        Spacer(Modifier.height(10.dp))
        SectionTitle("口令列表", trailing = {
            IconButton(onClick = { showAdd = true }) {
                Icon(Icons.Outlined.Add, contentDescription = "添加", tint = MaterialTheme.colorScheme.primary)
            }
        })
        GroupCard {
            actions.forEachIndexed { index, action ->
                if (index > 0) DividerLine()
                Row(Modifier.fillMaxWidth().padding(start = 8.dp, end = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                    androidx.compose.material3.Checkbox(
                        checked = action in actions,
                        onCheckedChange = { on ->
                            val next = actions.toMutableSet()
                            if (on) next.add(action) else next.remove(action)
                            actions = next
                            Prefs.putStringSet(Prefs.K_VOICE_ACTIONS, next)
                            toast(context, "口令已${if (on) "启用" else "停用"}")
                        }
                    )
                    Text(action, fontSize = 14.5.sp, modifier = Modifier.weight(1f))
                    if (action !in defaultActions) {
                        IconButton(onClick = {
                            val next = actions.toMutableSet().apply { remove(action) }
                            actions = next
                            Prefs.putStringSet(Prefs.K_VOICE_ACTIONS, next)
                            toast(context, "已删除自定义口令")
                        }) {
                            Icon(Icons.Outlined.Delete, contentDescription = "删除", tint = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.size(19.dp))
                        }
                    }
                }
            }
        }
        Spacer(Modifier.height(12.dp))
        PrimaryAction("添加自定义口令") { showAdd = true }
        Spacer(Modifier.height(12.dp))
        InfoNote("口令只影响识别结果面板中的发送提示，不会在你未确认时自动发送。复刻版没有云端口令模型，匹配为本地规则。")
    }
    if (showAdd) {
        TextFieldDialog(
            title = "添加语音口令",
            label = "口令文本",
            onDismiss = { showAdd = false },
            onConfirm = { text, _ ->
                val next = actions.toMutableSet().apply { add(text) }
                actions = next
                Prefs.putStringSet(Prefs.K_VOICE_ACTIONS, next)
                showAdd = false
                toast(context, "已添加入口")
            }
        )
    }
}

@Composable
fun OfflineVoicePage(rev: Int, onBack: () -> Unit) {
    val context = LocalContext.current
    var progress by remember { mutableIntStateOf(Prefs.getInt(Prefs.K_VOICE_OFFLINE_PROGRESS)) }
    var downloading by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    ScreenScaffold("离线语音", "演示下载 · 实际识别依赖系统服务", onBack) {
        Column(
            Modifier.fillMaxWidth().background(MaterialTheme.colorScheme.surface, RoundedCornerShape(18.dp)).padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            androidx.compose.foundation.layout.Box(
                Modifier.size(64.dp).background(MaterialTheme.colorScheme.primary.copy(alpha = 0.1f), CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Icon(Icons.Outlined.CloudOff, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(30.dp))
            }
            Spacer(Modifier.height(10.dp))
            Text(
                when {
                    downloading -> "正在下载离线语音包…"
                    progress >= 100 -> "离线语音包已下载（演示）"
                    progress > 0 -> "已下载 $progress%（演示）"
                    else -> "下载离线语音包"
                },
                fontSize = 16.sp,
                fontWeight = FontWeight.Medium
            )
            Text(
                "参考体积 177 MB · 复刻版不会下载官方模型文件",
                fontSize = 11.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(top = 4.dp)
            )
            Spacer(Modifier.height(14.dp))
            if (progress > 0) {
                LinearProgressIndicator(
                    progress = { progress / 100f },
                    modifier = Modifier.fillMaxWidth().height(8.dp).clip(RoundedCornerShape(4.dp))
                )
                Spacer(Modifier.height(6.dp))
                Text("$progress%", fontSize = 12.sp, color = MaterialTheme.colorScheme.primary)
            }
            Spacer(Modifier.height(14.dp))
            PrimaryAction(
                when {
                    downloading -> "下载中…"
                    progress >= 100 -> "重新下载"
                    else -> "开始下载（演示）"
                },
                enabled = !downloading
            ) {
                if (!downloading) {
                    downloading = true
                    scope.launch {
                        progress = 0
                        while (progress < 100) {
                            delay(90)
                            progress = (progress + 4).coerceAtMost(100)
                        }
                        Prefs.putInt(Prefs.K_VOICE_OFFLINE_PROGRESS, 100)
                        downloading = false
                        toast(context, "离线语音演示包已就绪")
                    }
                }
            }
            if (progress >= 100) {
                Spacer(Modifier.height(8.dp))
                SecondaryAction("删除离线包") {
                    progress = 0
                    Prefs.putInt(Prefs.K_VOICE_OFFLINE_PROGRESS, 0)
                    toast(context, "已删除离线包（演示）")
                }
            }
        }
        Spacer(Modifier.height(14.dp))
        SwitchRow(
            "WiFi 弱网切换流量",
            "网络较差时允许使用蜂窝网络",
            icon = Icons.Outlined.Wifi,
            checked = Prefs.getBool(Prefs.K_VOICE_WIFI, true)
        ) { on -> Prefs.putBool(Prefs.K_VOICE_WIFI, on); toast(context, "已${if (on) "开启" else "关闭"}弱网切换流量") }
        Spacer(Modifier.height(8.dp))
        SwitchRow(
            "耳机麦克风优先",
            "连接耳机时使用耳机麦克风",
            icon = Icons.Outlined.Headphones,
            checked = Prefs.getBool(Prefs.K_VOICE_HEADSET, true)
        ) { on -> Prefs.putBool(Prefs.K_VOICE_HEADSET, on); toast(context, "已${if (on) "开启" else "关闭"}耳机麦克风") }
        Spacer(Modifier.height(12.dp))
        InfoNote("说明：本页下载进度为本地模拟，不会下载或包含官方离线语音模型。若设备提供系统语音识别，语音输入在无本页离线包时仍可能可用；否则会显示错误与示例文本。")
    }
}

@Composable
fun KeyboardTypesPage(rev: Int, onBack: () -> Unit, onNavigate: (Route) -> Unit) {
    val context = LocalContext.current
    ScreenScaffold("键盘类型", "切换后键盘立即生效", onBack) {
        KeyboardTypeCards(selected = Prefs.keyboardType) { type ->
            Prefs.putString(Prefs.K_KEYBOARD_TYPE, type)
            Prefs.putBool(Prefs.K_KEYBOARD_TYPE_CHOSEN, true)
            toast(context, "已切换到${keyboardTypeLabel(type)}")
        }
        Spacer(Modifier.height(16.dp))
        SettingRow(
            "双拼设置",
            "小鹤 / 自然码；9 键双拼敬请期待",
            icon = Icons.Outlined.Tune,
            showChevron = true,
            onClick = { onNavigate(Route.DoublePinyin) }
        )
        Spacer(Modifier.height(8.dp))
        SettingRow(
            "五笔设置",
            "86 版、编码提示、拼音混输",
            icon = Icons.Outlined.Keyboard,
            showChevron = true,
            onClick = { onNavigate(Route.Wubi) }
        )
        Spacer(Modifier.height(12.dp))
        InfoNote("26 键与 9 键使用各自独立布局。手写、笔画与五笔为演示级实现：手写为形状模板匹配，笔画/五笔词表覆盖常用字，适合验证交互而非替代完整引擎。双拼按小鹤/自然码规则转换后复用本地拼音词库。")
    }
}

@Composable
fun DoublePinyinPage(rev: Int, onBack: () -> Unit) {
    val context = LocalContext.current
    val scheme = Prefs.getString(Prefs.K_DOUBLE_PINYIN, "xiaohe")
    var code by remember { mutableStateOf("nihc") }
    val converted = remember(code, scheme) { PinyinEngine.shuangpinToPinyin(code, scheme) }
    ScreenScaffold("双拼设置", "小鹤 / 自然码", onBack) {
        SectionTitle("方案")
        GroupCard {
            RadioRow("小鹤双拼", "zh=v ch=i sh=u，韵母按小鹤键位", scheme == "xiaohe") {
                Prefs.putString(Prefs.K_DOUBLE_PINYIN, "xiaohe"); toast(context, "已选择小鹤双拼")
            }
            DividerLine()
            RadioRow("自然码双拼", "zh=v ch=i sh=u，韵母按自然码键位", scheme == "ziran") {
                Prefs.putString(Prefs.K_DOUBLE_PINYIN, "ziran"); toast(context, "已选择自然码双拼")
            }
            DividerLine()
            RadioRow("9 键双拼", "敬请期待", false, enabled = false) {}
        }
        Spacer(Modifier.height(12.dp))
        SectionTitle("实时转换")
        OutlinedTextField(
            value = code,
            onValueChange = { code = it.take(24) },
            label = { Text("双拼编码") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(Modifier.height(8.dp))
        SurfaceHint("转换为：${converted.ifBlank { "—" }}")
        Spacer(Modifier.height(12.dp))
        InfoNote("示例：小鹤输入 nihc → ni hao，再从本地词库取候选。双拼与拼音共享 MRU 与个性词库；尚未实现 9 键双拼。")
    }
}

@Composable
private fun SurfaceHint(text: String) {
    androidx.compose.material3.Surface(
        shape = RoundedCornerShape(12.dp),
        color = MaterialTheme.colorScheme.primary.copy(alpha = 0.08f),
        modifier = Modifier.fillMaxWidth()
    ) {
        Text(text, fontSize = 14.sp, color = MaterialTheme.colorScheme.primary, modifier = Modifier.padding(14.dp))
    }
}

@Composable
fun WubiPage(rev: Int, onBack: () -> Unit) {
    val context = LocalContext.current
    var code by remember { mutableStateOf("wqvb") }
    val results = remember(code) { WubiData.lookup(code, 12) }
    ScreenScaffold("五笔设置", "86 版 · 演示码表", onBack) {
        SectionTitle("方案")
        GroupCard {
            RadioRow("86 版五笔", "常用字演示码表（${WubiData.size()} 条）", true) {}
        }
        Spacer(Modifier.height(8.dp))
        SwitchRow("编码提示", "键盘上方显示当前编码与候选", checked = Prefs.getBool(Prefs.K_WUBI_HINT, true)) {
            Prefs.putBool(Prefs.K_WUBI_HINT, it); toast(context, "编码提示已${if (it) "开启" else "关闭"}")
        }
        Spacer(Modifier.height(8.dp))
        SwitchRow("拼音混输", "五笔无候选时按拼音查找", checked = Prefs.getBool(Prefs.K_WUBI_MIX, true)) {
            Prefs.putBool(Prefs.K_WUBI_MIX, it); toast(context, "拼音混输已${if (it) "开启" else "关闭"}")
        }
        Spacer(Modifier.height(8.dp))
        SwitchRow("四码唯一上屏", "四码唯一候选时自动上屏", checked = Prefs.getBool(Prefs.K_WUBI_UNIQUE, true)) {
            Prefs.putBool(Prefs.K_WUBI_UNIQUE, it); toast(context, "四码唯一已${if (it) "开启" else "关闭"}")
        }
        Spacer(Modifier.height(8.dp))
        SwitchRow("第五码首选上屏", "第五码按下时首选上屏", checked = Prefs.getBool(Prefs.K_WUBI_FIFTH, false)) {
            Prefs.putBool(Prefs.K_WUBI_FIFTH, it); toast(context, "第五码首选已${if (it) "开启" else "关闭"}")
        }
        Spacer(Modifier.height(12.dp))
        SectionTitle("码表试用")
        OutlinedTextField(
            value = code,
            onValueChange = { code = it.lowercase().filter { c -> c in 'a'..'z' }.take(5) },
            label = { Text("五笔编码，如 wqvb") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(Modifier.height(8.dp))
        if (results.isEmpty()) {
            Text("无匹配。试试 wqvb（你好）、trnt（我）、khlg（中国）。", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
        } else {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
                results.take(6).forEach { (c, ch) ->
                    androidx.compose.material3.Surface(
                        shape = RoundedCornerShape(10.dp),
                        color = MaterialTheme.colorScheme.surface,
                        modifier = Modifier.weight(1f)
                    ) {
                        Column(
                            Modifier.padding(vertical = 10.dp).fillMaxWidth(),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Text(ch, fontSize = 20.sp, fontWeight = FontWeight.Medium)
                            Text(c, fontSize = 9.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                }
                repeat(6 - minOf(6, results.size)) { Spacer(Modifier.weight(1f)) }
            }
        }
        Spacer(Modifier.height(12.dp))
        InfoNote("五笔码表为净室整理的常用字演示（约 ${WubiData.size()} 条），不包含官方词库。完整五笔输入需要更大的码表，可在后续版本替换。")
    }
}
