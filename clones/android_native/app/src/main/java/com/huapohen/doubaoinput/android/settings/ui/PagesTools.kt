package com.huapohen.doubaoinput.android.settings.ui

import android.Manifest
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.pm.PackageManager
import android.provider.ContactsContract
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
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
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.ContentPaste
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Devices
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.PushPin
import androidx.compose.material.icons.outlined.Sync
import androidx.compose.material.icons.outlined.Wifi
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import com.huapohen.doubaoinput.android.core.ClipboardRepo
import com.huapohen.doubaoinput.android.core.DeviceRepo
import com.huapohen.doubaoinput.android.core.LexiconRepo
import com.huapohen.doubaoinput.android.core.Prefs
import com.huapohen.doubaoinput.android.engine.PinyinEngine
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

private fun timeLabel(ts: Long): String = SimpleDateFormat("MM-dd HH:mm", Locale.CHINA).format(Date(ts))

@Composable
fun ClipboardSettingsPage(rev: Int, onBack: () -> Unit) {
    val context = LocalContext.current
    var confirmClear by remember { mutableStateOf(false) }
    ScreenScaffold("剪切板", "本地历史 · 点击复制", onBack) {
        SwitchRow(
            "候选栏展示剪切板",
            "空闲时在候选栏显示最近一次复制内容",
            icon = Icons.Outlined.ContentPaste,
            checked = Prefs.clipboardCandidate
        ) { on -> Prefs.putBool(Prefs.K_CLIPBOARD_CANDIDATE, on); toast(context, "候选栏剪贴板已${if (on) "开启" else "关闭"}") }
        Spacer(Modifier.height(8.dp))
        SwitchRow(
            "历史记录",
            "保留本机复制过的文字，最多 100 条",
            icon = Icons.Outlined.Info,
            checked = Prefs.clipboardHistory
        ) { on -> Prefs.putBool(Prefs.K_CLIPBOARD_HISTORY, on); toast(context, "剪切板历史已${if (on) "开启" else "关闭"}") }
        Spacer(Modifier.height(10.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            androidx.compose.material3.Button(
                onClick = {
                    val cm = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                    val text = cm.primaryClip?.takeIf { it.itemCount > 0 }?.getItemAt(0)?.coerceToText(context)?.toString()?.trim().orEmpty()
                    if (text.isBlank()) toast(context, "系统剪贴板为空") else {
                        ClipboardRepo.add(text)
                        toast(context, "已加入本机历史")
                    }
                },
                modifier = Modifier.weight(1f).height(44.dp),
                shape = RoundedCornerShape(12.dp)
            ) { Text("读取系统剪贴板", fontSize = 13.sp) }
            androidx.compose.material3.OutlinedButton(
                onClick = { confirmClear = true },
                modifier = Modifier.weight(1f).height(44.dp),
                shape = RoundedCornerShape(12.dp)
            ) { Text("清空历史", fontSize = 13.sp) }
        }
        Spacer(Modifier.height(12.dp))
        val items = ClipboardRepo.all()
        SectionTitle("历史记录（${items.size}）")
        if (items.isEmpty()) {
            EmptyState("暂无剪切板历史", "复制文字后回到键盘，或点击上方按钮读取系统剪贴板。")
        } else {
            items.forEach { item ->
                Surface(
                    shape = RoundedCornerShape(16.dp),
                    color = MaterialTheme.colorScheme.surface,
                    modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp)
                ) {
                    Column(Modifier.padding(start = 14.dp, top = 10.dp, end = 4.dp, bottom = 4.dp)) {
                        Text(
                            item.text.replace("\n", " ").take(160),
                            fontSize = 13.5.sp,
                            maxLines = 2,
                            overflow = TextOverflow.Ellipsis,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                timeLabel(item.ts) + if (item.pinned) " · 已置顶" else "",
                                fontSize = 10.5.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.weight(1f)
                            )
                            TextButton(onClick = {
                                val cm = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                                cm.setPrimaryClip(ClipData.newPlainText("豆包输入法", item.text))
                                toast(context, "已复制到系统剪贴板")
                            }) { Text("复制", fontSize = 12.sp) }
                            IconButton(onClick = { ClipboardRepo.togglePin(item.id); toast(context, if (item.pinned) "已取消置顶" else "已置顶") }) {
                                Icon(Icons.Outlined.PushPin, "置顶", tint = if (item.pinned) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.size(18.dp))
                            }
                            IconButton(onClick = { ClipboardRepo.delete(item.id); toast(context, "已删除") }) {
                                Icon(Icons.Outlined.Delete, "删除", tint = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.size(18.dp))
                            }
                        }
                    }
                }
            }
        }
        Spacer(Modifier.height(8.dp))
        SettingRow(
            "跨设备剪切板",
            if (Prefs.accountLoggedIn && Prefs.getBool(Prefs.K_SUPER_TRANSFER)) "已开启 · 本地模拟" else "登录并开启超级互传",
            icon = Icons.Outlined.Sync,
            showChevron = true,
            onClick = { toast(context, "请到超级互传页面管理设备") }
        )
        Spacer(Modifier.height(12.dp))
        InfoNote("剪切板历史仅保存在本机。关闭“历史记录”只是停止在键盘中展示/追加，已有记录仍可在此删除。")
    }
    if (confirmClear) {
        ConfirmDialog("清空剪切板", "将删除全部本地剪切板历史，此操作不可撤销。", "清空", destructive = true, onDismiss = { confirmClear = false }) {
            ClipboardRepo.clear()
            toast(context, "剪切板历史已清空")
        }
    }
}

@Composable
fun LexiconPage(rev: Int, onBack: () -> Unit) {
    val context = LocalContext.current
    var showAdd by remember { mutableStateOf(false) }
    var editing by remember { mutableStateOf<Pair<String, String>?>(null) }
    var confirmClear by remember { mutableStateOf(false) }
    var engineCount by remember { mutableIntStateOf(PinyinEngine.entryCount) }
    var importing by remember { mutableStateOf(false) }
    val scope = androidx.compose.runtime.rememberCoroutineScope()
    val contactLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (!granted) {
            toast(context, "未获得通讯录权限")
        } else {
            importing = true
            scope.launch {
                val names = withContext(Dispatchers.IO) {
                    val out = mutableListOf<String>()
                    try {
                        context.contentResolver.query(
                            ContactsContract.Contacts.CONTENT_URI,
                            arrayOf(ContactsContract.Contacts.DISPLAY_NAME_PRIMARY),
                            null, null, null
                        )?.use { c ->
                            val idx = c.getColumnIndex(ContactsContract.Contacts.DISPLAY_NAME_PRIMARY)
                            while (c.moveToNext() && out.size < 80) {
                                val n = if (idx >= 0) c.getString(idx) else null
                                if (!n.isNullOrBlank() && n.length <= 16) out.add(n)
                            }
                        }
                    } catch (t: Throwable) { }
                    out.distinct()
                }
                if (names.isEmpty()) {
                    toast(context, "没有读取到联系人姓名")
                } else {
                    var added = 0
                    names.forEach { name ->
                        val py = PinyinEngine.findPinyinForWord(name).replace(" ", "")
                        if (LexiconRepo.add(name, py, "通讯录")) added++
                    }
                    toast(context, "已导入 $added 个联系人姓名")
                }
                importing = false
            }
        }
    }
    LaunchedEffect(Unit) {
        withContext(Dispatchers.IO) {
            PinyinEngine.ensureLoaded(context)
            PinyinEngine.awaitLoaded(4000)
        }
        engineCount = PinyinEngine.entryCount
    }
    ScreenScaffold("词库管理", "个人词库 · 通讯录 · 本地引擎", onBack) {
        SectionTitle("本地引擎")
        Surface(shape = RoundedCornerShape(18.dp), color = MaterialTheme.colorScheme.surface, modifier = Modifier.fillMaxWidth()) {
            Column(Modifier.padding(16.dp)) {
                Text("拼音词库  $engineCount 条", fontSize = 15.sp, fontWeight = FontWeight.Medium)
                Text("来源：jieba + pypinyin（MIT）· 随 APK 打包，无需联网", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(top = 3.dp))
                Text("索引：全拼 / 简拼 / T9 · MRU 学习 · 模糊拼音", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(top = 2.dp))
            }
        }
        Spacer(Modifier.height(10.dp))
        SectionTitle("个人词库", trailing = {
            TextButton(onClick = { showAdd = true }) { Text("添加", fontSize = 13.sp) }
        })
        val entries = LexiconRepo.all()
        if (entries.isEmpty()) {
            EmptyState("还没有个人词条", "添加姓名、专业术语或固定搭配，候选会优先展示。")
        } else {
            GroupCard {
                entries.take(80).forEachIndexed { index, entry ->
                    if (index > 0) DividerLine()
                    Row(Modifier.fillMaxWidth().padding(start = 16.dp, end = 4.dp, top = 6.dp, bottom = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                        Column(Modifier.weight(1f)) {
                            Text(entry.word, fontSize = 14.5.sp)
                            Text(
                                entry.pinyin.ifBlank { "未设置拼音（不会产生候选）" } + " · ${entry.source}",
                                fontSize = 10.5.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        IconButton(onClick = { editing = entry.word to entry.pinyin }) {
                            Icon(Icons.Outlined.Edit, "编辑", tint = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.size(18.dp))
                        }
                        IconButton(onClick = { LexiconRepo.delete(entry.word); toast(context, "已删除") }) {
                            Icon(Icons.Outlined.Delete, "删除", tint = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.size(18.dp))
                        }
                    }
                }
            }
        }
        Spacer(Modifier.height(10.dp))
        SectionTitle("通讯录词库")
        SettingRow(
            "导入通讯录人名",
            if (importing) "正在导入…" else "读取显示名称并加入词库，需要通讯录权限",
            icon = Icons.Outlined.Person,
            showChevron = true,
            onClick = {
                val granted = ContextCompat.checkSelfPermission(context, Manifest.permission.READ_CONTACTS) == PackageManager.PERMISSION_GRANTED
                if (granted) {
                    importing = true
                    scope.launch {
                        val names = withContext(Dispatchers.IO) {
                            val out = mutableListOf<String>()
                            try {
                                context.contentResolver.query(
                                    ContactsContract.Contacts.CONTENT_URI,
                                    arrayOf(ContactsContract.Contacts.DISPLAY_NAME_PRIMARY),
                                    null, null, null
                                )?.use { c ->
                                    val idx = c.getColumnIndex(ContactsContract.Contacts.DISPLAY_NAME_PRIMARY)
                                    while (c.moveToNext() && out.size < 80) {
                                        val n = if (idx >= 0) c.getString(idx) else null
                                        if (!n.isNullOrBlank() && n.length <= 16) out.add(n)
                                    }
                                }
                            } catch (t: Throwable) { }
                            out.distinct()
                        }
                        var added = 0
                        names.forEach { name ->
                            val py = PinyinEngine.findPinyinForWord(name).replace(" ", "")
                            if (LexiconRepo.add(name, py, "通讯录")) added++
                        }
                        importing = false
                        toast(context, if (names.isEmpty()) "没有读取到联系人" else "已导入 $added 个姓名")
                    }
                } else contactLauncher.launch(Manifest.permission.READ_CONTACTS)
            }
        )
        val contacts = entries.filter { it.source == "通讯录" }
        if (contacts.isNotEmpty()) {
            Spacer(Modifier.height(6.dp))
            Text("已导入 ${contacts.size} 个姓名", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        Spacer(Modifier.height(12.dp))
        SecondaryAction("清空个人词库") { confirmClear = true }
        Spacer(Modifier.height(12.dp))
        InfoNote("个人词库在本地参与候选排序，并会随 MRU 学习更新。通讯录中未收录拼音的姓名不会产生拼音候选，可手动编辑补全。")
    }
    if (showAdd) {
        TextFieldDialog(
            title = "添加个人词条",
            label = "词语",
            extraLabel = "拼音（可选，如 ni hao）",
            onDismiss = { showAdd = false },
            onConfirm = { word, pinyin ->
                val py = pinyin.ifBlank { PinyinEngine.findPinyinForWord(word) }
                if (LexiconRepo.add(word, py, "个人")) {
                    showAdd = false
                    toast(context, if (py.isBlank()) "已添加；建议补全拼音" else "已添加")
                } else toast(context, "该词已存在")
            }
        )
    }
    editing?.let { (word, pinyin) ->
        TextFieldDialog(
            title = "编辑词条",
            label = "词语",
            initial = word,
            extraLabel = "拼音",
            extraInitial = pinyin,
            onDismiss = { editing = null },
            onConfirm = { newWord, newPinyin ->
                LexiconRepo.update(word, newWord, newPinyin)
                editing = null
                toast(context, "已保存")
            }
        )
    }
    if (confirmClear) {
        ConfirmDialog("清空个人词库", "将删除全部个人与通讯录词条，不影响内置 33,500 条拼音词库。", "清空", destructive = true, onDismiss = { confirmClear = false }) {
            LexiconRepo.clearAll()
            toast(context, "个人词库已清空")
        }
    }
}

@Composable
fun SuperTransferPage(rev: Int, onBack: () -> Unit, onNavigate: (Route) -> Unit) {
    val context = LocalContext.current
    var addDevice by remember { mutableStateOf(false) }
    val logged = Prefs.accountLoggedIn
    val enabled = Prefs.getBool(Prefs.K_SUPER_TRANSFER)
    ScreenScaffold("超级互传", "跨设备剪切板 · 本地模拟", onBack) {
        if (!logged) {
            Surface(
                shape = RoundedCornerShape(18.dp),
                color = MaterialTheme.colorScheme.primary.copy(alpha = 0.08f),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(Modifier.padding(16.dp)) {
                    Text("登录后启用超级互传", fontSize = 16.sp, fontWeight = FontWeight.Medium, color = MaterialTheme.colorScheme.primary)
                    Text("复刻版使用本地模拟账号与设备列表，不请求官方服务。", fontSize = 11.5.sp, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(top = 4.dp))
                    Spacer(Modifier.height(12.dp))
                    PrimaryAction("登录并启用") { onNavigate(Route.Login) }
                }
            }
        } else {
            SwitchRow(
                "启用超级互传",
                "允许本机与已添加设备共享剪切板（演示）",
                icon = Icons.Outlined.Sync,
                checked = enabled
            ) { on ->
                Prefs.putBool(Prefs.K_SUPER_TRANSFER, on)
                toast(context, "超级互传已${if (on) "启用" else "关闭"}")
            }
        }
        Spacer(Modifier.height(14.dp))
        SectionTitle("特性")
        val features = listOf(
            Triple("无损超长文本", "长文本与多行内容不做摘要截断", "📄"),
            Triple("多格式图片", "图片以占位卡片同步，保留来源标签", "🖼"),
            Triple("低延迟", "同一局域网内近乎实时（演示）", "⚡")
        )
        features.forEach { (title, sub, icon) ->
            Surface(shape = RoundedCornerShape(16.dp), color = MaterialTheme.colorScheme.surface, modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp)) {
                Row(Modifier.padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(icon, fontSize = 22.sp)
                    Spacer(Modifier.width(12.dp))
                    Column {
                        Text(title, fontSize = 14.5.sp, fontWeight = FontWeight.Medium)
                        Text(sub, fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            }
        }
        Spacer(Modifier.height(8.dp))
        SectionTitle("设备", trailing = {
            TextButton(onClick = {
                if (!logged) toast(context, "请先登录") else addDevice = true
            }) { Text("添加设备", fontSize = 13.sp) }
        })
        GroupCard {
            DeviceRepo.devices().forEachIndexed { index, device ->
                if (index > 0) DividerLine()
                Row(Modifier.fillMaxWidth().padding(start = 16.dp, end = 4.dp, top = 8.dp, bottom = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        Modifier.size(34.dp).background(MaterialTheme.colorScheme.primary.copy(alpha = 0.1f), CircleShape),
                        contentAlignment = Alignment.Center
                    ) { Icon(if (device.kind == "手机") Icons.Outlined.Devices else Icons.Outlined.Devices, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(18.dp)) }
                    Spacer(Modifier.width(10.dp))
                    Column(Modifier.weight(1f)) {
                        Text(device.name, fontSize = 14.sp)
                        Text(device.kind + if (device.active) " · 在线（演示）" else " · 离线", fontSize = 10.5.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    if (device.name != "本机 · Android") {
                        IconButton(onClick = {
                            val l = DeviceRepo.devices().filter { it.name != device.name }
                            DeviceRepo.save(l)
                            toast(context, "已移除设备")
                        }) { Icon(Icons.Outlined.Delete, "移除", tint = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.size(18.dp)) }
                    } else ValuePill("本机")
                }
            }
        }
        Spacer(Modifier.height(12.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            androidx.compose.material3.Button(
                onClick = {
                    val text = "来自豆包输入法（原生复刻）的互传示例：" + timeLabel(System.currentTimeMillis())
                    val cm = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                    cm.setPrimaryClip(ClipData.newPlainText("互传示例", text))
                    ClipboardRepo.add(text)
                    toast(context, "已复制互传示例文本")
                },
                modifier = Modifier.weight(1f).height(44.dp),
                shape = RoundedCornerShape(12.dp)
            ) { Text("复制示例文本", fontSize = 13.sp) }
            androidx.compose.material3.OutlinedButton(
                onClick = { onNavigate(Route.ClipboardSettings) },
                modifier = Modifier.weight(1f).height(44.dp),
                shape = RoundedCornerShape(12.dp)
            ) { Text("打开剪切板", fontSize = 13.sp) }
        }
        Spacer(Modifier.height(12.dp))
        InfoNote("使用须知：跨设备能力需要同一账号。本复刻不连接豆包官方账号或服务，设备与传输均为本地模拟，仅用于展示交互与数据流。")
    }
    if (addDevice) {
        TextFieldDialog("添加设备", "设备名称", onDismiss = { addDevice = false }) { name, _ ->
            DeviceRepo.addDevice(name, if (name.contains("Mac", true) || name.contains("PC", true) || name.contains("电脑")) "电脑" else "手机")
            addDevice = false
            toast(context, "已添加设备")
        }
    }
}
