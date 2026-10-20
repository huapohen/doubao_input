package com.huapohen.doubaoinput.android.settings.ui

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AccountCircle
import androidx.compose.material.icons.outlined.AutoAwesome
import androidx.compose.material.icons.outlined.Build
import androidx.compose.material.icons.outlined.ChevronRight
import androidx.compose.material.icons.outlined.CloudOff
import androidx.compose.material.icons.outlined.Computer
import androidx.compose.material.icons.outlined.ContentPaste
import androidx.compose.material.icons.outlined.GridView
import androidx.compose.material.icons.outlined.HelpOutline
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Keyboard
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.Mic
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.Security
import androidx.compose.material.icons.outlined.Spellcheck
import androidx.compose.material.icons.outlined.Sync
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import com.huapohen.doubaoinput.android.core.Prefs
import com.huapohen.doubaoinput.android.engine.PinyinEngine
import kotlinx.coroutines.delay

private data class HomeBanner(
    val title: String,
    val subtitle: String,
    val tag: String,
    val route: Route,
    val icon: ImageVector,
    val colors: List<Color>
)

private val banners = listOf(
    HomeBanner("全场景语音精准识别", "支持中文、英语与多方言，说完即上屏", "语音", Route.Voice, Icons.Outlined.Mic, listOf(Color(0xFF4F84FF), Color(0xFF7EA8FF))),
    HomeBanner("智能联想", "根据上文推荐词语、表情与符号", "联想", Route.Association, Icons.Outlined.AutoAwesome, listOf(Color(0xFF6D5DD3), Color(0xFF9B8AF5))),
    HomeBanner("智能文字整理", "口语变书面，自动补全标点", "整理", Route.Voice, Icons.Outlined.Spellcheck, listOf(Color(0xFF16A085), Color(0xFF4FD1B5))),
    HomeBanner("离线语音", "无网也能说话（本地演示下载）", "离线", Route.OfflineVoice, Icons.Outlined.CloudOff, listOf(Color(0xFFE67E22), Color(0xFFF5B041))),
    HomeBanner("超级互传", "手机与电脑共享剪切板", "互传", Route.SuperTransfer, Icons.Outlined.Sync, listOf(Color(0xFF2575FC), Color(0xFF6A11CB))),
    HomeBanner("电脑桌面端", "macOS / Windows 版说明", "桌面", Route.Desktop, Icons.Outlined.Computer, listOf(Color(0xFF2C3E50), Color(0xFF4CA1AF)))
)

@Composable
fun HomeScreen(rev: Int, onNavigate: (Route) -> Unit) {
    val context = LocalContext.current
    val tablet = isTabletWidth()
    val dark = appDark()
    val unread = MessageRepoUnread(rev)
    if (tablet) {
        Row(Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background)) {
            HomeRail(
                onNavigate = onNavigate,
                unread = unread,
                modifier = Modifier.fillMaxHeight().width(92.dp).statusBarsPadding()
            )
            Box(Modifier.weight(1f).fillMaxHeight(), contentAlignment = Alignment.TopCenter) {
                HomeContent(rev, onNavigate, Modifier.widthIn(max = 820.dp).fillMaxWidth())
            }
        }
    } else {
        HomeContent(rev, onNavigate, Modifier.fillMaxSize())
    }
}

private fun MessageRepoUnread(rev: Int): Int {
    return try { com.huapohen.doubaoinput.android.core.MessageRepo.unreadCount() } catch (t: Throwable) { 0 }
}

@Composable
private fun HomeRail(onNavigate: (Route) -> Unit, unread: Int, modifier: Modifier = Modifier) {
    val items = listOf(
        Triple("首页", Icons.Outlined.Home, null),
        Triple("语音", Icons.Outlined.Mic, Route.Voice),
        Triple("键盘", Icons.Outlined.Keyboard, Route.KeyboardTypes),
        Triple("剪切板", Icons.Outlined.ContentPaste, Route.ClipboardSettings),
        Triple("我的", Icons.Outlined.Person, Route.Account)
    )
    Column(
        modifier
            .background(MaterialTheme.colorScheme.surface.copy(alpha = 0.72f))
            .padding(vertical = 12.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(
            Modifier.size(42.dp).background(Brush.linearGradient(listOf(Color(0xFF4F84FF), Color(0xFF3051F2))), RoundedCornerShape(12.dp)),
            contentAlignment = Alignment.Center
        ) { Text("豆", color = Color.White, fontSize = 20.sp, fontWeight = FontWeight.Bold) }
        Spacer(Modifier.height(24.dp))
        items.forEachIndexed { index, (label, icon, route) ->
            val selected = index == 0
            Column(
                Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 10.dp, vertical = 4.dp)
                    .clip(RoundedCornerShape(14.dp))
                    .background(if (selected) MaterialTheme.colorScheme.primary.copy(alpha = 0.12f) else Color.Transparent)
                    .clickable { route?.let(onNavigate) }
                    .padding(vertical = 10.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Box {
                    Icon(
                        icon,
                        contentDescription = label,
                        tint = if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.size(22.dp)
                    )
                    if (label == "我的" && unread > 0) {
                        Box(Modifier.size(7.dp).align(Alignment.TopEnd).background(Color(0xFFFF5353), CircleShape))
                    }
                }
                Spacer(Modifier.height(4.dp))
                Text(
                    label,
                    fontSize = 10.5.sp,
                    color = if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun HomeContent(rev: Int, onNavigate: (Route) -> Unit, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val dark = appDark()
    val contactLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        Prefs.putBool(Prefs.K_CONTACTS_IMPORT, granted)
        toast(context, if (granted) "已获得通讯录权限，可在词库管理中导入" else "未获得通讯录权限")
    }
    fun setSwitch(key: String, on: Boolean, label: String) {
        Prefs.putBool(key, on)
        toast(context, "${label}已${if (on) "开启" else "关闭"}")
    }
    val cached = remember { PinyinEngine.entryCount }
    LazyColumn(
        modifier.statusBarsPadding().navigationBarsPadding(),
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 10.dp, bottom = 28.dp),
        verticalArrangement = Arrangement.spacedBy(0.dp)
    ) {
        item {
            HomeHeader(onAccount = { onNavigate(Route.Account) })
        }
        item {
            Spacer(Modifier.height(12.dp))
            BannerCarousel(onNavigate)
        }
        item {
            HomeGroup("语音输入") {
                SettingRow(
                    "语音转文字",
                    "标点、智能整理与离线语音",
                    icon = Icons.Outlined.Mic,
                    showChevron = true,
                    onClick = { onNavigate(Route.Voice) }
                )
            }
        }
        item {
            HomeGroup("键盘输入") {
                SettingRow(
                    "键盘类型",
                    "9 键、26 键、手写、双拼、五笔",
                    icon = Icons.Outlined.Keyboard,
                    showChevron = true,
                    trailing = { ValuePill(keyboardTypeLabel(Prefs.keyboardType)) },
                    onClick = { onNavigate(Route.KeyboardTypes) }
                )
                SettingRow(
                    "布局与显示",
                    "键盘布局、高度、外观与符号",
                    icon = Icons.Outlined.GridView,
                    showChevron = true,
                    onClick = { onNavigate(Route.Layout) }
                )
                SettingRow(
                    "模糊拼音",
                    "设置打字习惯，如 z=zh、in=ing、n=l",
                    icon = Icons.Outlined.Tune,
                    showChevron = true,
                    trailing = { ValuePill(if (Prefs.fuzzyEnabled) "已开启" else "已关闭", if (Prefs.fuzzyEnabled) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant) },
                    onClick = { onNavigate(Route.Fuzzy) }
                )
                SettingRow(
                    "智能联想",
                    "根据上文推荐文字、表情与符号",
                    icon = Icons.Outlined.AutoAwesome,
                    showChevron = true,
                    onClick = { onNavigate(Route.Association) },
                    trailing = {
                        Switch(
                            checked = Prefs.associationEnabled,
                            onCheckedChange = {
                                Prefs.putBool(Prefs.K_ASSOCIATION, it)
                                toast(context, "智能联想已${if (it) "开启" else "关闭"}")
                            }
                        )
                    }
                )
                SettingRow(
                    "输入预测类型",
                    "Emoji、图片表情与颜文字",
                    icon = Icons.Outlined.Info,
                    showChevron = true,
                    onClick = { onNavigate(Route.Prediction) }
                )
                SettingRow(
                    "按键反馈",
                    "声音、振动与响应速度",
                    icon = Icons.Outlined.Tune,
                    showChevron = true,
                    onClick = { onNavigate(Route.KeyFeedback) }
                )
                SettingRow(
                    "快捷格式输入",
                    "中英数空格、首字母大写、双击空格句号",
                    icon = Icons.Outlined.Spellcheck,
                    showChevron = true,
                    onClick = { onNavigate(Route.QuickFormat) }
                )
                SwitchRow(
                    title = "辅助输入",
                    subtitle = "候选栏快捷操作与悬浮工具",
                    icon = Icons.Outlined.Build,
                    checked = Prefs.getBool(Prefs.K_AUX_INPUT, true)
                ) { setSwitch(Prefs.K_AUX_INPUT, it, "辅助输入") }
            }
        }
        item {
            HomeGroup("工具") {
                SettingRow(
                    "超级互传",
                    if (Prefs.getBool(Prefs.K_SUPER_TRANSFER)) "已启用 · 本地模拟设备" else "手机与电脑互传文字与图片",
                    icon = Icons.Outlined.Sync,
                    showChevron = true,
                    onClick = { onNavigate(Route.SuperTransfer) }
                )
                SettingRow(
                    "剪切板",
                    "候选栏展示与本地历史记录",
                    icon = Icons.Outlined.ContentPaste,
                    showChevron = true,
                    onClick = { onNavigate(Route.ClipboardSettings) }
                )
                SettingRow(
                    "验证码填充",
                    "需短信权限 · 复刻版仅演示，不读取短信",
                    icon = Icons.Outlined.Lock,
                    showChevron = true,
                    onClick = { onNavigate(Route.Permissions) },
                    trailing = {
                        Switch(
                            checked = Prefs.getBool(Prefs.K_VERIFY_FILL),
                            onCheckedChange = { on ->
                                Prefs.putBool(Prefs.K_VERIFY_FILL, on)
                                toast(context, if (on) "验证码填充演示已开启（不读取短信）" else "验证码填充已关闭")
                            }
                        )
                    }
                )
                SettingRow(
                    "导入通讯录人名",
                    "需通讯录权限，导入后加入个人词库",
                    icon = Icons.Outlined.Person,
                    showChevron = true,
                    onClick = { onNavigate(Route.Lexicon) },
                    trailing = {
                        Switch(
                            checked = Prefs.getBool(Prefs.K_CONTACTS_IMPORT),
                            onCheckedChange = { on ->
                                if (on) {
                                    val granted = ContextCompat.checkSelfPermission(context, Manifest.permission.READ_CONTACTS) == PackageManager.PERMISSION_GRANTED
                                    if (granted) {
                                        Prefs.putBool(Prefs.K_CONTACTS_IMPORT, true)
                                        toast(context, "已开启，可在词库管理中导入")
                                    } else contactLauncher.launch(Manifest.permission.READ_CONTACTS)
                                } else {
                                    Prefs.putBool(Prefs.K_CONTACTS_IMPORT, false)
                                    toast(context, "已关闭通讯录导入")
                                }
                            }
                        )
                    }
                )
                SettingRow(
                    "词库管理",
                    "个人词库、通讯录词库与本地引擎",
                    icon = Icons.Outlined.Build,
                    showChevron = true,
                    onClick = { onNavigate(Route.Lexicon) }
                )
            }
        }
        item {
            HomeGroup("隐私与权限") {
                SettingRow(
                    "输入模式与信息保护",
                    if (Prefs.smartMode) "智能输入模式 · 语音与 AI 可用" else "基础输入模式 · 仅本地",
                    icon = Icons.Outlined.Lock,
                    showChevron = true,
                    onClick = { onNavigate(Route.InputMode) }
                )
                SwitchRow(
                    title = "加入体验改进计划",
                    subtitle = "仅保存匿名崩溃统计（演示开关）",
                    icon = Icons.Outlined.Security,
                    checked = Prefs.getBool(Prefs.K_EXPERIENCE_PLAN, false)
                ) { setSwitch(Prefs.K_EXPERIENCE_PLAN, it, "体验改进计划") }
                SettingRow(
                    "系统权限设置",
                    "麦克风、通讯录、相机与通知",
                    icon = Icons.Outlined.Security,
                    showChevron = true,
                    onClick = { onNavigate(Route.Permissions) }
                )
                SettingRow(
                    "AI 服务",
                    if (Prefs.hasAiKey()) "已配置 · ${Prefs.aiModel}" else "未配置 Key · 使用离线示例",
                    icon = Icons.Outlined.AutoAwesome,
                    showChevron = true,
                    onClick = { onNavigate(Route.AiService) }
                )
            }
        }
        item {
            HomeGroup("更多") {
                SettingRow("键盘试用", "在应用内体验完整键盘与工具面板", icon = Icons.Outlined.Keyboard, showChevron = true, onClick = { onNavigate(Route.KeyboardDemo) })
                SettingRow("电脑版", "macOS / Windows 版说明", icon = Icons.Outlined.Computer, showChevron = true, onClick = { onNavigate(Route.Desktop) })
                SettingRow("帮助与反馈", "常见问题与本地反馈", icon = Icons.Outlined.HelpOutline, showChevron = true, onClick = { onNavigate(Route.Help) })
                SettingRow("关于", "版本 1.5.2-clone · 非官方复刻", icon = Icons.Outlined.Info, showChevron = true, onClick = { onNavigate(Route.About) })
            }
        }
        item {
            Column(Modifier.fillMaxWidth().padding(top = 24.dp, bottom = 8.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                Text("豆包输入法（原生复刻）", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text(
                    "本地词库 33,500 条 · 非官方净室复刻 ${if (Prefs.onboardingDone) "" else ""}",
                    fontSize = 10.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.75f),
                    modifier = Modifier.padding(top = 3.dp)
                )
            }
        }
    }
}

@Composable
private fun HomeHeader(onAccount: () -> Unit) {
    val context = LocalContext.current
    val name = if (Prefs.accountLoggedIn) Prefs.accountName else "未登录"
    val unread = MessageRepoUnread(0)
    Row(Modifier.fillMaxWidth().padding(top = 8.dp, bottom = 4.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(
            Modifier.size(44.dp).background(Brush.linearGradient(listOf(Color(0xFF4F84FF), Color(0xFF3051F2))), CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Text(
                if (Prefs.accountLoggedIn) Prefs.accountName.take(1) else "豆",
                color = Color.White,
                fontSize = 19.sp,
                fontWeight = FontWeight.Bold
            )
        }
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text("豆包输入法", fontSize = 22.sp, fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.onBackground)
            Text("非官方净室复刻 · 本地优先 · $name", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
        Box {
            Box(
                Modifier.size(42.dp).background(MaterialTheme.colorScheme.surface, CircleShape).clickable(onClick = onAccount),
                contentAlignment = Alignment.Center
            ) {
                Icon(Icons.Outlined.AccountCircle, contentDescription = "账号", tint = MaterialTheme.colorScheme.onSurface, modifier = Modifier.size(24.dp))
            }
            if (unread > 0) {
                Box(
                    Modifier.size(16.dp).align(Alignment.TopEnd).background(Color(0xFFFF5353), CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Text("$unread", color = Color.White, fontSize = 9.sp)
                }
            }
        }
    }
}

@Composable
private fun BannerCarousel(onNavigate: (Route) -> Unit) {
    val pager = rememberPagerState(pageCount = { banners.size })
    LaunchedEffect(pager) {
        while (true) {
            delay(4300)
            if (!pager.isScrollInProgress) {
                try { pager.animateScrollToPage((pager.currentPage + 1) % banners.size) } catch (t: Throwable) { }
            }
        }
    }
    Column(Modifier.fillMaxWidth().padding(top = 6.dp)) {
        HorizontalPager(state = pager, pageSpacing = 10.dp, modifier = Modifier.fillMaxWidth().height(158.dp)) { index ->
            val b = banners[index]
            Box(
                Modifier
                    .fillMaxSize()
                    .clip(RoundedCornerShape(20.dp))
                    .background(Brush.linearGradient(b.colors))
                    .clickable { onNavigate(b.route) }
            ) {
                Box(Modifier.size(150.dp).align(Alignment.TopEnd).background(Color.White.copy(alpha = 0.08f), CircleShape).padding(0.dp))
                Box(Modifier.size(90.dp).align(Alignment.BottomEnd).background(Color.White.copy(alpha = 0.06f), CircleShape))
                Column(Modifier.fillMaxSize().padding(18.dp), verticalArrangement = Arrangement.SpaceBetween) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(Modifier.size(26.dp).background(Color.White.copy(alpha = 0.18f), CircleShape), contentAlignment = Alignment.Center) {
                            Icon(b.icon, contentDescription = null, tint = Color.White, modifier = Modifier.size(15.dp))
                        }
                        Spacer(Modifier.width(8.dp))
                        Text(b.tag, color = Color.White.copy(alpha = 0.9f), fontSize = 11.sp)
                    }
                    Column {
                        Text(b.title, color = Color.White, fontSize = 20.sp, fontWeight = FontWeight.SemiBold, maxLines = 1)
                        Spacer(Modifier.height(4.dp))
                        Text(b.subtitle, color = Color.White.copy(alpha = 0.86f), fontSize = 11.5.sp, maxLines = 2, overflow = TextOverflow.Ellipsis)
                    }
                }
            }
        }
        Row(Modifier.fillMaxWidth().padding(top = 8.dp), horizontalArrangement = Arrangement.Center) {
            repeat(banners.size) { i ->
                Box(
                    Modifier
                        .padding(horizontal = 3.dp)
                        .width(if (i == pager.currentPage) 16.dp else 5.dp)
                        .height(5.dp)
                        .background(
                            if (i == pager.currentPage) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.primary.copy(alpha = 0.22f),
                            CircleShape
                        )
                )
            }
        }
    }
}

@Composable
private fun HomeGroup(title: String, content: @Composable ColumnScope.() -> Unit) {
    Column(Modifier.fillMaxWidth()) {
        SectionTitle(title)
        Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) { content() }
    }
}

@Composable
fun KeyboardTypeCards(selected: String, onSelect: (String) -> Unit) {
    val types = listOf(
        TypeCard("pinyin9", "9 键拼音", "2 ABC · 3 DEF", "t9"),
        TypeCard("pinyin26", "26 键拼音", "Q W E R T Y", "qwerty"),
        TypeCard("handwriting", "手写", "全屏画布 · 停顿识别", "hand"),
        TypeCard("stroke", "笔画", "横 竖 撇 捺 折", "stroke"),
        TypeCard("shuangpin", "双拼", "小鹤 / 自然码", "double"),
        TypeCard("wubi", "五笔", "86 版 · 四码上屏", "wubi")
    )
    val columns = if (isTabletWidth()) 3 else 2
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        types.chunked(columns).forEach { rowItems ->
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                rowItems.forEach { card ->
                    val type = card.type
                    val label = card.label
                    val preview = card.preview
                    val kind = card.kind
                    val active = type == selected
                    androidx.compose.material3.Surface(
                        shape = RoundedCornerShape(18.dp),
                        color = if (active) MaterialTheme.colorScheme.primary.copy(alpha = 0.08f) else MaterialTheme.colorScheme.surface,
                        border = androidx.compose.foundation.BorderStroke(if (active) 2.dp else 1.dp, if (active) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline),
                        modifier = Modifier.weight(1f).clickable { onSelect(type) }
                    ) {
                        Column(Modifier.padding(14.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                            Box(
                                Modifier.fillMaxWidth().height(48.dp).clip(RoundedCornerShape(9.dp))
                                    .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.07f)),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    when (kind) {
                                        "qwerty" -> "QWERTY"
                                        "t9" -> "1   2   3"
                                        "hand" -> "✍"
                                        "stroke" -> "一 丨 丿 丶 乛"
                                        "double" -> "ni hc"
                                        else -> "字 根 码"
                                    },
                                    fontSize = if (kind == "hand") 22.sp else 12.sp,
                                    color = MaterialTheme.colorScheme.primary,
                                    fontWeight = FontWeight.Medium
                                )
                            }
                            Spacer(Modifier.height(8.dp))
                            Text(label, fontSize = 15.sp, fontWeight = FontWeight.Medium, color = if (active) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface)
                            Text(preview, fontSize = 9.5.sp, color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 1, overflow = TextOverflow.Ellipsis)
                            if (active) {
                                Text("当前使用", fontSize = 9.5.sp, color = MaterialTheme.colorScheme.primary, modifier = Modifier.padding(top = 2.dp))
                            }
                        }
                    }
                }
                repeat(columns - rowItems.size) { Spacer(Modifier.weight(1f)) }
            }
        }
    }
}

private data class TypeCard(val type: String, val label: String, val preview: String, val kind: String)
