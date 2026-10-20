import 'package:flutter/material.dart';
import '../core/docs.dart';
import '../core/platform_bridge.dart';
import '../theme.dart';
import 'widgets.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;
  bool? _imeEnabled;

  Future<void> _refreshIme() async {
    final v = await PlatformBridge.isImeEnabled();
    if (!mounted) return;
    setState(() => _imeEnabled = v);
  }

  Future<void> _openIme() async {
    final ok = await PlatformBridge.openImeSettings();
    if (!mounted) return;
    if (!ok) toast(context, '无法自动打开，请前往「设置 → 系统 → 语言与输入法」');
  }

  Future<void> _showPicker() async {
    final ok = await PlatformBridge.showImePicker();
    if (!mounted) return;
    if (!ok) toast(context, '当前平台需在系统设置中添加键盘');
  }

  void _next() {
    if (_page == 0) {
      _controller.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
      setState(() => _page = 1);
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyConsentPage()));
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshIme();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.pageBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
                  child: Row(
                    children: [
                      const AppMark(size: 40),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('豆包输入法（复刻）',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: p.text)),
                            Text('非官方净室复刻版',
                                style: TextStyle(fontSize: 11, color: p.textSecondary)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PrivacyConsentPage()),
                        ),
                        child: const Text('稍后设置'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _page = i),
                    children: [
                      _GuidePage(
                        step: '01',
                        title: '启用输入法',
                        subtitle: '在系统设置中开启「豆包输入法（复刻）」，\n它才能出现在键盘列表里。',
                        icon: Icons.power_settings_new_rounded,
                        points: const [
                          'Android：设置 → 系统 → 语言与输入法 → 屏幕键盘',
                          'iOS：设置 → 通用 → 键盘 → 添加新键盘',
                          '复刻版不会连接官方服务，输入数据默认留在本机',
                        ],
                        primaryLabel: PlatformBridge.isAndroid ? '打开输入法设置' : '打开系统设置',
                        onPrimary: _openIme,
                        secondaryLabel: PlatformBridge.isAndroid ? '检测启用状态' : '重新检测',
                        onSecondary: _refreshIme,
                        status: _imeEnabled == null
                            ? null
                            : (_imeEnabled! ? '已检测到输入法' : '尚未检测到，请按指引手动启用'),
                      ),
                      _GuidePage(
                        step: '02',
                        title: '切换到输入法',
                        subtitle: '唤起系统输入法选择器，\n选择「豆包输入法（复刻）」开始输入。',
                        icon: Icons.keyboard_alt_outlined,
                        points: PlatformBridge.isAndroid
                            ? const [
                                '在任意输入框点击，然后选择本输入法',
                                '长按空格键也可以切换输入法',
                                '也可以直接进入 App 内键盘体验，无需切换',
                              ]
                            : const [
                                '设置 → 通用 → 键盘 → 键盘 → 添加新键盘',
                                '选择「豆包输入法（复刻）」并允许完全访问',
                                '在输入框长按地球键切换键盘',
                              ],
                        primaryLabel: PlatformBridge.isAndroid ? '打开输入法选择器' : '打开系统设置',
                        onPrimary: PlatformBridge.isAndroid ? _showPicker : _openIme,
                        secondaryLabel: '进入键盘体验（可稍后）',
                        onSecondary: () => Navigator.of(context).pushNamed('/keyboard'),
                        status: null,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(2, (i) {
                          final active = i == _page;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 22 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: active ? p.primary : p.divider,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 18),
                      PrimaryButton(_page == 0 ? '下一步' : '完成，继续',
                          icon: Icons.arrow_forward_rounded, onPressed: _next),
                      const SizedBox(height: 6),
                      Text('继续即表示你已阅读并同意《用户协议》与《隐私政策》',
                          style: TextStyle(fontSize: 11, color: p.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuidePage extends StatelessWidget {
  final String step;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> points;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;
  final String? status;

  const _GuidePage({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.points,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [p.primary.withValues(alpha: 0.15), p.primary.withValues(alpha: 0.04)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: p.primary.withValues(alpha: 0.18),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Icon(icon, size: 52, color: p.primary),
                  ),
                ),
                Positioned(
                  left: 18,
                  top: 16,
                  child: Text(step,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: p.primary.withValues(alpha: 0.25),
                      )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(title, style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700, color: p.text)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: TextStyle(fontSize: 14, color: p.textSecondary, height: 1.55)),
          const SizedBox(height: 20),
          ...points.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: p.primary, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s,
                          style: TextStyle(fontSize: 13, color: p.text, height: 1.45)),
                    ),
                  ],
                ),
              )),
          if (status != null) ...[
            const SizedBox(height: 6),
            InfoBanner(status!,
                icon: status!.contains('已检测') ? Icons.check_circle_outline : Icons.info_outline,
                color: status!.contains('已检测') ? const Color(0xFF23A26D) : p.primary),
          ],
          const SizedBox(height: 18),
          PrimaryButton(primaryLabel, icon: Icons.settings_outlined, onPressed: onPrimary),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: onSecondary,
              child: Text(secondaryLabel, style: const TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyConsentPage extends StatefulWidget {
  const PrivacyConsentPage({super.key});
  @override
  State<PrivacyConsentPage> createState() => _PrivacyConsentPageState();
}

class _PrivacyConsentPageState extends State<PrivacyConsentPage> {
  String _mode = 'smart';

  void _finish(String mode) {
    AppScope.of(context).completeConsent(mode);
    Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
  }

  void _openDoc(String title, String content) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PolicyTextPage(title: title, content: content),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.pageBg,
      appBar: AppBar(
        title: const Text('隐私保护说明'),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.maybePop(context))
            : null,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          decoration: BoxDecoration(
            color: p.pageBg,
            border: Border(top: BorderSide(color: p.divider)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PrimaryButton(
                _mode == 'smart' ? '同意并继续（智能输入）' : '同意并继续（基础输入）',
                icon: Icons.check_rounded,
                onPressed: () => _finish(_mode),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => _finish('basic'),
                child: const Text('拒绝，使用基础输入模式'),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Center(child: AppMark(size: 58)),
                const SizedBox(height: 14),
                Text('先选择你的输入模式',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: p.text)),
                const SizedBox(height: 8),
                Text('复刻版不连接豆包官方服务。智能输入仅在你配置自己的\nAI Key 后调用你指定的 OpenAI 兼容服务。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: p.textSecondary, height: 1.55)),
                const SizedBox(height: 22),
                _ModeCard(
                  title: '智能输入模式',
                  tag: '推荐',
                  selected: _mode == 'smart',
                  icon: Icons.auto_awesome_rounded,
                  points: const [
                    '可使用 AI 写作、整理、翻译（需自备 Key）',
                    '启用本地联想与表情预测',
                    '语音识别调用系统服务',
                  ],
                  note: '输入内容不会发送到官方服务器。',
                  onTap: () => setState(() => _mode = 'smart'),
                ),
                const SizedBox(height: 12),
                _ModeCard(
                  title: '基础输入模式',
                  selected: _mode == 'basic',
                  icon: Icons.shield_outlined,
                  points: const [
                    '仅本地拼音 / 手写 / 笔画 / 词库',
                    'AI、翻译、智能整理显示为不可用',
                    '所有设置仍可正常访问',
                  ],
                  note: '最保守的选择，适合只想要本地键盘的用户。',
                  onTap: () => setState(() => _mode = 'basic'),
                ),
                const SizedBox(height: 20),
                SettingsGroup(children: [
                  NavRow(
                    title: '用户协议',
                    subtitle: '复刻版使用说明与行为约定',
                    onTap: () => _openDoc('用户协议', agreementText),
                  ),
                  NavRow(
                    title: '隐私政策',
                    subtitle: '本地数据、权限与第三方服务说明',
                    onTap: () => _openDoc('隐私政策', privacyText),
                  ),
                  NavRow(
                    title: '第三方共享清单',
                    subtitle: '仅在你配置后调用你自己选择的 AI 服务',
                    onTap: () => _openDoc('第三方共享清单', thirdPartyText),
                  ),
                ]),
                const SizedBox(height: 12),
                Text('提示：本应用为净室行为复刻，非豆包官方产品。不会上传通讯录、短信或剪贴板内容到官方服务。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: p.textSecondary, height: 1.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String? tag;
  final bool selected;
  final IconData icon;
  final List<String> points;
  final String note;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    this.tag,
    required this.selected,
    required this.icon,
    required this.points,
    required this.note,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(T.radiusCard),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(T.radiusCard),
          border: Border.all(color: selected ? p.primary : p.divider, width: selected ? 1.8 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconSquare(icon, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600, color: p.text)),
                      if (tag != null) ...[const SizedBox(width: 8), TagChip(tag!)],
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                  color: selected ? p.primary : p.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...points.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check, size: 14, color: p.primary),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(s,
                            style: TextStyle(fontSize: 13, color: p.textSecondary, height: 1.4)),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 6),
            Text(note, style: TextStyle(fontSize: 11, color: p.textSecondary.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }
}

class KeyboardTypePickerPage extends StatelessWidget {
  final bool firstRun;
  const KeyboardTypePickerPage({super.key, this.firstRun = false});

  static const types = <List<String>>[
    ['pinyin9', '拼音 9 键', '单手快速输入，T9 候选', '9'],
    ['pinyin26', '拼音 26 键', '全键盘，支持上滑数字', '26'],
    ['handwriting', '手写键盘', '手写画布，模板识别', '手'],
    ['stroke', '笔画键盘', '横竖撇捺折五笔画', '笔'],
    ['shuangpin', '双拼键盘', '小鹤 / 自然码双拼', '双'],
    ['wubi', '五笔键盘', '五笔 86 演示码表', '五'],
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final state = AppScope.of(context);
    final selected = state.keyboardType.isEmpty ? 'pinyin26' : state.keyboardType;
    return Scaffold(
      backgroundColor: p.pageBg,
      appBar: AppBar(
        title: Text(firstRun ? '选择键盘类型' : '键盘类型'),
        automaticallyImplyLeading: !firstRun,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(builder: (context, constraints) {
                    final cols = constraints.maxWidth > 700 ? 3 : 2;
                    final rows = (types.length / cols).ceil();
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: rows > 2 ? 0.92 : 1.12,
                      ),
                      itemCount: types.length,
                      itemBuilder: (context, i) {
                        final t = types[i];
                        return _TypeCard(
                          code: t[0],
                          title: t[1],
                          subtitle: t[2],
                          glyph: t[3],
                          selected: selected == t[0],
                          onTap: () {
                            state.setKeyboardType(t[0]);
                            if (t[0] == 'shuangpin') {
                              Navigator.of(context).pushNamed('/double-pinyin');
                            } else if (t[0] == 'wubi') {
                              Navigator.of(context).pushNamed('/wubi');
                            } else {
                              toast(context, '已选择 ${t[1]}');
                            }
                          },
                        );
                      },
                    );
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                  child: Column(
                    children: [
                      Text(
                        '当前：${types.firstWhere((e) => e[0] == selected)[1]} · 之后可在「键盘类型」中修改',
                        style: TextStyle(fontSize: 12, color: p.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      PrimaryButton(firstRun ? '开始使用' : '完成', icon: Icons.check_rounded, onPressed: () {
                        if (firstRun) {
                          Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
                        } else {
                          Navigator.of(context).pop();
                        }
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String code;
  final String title;
  final String subtitle;
  final String glyph;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.glyph,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(T.radiusCard),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(T.radiusCard),
          border: Border.all(color: selected ? p.primary : p.divider, width: selected ? 1.8 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected ? p.primary : p.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(glyph,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : p.primary,
                        )),
                  ),
                ),
                const Spacer(),
                if (selected) Icon(Icons.check_circle_rounded, color: p.primary, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.text)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(fontSize: 11.5, color: p.textSecondary, height: 1.35),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const Spacer(),
            _MiniKeys(code: code),
          ],
        ),
      ),
    );
  }
}

class _MiniKeys extends StatelessWidget {
  final String code;
  const _MiniKeys({required this.code});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final rows = code == 'pinyin9'
        ? const ['1 2 3', '4 5 6', '7 8 9']
        : code == 'stroke'
            ? const ['一 丨 丿', '丶 折 *', '删 空格']
            : code == 'handwriting'
                ? const ['✎ 手写区域', '撤销 清空 识别']
                : const ['Q W E R T', 'A S D F G', 'Z X C V B'];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: p.keyboardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: rows.map((r) {
          final keys = r.split(' ');
          return Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: keys.map((k) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    height: 17,
                    decoration: BoxDecoration(
                      color: p.key,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Center(
                      child: Text(k,
                          style: TextStyle(fontSize: 7, color: p.textSecondary),
                          maxLines: 1),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class PolicyTextPage extends StatelessWidget {
  final String title;
  final String content;
  const PolicyTextPage({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return PageScaffold(
      title: title,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(T.radiusCard),
          ),
          child: SelectableText(
            content,
            style: TextStyle(fontSize: 14, height: 1.75, color: p.text),
          ),
        ),
      ],
    );
  }
}
