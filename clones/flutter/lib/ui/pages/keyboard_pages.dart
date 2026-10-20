import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_state.dart';
import '../../core/pinyin_engine.dart';
import '../../theme.dart';
import '../widgets.dart';

class KeyboardTypesPage extends StatelessWidget {
  const KeyboardTypesPage({super.key});

  static const types = <List<String>>[
    ['pinyin9', '拼音 9 键', 'T9 布局，单手输入更快', '9'],
    ['pinyin26', '拼音 26 键', '全键盘，支持上滑数字符号', '26'],
    ['handwriting', '手写键盘', '手写画布，模板识别', '手'],
    ['stroke', '笔画键盘', '横竖撇捺折五笔画', '笔'],
    ['shuangpin', '双拼键盘', '小鹤 / 自然码', '双'],
    ['wubi', '五笔键盘', '五笔 86 演示码表', '五'],
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = AppScope.of(context);
    return PageScaffold(
      title: '键盘类型',
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.05,
          ),
          itemCount: types.length,
          itemBuilder: (context, i) {
            final t = types[i];
            final active = s.keyboardType == t[0];
            return InkWell(
              onTap: () {
                s.setKeyboardType(t[0]);
                toast(context, '已切换为 ${t[1]}');
                if (t[0] == 'shuangpin') {
                  Navigator.of(context).pushNamed('/double-pinyin');
                } else if (t[0] == 'wubi') {
                  Navigator.of(context).pushNamed('/wubi');
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: active ? p.primary : p.divider, width: active ? 1.8 : 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: active ? p.primary : p.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(t[3],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: active ? Colors.white : p.primary,
                                )),
                          ),
                        ),
                        const Spacer(),
                        if (active) Icon(Icons.check_circle_rounded, size: 17, color: p.primary),
                      ],
                    ),
                    const Spacer(),
                    Text(t[1],
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600, color: p.text),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(t[2],
                        style: TextStyle(fontSize: 10, color: p.textSecondary, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('当前预览',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.text)),
              const SizedBox(height: 10),
              _KeyboardPreview(type: s.keyboardType, candidateSize: s.candidateFontSize),
            ],
          ),
        ),
        const SizedBox(height: 14),
        PrimaryButton('打开键盘体验', icon: Icons.keyboard_alt_outlined,
            onPressed: () => Navigator.of(context).pushNamed('/keyboard')),
        const SizedBox(height: 10),
        const InfoBanner('切换后键盘体验会立即使用新布局。手写与笔画为演示级识别，覆盖常用字与数字。'),
      ],
    );
  }
}

class _KeyboardPreview extends StatelessWidget {
  final String type;
  final double candidateSize;
  const _KeyboardPreview({required this.type, required this.candidateSize});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final rows = switch (type) {
      'pinyin9' => const ['1 @#', 'ABC DEF', 'GHI JKL MNO', 'PQRS TUV WXYZ'],
      'handwriting' => const ['手写画布', '撤销 识别'],
      'stroke' => const ['一 丨 丿', '丶 折 *', '删除 空格'],
      'wubi' => const ['Q W E R T Y U I O P', 'A S D F G H J K L', 'Z X C V B N M'],
      _ => const ['Q W E R T Y U I O P', 'A S D F G H J K L', 'Z X C V B N M'],
    };
    return Container(
      color: p.keyboardBg,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Container(
            height: 26,
            decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(6)),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Text('你好', style: TextStyle(fontSize: candidateSize * 0.6, color: p.text)),
                const SizedBox(width: 10),
                Text('豆包', style: TextStyle(fontSize: candidateSize * 0.6, color: p.text)),
                const Spacer(),
                Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: p.textSecondary),
                const SizedBox(width: 4),
              ],
            ),
          ),
          const SizedBox(height: 5),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  for (final k in row.split(' '))
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        height: 22,
                        decoration: BoxDecoration(
                          color: p.key,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(k,
                              style: TextStyle(fontSize: 7, color: p.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.clip),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class DoublePinyinPage extends StatelessWidget {
  const DoublePinyinPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = AppScope.of(context);
    final scheme = s.shuangpinScheme;
    return PageScaffold(
      title: '双拼',
      children: [
        SettingsGroup(children: [
          RadioOptionRow(
            title: '小鹤双拼',
            subtitle: '形码友好，常用双拼方案',
            selected: scheme == '小鹤双拼',
            onTap: () {
              s.setString(K.shuangpinScheme, '小鹤双拼');
              s.setKeyboardType('shuangpin');
              toast(context, '已选择小鹤双拼');
            },
          ),
          RadioOptionRow(
            title: '自然码双拼',
            subtitle: '历史最久的双拼方案之一',
            selected: scheme == '自然码双拼',
            onTap: () {
              s.setString(K.shuangpinScheme, '自然码双拼');
              s.setKeyboardType('shuangpin');
              toast(context, '已选择自然码双拼');
            },
          ),
          Opacity(
            opacity: 0.55,
            child: ListTile(
              leading: const Icon(Icons.radio_button_off_rounded, size: 21),
              title: const Text('9 键双拼'),
              subtitle: const Text('敬请期待'),
              trailing: const TagChip('即将支持'),
              enabled: false,
            ),
          ),
        ]),
        const SectionTitle('键位预览'),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$scheme · 韵母键位',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.text)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (scheme == '自然码双拼'
                        ? const ['q=iu', 'w=ua/ia', 'r=uan', 't=ue', 'y=uai/ing', 'o=o/uo', 'p=un', 's=iong/ong', 'd=uang/iang', 'f=en/eng', 'g=eng', 'h=ang', 'j=an', 'k=ao', 'l=ai', 'z=ei', 'x=ie', 'c=iao', 'b=ou', 'n=in', 'm=ian']
                        : const ['q=iu', 'w=ei', 'r=uan', 't=ue', 'y=un', 'o=uo', 'p=ie', 's=ong/iong', 'd=ai', 'f=en', 'g=eng', 'h=ang', 'j=an', 'k=ing/uai', 'l=iang/uang', 'z=ou', 'x=ia/ua', 'c=ao', 'v=ui', 'b=in', 'n=iao', 'm=ian'])
                    .map((e) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: p.pageBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(e,
                              style: TextStyle(fontSize: 11, color: p.textSecondary)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 10),
              Text('示例：输入「nihc」→ 你好（小鹤）',
                  style: TextStyle(fontSize: 12, color: p.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        PrimaryButton('在键盘中试试', icon: Icons.keyboard_alt_outlined, onPressed: () {
          s.setKeyboardType('shuangpin');
          Navigator.of(context).pushNamed('/keyboard', arguments: {'mode': 'shuangpin'});
        }),
        const SizedBox(height: 10),
        const InfoBanner('双拼解析会把两字母音节还原为全拼并查询本地 33,500 词词典。零声母与多音节的极端组合可能与商业输入法略有差异。'),
      ],
    );
  }
}

class WubiPage extends StatelessWidget {
  const WubiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = AppScope.of(context);
    return PageScaffold(
      title: '五笔',
      children: [
        SettingsGroup(children: [
          RadioOptionRow(
            title: '五笔 86 版',
            subtitle: '经典 86 字根方案（演示码表）',
            selected: true,
            onTap: () {
              s.setKeyboardType('wubi');
              toast(context, '已选择五笔 86 版');
            },
          ),
        ]),
        const SectionTitle('输入选项'),
        SettingsGroup(children: [
          SwitchRow(
            title: '编码提示',
            subtitle: '在候选栏显示当前五笔编码',
            value: s.getBool(K.wubiHint),
            onChanged: (v) {
              s.setBool(K.wubiHint, v);
              toast(context, '编码提示已${v ? '开启' : '关闭'}');
            },
          ),
          SwitchRow(
            title: '拼音混输',
            subtitle: '五笔无候选时可继续用拼音查找',
            value: s.getBool(K.wubiMix),
            onChanged: (v) {
              s.setBool(K.wubiMix, v);
              toast(context, '拼音混输已${v ? '开启' : '关闭'}');
            },
          ),
          SwitchRow(
            title: '四码唯一时自动上屏',
            subtitle: '输入满四码且仅有一个候选时直接上屏',
            value: s.getBool(K.wubiUnique4),
            onChanged: (v) {
              s.setBool(K.wubiUnique4, v);
              toast(context, '四码唯一自动上屏已${v ? '开启' : '关闭'}');
            },
          ),
          SwitchRow(
            title: '第五码首选上屏',
            subtitle: '第五码直接选择第一个候选',
            value: s.getBool(K.wubiFifth),
            onChanged: (v) {
              s.setBool(K.wubiFifth, v);
              toast(context, '第五码首选已${v ? '开启' : '关闭'}');
            },
          ),
        ]),
        const SectionTitle('码表示例'),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16)),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              '我 trnt', '你 wqiy', '好 vbg', '中 khk', '国 lgyi', '是 jghu',
              '的 rqyy', '一 ggll', '有 def', '和 tkg', '在 dhfd', '人 wwww',
            ].map((e) => TagChip(e)).toList(),
          ),
        ),
        const SizedBox(height: 14),
        PrimaryButton('在键盘中试试', icon: Icons.keyboard_alt_outlined, onPressed: () {
          s.setKeyboardType('wubi');
          Navigator.of(context).pushNamed('/keyboard', arguments: {'mode': 'wubi'});
        }),
        const SizedBox(height: 10),
        const InfoBanner('内置约 70 条常用五笔码表，仅用于演示交互；真实五笔词库需使用你自己的开源码表导入。'),
      ],
    );
  }
}

class LayoutSettingsPage extends StatelessWidget {
  const LayoutSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = AppScope.of(context);
    return PageScaffold(
      title: '布局与显示',
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('实时预览',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.text)),
                  const Spacer(),
                  Text('候选 ${s.candidateFontSize.toStringAsFixed(0)}sp',
                      style: TextStyle(fontSize: 11, color: p.primary)),
                ],
              ),
              const SizedBox(height: 8),
              _KeyboardPreview(type: s.keyboardType.isEmpty ? 'pinyin26' : s.keyboardType,
                  candidateSize: s.candidateFontSize),
            ],
          ),
        ),
        const SectionTitle('候选与键盘'),
        SettingsGroup(children: [
          LabeledSlider(
            label: '候选字大小',
            value: s.candidateFontSize,
            min: 14,
            max: 28,
            divisions: 14,
            format: (v) => '${v.toStringAsFixed(0)} sp',
            onChanged: (v) => s.setDouble(K.candidateFontSize, v),
          ),
          NavRow(
            title: '拼音显示位置',
            subtitle: '组词时拼音串显示的位置',
            trailing: s.pinyinLocation,
            onTap: () => _choosePinyinLocation(context, s),
          ),
          NavRow(
            title: '键盘调节',
            subtitle: '高度、底部间距、候选字号',
            trailing: '${s.keyboardHeight} dp',
            onTap: () => _tuningSheet(context, s),
          ),
          SwitchRow(
            title: '26 键数字符号合并',
            subtitle: '数字与符号共用一个切换键',
            value: s.getBool('num_symbol_merge', fallback: true),
            onChanged: (v) {
              s.setBool('num_symbol_merge', v);
              toast(context, '数字符号合并已${v ? '开启' : '关闭'}');
            },
          ),
          SwitchRow(
            title: '逗号句号分开',
            subtitle: '关闭后使用一个按键循环输入标点',
            value: s.getBool('comma_period_split', fallback: true),
            onChanged: (v) {
              s.setBool('comma_period_split', v);
              toast(context, '逗号句号已${v ? '分开' : '合并'}');
            },
          ),
          NavRow(
            title: '中英切换位置',
            subtitle: '中/英按键放在键盘左侧或右侧',
            trailing: s.getBool('cn_en_left') ? '左侧' : '右侧',
            onTap: () {
              final v = !s.getBool('cn_en_left');
              s.setBool('cn_en_left', v);
              toast(context, '中英切换已移至${v ? '左' : '右'}侧');
            },
          ),
          SwitchRow(
            title: '上滑输入数字符号',
            subtitle: '字母键上滑快速输入对应数字/符号',
            value: s.getBool('swipe_symbols', fallback: true),
            onChanged: (v) {
              s.setBool('swipe_symbols', v);
              toast(context, '上滑数字符号已${v ? '开启' : '关闭'}');
            },
          ),
          SwitchRow(
            title: '回车键发送',
            subtitle: '回车显示为“发送”并提交当前文本',
            value: s.enterSend,
            onChanged: (v) {
              s.setBool(K.enterSend, v);
              toast(context, '回车键已设置为「${v ? '发送' : '换行'}」');
            },
          ),
        ]),
        const SectionTitle('外观'),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('主题外观', style: TextStyle(fontSize: 15, color: p.text)),
              const SizedBox(height: 10),
              ChoiceChips(
                options: const ['跟随系统', '浅色', '深色'],
                selected: switch (s.getString(K.themeMode)) {
                  'light' => '浅色',
                  'dark' => '深色',
                  _ => '跟随系统',
                },
                onSelected: (v) {
                  s.setThemeMode(v == '浅色' ? 'light' : (v == '深色' ? 'dark' : 'system'));
                  toast(context, '外观已切换为$v');
                },
              ),
            ],
          ),
        ),
        const SectionTitle('自定义'),
        SettingsGroup(children: [
          NavRow(
            title: '侧边栏自定义符号',
            subtitle: s.customSymbols.join('  '),
            trailing: '${s.customSymbols.length} 个',
            onTap: () => Navigator.of(context).pushNamed('/custom-symbols'),
          ),
          NavRow(
            title: '定制工具栏',
            subtitle: '拖拽排序、两页布局、左右吸附',
            onTap: () => Navigator.of(context).pushNamed('/keyboard', arguments: {'panel': 'toolbar'}),
          ),
        ]),
        const SizedBox(height: 14),
        SecondaryButton('恢复键盘默认调节', icon: Icons.restart_alt_rounded, onPressed: () async {
          final ok = await confirm(context,
              title: '恢复默认', message: '将键盘高度、底部间距、悬浮缩放与候选字号恢复默认。');
          if (ok) {
            s.resetKeyboardTuning();
            if (context.mounted) toast(context, '已恢复键盘默认调节');
          }
        }),
      ],
    );
  }

  void _choosePinyinLocation(BuildContext context, AppState s) {
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
              const Text('拼音显示位置', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              for (final v in const ['候选栏', '输入框上方'])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(v),
                  trailing: Icon(
                    s.pinyinLocation == v ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                    color: s.pinyinLocation == v ? context.pal.primary : context.pal.textSecondary,
                  ),
                  onTap: () {
                    s.setString(K.pinyinLocation, v);
                    Navigator.pop(ctx);
                    toast(context, '拼音将显示在$v');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _tuningSheet(BuildContext context, AppState s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final p = context.pal;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('键盘调节', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: p.text)),
                  const SizedBox(height: 4),
                  Text('所有调节会实时写入键盘体验', style: TextStyle(fontSize: 12, color: p.textSecondary)),
                  const SizedBox(height: 12),
                  LabeledSlider(
                    label: '键盘高度',
                    value: s.keyboardHeight.toDouble(),
                    min: 260,
                    max: 440,
                    divisions: 18,
                    format: (v) => '${v.toStringAsFixed(0)} dp',
                    onChanged: (v) {
                      s.setInt(K.keyboardHeight, v.round());
                      setSheet(() {});
                    },
                  ),
                  LabeledSlider(
                    label: '底部间距',
                    value: s.keyboardGap.toDouble(),
                    min: 0,
                    max: 24,
                    divisions: 12,
                    format: (v) => '${v.toStringAsFixed(0)} dp',
                    onChanged: (v) {
                      s.setInt('keyboard_gap', v.round());
                      setSheet(() {});
                    },
                  ),
                  LabeledSlider(
                    label: '候选字号',
                    value: s.candidateFontSize,
                    min: 14,
                    max: 28,
                    divisions: 14,
                    format: (v) => '${v.toStringAsFixed(0)} sp',
                    onChanged: (v) {
                      s.setDouble(K.candidateFontSize, v);
                      setSheet(() {});
                    },
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton('恢复默认', icon: Icons.restart_alt_rounded, onPressed: () {
                          s.resetKeyboardTuning();
                          setSheet(() {});
                          toast(context, '已恢复默认调节');
                        }),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: PrimaryButton('完成', onPressed: () => Navigator.pop(ctx))),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CustomSymbolsPage extends StatelessWidget {
  const CustomSymbolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = AppScope.of(context);
    final symbols = s.customSymbols;
    return PageScaffold(
      title: '侧边栏自定义符号',
      children: [
        const InfoBanner('这些符号会出现在 9 键键盘左侧与数字键盘侧边，可拖动排序、添加或删除。'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: (oldIndex, newIndex) {
              final list = List<String>.of(symbols);
              if (newIndex > oldIndex) newIndex -= 1;
              final item = list.removeAt(oldIndex);
              list.insert(newIndex, item);
              s.setCustomSymbols(list);
              toast(context, '符号顺序已保存');
            },
            children: [
              for (var i = 0; i < symbols.length; i++)
                ListTile(
                  key: ValueKey('$i-${symbols[i]}'),
                  leading: ReorderableDragStartListener(
                    index: i,
                    child: Icon(Icons.drag_indicator_rounded, color: p.textSecondary),
                  ),
                  title: Text(symbols[i], style: TextStyle(fontSize: 20, color: p.text)),
                  subtitle: Text('第 ${i + 1} 个', style: TextStyle(fontSize: 11, color: p.textSecondary)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: '删除',
                    onPressed: symbols.length <= 1
                        ? null
                        : () {
                            final list = List<String>.of(symbols)..removeAt(i);
                            s.setCustomSymbols(list);
                            toast(context, '已删除「${symbols[i]}」');
                          },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PrimaryButton('添加符号', icon: Icons.add_rounded, onPressed: () async {
          final v = await promptText(context, title: '添加符号', hint: '输入一个字符，如“、”');
          if (v == null || v.isEmpty) return;
          if (v.runes.length > 2) {
            toast(context, '请只输入一个符号');
            return;
          }
          s.setCustomSymbols([...symbols, v]);
          if (context.mounted) toast(context, '已添加「$v」');
        }),
        const SizedBox(height: 10),
        SecondaryButton('恢复默认符号（，。？！）', icon: Icons.restart_alt_rounded, onPressed: () {
          s.setCustomSymbols(const ['，', '。', '？', '！']);
          toast(context, '已恢复默认符号');
        }),
      ],
    );
  }
}

class FuzzyPinyinPage extends StatefulWidget {
  const FuzzyPinyinPage({super.key});
  @override
  State<FuzzyPinyinPage> createState() => _FuzzyPinyinPageState();
}

class _FuzzyPinyinPageState extends State<FuzzyPinyinPage> {
  static const _initials = <List<String>>[
    ['z_zh', 'z = zh'], ['c_ch', 'c = ch'], ['s_sh', 's = sh'],
    ['f_h', 'f = h'], ['n_l', 'n = l'], ['r_l', 'r = l'],
  ];
  static const _finals = <List<String>>[
    ['an_ang', 'an = ang'], ['en_eng', 'en = eng'], ['in_ing', 'in = ing'],
    ['ian_iang', 'ian = iang'], ['uan_uang', 'uan = uang'], ['un_ong', 'un = ong'],
    ['eng_ong', 'eng = ong'], ['ai_ei', 'ai = ei'], ['ou_uo', 'ou = uo'],
  ];
  static const _syllables = <List<String>>[
    ['hui_fei', 'hui = fei'], ['huang_wang', 'huang = wang'],
  ];
  bool _openInitials = true;
  bool _openFinals = true;
  bool _openSyllables = true;

  void _toggle(AppState s, String key, String id, bool v) {
    final list = s.getList(key).toSet();
    if (v) {
      list.add(id);
    } else {
      list.remove(id);
    }
    s.setList(key, list.toList());
  }

  Widget _group(
    BuildContext context,
    AppState s,
    String title,
    String key,
    List<List<String>> items,
    bool open,
    VoidCallback onToggle,
  ) {
    final p = context.pal;
    final selected = s.getList(key);
    final enabled = s.getBool(K.fuzzyEnabled);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.text)),
                  const SizedBox(width: 8),
                  TagChip('${selected.length}/${items.length}'),
                  const Spacer(),
                  TextButton(
                    onPressed: enabled
                        ? () {
                            s.setList(key, items.map((e) => e[0]).toList());
                            toast(context, '$title已全选');
                          }
                        : null,
                    child: const Text('全选', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton(
                    onPressed: enabled
                        ? () {
                            s.setList(key, const []);
                            toast(context, '$title已清空');
                          }
                        : null,
                    child: const Text('清空', style: TextStyle(fontSize: 12)),
                  ),
                  Icon(open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: p.textSecondary),
                ],
              ),
            ),
          ),
          if (open)
            for (var i = 0; i < items.length; i++)
              Column(
                children: [
                  Divider(height: 0.7, color: p.divider),
                  SwitchRow(
                    title: items[i][1],
                    value: selected.contains(items[i][0]),
                    onChanged: enabled
                        ? (v) {
                            _toggle(s, key, items[i][0], v);
                            toast(context, '${items[i][1]} 已${v ? '开启' : '关闭'}');
                          }
                        : null,
                  ),
                ],
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return PageScaffold(
      title: '模糊拼音',
      children: [
        SettingsGroup(children: [
          SwitchRow(
            title: '启用模糊拼音',
            subtitle: '允许相近声母、韵母互相匹配',
            value: s.getBool(K.fuzzyEnabled),
            onChanged: (v) {
              s.setBool(K.fuzzyEnabled, v);
              toast(context, '模糊拼音已${v ? '开启' : '关闭'}');
            },
          ),
        ]),
        const SizedBox(height: 12),
        _group(context, s, '声母', K.fuzzyInitials, _initials, _openInitials,
            () => setState(() => _openInitials = !_openInitials)),
        _group(context, s, '韵母', K.fuzzyFinals, _finals, _openFinals,
            () => setState(() => _openFinals = !_openFinals)),
        _group(context, s, '音节', K.fuzzySyllables, _syllables, _openSyllables,
            () => setState(() => _openSyllables = !_openSyllables)),
        const SizedBox(height: 8),
        const InfoBanner('模糊拼音会扩大候选范围。例如开启 z=zh 后，输入「zong」也会匹配「中」。关闭总开关后下级设置保留但不生效。'),
      ],
    );
  }
}

class AssociationPage extends StatelessWidget {
  const AssociationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = AppScope.of(context);
    final assoc = PinyinEngine.instance.associates('你好');
    return PageScaffold(
      title: '智能联想',
      children: [
        SettingsGroup(children: [
          SwitchRow(
            title: '智能联想',
            subtitle: '根据上文提供文字、表情、符号等推荐',
            value: s.getBool(K.associationEnabled),
            onChanged: (v) {
              s.setBool(K.associationEnabled, v);
              toast(context, '智能联想已${v ? '开启' : '关闭'}');
            },
          ),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('联想示例', style: TextStyle(fontSize: 13, color: p.textSecondary)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('你好',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.text)),
                  ...assoc.map((e) => Chip(
                        label: Text(e, style: const TextStyle(fontSize: 13)),
                        visualDensity: VisualDensity.compact,
                      )),
                ],
              ),
              const SizedBox(height: 12),
              Text('开启后，上屏「你好」时会在候选栏显示「吗 / 呀 / 世界」等联想词；关闭后只显示拼音候选。',
                  style: TextStyle(fontSize: 12, color: p.textSecondary, height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        PrimaryButton('在键盘中体验联想', icon: Icons.keyboard_alt_outlined,
            onPressed: () => Navigator.of(context).pushNamed('/keyboard')),
        const SizedBox(height: 10),
        const InfoBanner('联想词来自本地词库与常用搭配表，不请求云端。输入预测类型可单独控制 Emoji、图片表情与颜文字。'),
      ],
    );
  }
}

class PredictionTypesPage extends StatelessWidget {
  const PredictionTypesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return PageScaffold(
      title: '输入预测类型',
      children: [
        _predictionGroup(
          context,
          s,
          key: K.predictionEmoji,
          title: 'Emoji',
          subtitle: '根据上下文推荐表情符号',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PinyinEngine.emojiPredictions.values
                .expand((e) => e)
                .take(16)
                .map((e) => _sample(context, e, big: true))
                .toList(),
          ),
        ),
        _predictionGroup(
          context,
          s,
          key: K.predictionImage,
          title: '图片表情',
          subtitle: '本地生成的彩色表情占位卡片',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PinyinEngine.stickers
                .map((e) => _sticker(context, e[0], e[1]))
                .toList(),
          ),
        ),
        _predictionGroup(
          context,
          s,
          key: K.predictionKaomoji,
          title: '颜文字',
          subtitle: '文字组合的日式表情',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PinyinEngine.kaomoji
                .take(10)
                .map((e) => _sample(context, e, big: false))
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        const InfoBanner('开关控制候选栏是否展示对应类型。点击示例会在键盘体验中插入；此处点击仅预演样式并提示。'),
      ],
    );
  }

  Widget _predictionGroup(
    BuildContext context,
    AppState s, {
    required String key,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final p = context.pal;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchRow(
            title: title,
            subtitle: subtitle,
            value: s.getBool(key),
            onChanged: (v) {
              s.setBool(key, v);
              toast(context, '$title已${v ? '开启' : '关闭'}');
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Opacity(opacity: s.getBool(key) ? 1 : 0.4, child: child),
          ),
        ],
      ),
    );
  }

  Widget _sample(BuildContext context, String text, {required bool big}) {
    final p = context.pal;
    return InkWell(
      onTap: () => toast(context, '示例：$text（在键盘中点击会插入）'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: p.pageBg, borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: TextStyle(fontSize: big ? 20 : 13, color: p.text)),
      ),
    );
  }

  Widget _sticker(BuildContext context, String emoji, String label) {
    final p = context.pal;
    return InkWell(
      onTap: () => toast(context, '图片表情示例：$label（插入为 [表情]）'),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            p.primary.withValues(alpha: 0.12),
            p.primary.withValues(alpha: 0.03),
          ]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 8.5, color: p.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class KeyFeedbackPage extends StatelessWidget {
  const KeyFeedbackPage({super.key});

  void _testSound() {
    SystemSound.play(SystemSoundType.click);
  }

  void _testVibrate(BuildContext context) {
    final level = AppScope.of(context).getInt(K.keyVibrateLevel);
    if (level <= 1) {
      HapticFeedback.selectionClick();
    } else if (level == 2) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return PageScaffold(
      title: '按键反馈',
      children: [
        const SectionTitle('手感'),
        SettingsGroup(children: [
          NavRow(
            title: '响应速度',
            subtitle: '跟手优先或质量优先',
            trailing: s.getString('key_response').isEmpty ? '跟手' : s.getString('key_response'),
            onTap: () => showModalBottomSheet(
              context: context,
              showDragHandle: true,
              builder: (ctx) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('响应速度', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      ChoiceChips(
                        options: const ['跟手', '质量'],
                        selected: s.getString('key_response').isEmpty ? '跟手' : s.getString('key_response'),
                        onSelected: (v) {
                          s.setString('key_response', v);
                          Navigator.pop(ctx);
                          toast(context, '响应速度：$v');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SwitchRow(
            title: '按键声音',
            subtitle: '使用系统点击音',
            value: s.getBool(K.keySound),
            onChanged: (v) {
              s.setBool(K.keySound, v);
              toast(context, '按键声音已${v ? '开启' : '关闭'}');
            },
          ),
          LabeledSlider(
            label: '声音音量',
            value: s.getDouble('key_sound_volume', fallback: 60).clamp(0, 100),
            min: 0,
            max: 100,
            divisions: 10,
            format: (v) => '${v.toStringAsFixed(0)}%',
            onChanged: (v) => s.setDouble('key_sound_volume', v),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: SecondaryButton('试听', icon: Icons.volume_up_outlined, onPressed: _testSound),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SecondaryButton('试振', icon: Icons.vibration_rounded,
                      onPressed: () => _testVibrate(context)),
                ),
              ],
            ),
          ),
          SwitchRow(
            title: '按键振动',
            subtitle: '使用系统触觉反馈',
            value: s.getBool(K.keyVibrate),
            onChanged: (v) {
              s.setBool(K.keyVibrate, v);
              toast(context, '按键振动已${v ? '开启' : '关闭'}');
            },
          ),
          LabeledSlider(
            label: '振动强度',
            value: s.getInt(K.keyVibrateLevel).toDouble().clamp(1, 3),
            min: 1,
            max: 3,
            divisions: 2,
            format: (v) => switch (v.round()) { 1 => '轻', 2 => '中', _ => '强' },
            onChanged: (v) {
              s.setInt(K.keyVibrateLevel, v.round());
              _testVibrate(context);
            },
          ),
          SwitchRow(
            title: '26 键按键气泡',
            subtitle: '按下字母时显示放大气泡',
            value: s.getBool(K.keyBubble),
            onChanged: (v) {
              s.setBool(K.keyBubble, v);
              toast(context, '按键气泡已${v ? '开启' : '关闭'}');
            },
          ),
        ]),
        const SizedBox(height: 12),
        const InfoBanner('声音音量滑杆保存偏好并影响键盘是否播放点击音；系统媒体音量仍由设备控制。振动强度会立即试振。'),
      ],
    );
  }
}

class QuickFormatPage extends StatelessWidget {
  const QuickFormatPage({super.key});

  String _preview(AppState s) {
    var v = '我爱Flutter2026，Hello world';
    if (s.getBool(K.quickSpace)) {
      v = v.replaceAll('爱F', '爱 F').replaceAll('r2', 'r 2');
    }
    if (s.getBool(K.quickCapitalize)) {
      v = v.replaceAll('Hello', 'Hello').replaceAll('world', 'World');
    }
    if (s.getBool(K.quickDoubleSpacePeriod)) {
      v = '$v. ';
    }
    return v;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = AppScope.of(context);
    return PageScaffold(
      title: '快捷格式输入',
      children: [
        SettingsGroup(children: [
          SwitchRow(
            title: '中英数之间自动加空格',
            subtitle: '在中文、英文与数字交界处补一个空格',
            value: s.getBool(K.quickSpace),
            onChanged: (v) {
              s.setBool(K.quickSpace, v);
              toast(context, '中英数空格已${v ? '开启' : '关闭'}');
            },
          ),
          SwitchRow(
            title: '英文首字母大写',
            subtitle: '句首英文自动大写',
            value: s.getBool(K.quickCapitalize),
            onChanged: (v) {
              s.setBool(K.quickCapitalize, v);
              toast(context, '首字母大写已${v ? '开启' : '关闭'}');
            },
          ),
          SwitchRow(
            title: '双击空格输入句号',
            subtitle: '英文模式下连续两次空格补句号',
            value: s.getBool(K.quickDoubleSpacePeriod),
            onChanged: (v) {
              s.setBool(K.quickDoubleSpacePeriod, v);
              toast(context, '双击空格句号已${v ? '开启' : '关闭'}');
            },
          ),
        ]),
        const SectionTitle('实时示例'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('原始输入', style: TextStyle(fontSize: 12, color: p.textSecondary)),
              const SizedBox(height: 4),
              Text('我爱Flutter2026，Hello world  ',
                  style: TextStyle(fontSize: 15, color: p.text)),
              const SizedBox(height: 14),
              Text('应用快捷格式后', style: TextStyle(fontSize: 12, color: p.textSecondary)),
              const SizedBox(height: 4),
              Text(_preview(s),
                  style: TextStyle(fontSize: 15, color: p.primary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        PrimaryButton('在键盘中试试', icon: Icons.keyboard_alt_outlined,
            onPressed: () => Navigator.of(context).pushNamed('/keyboard')),
      ],
    );
  }
}

class ClipboardSettingsPage extends StatelessWidget {
  const ClipboardSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = AppScope.of(context);
    final items = s.clipboardItems;
    return PageScaffold(
      title: '剪切板',
      children: [
        SettingsGroup(children: [
          SwitchRow(
            title: '候选栏展示剪切板',
            subtitle: '复制文本后在候选栏显示一键粘贴',
            value: s.getBool(K.clipboardCandidate),
            onChanged: (v) async {
              if (v && !s.getBool('clipboard_consent')) {
                final ok = await confirm(context,
                    title: '剪切板权限说明',
                    message: '开启后，键盘打开时会读取一次系统剪贴板并在本机保存历史。复刻版不会上传剪贴板内容。',
                    ok: '开启');
                if (!ok) return;
                s.setBool('clipboard_consent', true);
              }
              s.setBool(K.clipboardCandidate, v);
              if (context.mounted) toast(context, '候选栏剪切板已${v ? '开启' : '关闭'}');
            },
          ),
          SwitchRow(
            title: '保存历史记录',
            subtitle: '最多保留 100 条文本',
            value: s.getBool(K.clipboardHistory),
            onChanged: (v) {
              s.setBool(K.clipboardHistory, v);
              toast(context, '历史记录已${v ? '开启' : '关闭'}');
            },
          ),
        ]),
        const SectionTitle('历史记录'),
        SettingsGroup(children: [
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('暂无剪切板记录', style: TextStyle(fontSize: 13, color: p.textSecondary)),
            ),
          for (var i = 0; i < items.length && i < 8; i++)
            ListTile(
              leading: Icon(Icons.content_paste_rounded, size: 20, color: p.primary),
              title: Text((items[i]['text'] ?? '').toString(),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: p.text)),
              subtitle: Text((items[i]['time'] ?? '').toString(),
                  style: TextStyle(fontSize: 11, color: p.textSecondary)),
              trailing: IconButton(
                tooltip: '删除',
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  s.removeClipboard(i);
                  toast(context, '已删除该条记录');
                },
              ),
            ),
          ListTile(
            leading: Icon(Icons.add_rounded, color: p.primary),
            title: Text('保存当前系统剪贴板', style: TextStyle(fontSize: 14, color: p.primary)),
            onTap: () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              final text = data?.text;
              if (text == null || text.trim().isEmpty) {
                toast(context, '系统剪贴板为空');
                return;
              }
              s.addClipboard(text.trim());
              toast(context, '已保存剪贴板内容');
            },
          ),
        ]),
        const SizedBox(height: 14),
        SecondaryButton('清空全部历史记录', icon: Icons.delete_sweep_outlined, onPressed: () async {
          final ok = await confirm(context,
              title: '清空剪切板历史', message: '将删除本机保存的全部 ${items.length} 条记录，无法恢复。',
              danger: true, ok: '清空');
          if (!ok) return;
          s.clearClipboard();
          toast(context, '剪切板历史已清空');
        }),
        const SizedBox(height: 12),
        const InfoBanner('剪切板历史保存在本机。超级互传开启后，可在键盘剪切板面板的「跨设备」标签查看模拟设备内容。'),
      ],
    );
  }
}

class LexiconManagementPage extends StatelessWidget {
  const LexiconManagementPage({super.key});

  Future<void> _addWord(BuildContext context, AppState s) async {
    final wordCtrl = TextEditingController();
    final pinyinCtrl = TextEditingController();
    final p = context.pal;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('添加个人词条', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: p.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: wordCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: '词语', hintText: '例如：复刻输入法'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: pinyinCtrl,
              decoration: const InputDecoration(labelText: '拼音（可选）', hintText: 'fu ke shu ru fa'),
            ),
            const SizedBox(height: 6),
            Text('拼音留空时，词条只在完全匹配时优先展示。',
                style: TextStyle(fontSize: 11, color: p.textSecondary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('添加')),
        ],
      ),
    );
    if (ok == true) {
      final w = wordCtrl.text.trim();
      final py = pinyinCtrl.text.trim();
      if (w.isEmpty) {
        if (context.mounted) toast(context, '词语不能为空');
      } else {
        s.addLexicon(w, py);
        if (context.mounted) toast(context, '已添加「$w」');
      }
    }
    wordCtrl.dispose();
    pinyinCtrl.dispose();
  }

  Future<void> _importContacts(BuildContext context, AppState s) async {
    if (!s.getBool('contacts_import')) {
      final enable = await confirm(context,
          title: '需要开启通讯录导入',
          message: '将开关切换到开启后，才能模拟导入姓名。复刻版不会读取真实通讯录；此操作仅添加示例姓名到本地词库。',
          ok: '开启并继续');
      if (!enable) return;
      s.setBool('contacts_import', true);
    }
    const names = <List<String>>[
      ['张伟', 'zhang wei'], ['李娜', 'li na'], ['王芳', 'wang fang'],
      ['刘洋', 'liu yang'], ['陈晨', 'chen chen'], ['赵敏', 'zhao min'],
    ];
    var added = 0;
    for (final n in names) {
      if (!s.lexicon.any((e) => e['w'] == n[0])) {
        s.addLexicon(n[0], n[1], contact: true);
        added++;
      }
    }
    if (context.mounted) toast(context, added == 0 ? '示例联系人已在词库中' : '已导入 $added 个示例联系人');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = AppScope.of(context);
    final words = s.lexicon;
    final contacts = words.where((e) => e['contact'] == true).toList();
    return PageScaffold(
      title: '词库管理',
      children: [
        const SectionTitle('个人词库'),
        SettingsGroup(children: [
          if (words.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('暂无个人词条，添加后会优先出现在候选栏',
                  style: TextStyle(fontSize: 13, color: p.textSecondary)),
            ),
          for (var i = 0; i < words.length; i++)
            ListTile(
              leading: IconSquare(Icons.bookmark_outline_rounded, size: 34),
              title: Text((words[i]['w'] ?? '').toString(),
                  style: TextStyle(fontSize: 15, color: p.text)),
              subtitle: Text(
                '${(words[i]['p'] ?? '').toString().isEmpty ? '无拼音' : words[i]['p']}${words[i]['contact'] == true ? ' · 通讯录' : ''}',
                style: TextStyle(fontSize: 12, color: p.textSecondary),
              ),
              trailing: IconButton(
                tooltip: '删除词条',
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                onPressed: () {
                  s.removeLexicon(i);
                  toast(context, '已删除「${words[i]['w']}」');
                },
              ),
            ),
          ListTile(
            leading: Icon(Icons.add_circle_outline_rounded, color: p.primary),
            title: Text('添加词条', style: TextStyle(fontSize: 15, color: p.primary)),
            onTap: () => _addWord(context, s),
          ),
        ]),
        const SectionTitle('通讯录词库'),
        SettingsGroup(children: [
          SwitchRow(
            title: '允许导入通讯录人名',
            subtitle: '仅在点击导入时读取姓名；复刻版使用示例数据',
            value: s.getBool('contacts_import'),
            onChanged: (v) {
              s.setBool('contacts_import', v);
              toast(context, v ? '通讯录导入已开启' : '已关闭通讯录导入');
            },
          ),
          NavRow(
            title: '导入人名到本地词库',
            subtitle: contacts.isEmpty ? '尚未导入' : '已导入 ${contacts.length} 位联系人',
            trailing: '模拟导入',
            onTap: () => _importContacts(context, s),
          ),
          if (contacts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: contacts
                    .map((e) => TagChip(e['w'].toString()))
                    .toList(),
              ),
            ),
        ]),
        const SizedBox(height: 14),
        SecondaryButton('清空个人词库', icon: Icons.delete_sweep_outlined, onPressed: () async {
          final ok = await confirm(context,
              title: '清空个人词库', message: '将删除 ${words.length} 条个人词条，不影响内置词典。',
              danger: true, ok: '清空');
          if (!ok) return;
          for (var i = words.length - 1; i >= 0; i--) {
            s.removeLexicon(i);
          }
          toast(context, '个人词库已清空');
        }),
        const SizedBox(height: 10),
        const InfoBanner('内置词典来自 jieba + pypinyin（MIT）生成的 33,500 条数据。个人词条与最近使用会参与本地排序，不会上传。'),
      ],
    );
  }
}
