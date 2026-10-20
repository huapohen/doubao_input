package com.huapohen.doubaoinput.android.settings.ui

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
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
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AutoAwesome
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.Cloud
import androidx.compose.material.icons.outlined.CloudOff
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.PhotoCamera
import androidx.compose.material.icons.outlined.Security
import androidx.compose.material.icons.outlined.Sms
import androidx.compose.material.icons.outlined.Visibility
import androidx.compose.material.icons.outlined.VisibilityOff
import androidx.compose.material.icons.outlined.VolumeUp
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
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import com.huapohen.doubaoinput.android.ai.AiClient
import com.huapohen.doubaoinput.android.core.Prefs
import com.huapohen.doubaoinput.android.ime.DoubaoImeService
import com.huapohen.doubaoinput.android.settings.MainActivity
import kotlinx.coroutines.launch

@Composable
fun InputModePage(rev: Int, onBack: () -> Unit, onNavigate: (Route) -> Unit) {
    val context = LocalContext.current
    var showThirdParty by remember { mutableStateOf(false) }
    ScreenScaffold("输入模式与信息保护", "决定语音与 AI 是否可用", onBack) {
        val smart = Prefs.smartMode
        androidx.compose.material3.Surface(
            shape = androidx.compose.foundation.shape.RoundedCornerShape(18.dp),
            color = if (smart) MaterialTheme.colorScheme.primary.copy(alpha = 0.08f) else MaterialTheme.colorScheme.surface,
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(Modifier.padding(18.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(if (smart) Icons.Outlined.Cloud else Icons.Outlined.CloudOff, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(22.dp))
                    Spacer(Modifier.width(10.dp))
                    Text(if (smart) "当前：智能输入模式" else "当前：基础输入模式", fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
                }
                Text(
                    if (smart) "键盘输入仍在本机处理；语音与 AI 只在你主动触发时使用网络。"
                    else "所有输入与候选在本机完成，语音、AI 写作、智能整理与翻译增强已关闭。",
                    fontSize = 12.sp,
                    lineHeight = 18.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(top = 6.dp)
                )
            }
        }
        Spacer(Modifier.height(10.dp))
        SectionTitle("选择模式")
        GroupCard {
            RadioRow(
                "智能输入模式",
                "启用语音、AI 写作、整理与翻译增强",
                smart
            ) {
                Prefs.putString(Prefs.K_PRIVACY_MODE, "smart")
                toast(context, "已切换到智能输入模式")
            }
            DividerLine()
            RadioRow(
                "基础输入模式",
                "仅本地词库，完全离线",
                !smart
            ) {
                Prefs.putString(Prefs.K_PRIVACY_MODE, "basic")
                toast(context, "已切换到基础输入模式，语音与 AI 已关闭")
            }
        }
        Spacer(Modifier.height(8.dp))
        SettingRow(
            "智能输入设置",
            "云端使用输入信息、个人词库与 AI 服务",
            icon = Icons.Outlined.AutoAwesome,
            showChevron = true,
            onClick = { onNavigate(Route.SmartInput) }
        )
        Spacer(Modifier.height(8.dp))
        SwitchRow(
            "加入体验改进计划",
            "匿名崩溃统计（演示开关，不上传输入内容）",
            icon = Icons.Outlined.Security,
            checked = Prefs.getBool(Prefs.K_EXPERIENCE_PLAN)
        ) { on -> Prefs.putBool(Prefs.K_EXPERIENCE_PLAN, on); toast(context, "体验改进计划已${if (on) "开启" else "关闭"}") }
        Spacer(Modifier.height(10.dp))
        SectionTitle("协议与清单")
        GroupCard {
            listOf(
                "第三方共享清单" to "thirdparty",
                "用户协议" to "agreement",
                "隐私政策" to "privacy",
                "系统权限清单" to "permissions"
            ).forEachIndexed { index, (label, kind) ->
                if (index > 0) DividerLine()
                Row(
                    Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 14.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(label, fontSize = 14.sp, modifier = Modifier.weight(1f))
                    TextButton(onClick = {
                        if (kind == "thirdparty") showThirdParty = true else onNavigate(Route.Doc(kind))
                    }) { Text("查看", fontSize = 12.sp) }
                }
            }
        }
        Spacer(Modifier.height(12.dp))
        InfoNote("复刻版不会接入豆包官方账号、私有接口或广告 SDK。语音使用系统 SpeechRecognizer，AI 使用你自行填写的 OpenAI 兼容服务。")
    }
    if (showThirdParty) {
        DocumentDialog("第三方共享清单", Docs.thirdParty) { showThirdParty = false }
    }
}

@Composable
fun SmartInputPage(rev: Int, onBack: () -> Unit) {
    val context = LocalContext.current
    val smart = Prefs.smartMode
    ScreenScaffold("智能输入设置", "云端能力与 AI 服务", onBack) {
        if (!smart) {
            InfoNote("当前为基础输入模式，以下云端开关不会生效。可在“输入模式与信息保护”中切换。")
            Spacer(Modifier.height(10.dp))
        }
        SwitchRow(
            "云端使用输入信息",
            "在你主动触发 AI/语音时上传必要的上下文",
            icon = Icons.Outlined.Cloud,
            checked = Prefs.getBool(Prefs.K_SMART_CLOUD_INPUT, true),
            enabled = smart
        ) { on -> Prefs.putBool(Prefs.K_SMART_CLOUD_INPUT, on); toast(context, "云端输入信息已${if (on) "开启" else "关闭"}") }
        Spacer(Modifier.height(8.dp))
        SwitchRow(
            "云端使用个人词库",
            "让 AI 参考你的个人词条（仅请求时）",
            icon = Icons.Outlined.Lock,
            checked = Prefs.getBool(Prefs.K_SMART_CLOUD_LEXICON, true),
            enabled = smart
        ) { on -> Prefs.putBool(Prefs.K_SMART_CLOUD_LEXICON, on); toast(context, "云端个人词库已${if (on) "开启" else "关闭"}") }
        Spacer(Modifier.height(8.dp))
        SettingRow(
            "AI 服务",
            if (Prefs.hasAiKey()) "已配置 · ${Prefs.aiModel}" else "未配置 API Key，使用离线示例",
            icon = Icons.Outlined.AutoAwesome,
            showChevron = true,
            onClick = {
                context.startActivity(
                    Intent(context, MainActivity::class.java)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                        .putExtra(DoubaoImeService.EXTRA_ROUTE, "ai")
                )
            }
        )
        Spacer(Modifier.height(8.dp))
        SettingRow(
            "语音与 AI 权限",
            "麦克风与系统语音识别状态",
            icon = Icons.Outlined.Info,
            showChevron = true,
            onClick = {
                context.startActivity(
                    Intent(context, MainActivity::class.java)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                        .putExtra(DoubaoImeService.EXTRA_ROUTE, "permissions")
                )
            }
        )
        Spacer(Modifier.height(12.dp))
        InfoNote("所有云端调用都需要你主动触发；不会在后台持续上传输入。基础输入模式下云端调用会被直接拒绝，并返回离线结果。")
    }
}

private data class PermItem(
    val title: String,
    val subtitle: String,
    val icon: androidx.compose.ui.graphics.vector.ImageVector,
    val permission: String?
)

@Composable
fun PermissionsPage(rev: Int, onBack: () -> Unit) {
    val context = LocalContext.current
    var refresh by remember { mutableIntStateOf(0) }
    val lifecycle = LocalLifecycleOwner.current
    DisposableEffect(lifecycle) {
        val obs = LifecycleEventObserver { _, event -> if (event == Lifecycle.Event.ON_RESUME) refresh++ }
        lifecycle.lifecycle.addObserver(obs)
        onDispose { lifecycle.lifecycle.removeObserver(obs) }
    }
    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { result ->
        refresh++
        toast(context, "权限请求完成：${result.count { it.value }} 项已授权")
    }
    val items = listOf(
        PermItem("麦克风", "语音输入；首次点击语音时请求", Icons.Outlined.VolumeUp, Manifest.permission.RECORD_AUDIO),
        PermItem("通讯录", "导入联系人姓名到个人词库", Icons.Outlined.Person, Manifest.permission.READ_CONTACTS),
        PermItem("相机", "保留权限项；复刻版不采集相机画面", Icons.Outlined.PhotoCamera, Manifest.permission.CAMERA),
        PermItem("通知", "系统通知与权限状态展示", Icons.Outlined.Notifications, if (Build.VERSION.SDK_INT >= 33) Manifest.permission.POST_NOTIFICATIONS else null),
        PermItem("短信", "复刻版不申请、不读取短信；验证码填充为演示", Icons.Outlined.Sms, null)
    )
    fun granted(item: PermItem): Boolean {
        if (item.title == "通知") return NotificationManagerCompat.from(context).areNotificationsEnabled()
        val p = item.permission ?: return false
        return ContextCompat.checkSelfPermission(context, p) == PackageManager.PERMISSION_GRANTED
    }
    ScreenScaffold("系统权限设置", "状态会随系统设置刷新", onBack) {
        items.forEach { item ->
            val ok = granted(item)
            Surface(
                shape = androidx.compose.foundation.shape.RoundedCornerShape(16.dp),
                color = MaterialTheme.colorScheme.surface,
                modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp)
            ) {
                Row(Modifier.padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
                    androidx.compose.foundation.layout.Box(
                        Modifier.size(36.dp).background(MaterialTheme.colorScheme.primary.copy(alpha = 0.1f), CircleShape),
                        contentAlignment = Alignment.Center
                    ) { Icon(item.icon, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(19.dp)) }
                    Spacer(Modifier.width(12.dp))
                    Column(Modifier.weight(1f)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(item.title, fontSize = 14.5.sp, fontWeight = FontWeight.Medium)
                            Spacer(Modifier.width(6.dp))
                            ValuePill(if (item.permission == null) "未申请" else if (ok) "已授权" else "未授权", if (ok) Color(0xFF1FA971) else MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        Text(item.subtitle, fontSize = 10.5.sp, color = MaterialTheme.colorScheme.onSurfaceVariant, lineHeight = 15.sp)
                    }
                    if (item.permission != null && !ok) {
                        TextButton(onClick = { launcher.launch(arrayOf(item.permission)) }) { Text("授权", fontSize = 12.sp) }
                    }
                }
            }
        }
        Spacer(Modifier.height(10.dp))
        PrimaryAction("请求麦克风 / 通讯录 / 相机 / 通知") {
            val request = mutableListOf<String>()
            if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) request.add(Manifest.permission.RECORD_AUDIO)
            if (ContextCompat.checkSelfPermission(context, Manifest.permission.READ_CONTACTS) != PackageManager.PERMISSION_GRANTED) request.add(Manifest.permission.READ_CONTACTS)
            if (ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) request.add(Manifest.permission.CAMERA)
            if (Build.VERSION.SDK_INT >= 33 && ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) request.add(Manifest.permission.POST_NOTIFICATIONS)
            if (request.isEmpty()) toast(context, "核心权限已全部授予") else launcher.launch(request.toTypedArray())
        }
        Spacer(Modifier.height(8.dp))
        SecondaryAction("打开应用系统设置") { openAppSettings(context) }
        Spacer(Modifier.height(12.dp))
        InfoNote("权限状态读取自 Android 系统。若曾永久拒绝，系统不会再弹窗，请通过“打开应用系统设置”手动开启。短信权限未被声明，因此验证码填充只保留演示开关。")
    }
    // Keep the counter read so recomposition is guaranteed after returning from settings.
    if (refresh < 0) Text("")
}

private fun openAppSettings(context: Context) {
    try {
        context.startActivity(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.parse("package:" + context.packageName))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        )
    } catch (t: Throwable) {
        toast(context, "无法打开系统设置")
    }
}

@Composable
fun AiServicePage(rev: Int, onBack: () -> Unit) {
    val context = LocalContext.current
    var baseUrl by remember { mutableStateOf(Prefs.aiBaseUrl) }
    var model by remember { mutableStateOf(Prefs.aiModel) }
    var key by remember { mutableStateOf(Prefs.aiKey()) }
    var showKey by remember { mutableStateOf(false) }
    var status by remember { mutableStateOf(if (Prefs.hasAiKey()) "已保存 Key（${if (Prefs.aiKeyInSecureStorage()) "加密存储" else "本地存储"}）" else "未配置 Key") }
    var testing by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    fun save(showToast: Boolean = true) {
        val base = baseUrl.trim().trimEnd('/')
        if (!base.startsWith("http://") && !base.startsWith("https://")) {
            status = "Base URL 必须以 http:// 或 https:// 开头"
            return
        }
        Prefs.putString(Prefs.K_AI_BASE_URL, base)
        Prefs.putString(Prefs.K_AI_MODEL, model.trim().ifBlank { "deepseek-chat" })
        Prefs.setAiKey(key)
        if (showToast) toast(context, "AI 设置已保存到本机")
        status = if (key.isBlank()) "未配置 Key" else "已保存 Key（${if (Prefs.aiKeyInSecureStorage()) "加密存储" else "本地存储"}）"
    }
    ScreenScaffold("AI 服务", "OpenAI 兼容 · 运行时配置", onBack) {
        InfoNote("不内置任何厂商 Key。请求只发送到你填写的 Base URL；Key 不写入日志、仓库或截图。")
        Spacer(Modifier.height(10.dp))
        OutlinedTextField(
            value = baseUrl,
            onValueChange = { baseUrl = it },
            label = { Text("Base URL") },
            placeholder = { Text("https://api.deepseek.com") },
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri),
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(Modifier.height(8.dp))
        OutlinedTextField(
            value = model,
            onValueChange = { model = it },
            label = { Text("模型") },
            placeholder = { Text("deepseek-chat") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(Modifier.height(8.dp))
        OutlinedTextField(
            value = key,
            onValueChange = { key = it },
            label = { Text("API Key") },
            singleLine = true,
            visualTransformation = if (showKey) VisualTransformation.None else PasswordVisualTransformation(),
            trailingIcon = {
                IconButton(onClick = { showKey = !showKey }) {
                    Icon(if (showKey) Icons.Outlined.VisibilityOff else Icons.Outlined.Visibility, if (showKey) "隐藏" else "显示", tint = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            },
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(Modifier.height(6.dp))
        Text(status, fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Spacer(Modifier.height(12.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            androidx.compose.material3.Button(
                onClick = { save() },
                modifier = Modifier.weight(1f).height(46.dp),
                shape = androidx.compose.foundation.shape.RoundedCornerShape(12.dp)
            ) { Text("保存设置", fontSize = 14.sp) }
            androidx.compose.material3.OutlinedButton(
                onClick = {
                    save(showToast = false)
                    if (key.isBlank()) {
                        status = "请先填写 API Key"
                    } else {
                        testing = true
                        status = "正在测试连接…"
                        scope.launch {
                            val r = AiClient.testConnection()
                            testing = false
                            status = if (r.ok) r.text else r.error.ifBlank { "连接失败" }
                            toast(context, if (r.ok) "连接成功" else "连接失败，请查看状态")
                        }
                    }
                },
                enabled = !testing,
                modifier = Modifier.weight(1f).height(46.dp),
                shape = androidx.compose.foundation.shape.RoundedCornerShape(12.dp)
            ) { Text(if (testing) "测试中…" else "测试连接", fontSize = 14.sp) }
        }
        Spacer(Modifier.height(8.dp))
        SecondaryAction("清除 Key") {
            key = ""
            Prefs.setAiKey("")
            status = "已清除 Key；AI 功能将使用离线示例"
            toast(context, "API Key 已从本机清除")
        }
        Spacer(Modifier.height(12.dp))
        SectionTitle("说明")
        InfoNote(
            "• 请求格式：POST {Base URL}/chat/completions，Authorization: Bearer <Key>。\n" +
            "• 默认 Base URL 为 DeepSeek；也可填写任何 OpenAI 兼容服务。\n" +
            "• 超时 20 秒；401/402/429/5xx 会显示明确错误并回退到离线结果。\n" +
            "• ${if (Prefs.aiKeyInSecureStorage()) "当前使用 EncryptedSharedPreferences 保存 Key。" else if (Prefs.hasAiKey()) "当前 Key 位于普通 SharedPreferences（加密存储未使用或不可用）；请自行评估风险。" else "尚未保存 Key。"}\n" +
            "• 未配置 Key 时，AI 写作/整理/翻译均返回标注为“离线示例”的本地结果。"
        )
    }
}

@Composable
fun AuxInputPage(rev: Int, onBack: () -> Unit) {
    val context = LocalContext.current
    ScreenScaffold("辅助输入", "候选栏与键盘的辅助能力", onBack) {
        SwitchRow(
            "辅助输入",
            "启用候选栏快捷操作与悬浮工具",
            checked = Prefs.getBool(Prefs.K_AUX_INPUT, true)
        ) { on -> Prefs.putBool(Prefs.K_AUX_INPUT, on); toast(context, "辅助输入已${if (on) "开启" else "关闭"}") }
        Spacer(Modifier.height(8.dp))
        SwitchRow(
            "悬浮键盘",
            "缩小键盘并可拖动位置",
            checked = Prefs.floating
        ) { on -> Prefs.putBool(Prefs.K_FLOATING, on); toast(context, "悬浮键盘已${if (on) "开启" else "关闭"}") }
        Spacer(Modifier.height(8.dp))
        SectionTitle("单手模式")
        ChoiceChips(
            listOf("关闭" to "off", "左手" to "left", "右手" to "right"),
            Prefs.oneHand
        ) { v ->
            Prefs.putString(Prefs.K_ONE_HAND, v)
            toast(context, "单手模式：" + when (v) { "left" -> "左手"; "right" -> "右手"; else -> "关闭" })
        }
        Spacer(Modifier.height(8.dp))
        SwitchRow(
            "26 键气泡",
            "长按/上滑显示键帽气泡",
            checked = Prefs.keyBubble
        ) { on -> Prefs.putBool(Prefs.K_KEY_BUBBLE, on); toast(context, "键帽气泡已${if (on) "开启" else "关闭"}") }
        Spacer(Modifier.height(12.dp))
        InfoNote("辅助输入与键盘设置共享状态：这里的开关会立即同步到键盘。候选栏长按候选可查看词频、复制或删除该词。")
    }
}
