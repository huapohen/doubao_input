import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/ai_service.dart';
import '../../core/app_state.dart';
import '../../core/docs.dart';
import '../../core/platform_bridge.dart';
import '../../theme.dart';
import '../widgets.dart';

class SuperTransferPage extends StatelessWidget {
  const SuperTransferPage({super.key});

  Future<void> _enable(BuildContext context, AppState s) async {
    if (!s.loggedIn) {
      final ok = await Navigator.of(context).pushNamed('/login');
      if (ok != true || !context.mounted) return;
    }
    s.setBool(K.superTransferEnabled, true);
    if (context.mounted) toast(context, '超级互传已启用（本机演示）');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = AppScope.of(context);
    final devices = s.devices;
    return PageScaffold(
      title: '超级互传',
      children: [
        Row(
          children: [
            Expanded(child: _featureCard(context, Icons.article_outlined, '无损长文本', '超长文字完整传递')),
            const SizedBox(width: 8),
            Expanded(child: _featureCard(context, Icons.photo_library_outlined, '多格式图片', '保留清晰度')),
            const SizedBox(width: 8),
            Expanded(child: _featureCard(context, Icons.bolt_rounded, '低延迟', '本机模拟同步')),
          ],
        ),
        const SizedBox(height: 14),
        SettingsGroup(children: [
          SwitchRow(
            title: '启用超级互传',
            subtitle: s.loggedIn ? '在登录设备之间互传文字' : '需要先登录本地账号',
            value: s.superTransferEnabled,
            onChanged: (v) async {
              if (v) {
                await _enable(context, s);
              } else {
                s.setBool(K.superTransferEnabled, false);
                toast(context, '超级互传已关闭');
              }
            },
          ),
        ]),
        if (!s.loggedIn) ...[
          const SizedBox(height: 10),
          PrimaryButton('登录并启用', icon: Icons.login_rounded, onPressed: () async {
            final ok = await Navigator.of(context).pushNamed('/login');
            if (ok == true && context.mounted) {
              s.setBool(K.superTransferEnabled, true);
              toast(context, '登录成功，超级互传已启用');
            }
          }),
          const SizedBox(height: 8),
          Center(
            child: Text('本复刻版不连接豆包账号或官方设备服务',
                style: TextStyle(fontSize: 11, color: p.textSecondary)),
          ),
        ],
        const SectionTitle('设备'),
        SettingsGroup(children: [
          ListTile(
            leading: IconSquare(Icons.smartphone_rounded),
            title: const Text('本机'),
            subtitle: Text(s.deviceId, style: const TextStyle(fontSize: 11)),
            trailing: TagChip(s.superTransferEnabled ? '在线' : '未启用',
                color: s.superTransferEnabled ? const Color(0xFF23A26D) : p.textSecondary),
          ),
          for (var i = 0; i < devices.length; i++)
            ListTile(
              leading: IconSquare(Icons.devices_other_rounded),
              title: Text((devices[i]['name'] ?? '未命名设备').toString()),
              subtitle: Text('${devices[i]['id']} · ${devices[i]['last']}',
                  style: const TextStyle(fontSize: 11)),
              trailing: IconButton(
                tooltip: '移除设备',
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  s.removeDevice(i);
                  toast(context, '已移除设备');
                },
              ),
            ),
          ListTile(
            leading: Icon(Icons.add_circle_outline_rounded, color: p.primary),
            title: Text('添加设备', style: TextStyle(fontSize: 15, color: p.primary)),
            onTap: () async {
              final name = await promptText(context,
                  title: '添加设备',
                  hint: '例如：我的 MacBook',
                  subtitle: '复刻版仅在本机保存设备名称，不会发起真实配对。');
              if (name == null || name.isEmpty) return;
              s.addDevice(name);
              if (context.mounted) {
                s.setBool(K.superTransferEnabled, true);
                toast(context, '已添加设备「$name」');
              }
            },
          ),
        ]),
        const SectionTitle('使用须知'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in const [
                '1. 复刻版不连接官方账号或互传服务，设备列表为本机演示。',
                '2. 示例文本可复制到系统剪贴板，便于自行测试跨端流程。',
                '3. 图片互传需要真实后端；此处仅展示状态。',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(line,
                      style: TextStyle(fontSize: 13, color: p.textSecondary, height: 1.5)),
                ),
              const SizedBox(height: 6),
              SecondaryButton('复制示例文本', icon: Icons.copy_rounded, onPressed: () {
                copyText(context, '豆包输入法（复刻）· 超级互传示例文本\n这是一段用于测试跨设备粘贴的长文本。');
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _featureCard(BuildContext context, IconData icon, String title, String subtitle) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, color: p.primary, size: 24),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.text)),
          const SizedBox(height: 3),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9.5, color: p.textSecondary, height: 1.3)),
        ],
      ),
    );
  }
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  Future<bool> _requireLogin(BuildContext context, AppState s, String feature) async {
    if (s.loggedIn) return true;
    final ok = await Navigator.of(context).pushNamed('/login');
    if (ok == true) {
      if (context.mounted) toast(context, '登录成功，可继续设置$feature');
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = AppScope.of(context);
    return PageScaffold(
      title: '账户',
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [p.primary.withValues(alpha: 0.15), p.primary.withValues(alpha: 0.04)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(T.radiusCard),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: p.primary,
                child: Text(
                  s.loggedIn && s.accountName.isNotEmpty ? s.accountName.characters.first : '?',
                  style: const TextStyle(fontSize: 21, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(s.loggedIn ? s.accountName : '未登录',
                            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: p.text)),
                        if (s.loggedIn) ...[const SizedBox(width: 8), const TagChip('本地账号')],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(s.loggedIn ? '数据仅保存在本机，不同步官方服务' : '登录后可管理本地同步与互传演示',
                        style: TextStyle(fontSize: 12, color: p.textSecondary)),
                  ],
                ),
              ),
              if (!s.loggedIn)
                FilledButton(
                  onPressed: () async {
                    final ok = await Navigator.of(context).pushNamed('/login');
                    if (ok == true && context.mounted) toast(context, '登录成功');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: p.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: const Text('登录'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SettingsGroup(children: [
          NavRow(
            title: '消息中心',
            subtitle: s.unreadMessages == 0 ? '暂无未读消息' : '${s.unreadMessages} 条未读消息',
            trailingWidget: s.unreadMessages > 0
                ? TagChip('${s.unreadMessages}', color: p.danger)
                : null,
            icon: Icons.notifications_none_rounded,
            onTap: () => Navigator.of(context).pushNamed('/messages'),
          ),
          NavRow(
            title: '超级互传',
            subtitle: s.superTransferEnabled ? '已启用 · ${s.devices.length + 1} 台设备' : '未启用',
            icon: Icons.sync_alt_rounded,
            onTap: () => Navigator.of(context).pushNamed('/transfer'),
          ),
        ]),
        const SectionTitle('同步'),
        SettingsGroup(children: [
          SwitchRow(
            title: '数据同步',
            subtitle: '仅同步本地设置到本机演示账户',
            value: s.loggedIn && s.getBool('sync_settings', fallback: true),
            onChanged: (v) async {
              if (!await _requireLogin(context, s, '数据同步')) return;
              s.setBool('sync_settings', v);
              if (context.mounted) toast(context, '数据同步已${v ? '开启' : '关闭'}');
            },
          ),
          SwitchRow(
            title: '个人词库同步',
            subtitle: '把个人词条纳入同步范围',
            value: s.loggedIn && s.getBool('sync_lexicon', fallback: true),
            onChanged: (v) async {
              if (!await _requireLogin(context, s, '词库同步')) return;
              s.setBool('sync_lexicon', v);
              if (context.mounted) toast(context, '个人词库同步已${v ? '开启' : '关闭'}');
            },
          ),
          SwitchRow(
            title: '常用语同步',
            subtitle: '把常用语纳入同步范围',
            value: s.loggedIn && s.getBool('sync_phrases'),
            onChanged: (v) async {
              if (!await _requireLogin(context, s, '常用语同步')) return;
              s.setBool('sync_phrases', v);
              if (context.mounted) toast(context, '常用语同步已${v ? '开启' : '关闭'}');
            },
          ),
        ]),
        if (s.loggedIn) ...[
          const SizedBox(height: 16),
          SecondaryButton('退出登录', icon: Icons.logout_rounded, onPressed: () async {
            final ok = await confirm(context,
                title: '退出登录', message: '退出后将关闭超级互传，本地词库与设置仍保留。', danger: true, ok: '退出');
            if (!ok) return;
            s.logout();
            if (context.mounted) toast(context, '已退出登录');
          }),
        ],
        const SizedBox(height: 12),
        InfoBanner('复刻版不接入豆包官方账号、短信登录或风控服务。登录为本机模拟，仅用于展示账户页状态。'),
      ],
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _name = TextEditingController(text: '复刻体验用户');
  bool _qr = false;
  bool _scanning = false;
  late final AnimationController _scan;
  int _countdown = 3;

  @override
  void initState() {
    super.initState();
    _scan = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _name.dispose();
    _scan.dispose();
    super.dispose();
  }

  Future<void> _scanLogin() async {
    if (_scanning) return;
    setState(() {
      _scanning = true;
      _countdown = 3;
    });
    for (var i = 3; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _countdown = i - 1);
    }
    if (!mounted) return;
    _finish('扫码用户');
  }

  void _finish(String name) {
    final s = AppScope.of(context);
    s.login(name);
    toast(context, '登录成功（本地模拟）');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return PageScaffold(
      title: '登录',
      children: [
        Center(
          child: Column(
            children: [
              const AppMark(size: 68),
              const SizedBox(height: 14),
              Text('豆包输入法（复刻）',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: p.text)),
              const SizedBox(height: 5),
              Text('本地模拟登录 · 不请求官方账号服务',
                  style: TextStyle(fontSize: 12, color: p.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(999)),
          child: Row(
            children: [
              for (final qr in [false, true])
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _qr = qr),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _qr == qr ? p.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(qr ? '扫码登录' : '一键登录',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _qr == qr ? Colors.white : p.textSecondary,
                          )),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!_qr) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('昵称',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.text)),
                const SizedBox(height: 8),
                TextField(
                  controller: _name,
                  style: TextStyle(color: p.text),
                  decoration: InputDecoration(
                    hintText: '输入一个本地昵称',
                    filled: true,
                    fillColor: p.pageBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                PrimaryButton('一键登录', icon: Icons.login_rounded, onPressed: () {
                  final v = _name.text.trim();
                  _finish(v.isEmpty ? '复刻体验用户' : v);
                }),
                const SizedBox(height: 8),
                Text('不发送短信验证码，不会创建真实账号。',
                    style: TextStyle(fontSize: 11, color: p.textSecondary)),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18)),
            child: Column(
              children: [
                SizedBox(
                  width: 210,
                  height: 210,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CustomPaint(
                          size: const Size(200, 200),
                          painter: _FakeQrPainter(seed: 'doubao-clone-local-login'),
                        ),
                      ),
                      if (_scanning)
                        AnimatedBuilder(
                          animation: _scan,
                          builder: (context, _) => Positioned(
                            top: 15 + (_scan.value * 170),
                            left: 15,
                            right: 15,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Colors.transparent,
                                  p.primary,
                                  Colors.transparent,
                                ]),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(_scanning ? '正在等待扫描… $_countdown 秒后模拟成功' : '使用手机扫描二维码（演示）',
                    style: TextStyle(fontSize: 12, color: p.textSecondary)),
                const SizedBox(height: 12),
                PrimaryButton(_scanning ? '扫描中…' : '模拟扫码成功',
                    icon: Icons.qr_code_scanner_rounded, onPressed: _scanning ? null : _scanLogin),
                const SizedBox(height: 8),
                Text('二维码为本机生成的占位图案，不包含任何真实登录链接。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: p.textSecondary)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/text',
                  arguments: {'title': '用户协议', 'content': agreementText}),
              child: const Text('用户协议', style: TextStyle(fontSize: 12)),
            ),
            Text('·', style: TextStyle(color: p.textSecondary)),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/text',
                  arguments: {'title': '隐私政策', 'content': privacyText}),
              child: const Text('隐私政策', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const InfoBanner('这是净室复刻版的本地账户：仅保存昵称与登录状态，用于展示账户、消息中心与超级互传联动。'),
      ],
    );
  }
}

class MessageCenterPage extends StatelessWidget {
  const MessageCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = AppScope.of(context);
    final list = s.messages;
    return PageScaffold(
      title: '消息中心',
      actions: [
        if (list.isNotEmpty)
          TextButton(
            onPressed: () {
              s.markAllMessagesRead();
              toast(context, '已全部标记为已读');
            },
            child: const Text('全部已读', style: TextStyle(fontSize: 12)),
          ),
      ],
      children: [
        if (list.isEmpty)
          EmptyState(
            title: '暂无消息',
            subtitle: '系统通知与功能提示会出现在这里',
            icon: Icons.notifications_none_rounded,
            action: SecondaryButton('返回', onPressed: () => Navigator.pop(context)),
          )
        else
          SettingsGroup(children: [
            for (final m in list)
              ListTile(
                leading: Stack(
                  children: [
                    IconSquare(m['read'] == true
                        ? Icons.mark_email_read_outlined
                        : Icons.mark_email_unread_outlined),
                    if (m['read'] != true)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: p.danger, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
                title: Text((m['title'] ?? '').toString(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: m['read'] == true ? FontWeight.w400 : FontWeight.w600,
                      color: p.text,
                    )),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((m['body'] ?? '').toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: p.textSecondary, height: 1.4)),
                    const SizedBox(height: 3),
                    Text('${m['time']} · ${m['category']}',
                        style: TextStyle(fontSize: 10, color: p.textSecondary.withValues(alpha: 0.7))),
                  ],
                ),
                isThreeLine: true,
                onTap: () {
                  s.markMessageRead(m['id'].toString());
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: p.card,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text((m['title'] ?? '').toString()),
                      content: Text((m['body'] ?? '').toString(),
                          style: TextStyle(fontSize: 14, height: 1.6, color: p.text)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('关闭'),
                        ),
                        TextButton(
                          onPressed: () {
                            s.deleteMessage(m['id'].toString());
                            Navigator.pop(ctx);
                            toast(context, '消息已删除');
                          },
                          child: Text('删除', style: TextStyle(color: p.danger)),
                        ),
                      ],
                    ),
                  );
                },
                trailing: IconButton(
                  tooltip: '删除消息',
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    s.deleteMessage(m['id'].toString());
                    toast(context, '消息已删除');
                  },
                ),
              ),
          ]),
        const SizedBox(height: 14),
        const InfoBanner('消息为本地示例数据，支持已读、删除与空态；不连接官方 IM 服务。'),
      ],
    );
  }
}

class DesktopAppPage extends StatelessWidget {
  const DesktopAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return PageScaffold(
      title: '电脑版',
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [p.primary.withValues(alpha: 0.16), p.primary.withValues(alpha: 0.03)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(T.radiusCard),
          ),
          child: Row(
            children: [
              const AppMark(size: 54),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('桌面端输入体验',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: p.text)),
                    const SizedBox(height: 4),
                    Text('与手机共享词库与常用语（复刻版为信息展示）',
                        style: TextStyle(fontSize: 12, color: p.textSecondary, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SettingsGroup(children: [
          NavRow(
            title: 'macOS 版',
            subtitle: '支持 Apple Silicon 与 Intel（信息展示）',
            icon: Icons.laptop_mac_rounded,
            trailing: '查看',
            onTap: () => _downloadInfo(context, 'macOS'),
          ),
          NavRow(
            title: 'Windows 版',
            subtitle: 'Windows 10 / 11（信息展示）',
            icon: Icons.desktop_windows_rounded,
            trailing: '查看',
            onTap: () => _downloadInfo(context, 'Windows'),
          ),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18)),
          child: Column(
            children: [
              Text('在电脑上继续', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.text)),
              const SizedBox(height: 10),
              SizedBox(
                width: 150,
                height: 150,
                child: CustomPaint(
                  painter: _FakeQrPainter(seed: 'desktop-download-info'),
                  child: const SizedBox.expand(),
                ),
              ),
              const SizedBox(height: 10),
              Text('扫码查看官网（公开信息）',
                  style: TextStyle(fontSize: 12, color: p.textSecondary)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton('复制官网链接', icon: Icons.copy_rounded, onPressed: () {
                      copyText(context, 'https://shurufa.doubao.com/pc', '官网链接已复制');
                    }),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton('打开官网', icon: Icons.open_in_new_rounded, onPressed: () async {
                      final ok = await PlatformBridge.openUrl('https://shurufa.doubao.com/pc');
                      if (context.mounted && !ok) toast(context, '无法打开浏览器，请手动访问');
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const InfoBanner('复刻版不提供官方桌面安装包，也不会下载或执行官方二进制。此页用于还原入口与复制交互。'),
      ],
    );
  }

  void _downloadInfo(BuildContext context, String platform) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$platform 版'),
        content: const Text('复刻版不包含官方桌面安装包。你可以复制公开官网链接，在浏览器中自行了解官方产品。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
          TextButton(
            onPressed: () {
              copyText(context, 'https://shurufa.doubao.com/pc', '官网链接已复制');
              Navigator.pop(ctx);
            },
            child: const Text('复制链接'),
          ),
        ],
      ),
    );
  }
}

class HelpFeedbackPage extends StatefulWidget {
  const HelpFeedbackPage({super.key});
  @override
  State<HelpFeedbackPage> createState() => _HelpFeedbackPageState();
}

class _HelpFeedbackPageState extends State<HelpFeedbackPage> {
  String _type = '功能建议';
  final _text = TextEditingController();
  final _contact = TextEditingController();

  static const _faq = <List<String>>[
    ['如何启用系统输入法？', 'Android：设置 → 系统 → 语言与输入法 → 屏幕键盘，开启「豆包输入法（复刻）」。iOS 复刻版未提供键盘扩展，请使用 App 内键盘体验。'],
    ['为什么 AI 功能显示离线示例？', '未配置 API Key，或当前处于基础输入模式。前往「AI 服务配置」填写你自己的 OpenAI 兼容服务信息，或切换到智能输入模式。'],
    ['语音识别提示不可用怎么办？', '模拟器可能没有系统语音识别服务。请确认麦克风与语音识别权限，或使用页面提供的“使用演示结果”。'],
    ['键盘候选排序为什么和官方不同？', '复刻版使用净室实现的 33,500 条本地词典与 MRU 排序，不复制官方私有词典，因此候选顺序会有差异。'],
    ['手写和五笔覆盖多少字？', '手写内置约 56 个常用字/数字模板；笔画约 60 个常用字；五笔约 70 条常用码。均为演示级覆盖。'],
    ['数据会上传吗？', '不会上传到官方服务。只有你配置 AI Key 并主动生成时，才会向你填写的 Base URL 发送当前文本。'],
  ];

  @override
  void dispose() {
    _text.dispose();
    _contact.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _text.text.trim();
    if (text.length < 4) {
      toast(context, '请至少输入 4 个字的反馈内容');
      return;
    }
    AppScope.of(context).addFeedback(_type, text);
    _text.clear();
    FocusScope.of(context).unfocus();
    toast(context, '反馈已保存到本机，感谢你的建议');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = AppScope.of(context);
    final feedbacks = s.feedbacks;
    return PageScaffold(
      title: '帮助与反馈',
      children: [
        const SectionTitle('常见问题'),
        Container(
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < _faq.length; i++)
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: p.divider),
                  child: ExpansionTile(
                    title: Text(_faq[i][0],
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: p.text)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: Text(_faq[i][1],
                            style: TextStyle(fontSize: 13, color: p.textSecondary, height: 1.6)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SectionTitle('提交反馈'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('反馈类型', style: TextStyle(fontSize: 13, color: p.text)),
              const SizedBox(height: 8),
              ChoiceChips(
                options: const ['功能建议', '问题反馈', '体验问题', '其他'],
                selected: _type,
                onSelected: (v) => setState(() => _type = v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _text,
                maxLines: 5,
                style: TextStyle(fontSize: 14, color: p.text),
                decoration: InputDecoration(
                  hintText: '请描述你遇到的问题或建议…',
                  filled: true,
                  fillColor: p.pageBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _contact,
                style: TextStyle(fontSize: 14, color: p.text),
                decoration: InputDecoration(
                  hintText: '联系方式（可选，仅保存在本机）',
                  filled: true,
                  fillColor: p.pageBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton('提交反馈', icon: Icons.send_rounded, onPressed: _submit),
              const SizedBox(height: 6),
              Text('反馈仅保存在本机，不会上传；提交后可在下方查看。',
                  style: TextStyle(fontSize: 11, color: p.textSecondary)),
            ],
          ),
        ),
        if (feedbacks.isNotEmpty) ...[
          const SectionTitle('已提交'),
          SettingsGroup(children: [
            for (var i = 0; i < feedbacks.length; i++)
              ListTile(
                leading: IconSquare(Icons.feedback_outlined, size: 34),
                title: Text((feedbacks[i]['text'] ?? '').toString(),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: p.text)),
                subtitle: Text('${feedbacks[i]['type']} · ${feedbacks[i]['time']}',
                    style: TextStyle(fontSize: 11, color: p.textSecondary)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  tooltip: '删除反馈',
                  onPressed: () {
                    s.deleteFeedback(i);
                    toast(context, '反馈记录已删除');
                  },
                ),
              ),
          ]),
        ],
        const SizedBox(height: 14),
        const InfoBanner('复刻版不连接官方客服中心；FAQ 与反馈均为本地实现，便于离线使用。'),
      ],
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = AppScope.of(context);
    return PageScaffold(
      title: '关于',
      children: [
        Center(
          child: Column(
            children: [
              const AppMark(size: 76),
              const SizedBox(height: 12),
              Text('豆包输入法（复刻）',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: p.text)),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TagChip('v1.5.2-clone'),
                  const SizedBox(width: 6),
                  TagChip('非官方复刻', color: const Color(0xFF23A26D)),
                ],
              ),
              const SizedBox(height: 8),
              Text('净室行为复刻 · Flutter 通用版',
                  style: TextStyle(fontSize: 12, color: p.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SettingsGroup(children: [
          ValueRow(title: '版本', value: '1.5.2-clone'),
          ValueRow(title: '构建时间', value: '2026-10-20'),
          ValueRow(title: 'DID', value: s.deviceId),
          NavRow(
            title: '检查更新',
            subtitle: '模拟检查，不连接官方升级服务',
            trailing: '检查',
            onTap: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => const Center(child: CircularProgressIndicator()),
              );
              await Future.delayed(const Duration(milliseconds: 900));
              if (!context.mounted) return;
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('检查更新'),
                  content: const Text('当前已是最新复刻版 v1.5.2-clone。复刻版不连接官方升级服务。'),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('知道了'))],
                ),
              );
            },
          ),
          NavRow(
            title: '开源许可',
            subtitle: 'Flutter、词典与依赖许可',
            onTap: () {
              Navigator.of(context).pushNamed('/text',
                  arguments: {'title': '开源许可', 'content': licensesText});
            },
          ),
        ]),
        const SectionTitle('协议与隐私'),
        SettingsGroup(children: [
          NavRow(
            title: '用户协议',
            onTap: () => Navigator.of(context).pushNamed('/text',
                arguments: {'title': '用户协议', 'content': agreementText}),
          ),
          NavRow(
            title: '隐私政策',
            onTap: () => Navigator.of(context).pushNamed('/text',
                arguments: {'title': '隐私政策', 'content': privacyText}),
          ),
          NavRow(
            title: '权限清单',
            onTap: () => Navigator.of(context).pushNamed('/text',
                arguments: {'title': '权限清单', 'content': permissionsText}),
          ),
          NavRow(
            title: '查看完整依赖许可',
            onTap: () => showLicensePage(
              context: context,
              applicationName: '豆包输入法（复刻）',
              applicationVersion: '1.5.2-clone',
              applicationLegalese: 'Clean-room clone. Not affiliated with ByteDance.',
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Center(
          child: Text('本应用与字节跳动及其关联公司无任何隶属关系。\n产品名称仅用于说明复刻对象。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: p.textSecondary, height: 1.6)),
        ),
      ],
    );
  }
}

class AISettingsPage extends StatefulWidget {
  const AISettingsPage({super.key});
  @override
  State<AISettingsPage> createState() => _AISettingsPageState();
}

class _AISettingsPageState extends State<AISettingsPage> {
  late final TextEditingController _base;
  late final TextEditingController _model;
  late final TextEditingController _key;
  bool _obscure = true;
  bool _busy = false;
  String? _result;
  bool _ok = false;

  @override
  void initState() {
    super.initState();
    final s = AppScope.of(context);
    _base = TextEditingController(text: s.aiBaseUrl);
    _model = TextEditingController(text: s.aiModel);
    _key = TextEditingController(text: s.aiKeyEffective);
  }

  @override
  void dispose() {
    _base.dispose();
    _model.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _save({bool quiet = false}) async {
    final s = AppScope.of(context);
    final base = _base.text.trim();
    final model = _model.text.trim();
    if (base.isNotEmpty && !base.startsWith('http://') && !base.startsWith('https://')) {
      toast(context, 'Base URL 需要以 http:// 或 https:// 开头');
      return;
    }
    s.setString(K.aiBaseUrl, base.isEmpty ? 'https://api.deepseek.com' : base);
    s.setString(K.aiModel, model.isEmpty ? 'deepseek-chat' : model);
    await s.setAiKey(_key.text);
    if (mounted && !quiet) {
      toast(context, 'AI 服务设置已保存${s.secureStorageOk ? '' : '（安全存储不可用，Key 存入本地偏好）'}');
    }
  }

  Future<void> _test() async {
    final s = AppScope.of(context);
    if (_key.text.trim().isEmpty) {
      toast(context, '请先输入 API Key');
      return;
    }
    if (!s.isSmartMode) {
      toast(context, '基础输入模式下 AI 不可用，请先切换模式');
      return;
    }
    setState(() {
      _busy = true;
      _result = null;
    });
    await _save(quiet: true);
    try {
      final reply = await AiService.testConnection();
      if (!mounted) return;
      setState(() {
        _ok = true;
        _result = '连接成功：${reply.length > 60 ? reply.substring(0, 60) : reply}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ok = false;
        _result = '连接失败：$e';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = AppScope.of(context);
    return PageScaffold(
      title: 'AI 服务配置',
      children: [
        InfoBanner(
          s.isSmartMode
              ? '使用你自己的 OpenAI 兼容服务（默认 DeepSeek）。Key 只在运行时读取，不会写入代码、日志或仓库。'
              : '当前为基础输入模式。保存 Key 后仍需切换到智能输入模式才能调用 AI。',
          icon: Icons.key_rounded,
          color: s.isSmartMode ? p.primary : const Color(0xFFE08A00),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(context, 'Base URL'),
              TextField(
                controller: _base,
                keyboardType: TextInputType.url,
                autocorrect: false,
                style: TextStyle(fontSize: 14, color: p.text),
                decoration: _decoration(context, 'https://api.deepseek.com'),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  for (final u in const ['https://api.deepseek.com', 'https://api.openai.com'])
                    ActionChip(
                      label: Text(u.replaceAll('https://', ''), style: const TextStyle(fontSize: 10)),
                      onPressed: () => setState(() => _base.text = u),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _label(context, '模型'),
              TextField(
                controller: _model,
                autocorrect: false,
                style: TextStyle(fontSize: 14, color: p.text),
                decoration: _decoration(context, 'deepseek-chat'),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  for (final m in const ['deepseek-chat', 'deepseek-flash', 'deepseek-reasoner'])
                    ActionChip(
                      label: Text(m, style: const TextStyle(fontSize: 10)),
                      onPressed: () => setState(() => _model.text = m),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _label(context, 'API Key'),
              TextField(
                controller: _key,
                obscureText: _obscure,
                autocorrect: false,
                enableSuggestions: false,
                style: TextStyle(fontSize: 14, color: p.text),
                decoration: _decoration(context, 'sk-…').copyWith(
                  suffixIcon: IconButton(
                    tooltip: _obscure ? '显示 Key' : '隐藏 Key',
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.secureStorageOk
                    ? 'Key 使用平台安全存储（Keychain / EncryptedSharedPreferences）保存。'
                    : '警告：安全存储不可用，Key 将退回本地偏好存储，请自行评估风险。',
                style: TextStyle(
                  fontSize: 11,
                  color: s.secureStorageOk ? p.textSecondary : p.danger,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(_busy ? '测试中…' : '测试连接',
                        icon: Icons.wifi_tethering_rounded,
                        onPressed: _busy ? null : _test),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton('保存', icon: Icons.save_outlined,
                        onPressed: _busy ? null : () => _save()),
                  ),
                ],
              ),
              if (_result != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_ok ? const Color(0xFF23A26D) : p.danger).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_result!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _ok ? const Color(0xFF1D8A5B) : p.danger,
                        height: 1.5,
                      )),
                ),
              ],
              if (_key.text.trim().isEmpty) ...[
                const SizedBox(height: 8),
                Text('未配置 Key：AI 写作、整理、翻译会使用本地模板，并标注「离线示例」。',
                    style: TextStyle(fontSize: 11, color: p.textSecondary)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        SettingsGroup(children: [
          NavRow(
            title: '输入模式',
            subtitle: s.isSmartMode ? '智能输入模式' : '基础输入模式（AI 不可用）',
            onTap: () => Navigator.of(context).pushNamed('/input-mode'),
          ),
          NavRow(
            title: '清空 API Key',
            subtitle: '从本机安全存储中删除 Key',
            trailing: '清空',
            onTap: () async {
              final ok = await confirm(context,
                  title: '清空 API Key', message: '清空后 AI 功能会退回本地模板，可随时重新填写。',
                  danger: true, ok: '清空');
              if (!ok) return;
              await s.clearAiKey();
              if (context.mounted) {
                setState(() => _key.clear());
                toast(context, 'API Key 已清空');
              }
            },
          ),
        ]),
        const SizedBox(height: 12),
        const InfoBanner('请求格式：POST {base}/v1/chat/completions（base 以 /v1 结尾时自动省略重复段），超时 20 秒。不会在日志中打印 Key 或请求头。'),
      ],
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(text,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.pal.text)),
      );

  InputDecoration _decoration(BuildContext context, String hint) {
    final p = context.pal;
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: p.pageBg,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

class ImeTestPage extends StatefulWidget {
  const ImeTestPage({super.key});
  @override
  State<ImeTestPage> createState() => _ImeTestPageState();
}

class _ImeTestPageState extends State<ImeTestPage> {
  final _single = TextEditingController();
  final _multi = TextEditingController();
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final v = await PlatformBridge.isImeEnabled();
    if (mounted) setState(() => _enabled = v);
  }

  @override
  void dispose() {
    _single.dispose();
    _multi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return PageScaffold(
      title: '系统输入法测试',
      actions: [
        IconButton(
          tooltip: '刷新输入法状态',
          icon: const Icon(Icons.refresh_rounded, size: 21),
          onPressed: _check,
        ),
      ],
      children: [
        InfoBanner(
          _enabled == null
              ? '正在检查输入法状态…'
              : (_enabled! ? '已检测到「豆包输入法（复刻）」系统输入法' : '尚未启用系统输入法，请先打开输入法设置'),
          icon: _enabled == true ? Icons.check_circle_outline_rounded : Icons.info_outline,
          color: _enabled == true ? const Color(0xFF23A26D) : p.primary,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('单行输入框（点击唤起系统键盘）',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.text)),
              const SizedBox(height: 8),
              TextField(
                controller: _single,
                style: TextStyle(fontSize: 16, color: p.text),
                decoration: InputDecoration(
                  hintText: '在这里用系统输入法输入中文…',
                  filled: true,
                  fillColor: p.pageBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('多行输入框',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.text)),
              const SizedBox(height: 8),
              TextField(
                controller: _multi,
                maxLines: 5,
                style: TextStyle(fontSize: 15, color: p.text),
                decoration: InputDecoration(
                  hintText: '可测试删除、换行、候选翻页与符号输入…',
                  filled: true,
                  fillColor: p.pageBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton('清空', icon: Icons.clear_rounded, onPressed: () {
                      _single.clear();
                      _multi.clear();
                      toast(context, '输入内容已清空');
                    }),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton('打开输入法设置', icon: Icons.settings_outlined, onPressed: () async {
                      final ok = await PlatformBridge.openImeSettings();
                      if (context.mounted && !ok) toast(context, '无法打开系统输入法设置');
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const InfoBanner('此页使用系统输入法（不是 App 内键盘体验）。原生 Kotlin IME 支持 26 键拼音、候选上屏、删除、空格、中英切换与 123 数字布局。'),
      ],
    );
  }
}

class _FakeQrPainter extends CustomPainter {
  final String seed;
  _FakeQrPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final n = 25;
    final cell = size.width / n;
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final rnd = Random(seed.hashCode);
    final black = Paint()..color = const Color(0xFF111111);
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        final finder = (x < 7 && y < 7) || (x >= n - 7 && y < 7) || (x < 7 && y >= n - 7);
        var paint = false;
        if (finder) {
          final lx = x >= n - 7 ? x - (n - 7) : x;
          final ly = y >= n - 7 ? y - (n - 7) : y;
          final edge = lx == 0 || lx == 6 || ly == 0 || ly == 6;
          final inner = lx >= 2 && lx <= 4 && ly >= 2 && ly <= 4;
          paint = edge || inner;
        } else {
          paint = rnd.nextBool();
        }
        if (paint) {
          canvas.drawRect(
            Rect.fromLTWH(x * cell + 0.2, y * cell + 0.2, cell - 0.4, cell - 0.4),
            black,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FakeQrPainter oldDelegate) => oldDelegate.seed != seed;
}
