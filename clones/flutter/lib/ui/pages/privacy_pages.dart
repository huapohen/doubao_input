import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/docs.dart';
import '../../core/platform_bridge.dart';
import '../../theme.dart';
import '../widgets.dart';

class InputModePage extends StatelessWidget {
  const InputModePage({super.key});

  void _openDoc(BuildContext context, String title, String content) {
    Navigator.of(context).pushNamed('/text', arguments: {'title': title, 'content': content});
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = AppScope.of(context);
    return PageScaffold(
      title: '输入模式与信息保护',
      children: [
        SettingsGroup(children: [
          RadioOptionRow(
            title: '智能输入模式',
            subtitle: '本地输入 + 可选的 AI 写作 / 整理 / 翻译（需自备 Key）',
            selected: s.inputMode != 'basic',
            onTap: () {
              s.setInputMode('smart');
              toast(context, '已切换到智能输入模式');
            },
          ),
          RadioOptionRow(
            title: '基础输入模式',
            subtitle: '仅使用本地拼音、手写、笔画与词库',
            selected: s.inputMode == 'basic',
            onTap: () async {
              final ok = await confirm(context,
                  title: '切换到基础输入模式',
                  message: 'AI、翻译与智能整理将不可用（仍可查看设置）。本地键盘、词库、剪贴板与常用语不受影响。');
              if (!ok) return;
              s.setInputMode('basic');
              if (context.mounted) toast(context, '已切换到基础输入模式');
            },
          ),
        ]),
        const SizedBox(height: 10),
        InfoBanner(
          s.isSmartMode
              ? (s.aiConfigured
                  ? '当前为智能输入模式，已配置 AI 服务。只有你主动点击生成时才会发送当前文本。'
                  : '当前为智能输入模式，但尚未配置 API Key。所有 AI 功能会使用本地模板，并标注「离线示例」。')
              : '当前为基础输入模式：全部 AI 能力关闭，仅本地输入可用。',
          icon: s.isSmartMode ? Icons.auto_awesome_rounded : Icons.shield_outlined,
          color: s.isSmartMode ? p.primary : const Color(0xFF23A26D),
        ),
        const SectionTitle('更多设置'),
        SettingsGroup(children: [
          NavRow(
            title: '智能输入设置',
            subtitle: '云端使用部分输入信息、个人词库',
            onTap: () => Navigator.of(context).pushNamed('/smart-input'),
          ),
          NavRow(
            title: '第三方共享清单',
            subtitle: '系统语音与你自行配置的 AI 服务',
            onTap: () => _openDoc(context, '第三方共享清单', thirdPartyText),
          ),
          NavRow(
            title: '用户协议',
            subtitle: '复刻版使用说明与边界',
            onTap: () => _openDoc(context, '用户协议', agreementText),
          ),
          NavRow(
            title: '隐私政策',
            subtitle: '本地数据、权限与网络请求',
            onTap: () => _openDoc(context, '隐私政策', privacyText),
          ),
          NavRow(
            title: '权限清单',
            subtitle: '每项权限的用途与关闭后的影响',
            onTap: () => _openDoc(context, '权限清单', permissionsText),
          ),
        ]),
        const SizedBox(height: 16),
        const InfoBanner('切换模式会立即生效并持久化。基础模式下键盘体验仍可完整使用，但 AI 面板会显示切换提示。'),
      ],
    );
  }
}

class SmartInputPage extends StatelessWidget {
  const SmartInputPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final enabled = s.isSmartMode;
    return PageScaffold(
      title: '智能输入设置',
      children: [
        SettingsGroup(children: [
          SwitchRow(
            title: '云端使用部分输入信息',
            subtitle: '允许 AI 生成时使用当前输入框的上下文',
            value: enabled && s.getBool('cloud_input_info'),
            onChanged: enabled
                ? (v) {
                    s.setBool('cloud_input_info', v);
                    toast(context, '云端输入信息已${v ? '开启' : '关闭'}');
                  }
                : null,
          ),
          SwitchRow(
            title: '云端使用个人词库',
            subtitle: 'AI 生成时可参考你的本地词条（仅发送相关文本）',
            value: enabled && s.getBool('cloud_personal_lexicon'),
            onChanged: enabled
                ? (v) {
                    s.setBool('cloud_personal_lexicon', v);
                    toast(context, '云端个人词库已${v ? '开启' : '关闭'}');
                  }
                : null,
          ),
        ]),
        const SizedBox(height: 12),
        if (!enabled) ...[
          const InfoBanner('当前为基础输入模式，智能输入选项不可用。',
              icon: Icons.lock_outline_rounded),
          const SizedBox(height: 12),
          PrimaryButton('切换到智能输入模式', icon: Icons.auto_awesome_rounded, onPressed: () {
            s.setInputMode('smart');
            toast(context, '已切换到智能输入模式');
          }),
          const SizedBox(height: 10),
        ],
        SettingsGroup(children: [
          NavRow(
            title: 'AI 服务配置',
            subtitle: s.aiConfigured ? '${s.aiModel} · 已配置 Key' : '未配置 Key',
            trailing: s.aiConfigured ? '已就绪' : '未配置',
            onTap: () => Navigator.of(context).pushNamed('/ai-settings'),
          ),
          NavRow(
            title: '输入模式与信息保护',
            subtitle: '切换智能 / 基础模式',
            onTap: () => Navigator.of(context).pushNamed('/input-mode'),
          ),
        ]),
        const SizedBox(height: 12),
        InfoBanner(
          enabled && s.aiConfigured
              ? '复刻版不会连接豆包官方云端。AI 请求只会发送到你在「AI 服务」中填写的 Base URL。'
              : '未配置 Key 时，所有 AI 功能使用本地模板，不发起网络请求。',
          icon: Icons.cloud_queue_rounded,
        ),
      ],
    );
  }
}

class SystemPermissionsPage extends StatefulWidget {
  const SystemPermissionsPage({super.key});
  @override
  State<SystemPermissionsPage> createState() => _SystemPermissionsPageState();
}

class _SystemPermissionsPageState extends State<SystemPermissionsPage> {
  final Map<String, Permission> _permissions = {
    '短信': Permission.sms,
    '通讯录': Permission.contacts,
    '麦克风': Permission.microphone,
    '相机': Permission.camera,
    '通知': Permission.notification,
  };
  final Map<String, PermissionStatus?> _status = {};
  bool _loading = true;

  static const _icons = <String, IconData>{
    '短信': Icons.sms_outlined,
    '通讯录': Icons.contacts_outlined,
    '麦克风': Icons.mic_none_rounded,
    '相机': Icons.photo_camera_outlined,
    '通知': Icons.notifications_none_rounded,
  };

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (mounted) setState(() => _loading = true);
    for (final entry in _permissions.entries) {
      try {
        _status[entry.key] = await entry.value.status;
      } catch (_) {
        _status[entry.key] = PermissionStatus.restricted;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _handlePermission(String label) async {
    final perm = _permissions[label]!;
    if (PlatformBridge.isIOS && label == '短信') {
      toast(context, 'iOS 不提供短信权限；复刻版也不会读取短信');
      return;
    }
    var status = await perm.status;
    if (status.isGranted || status.isLimited) {
      final opened = await PlatformBridge.openAppSettingsPage();
      if (mounted) {
        toast(context, opened ? '已打开系统设置' : '无法打开系统设置，请前往系统「设置」手动修改');
      }
      return;
    }
    try {
      status = await perm.request();
    } catch (_) {
      if (mounted) toast(context, '该权限在当前系统不可请求，请前往系统设置');
      return;
    }
    if (mounted) {
      setState(() => _status[label] = status);
      if (status.isGranted) {
        toast(context, '$label权限已授予');
      } else if (status.isPermanentlyDenied) {
        final open = await confirm(context,
            title: '$label权限被永久拒绝',
            message: '需要前往系统设置手动开启。复刻版只会在你使用对应功能时请求权限。',
            ok: '去设置');
        if (open) await PlatformBridge.openAppSettingsPage();
      } else {
        toast(context, '$label权限未授予，可稍后重试');
      }
    }
    await _refresh();
  }

  String _label(PermissionStatus? s) {
    if (_loading && s == null) return '检查中';
    if (s == null) return '未知';
    if (s.isGranted) return '已授予';
    if (s.isLimited) return '部分允许';
    if (s.isPermanentlyDenied) return '已拒绝';
    if (s.isRestricted) return '受限';
    if (s.isProvisional) return '临时';
    return '未授予';
  }

  Color _color(PermissionStatus? s) {
    final p = context.pal;
    if (s == null) return p.textSecondary;
    if (s.isGranted || s.isLimited || s.isProvisional) return const Color(0xFF23A26D);
    if (s.isPermanentlyDenied || s.isRestricted) return p.danger;
    return p.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '系统权限设置',
      actions: [
        IconButton(
          tooltip: '刷新权限状态',
          onPressed: _loading ? null : _refresh,
          icon: const Icon(Icons.refresh_rounded, size: 21),
        ),
      ],
      children: [
        if (_loading) ...[
          const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 10),
        ],
        SettingsGroup(children: [
          for (final entry in _permissions.entries)
            NavRow(
              title: entry.key,
              icon: _icons[entry.key],
              subtitle: switch (entry.key) {
                '短信' => '仅展示状态，不读取短信正文',
                '通讯录' => '用于把姓名加入本地词库',
                '麦克风' => '语音输入浮层使用',
                '相机' => '扫码登录与拍照输入演示',
                _ => '通知状态展示，不发送营销通知',
              },
              trailingWidget: TagChip(_label(_status[entry.key]),
                  color: _color(_status[entry.key])),
              trailing: '去设置',
              onTap: () => _handlePermission(entry.key),
            ),
        ]),
        if (PlatformBridge.isAndroid) ...[
          const SizedBox(height: 12),
          SettingsGroup(children: [
            NavRow(
              title: '系统输入法设置',
              subtitle: '启用或切换「豆包输入法（复刻）」',
              icon: Icons.keyboard_rounded,
              onTap: () async {
                final ok = await PlatformBridge.openImeSettings();
                if (context.mounted && !ok) toast(context, '无法打开输入法设置');
              },
            ),
            NavRow(
              title: '输入法选择器',
              subtitle: '在系统弹窗中选择当前输入法',
              icon: Icons.swap_horiz_rounded,
              onTap: () async {
                final ok = await PlatformBridge.showImePicker();
                if (context.mounted && !ok) toast(context, '当前系统不支持自动弹出选择器');
              },
            ),
          ]),
        ],
        const SizedBox(height: 12),
        const InfoBanner('状态通过系统权限 API 实时读取；厂商系统可能返回“受限”。复刻版不会在后台请求权限。'),
      ],
    );
  }
}
