package com.huapohen.doubaoinput.android.settings.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AccountCircle
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Devices
import androidx.compose.material.icons.outlined.Logout
import androidx.compose.material.icons.outlined.Message
import androidx.compose.material.icons.outlined.Sync
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.huapohen.doubaoinput.android.core.Message
import com.huapohen.doubaoinput.android.core.MessageRepo
import com.huapohen.doubaoinput.android.core.Prefs
import kotlinx.coroutines.delay
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID

@Composable
fun AccountPage(rev: Int, onBack: () -> Unit, onNavigate: (Route) -> Unit) {
    val context = LocalContext.current
    var confirmLogout by remember { mutableStateOf(false) }
    val logged = Prefs.accountLoggedIn
    val unread = MessageRepo.unreadCount()
    ScreenScaffold("账号", "本地模拟 · 不连接官方", onBack) {
        Surface(
            shape = RoundedCornerShape(20.dp),
            color = MaterialTheme.colorScheme.surface,
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(Modifier.padding(18.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        Modifier.size(58.dp).background(
                            Brush.linearGradient(listOf(Color(0xFF4F84FF), Color(0xFF3051F2))),
                            CircleShape
                        ),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            if (logged) Prefs.accountName.take(1) else "豆",
                            color = Color.White,
                            fontSize = 24.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                    Spacer(Modifier.width(14.dp))
                    Column(Modifier.weight(1f)) {
                        Text(if (logged) Prefs.accountName else "未登录", fontSize = 19.sp, fontWeight = FontWeight.SemiBold)
                        Text(
                            if (logged) "本地 ID · ${Prefs.getString(Prefs.K_ACCOUNT_ID, "local")}" else "登录后可模拟同步、消息与互传",
                            fontSize = 11.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                    if (!logged) {
                        androidx.compose.material3.Button(
                            onClick = { onNavigate(Route.Login) },
                            shape = RoundedCornerShape(12.dp),
                            modifier = Modifier.height(36.dp)
                        ) { Text("登录", fontSize = 13.sp) }
                    }
                }
                if (logged) {
                    Spacer(Modifier.height(14.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        ValuePill("已登录")
                        ValuePill(if (Prefs.getBool(Prefs.K_SUPER_TRANSFER)) "互传已启用" else "互传未启用")
                    }
                }
            }
        }
        Spacer(Modifier.height(12.dp))
        SettingRow(
            "消息中心",
            if (unread > 0) "$unread 条未读消息" else "暂无未读消息",
            icon = Icons.Outlined.Message,
            showChevron = true,
            onClick = { onNavigate(Route.Messages) },
            trailing = { if (unread > 0) ValuePill("$unread", Color(0xFFFF5353)) }
        )
        Spacer(Modifier.height(8.dp))
        SectionTitle("数据与同步")
        SwitchRow(
            "数据同步",
            if (logged) "同步设置到本地模拟云端" else "登录后可用",
            icon = Icons.Outlined.Sync,
            checked = Prefs.getBool(Prefs.K_SYNC_SETTINGS, true),
            enabled = logged
        ) { on -> Prefs.putBool(Prefs.K_SYNC_SETTINGS, on); toast(context, "数据同步已${if (on) "开启" else "关闭"}") }
        Spacer(Modifier.height(8.dp))
        SwitchRow(
            "个人词库同步",
            if (logged) "跨设备同步个人词条" else "登录后可用",
            icon = Icons.Outlined.Sync,
            checked = Prefs.getBool(Prefs.K_SYNC_LEXICON, true),
            enabled = logged
        ) { on -> Prefs.putBool(Prefs.K_SYNC_LEXICON, on); toast(context, "个人词库同步已${if (on) "开启" else "关闭"}") }
        Spacer(Modifier.height(8.dp))
        SwitchRow(
            "常用语同步",
            if (logged) "同步常用语列表" else "登录后可用",
            icon = Icons.Outlined.Sync,
            checked = Prefs.getBool(Prefs.K_SYNC_PHRASES, true),
            enabled = logged
        ) { on -> Prefs.putBool(Prefs.K_SYNC_PHRASES, on); toast(context, "常用语同步已${if (on) "开启" else "关闭"}") }
        Spacer(Modifier.height(12.dp))
        SettingRow(
            "超级互传",
            if (!logged) "登录并启用" else if (Prefs.getBool(Prefs.K_SUPER_TRANSFER)) "已启用 · ${Prefs.getBool(Prefs.K_SUPER_TRANSFER)} 台设备" else "未启用",
            icon = Icons.Outlined.Devices,
            showChevron = true,
            onClick = { onNavigate(Route.SuperTransfer) }
        )
        Spacer(Modifier.height(12.dp))
        if (logged) {
            SecondaryAction("退出登录") { confirmLogout = true }
        } else {
            PrimaryAction("登录 / 注册") { onNavigate(Route.Login) }
        }
        Spacer(Modifier.height(12.dp))
        InfoNote("这是本地模拟账号：登录状态、消息与同步开关只保存在本机，不会请求豆包官方账号系统，也不会上传任何输入内容。")
    }
    if (confirmLogout) {
        ConfirmDialog("退出登录", "退出后本地模拟同步将停止，已保存的词库与常用语不会删除。", "退出", destructive = true, onDismiss = { confirmLogout = false }) {
            Prefs.putBool(Prefs.K_ACCOUNT_LOGGED_IN, false)
            Prefs.putBool(Prefs.K_SUPER_TRANSFER, false)
            toast(context, "已退出登录")
        }
    }
}

@Composable
fun LoginPage(rev: Int, onBack: () -> Unit) {
    val context = LocalContext.current
    var tab by remember { mutableIntStateOf(0) }
    var phone by remember { mutableStateOf("") }
    var code by remember { mutableStateOf("") }
    var accepted by remember { mutableStateOf(false) }
    var countdown by remember { mutableIntStateOf(0) }
    var doc by remember { mutableStateOf<String?>(null) }
    var qrSeed by remember { mutableStateOf(Prefs.did) }
    val logged = Prefs.accountLoggedIn
    LaunchedEffect(countdown) {
        if (countdown > 0) {
            delay(1000)
            countdown -= 1
        }
    }
    fun finishLogin(name: String) {
        Prefs.putBool(Prefs.K_ACCOUNT_LOGGED_IN, true)
        Prefs.putString(Prefs.K_ACCOUNT_NAME, name)
        Prefs.putString(Prefs.K_ACCOUNT_ID, "local-" + UUID.randomUUID().toString().take(8))
        Prefs.putBool(Prefs.K_SYNC_SETTINGS, true)
        Prefs.putBool(Prefs.K_SYNC_LEXICON, true)
        Prefs.putBool(Prefs.K_SYNC_PHRASES, true)
        toast(context, "登录成功（本地模拟）")
        onBack()
    }
    ScreenScaffold("登录", "本地模拟账号", onBack) {
        if (logged) {
            Surface(shape = RoundedCornerShape(18.dp), color = MaterialTheme.colorScheme.surface, modifier = Modifier.fillMaxWidth()) {
                Column(Modifier.padding(20.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(Icons.Outlined.CheckCircle, null, tint = Color(0xFF1FA971), modifier = Modifier.size(38.dp))
                    Text("已登录为 ${Prefs.accountName}", fontSize = 16.sp, fontWeight = FontWeight.Medium, modifier = Modifier.padding(top = 8.dp))
                    Text("如需切换账号，请先在账号页退出登录。", fontSize = 11.5.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Spacer(Modifier.height(12.dp))
                    PrimaryAction("返回账号页") { onBack() }
                }
            }
            return@ScreenScaffold
        }
        ChoiceChips(listOf("手机号登录" to "0", "扫码登录" to "1"), tab.toString()) { tab = it.toInt() }
        Spacer(Modifier.height(12.dp))
        if (tab == 0) {
            OutlinedTextField(
                value = phone,
                onValueChange = { phone = it.filter { c -> c.isDigit() }.take(11) },
                label = { Text("手机号") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(Modifier.height(10.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                OutlinedTextField(
                    value = code,
                    onValueChange = { code = it.filter { c -> c.isDigit() }.take(6) },
                    label = { Text("验证码") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    singleLine = true,
                    modifier = Modifier.weight(1f)
                )
                Spacer(Modifier.width(8.dp))
                androidx.compose.material3.Button(
                    onClick = {
                        if (phone.length != 11) toast(context, "请输入 11 位手机号")
                        else {
                            countdown = 60
                            toast(context, "验证码已发送（本地模拟：任意 4-6 位数字）")
                        }
                    },
                    enabled = countdown == 0,
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.height(52.dp)
                ) { Text(if (countdown > 0) "${countdown}s" else "获取验证码", fontSize = 12.sp) }
            }
            Spacer(Modifier.height(10.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                androidx.compose.material3.Checkbox(checked = accepted, onCheckedChange = { accepted = it })
                Text("我已阅读并同意", fontSize = 11.5.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text("《用户协议》", fontSize = 11.5.sp, color = MaterialTheme.colorScheme.primary, modifier = Modifier.clickable { doc = "agreement" }.padding(start = 3.dp))
                Text("《隐私政策》", fontSize = 11.5.sp, color = MaterialTheme.colorScheme.primary, modifier = Modifier.clickable { doc = "privacy" }.padding(start = 3.dp))
            }
            Spacer(Modifier.height(10.dp))
            PrimaryAction("登录", enabled = accepted) {
                if (!accepted) toast(context, "请先同意协议")
                else if (phone.length != 11) toast(context, "请输入 11 位手机号")
                else if (code.length < 4) toast(context, "请输入验证码")
                else finishLogin("豆包用户" + phone.takeLast(4))
            }
        } else {
            Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
                Surface(shape = RoundedCornerShape(18.dp), color = Color.White, modifier = Modifier.size(190.dp)) {
                    Box(Modifier.padding(12.dp), contentAlignment = Alignment.Center) {
                        QrPattern(qrSeed, Modifier.fillMaxWidth().height(166.dp))
                    }
                }
                Text("使用已登录设备扫码（演示二维码）", fontSize = 11.5.sp, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(top = 8.dp))
                Spacer(Modifier.height(10.dp))
                PrimaryAction("模拟扫码成功") { if (accepted) finishLogin("豆包用户扫码") else toast(context, "请先同意协议") }
                Spacer(Modifier.height(8.dp))
                TextButton(onClick = { qrSeed = UUID.randomUUID().toString() }) { Text("刷新二维码", fontSize = 13.sp) }
            }
            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(top = 6.dp)) {
                androidx.compose.material3.Checkbox(checked = accepted, onCheckedChange = { accepted = it })
                Text("我已阅读并同意", fontSize = 11.5.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text("《用户协议》", fontSize = 11.5.sp, color = MaterialTheme.colorScheme.primary, modifier = Modifier.clickable { doc = "agreement" }.padding(start = 3.dp))
            }
        }
        Spacer(Modifier.height(16.dp))
        InfoNote("复刻版不实现豆包官方扫码登录或短信认证。验证码、手机号和二维码均为本地模拟；不会发送短信，也不会上传手机号。")
    }
    doc?.let { kind ->
        DocumentDialog(Docs.forKind(kind).first, Docs.forKind(kind).second) { doc = null }
    }
}

@Composable
fun MessageCenterPage(rev: Int, onBack: () -> Unit, onNavigate: (Route) -> Unit) {
    val context = LocalContext.current
    var confirmClear by remember { mutableStateOf(false) }
    val messages = MessageRepo.all().sortedByDescending { it.ts }
    ScreenScaffold(
        "消息中心",
        if (messages.isEmpty()) "暂无消息" else "${messages.count { !it.read }} 条未读",
        onBack,
        actions = {
            TextButton(onClick = { MessageRepo.markAllRead(); toast(context, "已全部标为已读") }) {
                Text("全部已读", fontSize = 12.5.sp)
            }
        }
    ) {
        if (messages.isEmpty()) {
            EmptyState("暂无消息", "系统通知、活动与安全提醒会出现在这里。")
        } else {
            messages.forEach { msg ->
                Surface(
                    shape = RoundedCornerShape(16.dp),
                    color = MaterialTheme.colorScheme.surface,
                    modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp)
                        .clickable {
                            MessageRepo.markRead(msg.id)
                            onNavigate(Route.MessageDetail(msg.id))
                        }
                ) {
                    Row(Modifier.padding(start = 14.dp, top = 12.dp, end = 4.dp, bottom = 12.dp), verticalAlignment = Alignment.Top) {
                        Box(
                            Modifier.size(34.dp).background(
                                MaterialTheme.colorScheme.primary.copy(alpha = 0.1f), CircleShape
                            ),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(Icons.Outlined.Message, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(18.dp))
                        }
                        Spacer(Modifier.width(10.dp))
                        Column(Modifier.weight(1f)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    msg.title,
                                    fontSize = 14.sp,
                                    fontWeight = if (!msg.read) FontWeight.SemiBold else FontWeight.Normal,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis,
                                    modifier = Modifier.weight(1f)
                                )
                                if (!msg.read) Box(Modifier.size(7.dp).background(Color(0xFFFF5353), CircleShape))
                            }
                            Text(
                                msg.body.replace("\n", " "),
                                fontSize = 11.5.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                maxLines = 2,
                                overflow = TextOverflow.Ellipsis,
                                modifier = Modifier.padding(top = 3.dp)
                            )
                            Text(fmtTime(msg.ts), fontSize = 10.sp, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(top = 4.dp))
                        }
                        IconButton(onClick = { MessageRepo.delete(msg.id); toast(context, "已删除消息") }) {
                            Icon(Icons.Outlined.Delete, "删除", tint = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.size(18.dp))
                        }
                    }
                }
            }
            Spacer(Modifier.height(8.dp))
            SecondaryAction("清空全部消息") { confirmClear = true }
        }
        Spacer(Modifier.height(12.dp))
        InfoNote("消息为本地示例数据，不包含官方推送。你可以删除单条或清空全部；未读数会显示在首页账号入口。")
    }
    if (confirmClear) {
        ConfirmDialog("清空消息", "将删除全部本地消息。", "清空", destructive = true, onDismiss = { confirmClear = false }) {
            MessageRepo.save(emptyList())
            toast(context, "消息已清空")
        }
    }
}

@Composable
fun MessageDetailPage(rev: Int, id: String, onBack: () -> Unit) {
    val context = LocalContext.current
    val message = MessageRepo.all().firstOrNull { it.id == id }
    LaunchedEffect(id) { if (message != null) MessageRepo.markRead(id) }
    ScreenScaffold("消息详情", null, onBack) {
        if (message == null) {
            EmptyState("消息不存在", "它可能已被删除。")
        } else {
            Text(message.title, fontSize = 20.sp, fontWeight = FontWeight.SemiBold)
            Text(fmtTime(message.ts) + " · " + message.kind, fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(top = 4.dp))
            Spacer(Modifier.height(14.dp))
            Surface(shape = RoundedCornerShape(16.dp), color = MaterialTheme.colorScheme.surface, modifier = Modifier.fillMaxWidth()) {
                Text(message.body, fontSize = 15.sp, lineHeight = 23.sp, modifier = Modifier.padding(16.dp))
            }
            Spacer(Modifier.height(14.dp))
            SecondaryAction("删除这条消息") { MessageRepo.delete(message.id); onBack(); toast(context, "已删除") }
            Spacer(Modifier.height(12.dp))
            InfoNote("此消息为本地示例数据，不来自官方服务器。")
        }
    }
}

private fun fmtTime(ts: Long): String = SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.CHINA).format(Date(ts))
