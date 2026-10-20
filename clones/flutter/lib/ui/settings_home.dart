import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/platform_bridge.dart';
import '../theme.dart';
import 'widgets.dart';

class SettingsHomePage extends StatefulWidget {
  const SettingsHomePage({super.key});
  @override
  State<SettingsHomePage> createState() => _SettingsHomePageState();
}

class _SettingsHomePageState extends State<SettingsHomePage> {
  final PageController _banner = PageController(viewportFraction: 0.94);
  Timer? _timer;
  int _bannerIndex = 0;

  static const _banners = <_BannerData>[
    _BannerData('全场景语音精准识别', '支持中文、英语与 20+ 种方言', Icons.mic_rounded, '语音设置', '/voice-settings',
        [Color(0xFF4F84FF), Color(0xFF7FA8FF)]),
    _BannerData('智能联想', '根据上文推荐词语、表情与符号', Icons.auto_awesome_rounded, '联想设置', '/association',
        [Color(0xFF6B7CFF), Color(0xFF9A8CFF)]),
    _BannerData('智能文字整理', '口语一键变成清晰书面表达', Icons.text_fields_rounded, '去设置', '/voice-settings',
        [Color(0xFF2BB5A0), Color(0xFF5FD3BE)]),
    _BannerData('离线语音', '没有网络也能完成语音输入', Icons.cloud_off_rounded, '离线语音', '/offline-voice',
        [Color(0xFF8E7BFF), Color(0xFFB6A5FF)]),
    _BannerData('超级互传', '手机与电脑之间快速互传文字', Icons.sync_alt_rounded, '了解更多', '/transfer',
        [Color(0xFF3E8BFF), Color(0xFF55C2FF)]),
    _BannerData('电脑桌面端', 'macOS 与 Windows 双端体验', Icons.desktop_windows_rounded, '查看电脑版', '/desktop',
        [Color(0xFF4A5B8C), Color(0xFF7086C9)]),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_banner.hasClients) return;
      final next = (_bannerIndex + 1) % _banners.length;
      _banner.animateToPage(next,
          duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _banner.dispose();
    super.dispose();
  }

  void _switch(BuildContext context, AppState s, String key, bool v, String label) {
    s.setBool(key, v);
    toast(context, '$label已${v ? '开启' : '关闭'}');
  }

  Future<void> _toggleSms(BuildContext context, AppState s, bool v) async {
    if (!v) {
      s.setBool('sms_fill', false);
      toast(context, '验证码填充已关闭');
      return;
    }
    final ok = await confirm(
      context,
      title: '验证码填充',
      message: '复刻版不会读取短信正文，仅在你手动点击时提供验证码粘贴入口。需要系统短信/通知权限状态。',
      ok: '开启',
    );
    if (!context.mounted) return;
    if (ok) {
      s.setBool('sms_fill', true);
      toast(context, '验证码填充已开启');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = AppScope.of(context);
    final keyboardLabel = switch (s.keyboardType) {
      'pinyin9' => '拼音 9 键',
      'pinyin26' => '拼音 26 键',
      'handwriting' => '手写键盘',
      'stroke' => '笔画键盘',
      'shuangpin' => '双拼键盘',
      'wubi' => '五笔键盘',
      _ => '未设置',
    };
    return Scaffold(
      backgroundColor: p.pageBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
              children: [
                _header(context, s),
                const SizedBox(height: 14),
                _keyboardCta(context),
                const SizedBox(height: 18),
                SizedBox(
                  height: 188,
                  child: PageView.builder(
                    controller: _banner,
                    onPageChanged: (i) => setState(() => _bannerIndex = i),
                    itemCount: _banners.length,
                    itemBuilder: (context, i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _BannerCard(
                          data: _banners[i],
                          onTap: () => Navigator.of(context).pushNamed(_banners[i].route),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_banners.length, (i) {
                    final active = i == _bannerIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active ? p.primary : p.divider,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
                const SectionTitle('语音输入', icon: Icons.mic_none_rounded),
                SettingsGroup(children: [
                  NavRow(
                    title: '语音转文字',
                    subtitle: '标点显示、智能整理、离线语音等',
                    icon: Icons.graphic_eq_rounded,
                    onTap: () => Navigator.of(context).pushNamed('/voice-settings'),
                  ),
                  NavRow(
                    title: '语音口令',
                    subtitle: s.voiceActionEnabled ? '已启用 · ${s.voiceActions.length} 个口令' : '用说话完成发送',
                    icon: Icons.record_voice_over_outlined,
                    onTap: () => Navigator.of(context).pushNamed('/voice-action'),
                  ),
                ]),
                const SectionTitle('键盘输入', icon: Icons.keyboard_alt_outlined),
                SettingsGroup(children: [
                  NavRow(
                    title: '键盘类型',
                    subtitle: '9 键、26 键、手写、双拼、五笔等',
                    trailing: keyboardLabel,
                    icon: Icons.dialpad_rounded,
                    onTap: () => Navigator.of(context).pushNamed('/keyboard-types'),
                  ),
                  NavRow(
                    title: '布局与显示',
                    subtitle: '键盘布局、外观、候选字大小等',
                    icon: Icons.dashboard_customize_outlined,
                    onTap: () => Navigator.of(context).pushNamed('/layout'),
                  ),
                  NavRow(
                    title: '模糊拼音',
                    subtitle: '设置打字习惯，如 z=zh、in=ing、n=l',
                    trailing: s.getBool(K.fuzzyEnabled) ? '已开启' : '已关闭',
                    icon: Icons.blur_on_rounded,
                    onTap: () => Navigator.of(context).pushNamed('/fuzzy'),
                  ),
                  NavRow(
                    title: '智能联想',
                    subtitle: '根据上文推荐文字、表情、符号等',
                    trailing: s.getBool(K.associationEnabled) ? '已开启' : '已关闭',
                    icon: Icons.bubble_chart_outlined,
                    onTap: () => Navigator.of(context).pushNamed('/association'),
                  ),
                  NavRow(
                    title: '输入预测类型',
                    subtitle: 'Emoji、图片表情、颜文字',
                    icon: Icons.emoji_emotions_outlined,
                    onTap: () => Navigator.of(context).pushNamed('/prediction'),
                  ),
                  NavRow(
                    title: '按键反馈',
                    subtitle: '声音、振动、气泡与响应速度',
                    icon: Icons.touch_app_outlined,
                    onTap: () => Navigator.of(context).pushNamed('/key-feedback'),
                  ),
                  NavRow(
                    title: '快捷格式输入',
                    subtitle: '中英数空格、首字母大写等',
                    icon: Icons.text_format_rounded,
                    onTap: () => Navigator.of(context).pushNamed('/quick-format'),
                  ),
                  SwitchRow(
                    title: '辅助输入',
                    subtitle: '在候选栏展示更多辅助入口',
                    value: s.getBool('auxiliary_input'),
                    onChanged: (v) => _switch(context, s, 'auxiliary_input', v, '辅助输入'),
                  ),
                ]),
                const SectionTitle('工具', icon: Icons.build_outlined),
                SettingsGroup(children: [
                  NavRow(
                    title: '超级互传',
                    subtitle: '手机与电脑互传文字和图片',
                    trailing: s.superTransferEnabled ? '已启用' : '未启用',
                    icon: Icons.devices_other_rounded,
                    onTap: () => Navigator.of(context).pushNamed('/transfer'),
                  ),
                  NavRow(
                    title: '剪切板',
                    subtitle: '候选栏展示、历史记录与清空',
                    trailing: '${s.clipboardItems.length} 条',
                    icon: Icons.content_paste_rounded,
                    onTap: () => Navigator.of(context).pushNamed('/clipboard-settings'),
                  ),
                  SwitchRow(
                    title: '验证码填充',
                    subtitle: '需要短信/通知权限状态，复刻版不读短信正文',
                    value: s.getBool('sms_fill'),
                    onChanged: (v) => _toggleSms(context, s, v),
                  ),
                  SwitchRow(
                    title: '导入通讯录人名',
                    subtitle: '将姓名加入本地词库，提升候选准确率',
                    value: s.getBool('contacts_import'),
                    onChanged: (v) {
                      s.setBool('contacts_import', v);
                      toast(context, v ? '开关已开启，可在词库管理中导入' : '已关闭通讯录导入');
                    },
                  ),
                  NavRow(
                    title: '词库管理',
                    subtitle: '个人词库、通讯录词库与清空',
                    trailing: s.lexicon.isEmpty ? '暂无自定义' : '${s.lexicon.length} 条',
                    icon: Icons.menu_book_outlined,
                    onTap: () => Navigator.of(context).pushNamed('/lexicon'),
                  ),
                ]),
                const SectionTitle('隐私与权限', icon: Icons.shield_outlined),
                SettingsGroup(children: [
                  NavRow(
                    title: '输入模式与信息保护',
                    subtitle: '智能 / 基础模式、第三方共享、协议',
                    trailing: s.isSmartMode ? '智能输入' : '基础输入',
                    icon: Icons.privacy_tip_outlined,
                    onTap: () => Navigator.of(context).pushNamed('/input-mode'),
                  ),
                  NavRow(
                    title: '智能输入设置',
                    subtitle: '云端使用部分输入信息、个人词库',
                    icon: Icons.cloud_outlined,
                    onTap: () => Navigator.of(context).pushNamed('/smart-input'),
                  ),
                  SwitchRow(
                    title: '加入体验改进计划',
                    subtitle: '仅保存本地统计，不自动上传',
                    value: s.getBool('improvement_plan'),
                    onChanged: (v) => _switch(context, s, 'improvement_plan', v, '体验改进计划'),
                  ),
                  NavRow(
                    title: '系统权限设置',
                    subtitle: '短信、通讯录、麦克风、相机、通知',
                    icon: Icons.admin_panel_settings_outlined,
                    onTap: () => Navigator.of(context).pushNamed('/permissions'),
                  ),
                ]),
                const SectionTitle('AI 服务', icon: Icons.auto_awesome_rounded),
                SettingsGroup(children: [
                  NavRow(
                    title: 'AI 服务配置',
                    subtitle: s.aiConfigured
                        ? '${s.aiModel} · 已配置 Key'
                        : '未配置 Key，所有 AI 功能使用本地模板',
                    trailing: s.aiConfigured ? '已就绪' : '未配置',
                    icon: Icons.settings_suggest_outlined,
                    onTap: () => Navigator.of(context).pushNamed('/ai-settings'),
                  ),
                  NavRow(
                    title: '键盘体验',
                    subtitle: '完整键盘、工具箱、语音、AI 与所有面板',
                    icon: Icons.play_circle_outline_rounded,
                    onTap: () => Navigator.of(context).pushNamed('/keyboard'),
                  ),
                ]),
                const SectionTitle('更多', icon: Icons.more_horiz_rounded),
                SettingsGroup(children: [
                  NavRow(
                    title: '电脑版',
                    subtitle: 'macOS / Windows 信息与官网链接',
                    icon: Icons.computer_rounded,
                    onTap: () => Navigator.of(context).pushNamed('/desktop'),
                  ),
                  NavRow(
                    title: '帮助与反馈',
                    subtitle: '常见问题、反馈类型与本地提交',
                    icon: Icons.help_outline_rounded,
                    onTap: () => Navigator.of(context).pushNamed('/help'),
                  ),
                  if (PlatformBridge.isAndroid)
                    NavRow(
                      title: '系统输入法测试',
                      subtitle: '打开普通输入框，调起本机系统输入法',
                      icon: Icons.keyboard_rounded,
                      onTap: () => Navigator.of(context).pushNamed('/ime-test'),
                    ),
                  NavRow(
                    title: '关于',
                    subtitle: '版本 1.5.2-clone · 非官方复刻',
                    icon: Icons.info_outline_rounded,
                    onTap: () => Navigator.of(context).pushNamed('/about'),
                  ),
                ]),
                const SizedBox(height: 22),
                Center(
                  child: Text('豆包输入法（复刻）· 净室实现 · 非官方产品\n所有设置均保存在本机',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: p.textSecondary, height: 1.6)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AppState s) {
    final p = context.pal;
    return Row(
      children: [
        const AppMark(size: 46),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('豆包输入法（复刻）',
                      style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: p.text)),
                  const SizedBox(width: 8),
                  TagChip('复刻', color: p.primary),
                ],
              ),
              const SizedBox(height: 2),
              Text(s.loggedIn ? '${s.accountName} · 本地账号' : '非官方净室复刻 · 本地优先',
                  style: TextStyle(fontSize: 12, color: p.textSecondary)),
            ],
          ),
        ),
        InkWell(
          onTap: () => Navigator.of(context).pushNamed('/account'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                const Center(child: Icon(Icons.person_outline_rounded, size: 22)),
                if (s.unreadMessages > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: p.danger, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _keyboardCta(BuildContext context) {
    final p = context.pal;
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed('/keyboard'),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.keyboard_alt_outlined, size: 18, color: p.primary),
                      const SizedBox(width: 6),
                      Text('键盘体验',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.text)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text('26键 · 9键 · 手写 · 双拼 · 五笔\n工具箱、语音、AI 与全部面板',
                      style: TextStyle(fontSize: 12, color: p.textSecondary, height: 1.45)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: p.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text('立即体验',
                        style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 150,
              height: 92,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: p.keyboardBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    for (final row in const [
                      ['Q', 'W', 'E', 'R', 'T', 'Y'],
                      ['A', 'S', 'D', 'F', 'G', 'H'],
                      ['Z', 'X', 'C', 'V', 'B', 'N'],
                    ])
                      Expanded(
                        child: Row(
                          children: [
                            for (final k in row)
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.all(1.5),
                                  decoration: BoxDecoration(
                                    color: p.key,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Center(
                                    child: Text(k,
                                        style: TextStyle(fontSize: 9, color: p.textSecondary)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: _miniBar(p)),
                          Container(width: 18, margin: const EdgeInsets.all(1.5), decoration: BoxDecoration(color: p.primary, borderRadius: BorderRadius.circular(4))),
                          Expanded(flex: 3, child: _miniBar(p)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniBar(AppPalette p) => Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(color: p.key, borderRadius: BorderRadius.circular(4)),
      );
}

class _BannerData {
  final String title;
  final String subtitle;
  final IconData icon;
  final String action;
  final String route;
  final List<Color> colors;
  const _BannerData(this.title, this.subtitle, this.icon, this.action, this.route, this.colors);
}

class _BannerCard extends StatelessWidget {
  final _BannerData data;
  final VoidCallback onTap;
  const _BannerCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: data.colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              bottom: -40,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              right: 24,
              top: 24,
              child: Icon(data.icon, size: 64, color: Colors.white.withValues(alpha: 0.3)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Spacer(),
                  Text(data.title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 5),
                  Text(data.subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.86))),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(data.action,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
