package com.huapohen.doubaoinput.android.settings.ui

import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.view.inputmethod.InputMethodManager
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.Keyboard
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.Mic
import androidx.compose.material.icons.outlined.Security
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import com.huapohen.doubaoinput.android.core.Prefs
import com.huapohen.doubaoinput.android.ime.DoubaoImeService
import com.huapohen.doubaoinput.android.settings.MainActivity

object NavBus {
    var pending by mutableStateOf<String?>(null)
    fun open(route: String) { pending = route }
}

sealed interface Route {
    data object Home : Route
    data object Voice : Route
    data object VoiceAction : Route
    data object OfflineVoice : Route
    data object KeyboardTypes : Route
    data object DoublePinyin : Route
    data object Wubi : Route
    data object Layout : Route
    data object Fuzzy : Route
    data object Association : Route
    data object Prediction : Route
    data object KeyFeedback : Route
    data object QuickFormat : Route
    data object ClipboardSettings : Route
    data object Lexicon : Route
    data object InputMode : Route
    data object SmartInput : Route
    data object Permissions : Route
    data object SuperTransfer : Route
    data object Account : Route
    data object Login : Route
    data object Messages : Route
    data object Desktop : Route
    data object Help : Route
    data object About : Route
    data object AiService : Route
    data object AuxInput : Route
    data object KeyboardDemo : Route
    data class Doc(val kind: String) : Route
    data class MessageDetail(val id: String) : Route
}

fun routeFromName(name: String?): Route? = when (name) {
    null, "", "home" -> null
    "voice" -> Route.Voice
    "voice_action" -> Route.VoiceAction
    "offline_voice" -> Route.OfflineVoice
    "keyboard_types" -> Route.KeyboardTypes
    "double_pinyin" -> Route.DoublePinyin
    "wubi" -> Route.Wubi
    "layout" -> Route.Layout
    "fuzzy" -> Route.Fuzzy
    "association" -> Route.Association
    "prediction" -> Route.Prediction
    "feedback_keys" -> Route.KeyFeedback
    "quick_format" -> Route.QuickFormat
    "clipboard" -> Route.ClipboardSettings
    "lexicon" -> Route.Lexicon
    "input_mode" -> Route.InputMode
    "smart_input" -> Route.SmartInput
    "permissions" -> Route.Permissions
    "super_transfer" -> Route.SuperTransfer
    "account" -> Route.Account
    "login" -> Route.Login
    "messages" -> Route.Messages
    "desktop" -> Route.Desktop
    "help" -> Route.Help
    "about" -> Route.About
    "ai" -> Route.AiService
    "aux" -> Route.AuxInput
    "keyboard_demo" -> Route.KeyboardDemo
    "doc_privacy" -> Route.Doc("privacy")
    "doc_agreement" -> Route.Doc("agreement")
    "doc_permissions" -> Route.Doc("permissions")
    "doc_licenses" -> Route.Doc("licenses")
    else -> null
}

@Composable
fun DoubaoCloneApp(initialRoute: String?) {
    val rev = Prefs.revision
    val dark = appDark()
    DoubaoTheme(dark) {
        Box(Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background)) {
            val onboardingDone = Prefs.onboardingDone
            val privacyDone = Prefs.privacyDone
            val keyboardChosen = Prefs.getBool(Prefs.K_KEYBOARD_TYPE_CHOSEN)
            when {
                !onboardingDone -> OnboardingScreen(
                    onFinished = {
                        Prefs.putBool(Prefs.K_ONBOARDING_DONE, true)
                        Prefs.bump()
                    }
                )
                !privacyDone -> PrivacyScreen(
                    onFinished = { mode ->
                        Prefs.putString(Prefs.K_PRIVACY_MODE, mode)
                        Prefs.putBool(Prefs.K_PRIVACY_DONE, true)
                        Prefs.bump()
                    }
                )
                !keyboardChosen -> FirstRunKeyboard(
                    onSelected = {
                        Prefs.putString(Prefs.K_KEYBOARD_TYPE, it)
                        Prefs.putBool(Prefs.K_KEYBOARD_TYPE_CHOSEN, true)
                        Prefs.bump()
                    }
                )
                else -> MainNavigation(rev = rev, initialRoute = initialRoute)
            }
        }
    }
}

@Composable
private fun MainNavigation(rev: Int, initialRoute: String?) {
    val stack = remember { mutableStateListOf<Route>(Route.Home) }
    val context = LocalContext.current
    var handledInitial by remember { mutableStateOf(false) }
    LaunchedEffect(initialRoute) {
        if (!handledInitial) {
            handledInitial = true
            routeFromName(initialRoute)?.let { if (stack.lastOrNull() != it) stack.add(it) }
        }
    }
    val pending = NavBus.pending
    LaunchedEffect(pending) {
        if (pending != null) {
            routeFromName(pending)?.let { if (stack.lastOrNull() != it) stack.add(it) }
            NavBus.pending = null
        }
    }
    BackHandler(enabled = stack.size > 1) {
        if (stack.size > 1) stack.removeAt(stack.lastIndex)
    }
    val nav = { route: Route ->
        if (stack.lastOrNull() != route) stack.add(route)
    }
    val back = { if (stack.size > 1) stack.removeAt(stack.lastIndex) }

    when (val current = stack.last()) {
        Route.Home -> HomeScreen(rev = rev, onNavigate = nav)
        Route.Voice -> VoiceSettingsPage(rev, back, nav)
        Route.VoiceAction -> VoiceActionPage(rev, back)
        Route.OfflineVoice -> OfflineVoicePage(rev, back)
        Route.KeyboardTypes -> KeyboardTypesPage(rev, back, nav)
        Route.DoublePinyin -> DoublePinyinPage(rev, back)
        Route.Wubi -> WubiPage(rev, back)
        Route.Layout -> LayoutPage(rev, back)
        Route.Fuzzy -> FuzzyPinyinPage(rev, back)
        Route.Association -> AssociationPage(rev, back)
        Route.Prediction -> PredictionPage(rev, back)
        Route.KeyFeedback -> KeyFeedbackPage(rev, back)
        Route.QuickFormat -> QuickFormatPage(rev, back)
        Route.ClipboardSettings -> ClipboardSettingsPage(rev, back)
        Route.Lexicon -> LexiconPage(rev, back)
        Route.InputMode -> InputModePage(rev, back, nav)
        Route.SmartInput -> SmartInputPage(rev, back)
        Route.Permissions -> PermissionsPage(rev, back)
        Route.SuperTransfer -> SuperTransferPage(rev, back, nav)
        Route.Account -> AccountPage(rev, back, nav)
        Route.Login -> LoginPage(rev, back)
        Route.Messages -> MessageCenterPage(rev, back, nav)
        Route.Desktop -> DesktopPage(rev, back)
        Route.Help -> HelpFeedbackPage(rev, back)
        Route.About -> AboutPage(rev, back, nav)
        Route.AiService -> AiServicePage(rev, back)
        Route.AuxInput -> AuxInputPage(rev, back)
        Route.KeyboardDemo -> KeyboardDemoPage(rev, back)
        is Route.Doc -> DocumentPage(current.kind, back)
        is Route.MessageDetail -> MessageDetailPage(rev, current.id, back)
    }
}

// ---------------- onboarding ----------------
@Composable
private fun OnboardingScreen(onFinished: () -> Unit) {
    val context = LocalContext.current
    var step by remember { mutableIntStateOf(0) }
    var refresh by remember { mutableIntStateOf(0) }
    val lifecycle = LocalLifecycleOwner.current
    DisposableEffect(lifecycle) {
        val obs = LifecycleEventObserver { _, event -> if (event == Lifecycle.Event.ON_RESUME) refresh++ }
        lifecycle.lifecycle.addObserver(obs)
        onDispose { lifecycle.lifecycle.removeObserver(obs) }
    }
    val enabled = remember(refresh) { isImeEnabled(context) }
    val selected = remember(refresh) { isImeDefault(context) }
    val tablet = isTabletWidth()

    Column(
        Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .statusBarsPadding()
            .navigationBarsPadding()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 24.dp, vertical = 12.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Row(Modifier.widthIn(max = 860.dp).fillMaxWidth().padding(top = 10.dp), verticalAlignment = Alignment.CenterVertically) {
            AppMark(44)
            Spacer(Modifier.width(10.dp))
            Column(Modifier.weight(1f)) {
                Text("豆包输入法（原生复刻）", fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
                Text("净室开源复刻 · 非官方版本", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            TextButton(onClick = {
                Prefs.putBool(Prefs.K_ONBOARDING_DONE, true); Prefs.bump()
            }) { Text("跳过", color = MaterialTheme.colorScheme.onSurfaceVariant) }
        }
        Spacer(Modifier.height(if (tablet) 56.dp else 30.dp))
        Row(
            Modifier.widthIn(max = 860.dp).fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(32.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (tablet) {
                Box(Modifier.weight(1f)) { KeyboardMock(appDark(), Modifier.fillMaxWidth(), showCandidates = false) }
            }
            Column(Modifier.weight(if (tablet) 1.1f else 1f), horizontalAlignment = Alignment.CenterHorizontally) {
                Surface(shape = CircleShape, color = MaterialTheme.colorScheme.primary.copy(alpha = 0.1f), modifier = Modifier.size(76.dp)) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            if (step == 0) Icons.Outlined.Keyboard else Icons.Outlined.CheckCircle,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(38.dp)
                        )
                    }
                }
                Spacer(Modifier.height(22.dp))
                Text(
                    if (step == 0) "启用输入法" else "切换到豆包输入法",
                    fontSize = 26.sp,
                    fontWeight = FontWeight.SemiBold,
                    textAlign = TextAlign.Center
                )
                Spacer(Modifier.height(10.dp))
                Text(
                    if (step == 0) "第一步：在系统设置中启用「豆包输入法（原生复刻）」。\n只有启用后，键盘才能出现在任何输入框中。"
                    else "第二步：在输入法选择器中切换到我们。\n你也可以稍后在键盘底部的地球键 / 系统设置中切换。",
                    fontSize = 14.sp,
                    lineHeight = 22.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center
                )
                Spacer(Modifier.height(18.dp))
                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = if ((step == 0 && enabled) || (step == 1 && selected)) Color(0xFF1FA971).copy(alpha = 0.12f)
                    else MaterialTheme.colorScheme.primary.copy(alpha = 0.08f)
                ) {
                    Text(
                        when {
                            step == 0 && enabled -> "✓ 已启用，可继续下一步"
                            step == 0 -> "尚未在系统中启用"
                            selected -> "✓ 当前已是默认输入法"
                            else -> if (enabled) "已启用，尚未设为默认" else "尚未启用"
                        },
                        fontSize = 12.sp,
                        color = if ((step == 0 && enabled) || (step == 1 && selected)) Color(0xFF1FA971) else MaterialTheme.colorScheme.primary,
                        modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp)
                    )
                }
                Spacer(Modifier.height(26.dp))
                PrimaryAction(if (step == 0) "打开输入法设置" else "弹出输入法选择器") {
                    if (step == 0) {
                        try {
                            context.startActivity(Intent(Settings.ACTION_INPUT_METHOD_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                        } catch (t: Throwable) {
                            toast(context, "无法打开系统设置")
                        }
                    } else {
                        val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
                        imm.showInputMethodPicker()
                    }
                }
                Spacer(Modifier.height(12.dp))
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    if (step == 1) {
                        SecondaryAction("上一步", Modifier.weight(1f)) { step = 0 }
                    }
                    PrimaryAction(if (step == 0) "下一步" else "进入隐私说明", Modifier.weight(1f)) {
                        if (step == 0) step = 1 else onFinished()
                    }
                }
                if (step == 0) {
                    Spacer(Modifier.height(6.dp))
                    TextButton(onClick = { step = 1 }) { Text("我已启用，下一步", fontSize = 13.sp) }
                }
                Spacer(Modifier.height(20.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    StepDot(active = step == 0)
                    StepDot(active = step == 1)
                }
                Spacer(Modifier.height(24.dp))
                Text(
                    "本应用为互操作性研究用途的净室复刻，与豆包官方无关联。",
                    fontSize = 10.5.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center
                )
            }
        }
    }
}

@Composable
private fun StepDot(active: Boolean) {
    Box(
        Modifier
            .width(if (active) 22.dp else 7.dp)
            .height(7.dp)
            .background(if (active) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.primary.copy(alpha = 0.25f), CircleShape)
    )
}

@Composable
private fun AppMark(size: Int = 44) {
    Box(
        Modifier
            .size(size.dp)
            .background(
                androidx.compose.ui.graphics.Brush.linearGradient(listOf(Color(0xFF4F84FF), Color(0xFF3051F2))),
                RoundedCornerShape((size * 0.28f).dp)
            ),
        contentAlignment = Alignment.Center
    ) {
        Text("豆", color = Color.White, fontSize = (size * 0.48f).sp, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun PrivacyScreen(onFinished: (String) -> Unit) {
    val context = LocalContext.current
    var mode by remember { mutableStateOf("smart") }
    var accepted by remember { mutableStateOf(false) }
    var doc by remember { mutableStateOf<String?>(null) }
    val tablet = isTabletWidth()
    Column(
        Modifier
            .fillMaxSize()
            .statusBarsPadding()
            .navigationBarsPadding()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 24.dp, vertical = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Row(Modifier.widthIn(max = 860.dp).fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            AppMark(36)
            Spacer(Modifier.width(10.dp))
            Text("隐私与输入模式", fontSize = 18.sp, fontWeight = FontWeight.SemiBold)
        }
        Spacer(Modifier.height(34.dp))
        Column(Modifier.widthIn(max = 720.dp).fillMaxWidth()) {
            Text("请选择输入模式", fontSize = 26.sp, fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.height(8.dp))
            Text(
                "我们默认在本机完成输入、候选与词库学习。以下模式决定语音、翻译与 AI 写作是否可用。",
                fontSize = 14.sp,
                lineHeight = 22.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(Modifier.height(20.dp))
            ModeCard(
                title = "智能输入模式",
                subtitle = "使用平台语音识别与你自己配置的 AI 服务（DeepSeek）。输入内容仅在你主动触发时发送。",
                icon = Icons.Outlined.Mic,
                selected = mode == "smart",
                onClick = { mode = "smart" }
            )
            Spacer(Modifier.height(12.dp))
            ModeCard(
                title = "基础输入模式",
                subtitle = "只使用本地词库；语音、AI 写作、智能整理与翻译增强会被关闭，键盘输入完全离线可用。",
                icon = Icons.Outlined.Lock,
                selected = mode == "basic",
                onClick = { mode = "basic" }
            )
            Spacer(Modifier.height(18.dp))
            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
                androidx.compose.material3.Checkbox(checked = accepted, onCheckedChange = { accepted = it })
                Text("我已阅读并同意", fontSize = 12.5.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text("《用户协议》", fontSize = 12.5.sp, color = MaterialTheme.colorScheme.primary, modifier = Modifier.padding(start = 4.dp).clickableText { doc = "agreement" })
                Text("《隐私政策》", fontSize = 12.5.sp, color = MaterialTheme.colorScheme.primary, modifier = Modifier.padding(start = 4.dp).clickableText { doc = "privacy" })
            }
            Spacer(Modifier.height(14.dp))
            PrimaryAction("同意并继续", enabled = accepted) {
                if (!accepted) toast(context, "请先阅读并同意协议")
                else onFinished(mode)
            }
            Spacer(Modifier.height(10.dp))
            SecondaryAction("拒绝并仅使用基础模式") {
                if (!accepted) {
                    accepted = true
                    mode = "basic"
                    toast(context, "已选择基础输入模式，请勾选协议后继续")
                } else onFinished("basic")
            }
            Spacer(Modifier.height(16.dp))
            InfoNote("复刻说明：本应用不接入豆包官方账号或私有接口；AI 使用你自行配置的 OpenAI 兼容服务。API Key 仅保存在本机加密存储中。")
        }
    }
    doc?.let { kind ->
        DocumentDialog(
            if (kind == "privacy") "隐私政策" else "用户协议",
            if (kind == "privacy") Docs.privacy else Docs.agreement
        ) { doc = null }
    }
}

@Composable
private fun ModeCard(title: String, subtitle: String, icon: androidx.compose.ui.graphics.vector.ImageVector, selected: Boolean, onClick: () -> Unit) {
    Surface(
        shape = RoundedCornerShape(18.dp),
        color = if (selected) MaterialTheme.colorScheme.primary.copy(alpha = 0.08f) else MaterialTheme.colorScheme.surface,
        border = androidx.compose.foundation.BorderStroke(if (selected) 2.dp else 1.dp, if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline),
        modifier = Modifier.fillMaxWidth().clickableText(onClick)
    ) {
        Row(Modifier.padding(16.dp), verticalAlignment = Alignment.Top) {
            Box(
                Modifier.size(38.dp).background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f), CircleShape),
                contentAlignment = Alignment.Center
            ) { Icon(icon, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(20.dp)) }
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(title, fontSize = 16.sp, fontWeight = FontWeight.Medium)
                Text(subtitle, fontSize = 12.sp, lineHeight = 18.sp, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(top = 4.dp))
            }
            androidx.compose.material3.RadioButton(selected = selected, onClick = onClick)
        }
    }
}

@Composable
private fun FirstRunKeyboard(onSelected: (String) -> Unit) {
    val context = LocalContext.current
    Column(
        Modifier
            .fillMaxSize()
            .statusBarsPadding()
            .navigationBarsPadding()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp, vertical = 20.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(Modifier.height(20.dp))
        AppMark(46)
        Spacer(Modifier.height(16.dp))
        Text("选择你的键盘", fontSize = 26.sp, fontWeight = FontWeight.SemiBold)
        Spacer(Modifier.height(8.dp))
        Text(
            "首次使用请选择一种键盘，之后可在设置中随时切换。\n建议先用 26 键拼音，候选与本地词库开箱即用。",
            fontSize = 13.sp,
            lineHeight = 20.sp,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
        Spacer(Modifier.height(24.dp))
        Box(Modifier.widthIn(max = 720.dp).fillMaxWidth()) {
            KeyboardTypeCards(selected = "pinyin26") { type ->
                onSelected(type)
                toast(context, "已选择${keyboardTypeLabel(type)}")
            }
        }
        Spacer(Modifier.height(18.dp))
        TextButton(onClick = { onSelected("pinyin26") }) { Text("先使用 26 键拼音", fontSize = 13.sp) }
    }
}

fun keyboardTypeLabel(type: String): String = when (type) {
    "pinyin9" -> "9 键拼音"
    "pinyin26" -> "26 键拼音"
    "handwriting" -> "手写"
    "stroke" -> "笔画"
    "shuangpin" -> "双拼"
    "wubi" -> "五笔"
    else -> type
}

fun isImeEnabled(context: Context): Boolean {
    return try {
        val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as? android.view.inputmethod.InputMethodManager
        imm?.enabledInputMethodList?.any { it.packageName == context.packageName } == true
    } catch (_: Throwable) {
        false
    }
}

fun isImeDefault(context: Context): Boolean {
    return try {
        val def = Settings.Secure.getString(context.contentResolver, Settings.Secure.DEFAULT_INPUT_METHOD) ?: ""
        def.startsWith(context.packageName + "/")
    } catch (_: Throwable) {
        false
    }
}

private fun Modifier.clickableText(onClick: () -> Unit): Modifier =
    this.clickable(onClick = onClick)
