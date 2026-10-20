package com.huapohen.doubaoinput.android.settings.ui

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.inputmethod.InputMethodManager
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ArrowForward
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.ContentCopy
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Keyboard
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.OpenInNew
import androidx.compose.material.icons.outlined.PhoneAndroid
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material.icons.outlined.SupportAgent
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import com.huapohen.doubaoinput.android.BuildConfig
import com.huapohen.doubaoinput.android.core.ClipboardRepo
import com.huapohen.doubaoinput.android.core.FeedbackRepo
import com.huapohen.doubaoinput.android.core.Prefs
import com.huapohen.doubaoinput.android.engine.PinyinEngine
import com.huapohen.doubaoinput.android.ime.DoubaoImeService
import com.huapohen.doubaoinput.android.settings.MainActivity
import kotlinx.coroutines.delay

@Composable
fun DesktopPage(rev: Int, onBack: () -> Unit) {
    val context = LocalContext.current
    val url = "https://shurufa.doubao.com/pc"
    ScreenScaffold("电脑版", "macOS / Windows 说明", onBack) {
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            DesktopCard("macOS", "菜单栏与系统输入法", "⌘", Modifier.weight(1f))
            DesktopCard("Windows", "候选窗口与皮肤", "⊞", Modifier.weight(1f))
        }
        Spacer(Modifier.height(12.dp))
        Surface(shape = RoundedCornerShape(18.dp), color = MaterialTheme.colorScheme.surface, modifier = Modifier.fillMaxWidth()) {
            Column(Modifier.padding(18.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                Text("在电脑上体验豆包输入法", fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
                Text(
                    "当前复刻仅提供 Android 端。电脑端为官方独立产品，本复刻未包含其安装包，也不提供下载镜像。",
                    fontSize = 11.5.sp,
                    lineHeight = 17.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(top = 6.dp)
                )
                Spacer(Modifier.height(14.dp))
                Box(
                    Modifier.size(190.dp).background(Color.White, RoundedCornerShape(16.dp)).padding(12.dp),
                    contentAlignment = Alignment.Center
                ) { QrPattern(Prefs.did + "desktop", Modifier.fillMaxWidth().height(160.dp)) }
                Text("二维码为本地生成占位，不代表官方下载地址", fontSize = 9.5.sp, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(top = 6.dp))
            }
        }
        Spacer(Modifier.height(12.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            androidx.compose.material3.Button(
                onClick = {
                    val cm = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                    cm.setPrimaryClip(ClipData.newPlainText("豆包输入法官网", url))
                    ClipboardRepo.add(url)
                    toast(context, "官网地址已复制")
                },
                modifier = Modifier.weight(1f).height(46.dp),
                shape = RoundedCornerShape(12.dp)
            ) { Text("复制官网地址", fontSize = 13.sp) }
            androidx.compose.material3.OutlinedButton(
                onClick = {
                    try {
                        context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                    } catch (t: Throwable) { toast(context, "没有可用的浏览器") }
                },
                modifier = Modifier.weight(1f).height(46.dp),
                shape = RoundedCornerShape(12.dp)
            ) { Text("在浏览器打开", fontSize = 13.sp) }
        }
        Spacer(Modifier.height(12.dp))
        InfoNote("“电脑版”页面仅用于说明与互操作研究。链接指向官方 PC 页面，但本复刻与官方无关联，也不会下载或分发官方安装包。")
    }
}

@Composable
private fun DesktopCard(title: String, subtitle: String, glyph: String, modifier: Modifier = Modifier) {
    Surface(shape = RoundedCornerShape(18.dp), color = MaterialTheme.colorScheme.surface, modifier = modifier) {
        Column(Modifier.padding(14.dp)) {
            Box(
                Modifier.fillMaxWidth().height(70.dp).background(
                    Brush.linearGradient(listOf(Color(0xFF2C3E50), Color(0xFF4CA1AF))),
                    RoundedCornerShape(12.dp)
                ),
                contentAlignment = Alignment.Center
            ) { Text(glyph, color = Color.White, fontSize = 30.sp) }
            Spacer(Modifier.height(8.dp))
            Text(title, fontSize = 15.sp, fontWeight = FontWeight.Medium)
            Text(subtitle, fontSize = 10.5.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(Modifier.height(4.dp))
            ValuePill("开发中（演示）")
        }
    }
}

private data class Faq(val q: String, val a: String)

@Composable
fun HelpFeedbackPage(rev: Int, onBack: () -> Unit) {
    val context = LocalContext.current
    var expanded by remember { mutableIntStateOf(-1) }
    var type by remember { mutableStateOf("问题") }
    var text by remember { mutableStateOf("") }
    var contact by remember { mutableStateOf("") }
    var refresh by remember { mutableIntStateOf(0) }
    val faqs = listOf(
        Faq("如何启用并切换到复刻输入法？", "打开系统设置 → 系统 → 输入法，启用“豆包输入法（原生复刻）”，再在输入法选择器中选择它。也可在应用首次引导中完成。"),
        Faq("为什么没有候选或候选很少？", "候选来自内置 33,500 条拼音词库。请确认当前是中文模式、键盘类型正确；个人词库中未填写拼音的词条不会产生候选。"),
        Faq("语音提示“请连接网络后再试”怎么办？", "语音由系统 SpeechRecognizer 提供，模拟器可能缺少语音服务或网络。可安装系统语音服务，或在结果页使用示例文本。"),
        Faq("AI 写作没有结果？", "请到“设置 → AI 服务”填写 OpenAI 兼容的 Base URL、模型和 API Key，并点击测试连接。未配置 Key 时会返回“离线示例”。"),
        Faq("我的输入会上传吗？", "键盘输入与候选默认在本机处理。只有你主动触发语音或 AI 时才可能联网；基础输入模式下全部离线。"),
        Faq("平板/横屏如何适配？", "设置页在宽屏使用居中最大宽度与导航栏；键盘最大宽度 960dp 并居中，横屏自动缩短键盘高度。")
    )
    ScreenScaffold("帮助与反馈", "常见问题与本地反馈", onBack) {
        SectionTitle("常见问题")
        GroupCard {
            faqs.forEachIndexed { index, faq ->
                if (index > 0) DividerLine()
                Column(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp)) {
                    Row(
                        Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(faq.q, fontSize = 14.sp, fontWeight = FontWeight.Medium, modifier = Modifier.weight(1f))
                        TextButton(onClick = { expanded = if (expanded == index) -1 else index }) {
                            Text(if (expanded == index) "收起" else "展开", fontSize = 11.5.sp)
                        }
                    }
                    if (expanded == index) {
                        Text(faq.a, fontSize = 12.5.sp, lineHeight = 19.sp, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(top = 2.dp))
                    }
                }
            }
        }
        Spacer(Modifier.height(14.dp))
        SectionTitle("提交反馈")
        ChoiceChips(listOf("问题" to "问题", "建议" to "建议", "其他" to "其他"), type) { type = it }
        Spacer(Modifier.height(6.dp))
        OutlinedTextField(
            value = text,
            onValueChange = { text = it.take(1000) },
            label = { Text("问题或建议") },
            minLines = 4,
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(Modifier.height(8.dp))
        OutlinedTextField(
            value = contact,
            onValueChange = { contact = it.take(80) },
            label = { Text("联系方式（可选）") },
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(Modifier.height(10.dp))
        PrimaryAction("提交反馈") {
            if (text.isBlank()) toast(context, "请填写反馈内容") else {
                FeedbackRepo.add(type, text.trim(), contact.trim())
                text = ""
                refresh++
                toast(context, "反馈已保存在本机")
            }
        }
        Spacer(Modifier.height(8.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            androidx.compose.material3.OutlinedButton(
                onClick = {
                    val info = "豆包输入法（原生复刻） ${BuildConfig.VERSION_NAME}\n设备：${Build.MODEL}\nAndroid：${Build.VERSION.RELEASE}\n输入法已启用：${isImeEnabled(context)}\n词库：${PinyinEngine.entryCount} 条"
                    val cm = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                    cm.setPrimaryClip(ClipData.newPlainText("诊断信息", info))
                    toast(context, "诊断信息已复制")
                },
                modifier = Modifier.weight(1f).height(44.dp),
                shape = RoundedCornerShape(12.dp)
            ) { Text("复制诊断信息", fontSize = 12.5.sp) }
            androidx.compose.material3.OutlinedButton(
                onClick = {
                    try {
                        context.startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).setData(Uri.parse("package:" + context.packageName)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                    } catch (t: Throwable) { toast(context, "无法打开设置") }
                },
                modifier = Modifier.weight(1f).height(44.dp),
                shape = RoundedCornerShape(12.dp)
            ) { Text("应用信息", fontSize = 12.5.sp) }
        }
        Spacer(Modifier.height(14.dp))
        val feedback = FeedbackRepo.all()
        SectionTitle("我的反馈（${feedback.size}）")
        if (feedback.isEmpty()) {
            EmptyState("暂无反馈", "提交后反馈会保存在本机，便于复盘。")
        } else {
            feedback.take(20).forEach { f ->
                Surface(shape = RoundedCornerShape(14.dp), color = MaterialTheme.colorScheme.surface, modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp)) {
                    Row(Modifier.padding(start = 14.dp, top = 10.dp, end = 4.dp, bottom = 10.dp), verticalAlignment = Alignment.CenterVertically) {
                        Column(Modifier.weight(1f)) {
                            Text("${f.type} · ${fmtDate(f.ts)}", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            Text(f.text.take(160), fontSize = 13.sp, maxLines = 2)
                        }
                        IconButton(onClick = { FeedbackRepo.delete(f.id); refresh++; toast(context, "已删除反馈") }) {
                            Icon(Icons.Outlined.Delete, "删除", tint = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.size(18.dp))
                        }
                    }
                }
            }
        }
        Spacer(Modifier.height(12.dp))
        InfoNote("反馈只保存在本机，不会自动发送到官方客服或任何服务器。真正的线上反馈需要你提供可替换后端（见项目 README）。")
    }
    if (refresh < 0) Text("")
}

private fun fmtDate(ts: Long): String =
    java.text.SimpleDateFormat("MM-dd HH:mm", java.util.Locale.CHINA).format(java.util.Date(ts))

@Composable
fun AboutPage(rev: Int, onBack: () -> Unit, onNavigate: (Route) -> Unit) {
    val context = LocalContext.current
    var engineCount by remember { mutableIntStateOf(PinyinEngine.entryCount) }
    LaunchedEffect(Unit) {
        kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.IO) {
            PinyinEngine.ensureLoaded(context)
            PinyinEngine.awaitLoaded(3000)
        }
        engineCount = PinyinEngine.entryCount
    }
    ScreenScaffold("关于", "非官方净室复刻", onBack) {
        Column(Modifier.fillMaxWidth().padding(vertical = 14.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Box(
                Modifier.size(76.dp).background(Brush.linearGradient(listOf(Color(0xFF4F84FF), Color(0xFF3051F2))), RoundedCornerShape(20.dp)),
                contentAlignment = Alignment.Center
            ) { Text("豆", color = Color.White, fontSize = 34.sp, fontWeight = FontWeight.Bold) }
            Spacer(Modifier.height(10.dp))
            Text("豆包输入法（原生复刻）", fontSize = 20.sp, fontWeight = FontWeight.SemiBold)
            Text("版本 ${BuildConfig.VERSION_NAME} · build 20261020", fontSize = 11.5.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(Modifier.height(4.dp))
            ValuePill("非官方 · 仅供互操作性研究")
        }
        SectionTitle("应用")
        GroupCard {
            KeyValueRow("包名", "com.huapohen.doubaoinput.android")
            DividerLine()
            KeyValueRow("最低系统", "Android 8.0（API 26）")
            DividerLine()
            KeyValueRow("目标系统", "Android 16（API 36）")
            DividerLine()
            KeyValueRow("本地词库", "$engineCount 条")
            DividerLine()
            Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text("设备标识 DID", fontSize = 13.sp)
                    Text(Prefs.did, fontSize = 10.sp, color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 1)
                }
                IconButton(onClick = {
                    val cm = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                    cm.setPrimaryClip(ClipData.newPlainText("DID", Prefs.did))
                    toast(context, "DID 已复制")
                }) { Icon(Icons.Outlined.ContentCopy, "复制", tint = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.size(18.dp)) }
            }
        }
        Spacer(Modifier.height(8.dp))
        SettingRow(
            "检查更新",
            "当前版本 ${BuildConfig.VERSION_NAME}",
            icon = Icons.Outlined.Refresh,
            showChevron = true,
            onClick = { toast(context, "已是最新复刻版本（演示检查）") }
        )
        Spacer(Modifier.height(8.dp))
        SectionTitle("协议与许可")
        GroupCard {
            listOf(
                "用户协议" to "agreement",
                "隐私政策" to "privacy",
                "系统权限清单" to "permissions",
                "开源许可与数据来源" to "licenses"
            ).forEachIndexed { index, (label, kind) ->
                if (index > 0) DividerLine()
                Row(
                    Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 13.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(label, fontSize = 14.sp, modifier = Modifier.weight(1f))
                    TextButton(onClick = { onNavigate(Route.Doc(kind)) }) { Text("查看", fontSize = 12.sp) }
                }
            }
        }
        Spacer(Modifier.height(12.dp))
        InfoNote("本应用不含官方 APK/DEX/SO、皮肤 XML、字体、图片、音频、Lottie 或词典二进制，也不请求豆包官方私有接口。“豆包”及相关标识归其权利人所有。")
        Spacer(Modifier.height(8.dp))
        TextButton(onClick = { toast(context, "项目以开源仓库形式提供；请查看 README 的构建与替换后端说明") }, modifier = Modifier.fillMaxWidth()) {
            Text("项目与替换后端说明", fontSize = 12.5.sp)
        }
    }
}

@Composable
fun KeyboardDemoPage(rev: Int, onBack: () -> Unit) {
    val context = LocalContext.current
    var text by remember { mutableStateOf("") }
    var refresh by remember { mutableIntStateOf(0) }
    val focusRequester = remember { FocusRequester() }
    val lifecycle = LocalLifecycleOwner.current
    DisposableEffect(lifecycle) {
        val obs = LifecycleEventObserver { _, event -> if (event == Lifecycle.Event.ON_RESUME) refresh++ }
        lifecycle.lifecycle.addObserver(obs)
        onDispose { lifecycle.lifecycle.removeObserver(obs) }
    }
    val enabled = remember(refresh) { isImeEnabled(context) }
    val selected = remember(refresh) { isImeDefault(context) }
    LaunchedEffect(Unit) {
        delay(350)
        try { focusRequester.requestFocus() } catch (t: Throwable) { }
    }
    ScreenScaffold("键盘试用", "完整系统键盘 · 工具面板", onBack) {
        Surface(shape = RoundedCornerShape(18.dp), color = MaterialTheme.colorScheme.surface, modifier = Modifier.fillMaxWidth()) {
            Column(Modifier.padding(16.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(if (enabled) Icons.Outlined.CheckCircle else Icons.Outlined.Info, null, tint = if (enabled) Color(0xFF1FA971) else MaterialTheme.colorScheme.primary, modifier = Modifier.size(22.dp))
                    Spacer(Modifier.width(8.dp))
                    Column {
                        Text(if (enabled) "输入法已启用" else "输入法尚未启用", fontSize = 15.sp, fontWeight = FontWeight.Medium)
                        Text(if (selected) "当前为默认输入法" else "可能需要在系统中选择一次", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
                Spacer(Modifier.height(12.dp))
                OutlinedTextField(
                    value = text,
                    onValueChange = { text = it },
                    label = { Text("点这里，底部会弹出系统键盘") },
                    minLines = 3,
                    modifier = Modifier.fillMaxWidth().focusRequester(focusRequester)
                )
                Spacer(Modifier.height(8.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    androidx.compose.material3.Button(
                        onClick = { try { focusRequester.requestFocus() } catch (t: Throwable) { } },
                        modifier = Modifier.weight(1f).height(44.dp),
                        shape = RoundedCornerShape(12.dp)
                    ) { Text("调起键盘", fontSize = 13.sp) }
                    androidx.compose.material3.OutlinedButton(
                        onClick = { text = "" },
                        modifier = Modifier.weight(1f).height(44.dp),
                        shape = RoundedCornerShape(12.dp)
                    ) { Text("清空", fontSize = 13.sp) }
                }
            }
        }
        Spacer(Modifier.height(12.dp))
        SectionTitle("键盘预览")
        KeyboardMock(appDark(), Modifier.fillMaxWidth())
        Spacer(Modifier.height(12.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            androidx.compose.material3.Button(
                onClick = {
                    try { context.startActivity(Intent(Settings.ACTION_INPUT_METHOD_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) } catch (t: Throwable) { toast(context, "无法打开设置") }
                },
                modifier = Modifier.weight(1f).height(44.dp),
                shape = RoundedCornerShape(12.dp)
            ) { Text("输入法设置", fontSize = 12.5.sp) }
            androidx.compose.material3.OutlinedButton(
                onClick = {
                    val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
                    imm.showInputMethodPicker()
                },
                modifier = Modifier.weight(1f).height(44.dp),
                shape = RoundedCornerShape(12.dp)
            ) { Text("选择输入法", fontSize = 12.5.sp) }
        }
        Spacer(Modifier.height(8.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            androidx.compose.material3.OutlinedButton(
                onClick = {
                    context.startActivity(
                        Intent(context, MainActivity::class.java)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                            .putExtra(DoubaoImeService.EXTRA_ROUTE, "keyboard_types")
                    )
                },
                modifier = Modifier.weight(1f).height(44.dp),
                shape = RoundedCornerShape(12.dp)
            ) { Text("键盘类型", fontSize = 12.5.sp) }
            androidx.compose.material3.OutlinedButton(
                onClick = {
                    context.startActivity(
                        Intent(context, MainActivity::class.java)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                            .putExtra(DoubaoImeService.EXTRA_ROUTE, "layout")
                    )
                },
                modifier = Modifier.weight(1f).height(44.dp),
                shape = RoundedCornerShape(12.dp)
            ) { Text("布局调节", fontSize = 12.5.sp) }
        }
        Spacer(Modifier.height(12.dp))
        InfoNote("键盘弹出后可使用工具条的 13 个入口：语音、表情、键盘选择、智能整理、常用语、剪切板、定制工具栏、手写找字、翻译、单手、键盘调节、更多设置、帮助；第二页还有悬浮键盘。长按空格可直接进入语音。")
        Spacer(Modifier.height(10.dp))
        SettingRow(
            "打开输入模式设置",
            if (Prefs.smartMode) "当前：智能输入模式" else "当前：基础输入模式",
            icon = Icons.Outlined.Lock,
            showChevron = true,
            onClick = {
                context.startActivity(
                    Intent(context, MainActivity::class.java)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                        .putExtra(DoubaoImeService.EXTRA_ROUTE, "input_mode")
                )
            }
        )
    }
}

@Composable
fun DocumentPage(kind: String, onBack: () -> Unit) {
    val (title, body) = Docs.forKind(kind)
    ScreenScaffold(title, "最后更新：2026-10-20", onBack) {
        SelectionContainer {
            Column {
                body.split("\n\n").forEach { paragraph ->
                    Text(
                        paragraph,
                        fontSize = 14.sp,
                        lineHeight = 23.sp,
                        color = MaterialTheme.colorScheme.onSurface,
                        modifier = Modifier.padding(bottom = 12.dp)
                    )
                }
                Text(
                    "本文档为本复刻原创文本，不代表豆包官方条款。",
                    fontSize = 10.5.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(top = 8.dp, bottom = 20.dp)
                )
            }
        }
    }
}
