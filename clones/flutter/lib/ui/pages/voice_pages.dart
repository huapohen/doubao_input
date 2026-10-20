import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../core/local_tools.dart';
import '../../theme.dart';
import '../widgets.dart';

class VoiceSettingsPage extends StatelessWidget {
  const VoiceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = AppScope.of(context);
    final preview = localOrganize(
      '嗯那个，我明天上午十点开会，然后咱们下午再对一下方案',
      aggressive: s.voiceFiller == '激进',
      blankLine: s.getBool('voice_paragraph'),
      punctuation: s.voicePunctuation,
    );
    return PageScaffold(
      title: '语音转文字',
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [p.primary.withValues(alpha: 0.14), p.primary.withValues(alpha: 0.03)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(T.radiusCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.graphic_eq_rounded, color: p.primary, size: 22),
                  const SizedBox(width: 8),
                  Text('语音输入预览',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.text)),
                  const Spacer(),
                  TagChip(s.isSmartMode ? '智能模式' : '基础模式'),
                ],
              ),
              const SizedBox(height: 10),
              Text('“嗯那个，我明天上午十点开会，然后咱们下午再对一下方案”',
                  style: TextStyle(fontSize: 12, color: p.textSecondary, height: 1.5)),
              const SizedBox(height: 8),
              Text(preview,
                  style: TextStyle(fontSize: 14, color: p.text, height: 1.5)),
            ],
          ),
        ),
        const SectionTitle('整理'),
        SettingsGroup(children: [
          SwitchRow(
            title: '智能文字整理',
            subtitle: '自动去掉重复、口语化表达并补全标点',
            value: s.voiceSmartOrganize,
            onChanged: (v) {
              s.setBool(K.voiceSmartOrganize, v);
              toast(context, '智能文字整理已${v ? '开启' : '关闭'}');
            },
          ),
          NavRow(
            title: '分段方式',
            subtitle: '语音识别结果的换行方式',
            trailing: s.getBool('voice_paragraph') ? '空行' : '不空行',
            onTap: () => _chooseSegment(context, s),
          ),
          NavRow(
            title: '标点显示',
            subtitle: '控制语音结果的标点策略',
            trailing: s.voicePunctuation,
            onTap: () => _choosePunctuation(context, s),
          ),
          NavRow(
            title: '口水词处理',
            subtitle: '“嗯、那个、就是说”等口语词',
            trailing: s.voiceFiller,
            onTap: () => _chooseFiller(context, s),
          ),
          SwitchRow(
            title: '候选栏显示语音键',
            subtitle: '在候选栏右侧保留麦克风入口',
            value: s.getBool('voice_candidate_key', fallback: true),
            onChanged: (v) {
              s.setBool('voice_candidate_key', v);
              toast(context, '候选栏语音键已${v ? '显示' : '隐藏'}');
            },
          ),
        ]),
        const SectionTitle('离线语音'),
        SettingsGroup(children: [
          NavRow(
            title: '离线语音包',
            subtitle: '无网络时使用本地识别（复刻版为模拟下载）',
            trailing: s.voiceOffline ? '已启用' : (s.offlineStatus.isEmpty ? '未下载' : s.offlineStatus),
            onTap: () => Navigator.of(context).pushNamed('/offline-voice'),
          ),
        ]),
        const SectionTitle('其他'),
        SettingsGroup(children: [
          SwitchRow(
            title: 'WiFi 弱网自动切流量',
            subtitle: '网络不稳定时继续识别，可能消耗移动数据',
            value: s.getBool('voice_wifi_switch'),
            onChanged: (v) {
              s.setBool('voice_wifi_switch', v);
              toast(context, '弱网切换已${v ? '开启' : '关闭'}');
            },
          ),
          SwitchRow(
            title: '使用耳机麦克风',
            subtitle: '优先采集蓝牙/有线耳机麦克风',
            value: s.getBool('voice_headset'),
            onChanged: (v) {
              s.setBool('voice_headset', v);
              toast(context, '耳机麦克风已${v ? '开启' : '关闭'}');
            },
          ),
          NavRow(
            title: '语音口令',
            subtitle: s.voiceActionEnabled ? '已启用 ${s.voiceActions.length} 个口令' : '用说话完成发送',
            onTap: () => Navigator.of(context).pushNamed('/voice-action'),
          ),
        ]),
        const SizedBox(height: 16),
        const InfoBanner(
          '语音输入会真实申请麦克风与系统语音识别权限。模拟器或没有识别服务时会给出错误提示，并提供明确标注的演示结果。',
          icon: Icons.mic_none_rounded,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _chooseSegment(BuildContext context, AppState s) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('分段方式', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
            RadioGroup<bool>(
              groupValue: s.getBool('voice_paragraph'),
              onChanged: (v) {
                s.setBool('voice_paragraph', v ?? false);
                Navigator.pop(ctx);
                toast(context, '分段方式已更新');
              },
              child: Column(children: const [
                RadioListTile<bool>(value: false, title: Text('分段后不空行')),
                RadioListTile<bool>(value: true, title: Text('分段后空一行')),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _choosePunctuation(BuildContext context, AppState s) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('标点显示', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ChoiceChips(
                options: const ['智能标点', '句号结尾', '逗号分隔', '不添加标点'],
                selected: s.voicePunctuation,
                onSelected: (v) {
                  s.setString(K.voicePunctuation, v);
                  Navigator.pop(ctx);
                  toast(context, '标点策略：$v');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _chooseFiller(BuildContext context, AppState s) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('口水词处理', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
            for (final v in const ['正常', '激进'])
              ListTile(
                title: Text(v),
                subtitle: Text(v == '正常' ? '保留必要语气词，删除明显重复' : '尽可能删除所有口语填充词'),
                trailing: Icon(
                  s.voiceFiller == v ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                  color: s.voiceFiller == v ? context.pal.primary : context.pal.textSecondary,
                ),
                onTap: () {
                  s.setString(K.voiceFiller, v);
                  Navigator.pop(ctx);
                  toast(context, '口水词处理：$v');
                },
              ),
          ],
        ),
      ),
    );
  }
}

class VoiceActionPage extends StatefulWidget {
  const VoiceActionPage({super.key});
  @override
  State<VoiceActionPage> createState() => _VoiceActionPageState();
}

class _VoiceActionPageState extends State<VoiceActionPage> {
  late List<String> _actions;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    final s = AppScope.of(context);
    _actions = s.voiceActions;
    _enabled = s.voiceActionEnabled;
  }

  void _persist() {
    AppScope.of(context).setVoiceActions(_actions);
  }

  Future<void> _add() async {
    final text = await promptText(
      context,
      title: '添加自定义口令',
      hint: '例如：发送吧',
      subtitle: '说出该口令后自动发送当前输入内容',
    );
    if (text == null || text.trim().isEmpty) return;
    if (_actions.contains(text.trim())) {
      toast(context, '该口令已存在');
      return;
    }
    setState(() => _actions.add(text.trim()));
    _persist();
    if (mounted) toast(context, '已添加口令「${text.trim()}」');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = AppScope.of(context);
    return PageScaffold(
      title: '语音口令',
      children: [
        SettingsGroup(children: [
          SwitchRow(
            title: '启用语音口令',
            subtitle: '说出指定语句后自动发送，不用手动点击',
            value: _enabled,
            onChanged: (v) {
              setState(() => _enabled = v);
              s.setBool(K.voiceActionEnabled, v);
              toast(context, '语音口令已${v ? '开启' : '关闭'}');
            },
          ),
        ]),
        const SectionTitle('口令列表'),
        SettingsGroup(children: [
          for (var i = 0; i < _actions.length; i++)
            ListTile(
              enabled: _enabled,
              leading: Icon(Icons.record_voice_over_outlined,
                  color: _enabled ? p.primary : p.textSecondary),
              title: Text(_actions[i],
                  style: TextStyle(fontSize: 15, color: _enabled ? p.text : p.textSecondary)),
              subtitle: Text('说出后自动发送', style: TextStyle(fontSize: 12, color: p.textSecondary)),
              trailing: IconButton(
                tooltip: '删除口令',
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                onPressed: _enabled
                    ? () async {
                        final ok = await confirm(context,
                            title: '删除口令', message: '确定删除「${_actions[i]}」吗？', danger: true);
                        if (ok) {
                          setState(() => _actions.removeAt(i));
                          _persist();
                          if (context.mounted) toast(context, '已删除');
                        }
                      }
                    : null,
              ),
            ),
          if (_actions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('暂无口令，点击下方按钮添加',
                  style: TextStyle(fontSize: 13, color: p.textSecondary)),
            ),
          ListTile(
            enabled: _enabled,
            leading: Icon(Icons.add_circle_outline_rounded,
                color: _enabled ? p.primary : p.textSecondary),
            title: Text('添加自定义口令',
                style: TextStyle(fontSize: 15, color: _enabled ? p.primary : p.textSecondary)),
            onTap: _enabled ? _add : null,
          ),
        ]),
        const SizedBox(height: 14),
        PrimaryButton('保存口令', icon: Icons.check_rounded, onPressed: _enabled ? () {
          _persist();
          toast(context, '语音口令已保存（${_actions.length} 个）');
        } : null),
        const SizedBox(height: 10),
        const InfoBanner('语音口令在本地匹配，不会上传语音内容。发送动作只在键盘体验内演示，不控制其他 App。'),
      ],
    );
  }
}

class OfflineVoicePage extends StatefulWidget {
  const OfflineVoicePage({super.key});
  @override
  State<OfflineVoicePage> createState() => _OfflineVoicePageState();
}

class _OfflineVoicePageState extends State<OfflineVoicePage> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startDownload(AppState s) {
    if (_timer?.isActive ?? false) return;
    s.setOfflineProgress(0, '下载中');
    _timer = Timer.periodic(const Duration(milliseconds: 180), (t) {
      final v = s.offlineProgress + 0.035;
      if (v >= 1) {
        t.cancel();
        s.setOfflineProgress(1, '已下载');
        s.setBool(K.voiceOffline, true);
        if (mounted) toast(context, '离线语音包下载完成（演示）');
      } else {
        s.setOfflineProgress(v, '下载中');
      }
    });
  }

  Future<void> _remove(AppState s) async {
    final ok = await confirm(context,
        title: '删除离线语音包',
        message: '删除后无网络时将无法使用离线识别。确定删除吗？',
        danger: true,
        ok: '删除');
    if (!ok) return;
    s.setOfflineProgress(0, '');
    s.setBool(K.voiceOffline, false);
    if (mounted) toast(context, '离线语音包已删除');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = AppScope.of(context);
    final progress = s.offlineProgress;
    final downloading = s.offlineStatus == '下载中';
    final downloaded = progress >= 1;
    return PageScaffold(
      title: '离线语音',
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(T.radiusCard),
          ),
          child: Column(
            children: [
              Icon(downloaded ? Icons.offline_bolt_rounded : Icons.cloud_download_outlined,
                  size: 44, color: p.primary),
              const SizedBox(height: 10),
              Text(downloaded ? '离线语音包已就绪' : '离线语音包',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: p.text)),
              const SizedBox(height: 6),
              Text(downloaded ? '可在无网络环境使用本地识别（演示数据）' : '约 177 MB · 下载后无网络也能语音输入',
                  style: TextStyle(fontSize: 12.5, color: p.textSecondary)),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 9,
                  backgroundColor: p.pageBg,
                  color: p.primary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(s.offlineStatus.isEmpty ? '未下载' : s.offlineStatus,
                      style: TextStyle(fontSize: 12, color: p.textSecondary)),
                  const Spacer(),
                  Text('${(progress * 100).round()}%',
                      style: TextStyle(fontSize: 12, color: p.primary, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 16),
              if (downloaded)
                SecondaryButton('删除离线语音包', icon: Icons.delete_outline_rounded, onPressed: () => _remove(s))
              else
                PrimaryButton(downloading ? '下载中…' : '下载离线语音包',
                    icon: Icons.download_rounded, onPressed: downloading ? null : () => _startDownload(s)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SettingsGroup(children: [
          SwitchRow(
            title: '优先使用离线语音',
            subtitle: '仅在离线包已下载时可用',
            value: s.voiceOffline && downloaded,
            onChanged: downloaded
                ? (v) {
                    s.setBool(K.voiceOffline, v);
                    toast(context, '离线语音已${v ? '开启' : '关闭'}');
                  }
                : null,
          ),
          SwitchRow(
            title: 'WiFi 弱网切移动数据',
            subtitle: '弱网时继续在线识别',
            value: s.getBool('voice_wifi_switch'),
            onChanged: (v) {
              s.setBool('voice_wifi_switch', v);
              toast(context, '弱网切换已${v ? '开启' : '关闭'}');
            },
          ),
        ]),
        const SizedBox(height: 14),
        const InfoBanner(
          '复刻版不包含官方离线模型。此页面下载为模拟进度，用于还原交互与持久化状态；真实离线识别需接入你自己的本地 ASR 服务。',
          icon: Icons.science_outlined,
        ),
      ],
    );
  }
}
