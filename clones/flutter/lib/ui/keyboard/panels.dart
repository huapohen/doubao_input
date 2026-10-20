import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/ai_service.dart';
import '../../core/app_state.dart';
import '../../core/pinyin_engine.dart';
import '../../theme.dart';
import '../widgets.dart';
import 'keyboard_controller.dart';

class KeyboardPanelHost extends StatelessWidget {
  final String id;
  final KeyboardController c;
  final VoidCallback onClose;
  final void Function(String route) onNavigate;
  final VoidCallback onVoice;

  const KeyboardPanelHost({
    super.key,
    required this.id,
    required this.c,
    required this.onClose,
    required this.onNavigate,
    required this.onVoice,
  });

  @override
  Widget build(BuildContext context) {
    return switch (id) {
      'toolbox' => _ToolboxPanel(c: c, onClose: onClose, onNavigate: onNavigate, onVoice: onVoice),
      'emoji' => _EmojiPanel(c: c, onClose: onClose),
      'clipboard' => _ClipboardPanel(c: c, onClose: onClose, onNavigate: onNavigate),
      'phrases' => _PhrasesPanel(c: c, onClose: onClose),
      'toolbar' => _ToolbarPanel(c: c, onClose: onClose),
      'translate' => _TranslatePanel(c: c, onClose: onClose),
      'organize' => _OrganizePanel(c: c, onClose: onClose),
      'ai' => _AiPanel(c: c, onClose: onClose, onNavigate: onNavigate),
      'keyboard' => _KeyboardSwitchPanel(c: c, onClose: onClose),
      'handwriting' => _HandwritingLookupPanel(c: c, onClose: onClose),
      'onehand' => _OneHandPanel(c: c, onClose: onClose),
      'adjust' => _AdjustPanel(c: c, onClose: onClose),
      'candidates' => _CandidateDetailPanel(c: c, onClose: onClose),
      _ => const SizedBox.shrink(),
    };
  }
}

class _Shell extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  final Widget child;
  final List<Widget> actions;
  const _Shell({
    required this.title,
    required this.onClose,
    required this.child,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      color: p.keyboardBg,
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: Row(
              children: [
                const SizedBox(width: 12),
                Text(title,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: p.text)),
                const Spacer(),
                ...actions,
                IconButton(
                  tooltip: '返回键盘',
                  visualDensity: VisualDensity.compact,
                  onPressed: onClose,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: p.textSecondary),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toolbox
// ---------------------------------------------------------------------------
class _ToolboxPanel extends StatefulWidget {
  final KeyboardController c;
  final VoidCallback onClose;
  final void Function(String route) onNavigate;
  final VoidCallback onVoice;
  const _ToolboxPanel({
    required this.c,
    required this.onClose,
    required this.onNavigate,
    required this.onVoice,
  });

  @override
  State<_ToolboxPanel> createState() => _ToolboxPanelState();
}

class _ToolboxPanelState extends State<_ToolboxPanel> {
  final PageController _page = PageController();
  int _index = 0;

  static const _page1 = <List<Object>>[
    [Icons.mic_none_rounded, '语音输入', 'voice'],
    [Icons.emoji_emotions_outlined, '表情', 'emoji'],
    [Icons.keyboard_rounded, '键盘选择', 'keyboard'],
    [Icons.auto_fix_high_rounded, '智能整理', 'organize'],
    [Icons.format_quote_rounded, '常用语', 'phrases'],
    [Icons.content_paste_rounded, '剪切板', 'clipboard'],
    [Icons.tune_rounded, '定制工具栏', 'toolbar'],
    [Icons.gesture_rounded, '手写找字', 'handwriting'],
  ];
  static const _page2 = <List<Object>>[
    [Icons.translate_rounded, '翻译', 'translate'],
    [Icons.phone_iphone_rounded, '单手', 'onehand'],
    [Icons.height_rounded, '键盘调节', 'adjust'],
    [Icons.settings_outlined, '更多设置', 'route:/layout'],
    [Icons.help_outline_rounded, '帮助与反馈', 'route:/help'],
  ];

  void _tap(String target) {
    if (target == 'voice') {
      widget.onVoice();
      return;
    }
    if (target.startsWith('route:')) {
      widget.onNavigate(target.substring(6));
      return;
    }
    widget.c.setPanel(target);
  }

  @override
  Widget build(BuildContext context) {
    return _Shell(
      title: '工具箱',
      onClose: widget.onClose,
      child: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _page,
              onPageChanged: (i) => setState(() => _index = i),
              children: [
                _grid(_page1),
                _grid(_page2),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: _index == 0 ? null : () => _page.previousPage(
                    duration: const Duration(milliseconds: 200), curve: Curves.easeOut),
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
              ),
              for (var i = 0; i < 2; i++)
                Container(
                  width: _index == i ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _index == i ? context.pal.primary : context.pal.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: _index == 1 ? null : () => _page.nextPage(
                    duration: const Duration(milliseconds: 200), curve: Curves.easeOut),
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _grid(List<List<Object>> items) {
    final p = context.pal;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.12,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final highlight = item[0] == Icons.tune_rounded;
        return InkWell(
          onTap: () => _tap(item[2] as String),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item[0] as IconData, size: 24,
                    color: highlight ? p.primary : p.text),
                const SizedBox(height: 6),
                Text(item[1] as String,
                    style: TextStyle(fontSize: 11, color: highlight ? p.primary : p.text)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Emoji
// ---------------------------------------------------------------------------
class _EmojiPanel extends StatefulWidget {
  final KeyboardController c;
  final VoidCallback onClose;
  const _EmojiPanel({required this.c, required this.onClose});

  @override
  State<_EmojiPanel> createState() => _EmojiPanelState();
}

class _EmojiPanelState extends State<_EmojiPanel> {
  int _tab = 0;
  String _cat = '最近';

  static const _categories = <String, List<String>>{
    '表情': ['😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '😊', '😇', '🥰', '😍', '🤩', '😘', '😗', '😚', '😙', '🥲', '😋', '😛', '😜', '🤪', '😝', '🤗', '🤭', '🤫', '🤔', '🫡', '😐', '😑', '😶', '🙄', '😏', '😣', '😥', '😮', '🤐', '😯', '😪', '😫', '🥱', '😴', '😌', '😔', '🤤', '😒', '😓', '😕', '🙃'],
    '手势': ['👍', '👎', '👌', '🤌', '🤏', '✌️', '🤞', '🫰', '🤟', '🤘', '🤙', '👈', '👉', '👆', '👇', '☝️', '👏', '🙌', '👐', '🤲', '🤝', '🙏', '✍️', '💪'],
    '动物': ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯', '🦁', '🐮', '🐷', '🐸', '🐵', '🐔', '🐧', '🐦', '🐤', '🦆', '🦅', '🦉', '🦇', '🐺'],
    '食物': ['🍎', '🍐', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🫐', '🍈', '🍒', '🍑', '🥭', '🍍', '🥥', '🥝', '🍅', '🥑', '🍆', '🥔', '🥕', '🌽', '🌶️', '🍞'],
    '活动': ['⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉', '🥏', '🎱', '🪀', '🏓', '🏸', '🏒', '🏑', '🥍', '🏏', '🪃', '🥅', '⛳', '🪁', '🏹', '🎣', '🤿'],
    '旅行': ['🚗', '🚕', '🚙', '🚌', '🚎', '🏎️', '🚓', '🚑', '🚒', '🚐', '🛻', '🚚', '🚛', '🚜', '🛴', '🚲', '🛵', '🏍️', '🚨', '🚔', '🚍', '🚘', '🚖', '🚡'],
    '物品': ['⌚', '📱', '💻', '⌨️', '🖥️', '🖨️', '🖱️', '🖲️', '🕹️', '🗜️', '💽', '💾', '💿', '📀', '📼', '📷', '📸', '📹', '🎥', '📽️', '🎞️', '📞', '☎️', '📟'],
    '符号': ['❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔', '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💟', '☮️', '✝️', '☪️', '🕉️', '☸️'],
  };

  List<String> get _list {
    if (_cat == '最近') {
      final recent = AppState.I.recentEmoji;
      return recent.isEmpty ? _categories['表情']!.take(24).toList() : recent;
    }
    return _categories[_cat] ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return _Shell(
      title: '表情',
      onClose: widget.onClose,
      child: Column(
        children: [
          SizedBox(
            height: 38,
            child: Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tab = i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(['Emoji', '表情图', '颜文字'][i],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _tab == i ? FontWeight.w600 : FontWeight.w400,
                                color: _tab == i ? p.primary : p.textSecondary,
                              )),
                          const SizedBox(height: 6),
                          Container(
                            height: 2,
                            width: 30,
                            color: _tab == i ? p.primary : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _tab == 0
                ? _emojiTab(context, p)
                : (_tab == 1 ? _stickerTab(context, p) : _kaomojiTab(context, p)),
          ),
        ],
      ),
    );
  }

  Widget _emojiTab(BuildContext context, AppPalette p) {
    return Column(
      children: [
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              for (final c in ['最近', ..._categories.keys])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
                  child: InkWell(
                    onTap: () => setState(() => _cat = c),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _cat == c ? p.primary : p.card,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(c,
                          style: TextStyle(
                              fontSize: 10.5,
                              color: _cat == c ? Colors.white : p.textSecondary)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: _list.length,
            itemBuilder: (context, i) {
              final e = _list[i];
              return InkWell(
                onTap: () {
                  widget.c.insertText(e, applyScript: false);
                  AppState.I.addRecentEmoji(e);
                },
                borderRadius: BorderRadius.circular(8),
                child: Center(child: Text(e, style: const TextStyle(fontSize: 23))),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _stickerTab(BuildContext context, AppPalette p) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.15,
      ),
      itemCount: PinyinEngine.stickers.length,
      itemBuilder: (context, i) {
        final s = PinyinEngine.stickers[i];
        return InkWell(
          onTap: () => widget.c.insertText('[${s[1]}]', applyScript: false),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [p.primary.withValues(alpha: 0.13), p.primary.withValues(alpha: 0.03)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(s[0], style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 3),
                Text(s[1],
                    style: TextStyle(fontSize: 9, color: p.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _kaomojiTab(BuildContext context, AppPalette p) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.5,
      ),
      itemCount: PinyinEngine.kaomoji.length,
      itemBuilder: (context, i) {
        return InkWell(
          onTap: () => widget.c.insertText(PinyinEngine.kaomoji[i], applyScript: false),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(PinyinEngine.kaomoji[i],
                style: TextStyle(fontSize: 11, color: p.text),
                maxLines: 1,
                overflow: TextOverflow.clip),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Clipboard
// ---------------------------------------------------------------------------
class _ClipboardPanel extends StatefulWidget {
  final KeyboardController c;
  final VoidCallback onClose;
  final void Function(String) onNavigate;
  const _ClipboardPanel({required this.c, required this.onClose, required this.onNavigate});

  @override
  State<_ClipboardPanel> createState() => _ClipboardPanelState();
}

class _ClipboardPanelState extends State<_ClipboardPanel> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    if (!AppState.I.getBool('clipboard_consent')) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final ok = await confirm(
          context,
          title: '剪切板权限说明',
          message: '首次打开剪切板面板会读取一次系统剪贴板，并可在本机保存历史。复刻版不会上传剪贴板内容。',
          ok: '同意并继续',
        );
        if (!mounted) return;
        if (ok) {
          AppState.I.setBool('clipboard_consent', true);
          AppState.I.addClipboard((await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '');
        } else {
          widget.onClose();
        }
      });
    }
  }

  Future<void> _addFromSystem() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      if (mounted) toast(context, '系统剪贴板为空');
      return;
    }
    AppState.I.addClipboard(text.trim());
    if (mounted) toast(context, '已保存到本机历史');
  }

  Future<void> _action(Map<String, dynamic> item, int index) async {
    final text = (item['text'] ?? '').toString();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: const Text('剪切板记录'),
            ),
            ListTile(
              leading: const Icon(Icons.call_split_rounded),
              title: const Text('拆词'),
              onTap: () {
                Navigator.pop(ctx);
                _splitWords(text);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('复制回系统剪贴板'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: text));
                Navigator.pop(ctx);
                toast(context, '已复制');
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: context.pal.danger),
              title: Text('删除', style: TextStyle(color: context.pal.danger)),
              onTap: () {
                AppState.I.removeClipboard(index);
                Navigator.pop(ctx);
                toast(context, '已删除该条记录');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _splitWords(String text) {
    final pieces = <String>[];
    final matches = RegExp(r'[\u4e00-\u9fff]|[A-Za-z0-9]+').allMatches(text);
    for (final m in matches) {
      pieces.add(m.group(0)!);
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('拆词'),
        content: SizedBox(
          width: 300,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in pieces.take(60))
                  ActionChip(
                    label: Text(p),
                    onPressed: () {
                      widget.c.insertText(p, applyScript: false);
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.c.insertText(pieces.join(' '), applyScript: false);
              Navigator.pop(ctx);
            },
            child: const Text('全部插入'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = AppScope.of(context);
    return _Shell(
      title: '剪切板',
      onClose: widget.onClose,
      actions: [
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: '保存系统剪贴板',
          onPressed: _addFromSystem,
          icon: const Icon(Icons.add_rounded, size: 20),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: '清空历史',
          onPressed: () async {
            final ok = await confirm(context,
                title: '清空剪切板', message: '将删除本机全部 ${s.clipboardItems.length} 条记录。',
                danger: true, ok: '清空');
            if (ok) {
              s.clearClipboard();
              if (context.mounted) toast(context, '剪切板历史已清空');
            }
          },
          icon: Icon(Icons.delete_sweep_outlined, size: 20, color: p.danger),
        ),
      ],
      child: Column(
        children: [
          SizedBox(
            height: 34,
            child: Row(
              children: [
                for (var i = 0; i < 2; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tab = i),
                      child: Center(
                        child: Text(['本机', '跨设备'][i],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _tab == i ? FontWeight.w600 : FontWeight.w400,
                              color: _tab == i ? p.primary : p.textSecondary,
                            )),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _tab == 0 ? _local(context, s) : _cross(context, s),
          ),
        ],
      ),
    );
  }

  Widget _local(BuildContext context, AppState s) {
    final items = s.clipboardItems;
    if (items.isEmpty) {
      return EmptyState(
        title: '暂无剪切板记录',
        subtitle: '复制文本，或点击右上角 + 保存系统剪贴板',
        icon: Icons.content_paste_off_outlined,
        action: SecondaryButton('保存系统剪贴板', icon: Icons.add_rounded, onPressed: _addFromSystem),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      itemCount: items.length + 1,
      itemBuilder: (context, i) {
        if (i == items.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Material(
              color: context.pal.card,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () {
                  widget.c.insertText('[图片]', applyScript: false);
                  toast(context, '已插入图片占位符（复刻版仅支持文本）');
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            context.pal.primary.withValues(alpha: 0.25),
                            context.pal.primary.withValues(alpha: 0.06),
                          ]),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.image_outlined, size: 18, color: context.pal.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('图片占位（演示）',
                                style: TextStyle(fontSize: 12, color: context.pal.text)),
                            Text('点击插入 [图片]',
                                style: TextStyle(fontSize: 10, color: context.pal.textSecondary)),
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
        final item = items[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Material(
            color: context.pal.card,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => widget.c.insertText((item['text'] ?? '').toString()),
              onLongPress: () => _action(item, i),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((item['text'] ?? '').toString(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, color: context.pal.text)),
                          const SizedBox(height: 2),
                          Text((item['time'] ?? '').toString(),
                              style: TextStyle(fontSize: 10, color: context.pal.textSecondary)),
                        ],
                      ),
                    ),
                    Icon(Icons.north_west_rounded, size: 14, color: context.pal.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cross(BuildContext context, AppState s) {
    final p = context.pal;
    if (!s.loggedIn) {
      return EmptyState(
        title: '登录后使用跨设备剪切板',
        subtitle: '复刻版为本地演示，不会连接官方设备服务',
        icon: Icons.devices_other_rounded,
        action: PrimaryButton('去登录', icon: Icons.login_rounded, onPressed: () {
          widget.onNavigate('/login');
        }),
      );
    }
    if (!s.superTransferEnabled) {
      return EmptyState(
        title: '超级互传未启用',
        subtitle: '启用后可在这里查看其他设备的示例内容',
        icon: Icons.sync_alt_rounded,
        action: PrimaryButton('启用超级互传', icon: Icons.sync_rounded, onPressed: () {
          widget.onNavigate('/transfer');
        }),
      );
    }
    final items = s.clipboardItems;
    final text = items.isEmpty ? '来自电脑的示例文本' : (items.first['text'] ?? '').toString();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          child: Row(
            children: [
              Icon(Icons.laptop_mac_rounded, size: 16, color: p.primary),
              const SizedBox(width: 6),
              Text('我的 MacBook', style: TextStyle(fontSize: 12, color: p.text)),
              const Spacer(),
              TagChip('本机演示'),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            children: [
              for (final it in items.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: p.card,
                    borderRadius: BorderRadius.circular(10),
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.content_paste_rounded, size: 18, color: p.primary),
                      title: Text((it['text'] ?? '').toString(),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: p.text)),
                      subtitle: Text('来自 我的 MacBook',
                          style: TextStyle(fontSize: 10, color: p.textSecondary)),
                      onTap: () => widget.c.insertText((it['text'] ?? '').toString()),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SecondaryButton('获取示例同步文本', icon: Icons.refresh_rounded, onPressed: () {
                  s.addClipboard('来自电脑的同步示例：$text'.substring(0, text.length > 20 ? 26 : text.length + 7));
                  toast(context, '已拉取一条示例同步内容');
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Phrases
// ---------------------------------------------------------------------------
class _PhrasesPanel extends StatefulWidget {
  final KeyboardController c;
  final VoidCallback onClose;
  const _PhrasesPanel({required this.c, required this.onClose});

  @override
  State<_PhrasesPanel> createState() => _PhrasesPanelState();
}

class _PhrasesPanelState extends State<_PhrasesPanel> {
  String _cat = '全部';

  Future<void> _edit({int? index}) async {
    final s = AppState.I;
    final existing = index == null ? null : s.phrases[index];
    final ctrl = TextEditingController(text: existing?['text']?.toString() ?? '');
    var cat = existing?['category']?.toString() ?? '工作';
    final p = context.pal;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: p.card,
          title: Text(index == null ? '添加常用语' : '编辑常用语'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ctrl,
                maxLines: 3,
                autofocus: true,
                decoration: const InputDecoration(hintText: '输入常用语内容'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: [
                  for (final c in const ['工作', '日常', '地址', '自定义'])
                    ChoiceChip(
                      label: Text(c, style: const TextStyle(fontSize: 12)),
                      selected: cat == c,
                      onSelected: (_) => setD(() => cat = c),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('保存')),
          ],
        ),
      ),
    );
    if (ok == true) {
      final text = ctrl.text.trim();
      if (text.isEmpty) {
        ctrl.dispose();
        return;
      }
      if (index == null) {
        s.addPhrase(text, cat);
      } else {
        s.updatePhrase(index, text, cat);
      }
      if (mounted) toast(context, index == null ? '已添加常用语' : '已保存修改');
    }
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = context.pal;
    final all = s.phrases;
    final cats = ['全部', ...all.map((e) => (e['category'] ?? '自定义').toString()).toSet()];
    final list = _cat == '全部'
        ? all
        : all.where((e) => (e['category'] ?? '自定义').toString() == _cat).toList();
    return _Shell(
      title: '常用语',
      onClose: widget.onClose,
      actions: [
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: '添加常用语',
          onPressed: () => _edit(),
          icon: const Icon(Icons.add_rounded, size: 20),
        ),
      ],
      child: Column(
        children: [
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                for (final c in cats)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                    child: InkWell(
                      onTap: () => setState(() => _cat = c),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _cat == c ? p.primary : p.card,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(c,
                            style: TextStyle(
                                fontSize: 10.5,
                                color: _cat == c ? Colors.white : p.textSecondary)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? EmptyState(
                    title: '暂无常用语',
                    subtitle: '添加后可在键盘中一键插入',
                    icon: Icons.format_quote_rounded,
                    action: SecondaryButton('添加', icon: Icons.add_rounded, onPressed: () => _edit()),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final item = list[i];
                      final realIndex = all.indexOf(item);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Material(
                          color: p.card,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: () => widget.c.insertText((item['text'] ?? '').toString()),
                            onLongPress: () => _itemActions(realIndex, item),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text((item['text'] ?? '').toString(),
                                        style: TextStyle(fontSize: 13, color: p.text),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  const SizedBox(width: 8),
                                  TagChip((item['category'] ?? '自定义').toString()),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _itemActions(int index, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.north_west_rounded),
              title: const Text('插入'),
              onTap: () {
                Navigator.pop(ctx);
                widget.c.insertText((item['text'] ?? '').toString());
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('编辑'),
              onTap: () {
                Navigator.pop(ctx);
                _edit(index: index);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: context.pal.danger),
              title: Text('删除', style: TextStyle(color: context.pal.danger)),
              onTap: () {
                AppState.I.removePhrase(index);
                Navigator.pop(ctx);
                toast(context, '已删除常用语');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toolbar customization
// ---------------------------------------------------------------------------
class _ToolbarPanel extends StatefulWidget {
  final KeyboardController c;
  final VoidCallback onClose;
  const _ToolbarPanel({required this.c, required this.onClose});

  @override
  State<_ToolbarPanel> createState() => _ToolbarPanelState();
}

class _ToolbarPanelState extends State<_ToolbarPanel> {
  late List<String> _items;
  int _tab = 0;

  static const _labels = <String, String>{
    'toolbox': '工具箱', 'voice': '点击说话', 'clipboard': '剪切板', 'translate': '翻译',
    'emoji': '表情', 'phrases': '常用语', 'keyboard': '键盘选择', 'tradition': '繁简切换',
    'onehand': '单手', 'handwriting': '手写找字', 'undo': '撤销删除', 'ai': 'AI',
    'collapse': '收起键盘',
  };
  static const _icons = <String, IconData>{
    'toolbox': Icons.apps_rounded, 'voice': Icons.mic_none_rounded,
    'clipboard': Icons.content_paste_rounded, 'translate': Icons.translate_rounded,
    'emoji': Icons.emoji_emotions_outlined, 'phrases': Icons.format_quote_rounded,
    'keyboard': Icons.keyboard_rounded, 'tradition': Icons.translate_rounded,
    'onehand': Icons.phone_iphone_rounded, 'handwriting': Icons.gesture_rounded,
    'undo': Icons.undo_rounded, 'ai': Icons.auto_awesome_rounded,
    'collapse': Icons.keyboard_arrow_down_rounded,
  };

  @override
  void initState() {
    super.initState();
    _items = List<String>.of(AppState.I.toolbar);
  }

  int get _page1Count => _items.length > 8 ? 8 : _items.length;

  void _save() => AppState.I.setToolbar(List<String>.of(_items));

  void _onReorder(int oldIndex, int newIndex) {
    final start = _tab == 0 ? 0 : _page1Count;
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _items.removeAt(start + oldIndex);
    _items.insert(start + newIndex, item);
    setState(() {});
    _save();
  }

  void _move(int index, int toPage) {
    final item = _items.removeAt(index);
    if (toPage == 0) {
      _items.insert(math.min(_page1Count, 8), item);
    } else {
      _items.add(item);
    }
    setState(() {});
    _save();
  }

  void _remove(int index) {
    if (_items.length <= 1) {
      toast(context, '至少保留一个工具栏按钮');
      return;
    }
    _items.removeAt(index);
    setState(() {});
    _save();
  }

  Future<void> _add() async {
    final available = _labels.keys.where((e) => !_items.contains(e)).toList();
    if (available.isEmpty) {
      toast(context, '所有工具项都已添加');
      return;
    }
    final v = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final id in available)
              ListTile(
                leading: Icon(_icons[id], size: 20),
                title: Text(_labels[id] ?? id),
                onTap: () => Navigator.pop(ctx, id),
              ),
          ],
        ),
      ),
    );
    if (v != null) {
      setState(() => _items.add(v));
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final start = _tab == 0 ? 0 : _page1Count;
    final end = _tab == 0 ? _page1Count : _items.length;
    final list = _items.sublist(start, end);
    return _Shell(
      title: '定制工具栏',
      onClose: widget.onClose,
      actions: [
        TextButton(
          onPressed: () {
            AppState.I.setToolbar(AppState.defaultToolbar);
            setState(() => _items = List<String>.of(AppState.defaultToolbar));
            toast(context, '已恢复默认工具栏');
          },
          child: const Text('恢复默认', style: TextStyle(fontSize: 11)),
        ),
        IconButton(
          tooltip: '添加工具',
          visualDensity: VisualDensity.compact,
          onPressed: _add,
          icon: const Icon(Icons.add_rounded, size: 20),
        ),
      ],
      child: Column(
        children: [
          SizedBox(
            height: 36,
            child: Row(
              children: [
                for (var i = 0; i < 2; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tab = i),
                      child: Center(
                        child: Text('第${i + 1}页',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _tab == i ? FontWeight.w600 : FontWeight.w400,
                              color: _tab == i ? p.primary : p.textSecondary,
                            )),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text('这一页还没有工具',
                        style: TextStyle(fontSize: 12, color: p.textSecondary)))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
                    itemCount: list.length,
                    onReorder: _onReorder,
                    itemBuilder: (context, i) {
                      final id = list[i];
                      final idx = start + i;
                      return Material(
                        key: ValueKey('$id-$i'),
                        color: p.card,
                        borderRadius: BorderRadius.circular(9),
                        child: SizedBox(
                          height: 36,
                          child: Row(
                            children: [
                              const SizedBox(width: 6),
                              ReorderableDragStartListener(
                                index: i,
                                child: Icon(Icons.drag_indicator_rounded, size: 17, color: p.textSecondary),
                              ),
                              const SizedBox(width: 6),
                              Icon(_icons[id] ?? Icons.apps, size: 16, color: p.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_labels[id] ?? id,
                                    style: TextStyle(fontSize: 12, color: p.text)),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: _tab == 0 ? '移到第二页' : '移到第一页',
                                icon: Icon(_tab == 0 ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                    size: 15),
                                onPressed: () => _move(idx, _tab == 0 ? 1 : 0),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: '移除',
                                icon: Icon(Icons.close_rounded, size: 15, color: p.danger),
                                onPressed: () => _remove(idx),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                Text('吸附', style: TextStyle(fontSize: 11, color: p.textSecondary)),
                const SizedBox(width: 8),
                ChoiceChips(
                  options: const ['左侧', '右侧'],
                  selected: AppScope.of(context).toolbarAlign == 'right' ? '右侧' : '左侧',
                  onSelected: (v) {
                    AppState.I.setString('toolbar_align', v == '右侧' ? 'right' : 'left');
                    setState(() {});
                    toast(context, '工具栏已吸附$v');
                  },
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    _save();
                    widget.onClose();
                    toast(context, '工具栏已保存');
                  },
                  child: const Text('完成', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Translate
// ---------------------------------------------------------------------------
String _selectedOrAll(KeyboardController c) {
  final sel = c.text.selection;
  if (sel.isValid && sel.start != sel.end) {
    return c.text.text.substring(sel.start, sel.end);
  }
  return c.text.text;
}

void _replaceSelection(KeyboardController c, String result) {
  final sel = c.text.selection;
  final base = c.text.text;
  final start = sel.isValid ? sel.start : base.length;
  final end = sel.isValid ? sel.end : base.length;
  c.text.value = TextEditingValue(
    text: base.replaceRange(start, end, result),
    selection: TextSelection.collapsed(offset: start + result.length),
  );
  c.refreshUI();
}

class _TranslatePanel extends StatefulWidget {
  final KeyboardController c;
  final VoidCallback onClose;
  const _TranslatePanel({required this.c, required this.onClose});

  @override
  State<_TranslatePanel> createState() => _TranslatePanelState();
}

class _TranslatePanelState extends State<_TranslatePanel> {
  late final TextEditingController _src;
  bool _toEnglish = true;
  bool _busy = false;
  String? _result;
  bool _local = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _src = TextEditingController(text: _selectedOrAll(widget.c));
  }

  @override
  void dispose() {
    _src.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final text = _src.text.trim();
    if (text.isEmpty) {
      toast(context, '请输入要翻译的文本');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await AiService.translate(text, toEnglish: _toEnglish);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = r.text;
      _local = r.local;
      _error = r.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return _Shell(
      title: '翻译',
      onClose: widget.onClose,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Column(
          children: [
            Row(
              children: [
                Text(_toEnglish ? '中文' : 'English',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.text)),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: '切换方向',
                  onPressed: () => setState(() {
                    _toEnglish = !_toEnglish;
                    _result = null;
                    _error = null;
                  }),
                  icon: Icon(Icons.swap_horiz_rounded, size: 20, color: p.primary),
                ),
                Text(_toEnglish ? 'English' : '中文',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.text)),
                const Spacer(),
                TagChip(_result == null ? (AppState.I.aiUsable ? 'AI' : '离线') : (_local ? '离线词库' : 'AI'),
                    color: _result != null && _local ? const Color(0xFFE08A00) : p.primary),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: () => setState(() => _src.text = _selectedOrAll(widget.c)),
                  child: const Text('取当前文本', style: TextStyle(fontSize: 10)),
                ),
              ],
            ),
            SizedBox(
              height: 66,
              child: TextField(
                controller: _src,
                maxLines: 3,
                readOnly: true,
                onTap: () async {
                  final v = await promptText(context,
                      title: '编辑翻译文本',
                      initial: _src.text,
                      keyboardType: TextInputType.multiline);
                  if (v != null) setState(() => _src.text = v);
                },
                style: TextStyle(fontSize: 13, color: p.text),
                decoration: InputDecoration(
                  hintText: '点击编辑要翻译的文本',
                  filled: true,
                  fillColor: p.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(_busy ? '翻译中…' : '翻译',
                  icon: Icons.translate_rounded, onPressed: _busy ? null : _run),
            ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text('提示：$_error',
                  style: TextStyle(fontSize: 10, color: p.danger),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 6),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _result == null
                    ? Text('译文会显示在这里。未配置 AI Key 时使用离线词库。',
                        style: TextStyle(fontSize: 11, color: p.textSecondary))
                    : SingleChildScrollView(
                        child: SelectableText(_result!,
                            style: TextStyle(fontSize: 13, color: p.text, height: 1.5)),
                      ),
              ),
            ),
            if (_result != null)
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton('复制', icon: Icons.copy_rounded, onPressed: () {
                      Clipboard.setData(ClipboardData(text: _result!));
                      toast(context, '译文已复制');
                    }),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PrimaryButton('替换输入', icon: Icons.keyboard_return_rounded, onPressed: () {
                      _replaceSelection(widget.c, _result!);
                      toast(context, '已替换输入框文本');
                    }),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Smart organize
// ---------------------------------------------------------------------------
class _OrganizePanel extends StatefulWidget {
  final KeyboardController c;
  final VoidCallback onClose;
  const _OrganizePanel({required this.c, required this.onClose});

  @override
  State<_OrganizePanel> createState() => _OrganizePanelState();
}

class _OrganizePanelState extends State<_OrganizePanel> {
  late final TextEditingController _src;
  String _mode = '默认整理';
  bool _busy = false;
  String? _result;
  bool _local = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _src = TextEditingController(text: _selectedOrAll(widget.c));
  }

  @override
  void dispose() {
    _src.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final text = _src.text.trim();
    if (text.isEmpty) {
      toast(context, '请先输入或选中文本');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await AiService.organize(
      text,
      aggressive: AppState.I.voiceFiller == '激进',
      blankLine: AppState.I.getBool('voice_paragraph'),
      punctuation: AppState.I.voicePunctuation,
      mode: _mode,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = r.text;
      _local = r.local;
      _error = r.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return _Shell(
      title: '智能文字整理',
      onClose: widget.onClose,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('把口语整理成可直接发送的书面文本',
                      style: TextStyle(fontSize: 10.5, color: p.textSecondary)),
                ),
                TagChip(_local ? '离线' : 'AI',
                    color: _local ? const Color(0xFFE08A00) : p.primary),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 56,
              child: TextField(
                controller: _src,
                maxLines: 2,
                readOnly: true,
                onTap: () async {
                  final v = await promptText(context,
                      title: '编辑要整理的文本',
                      initial: _src.text,
                      keyboardType: TextInputType.multiline);
                  if (v != null) setState(() => _src.text = v);
                },
                style: TextStyle(fontSize: 12.5, color: p.text),
                decoration: InputDecoration(
                  hintText: '点击编辑或取当前选中文本',
                  filled: true,
                  fillColor: p.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: [
                for (final m in const ['默认整理', '精简', '正式'])
                  ChoiceChip(
                    label: Text(m, style: const TextStyle(fontSize: 10)),
                    selected: _mode == m,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => setState(() => _mode = m),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(_busy ? '整理中…' : '开始整理',
                  icon: Icons.auto_fix_high_rounded, onPressed: _busy ? null : _run),
            ),
            if (_error != null)
              Text('提示：$_error',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9.5, color: p.danger)),
            const SizedBox(height: 4),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(10)),
                child: _result == null
                    ? Text('整理结果会显示在这里',
                        style: TextStyle(fontSize: 11, color: p.textSecondary))
                    : SingleChildScrollView(
                        child: SelectableText(_result!,
                            style: TextStyle(fontSize: 12.5, color: p.text, height: 1.5)),
                      ),
              ),
            ),
            if (_result != null)
              Row(
                children: [
                  Expanded(child: SecondaryButton('复制', icon: Icons.copy_rounded, onPressed: () {
                    Clipboard.setData(ClipboardData(text: _result!));
                    toast(context, '已复制整理结果');
                  })),
                  const SizedBox(width: 6),
                  Expanded(child: SecondaryButton('重试', icon: Icons.refresh_rounded, onPressed: _run)),
                  const SizedBox(width: 6),
                  Expanded(child: PrimaryButton('替换', onPressed: () {
                    _replaceSelection(widget.c, _result!);
                    toast(context, '已替换输入框文本');
                  })),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI writing / chat
// ---------------------------------------------------------------------------
class _AiPanel extends StatefulWidget {
  final KeyboardController c;
  final VoidCallback onClose;
  final void Function(String) onNavigate;
  const _AiPanel({required this.c, required this.onClose, required this.onNavigate});

  @override
  State<_AiPanel> createState() => _AiPanelState();
}

class _AiPanelState extends State<_AiPanel> {
  int _tab = 0;
  String _action = '写祝福';
  late final TextEditingController _topic;
  late final TextEditingController _chatInput;
  bool _busy = false;
  String? _result;
  String? _error;
  bool _local = false;
  final List<String> _history = [];
  int _historyIndex = -1;

  final List<Map<String, String>> _messages = [
    {'role': 'assistant', 'text': '你好！我是复刻版 AI 聊天助手。可以帮你写回复、整理表达或快速查资料。'},
  ];
  String _scene = '微信';
  bool _chatLocal = false;

  static const _actions = <String>[
    '写祝福', '高赞动态', '写评论', '自我介绍', '宴席邀请', '写邮件', '爆款文案',
  ];

  @override
  void initState() {
    super.initState();
    _topic = TextEditingController(text: _selectedOrAll(widget.c));
    _chatInput = TextEditingController();
  }

  @override
  void dispose() {
    _topic.dispose();
    _chatInput.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final topic = _topic.text.trim().isEmpty ? _selectedOrAll(widget.c) : _topic.text.trim();
    final r = await AiService.write(_action, topic);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = r.text;
      _local = r.local;
      _error = r.error;
      _history.add(r.text);
      _historyIndex = _history.length - 1;
    });
  }

  Future<void> _assist(String mode) async {
    final base = _result ?? _selectedOrAll(widget.c);
    if (base.trim().isEmpty) {
      toast(context, '没有可处理的文本');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await AiService.assist(mode, base);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = r.text;
      _local = r.local;
      _error = r.error;
      _history.add(r.text);
      _historyIndex = _history.length - 1;
    });
  }

  Future<void> _send() async {
    final text = _chatInput.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _chatInput.clear();
      _busy = true;
    });
    final contextText = _messages.reversed
        .where((m) => m['role'] == 'user')
        .take(3)
        .map((m) => m['text'])
        .join('\n');
    final r = await AiService.chat('场景：$_scene\n$contextText');
    if (!mounted) return;
    setState(() {
      _busy = false;
      _messages.add({'role': 'assistant', 'text': r.text});
      _chatLocal = r.local;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return _Shell(
      title: 'AI 助手',
      onClose: widget.onClose,
      child: Column(
        children: [
          SizedBox(
            height: 34,
            child: Row(
              children: [
                for (var i = 0; i < 2; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tab = i),
                      child: Center(
                        child: Text(['AI 写作', 'AI 聊天'][i],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _tab == i ? FontWeight.w600 : FontWeight.w400,
                              color: _tab == i ? p.primary : p.textSecondary,
                            )),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _tab == 0 ? _writing(context, p) : _chat(context, p),
          ),
        ],
      ),
    );
  }

  Widget _writing(BuildContext context, AppPalette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final a in _actions)
                  Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: ChoiceChip(
                      label: Text(a, style: const TextStyle(fontSize: 10)),
                      selected: _action == a,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => _action = a),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 40,
            child: TextField(
              controller: _topic,
              readOnly: true,
              onTap: () async {
                final v = await promptText(context,
                    title: 'AI 写作主题',
                    initial: _topic.text,
                    subtitle: '例如：朋友生日、产品发布、周末随笔');
                if (v != null) setState(() => _topic.text = v);
              },
              style: TextStyle(fontSize: 12, color: p.text),
              decoration: InputDecoration(
                hintText: '点击编辑主题（可选）',
                filled: true,
                fillColor: p.card,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                  onPressed: _busy ? null : _generate,
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 32,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : _generate,
              icon: const Icon(Icons.auto_awesome_rounded, size: 15),
              label: Text(_busy ? '生成中…' : '生成内容',
                  style: const TextStyle(fontSize: 11)),
              style: FilledButton.styleFrom(
                backgroundColor: p.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          if (!AppState.I.isSmartMode)
            Text('基础输入模式：AI 不可用，将使用本地模板',
                style: TextStyle(fontSize: 9.5, color: p.danger)),
          if (_error != null)
            Text('提示：$_error',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 9.5, color: p.danger)),
          const SizedBox(height: 4),
          if (_result != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(_local ? '离线模板结果' : 'AI 生成结果',
                  style: TextStyle(fontSize: 9, color: p.textSecondary)),
            ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(10)),
              child: _busy
                  ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: p.primary))
                  : _result == null
                      ? Center(
                          child: Text('选择场景后点击生成\n未配置 Key 时使用离线模板',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: p.textSecondary)))
                      : SingleChildScrollView(
                          child: SelectableText(_result!,
                              style: TextStyle(fontSize: 12.5, color: p.text, height: 1.55)),
                        ),
            ),
          ),
          if (_result != null) ...[
            SizedBox(
              height: 28,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final m in const ['重写', '总结', '关键点', '列表', '检查'])
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: ActionChip(
                        label: Text(m, style: const TextStyle(fontSize: 9.5)),
                        visualDensity: VisualDensity.compact,
                        onPressed: _busy ? null : () => _assist(m),
                      ),
                    ),
                  ActionChip(
                    label: const Text('上一条', style: TextStyle(fontSize: 9.5)),
                    onPressed: _historyIndex > 0
                        ? () => setState(() {
                              _historyIndex--;
                              _result = _history[_historyIndex];
                            })
                        : null,
                  ),
                  ActionChip(
                    label: const Text('下一条', style: TextStyle(fontSize: 9.5)),
                    onPressed: _historyIndex >= 0 && _historyIndex < _history.length - 1
                        ? () => setState(() {
                              _historyIndex++;
                              _result = _history[_historyIndex];
                            })
                        : null,
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton('复制', icon: Icons.copy_rounded, onPressed: () {
                    Clipboard.setData(ClipboardData(text: _result!));
                    toast(context, '已复制');
                  }),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: PrimaryButton('替换输入', icon: Icons.keyboard_return_rounded, onPressed: () {
                    _replaceSelection(widget.c, _result!);
                    toast(context, '已替换输入框文本');
                  }),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chat(BuildContext context, AppPalette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Column(
        children: [
          SizedBox(
            height: 30,
            child: Row(
              children: [
                Text('场景', style: TextStyle(fontSize: 10, color: p.textSecondary)),
                const SizedBox(width: 6),
                for (final s in const ['微信', 'QQ', '飞书', '小红书'])
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: ChoiceChip(
                      label: Text(s, style: const TextStyle(fontSize: 9)),
                      selected: _scene == s,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => _scene = s),
                    ),
                  ),
                const Spacer(),
                TagChip(_chatLocal ? '本地' : (AppState.I.aiUsable ? 'AI' : '离线'),
                    color: _chatLocal ? const Color(0xFFE08A00) : p.primary),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final mine = m['role'] == 'user';
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    constraints: const BoxConstraints(maxWidth: 300),
                    decoration: BoxDecoration(
                      color: mine ? p.primary : p.card,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m['text'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: mine ? Colors.white : p.text,
                              height: 1.4,
                            )),
                        if (!mine)
                          GestureDetector(
                            onTap: () {
                              widget.c.insertText(m['text'] ?? '');
                              toast(context, '已插入聊天回复');
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text('点击插入',
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: p.primary.withValues(alpha: 0.9))),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final q in const ['在吗', '今天天气怎么样', '帮我回复：收到', '推荐一个周末计划'])
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: ActionChip(
                      label: Text(q, style: const TextStyle(fontSize: 9)),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        _chatInput.text = q;
                        _send();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _chatInput,
                    readOnly: true,
                    onTap: () async {
                      final v = await promptText(context,
                          title: '发送消息',
                          hint: '输入想让 AI 回复的内容',
                          keyboardType: TextInputType.multiline);
                      if (v != null && v.trim().isNotEmpty) {
                        _chatInput.text = v;
                        _send();
                      }
                    },
                    style: TextStyle(fontSize: 12, color: p.text),
                    decoration: InputDecoration(
                      hintText: '点击输入消息，AI 帮你回复',
                      filled: true,
                      fillColor: p.card,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _busy ? null : _send,
                icon: Icon(Icons.send_rounded, size: 20, color: p.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Keyboard switch
// ---------------------------------------------------------------------------
class _KeyboardSwitchPanel extends StatelessWidget {
  final KeyboardController c;
  final VoidCallback onClose;
  const _KeyboardSwitchPanel({required this.c, required this.onClose});

  static const _types = <List<String>>[
    ['pinyin9', '9 键', '9'],
    ['pinyin26', '26 键', '26'],
    ['handwriting', '手写', '手'],
    ['stroke', '笔画', '笔'],
    ['shuangpin', '双拼', '双'],
    ['wubi', '五笔', '五'],
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return _Shell(
      title: '键盘选择',
      onClose: onClose,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.5,
        ),
        itemCount: _types.length,
        itemBuilder: (context, i) {
          final t = _types[i];
          final active = c.mode == t[0];
          return InkWell(
            onTap: () {
              c.setMode(t[0]);
              onClose();
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                color: active ? p.primary : p.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: active ? p.primary : p.divider),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(t[2],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : p.primary,
                      )),
                  const SizedBox(height: 4),
                  Text(t[1],
                      style: TextStyle(
                          fontSize: 11, color: active ? Colors.white : p.textSecondary)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Handwriting lookup
// ---------------------------------------------------------------------------
class _HandwritingLookupPanel extends StatefulWidget {
  final KeyboardController c;
  final VoidCallback onClose;
  const _HandwritingLookupPanel({required this.c, required this.onClose});

  @override
  State<_HandwritingLookupPanel> createState() => _HandwritingLookupPanelState();
}

class _HandwritingLookupPanelState extends State<_HandwritingLookupPanel> {
  final _q = TextEditingController();
  List<String> _results = [];

  void _search() {
    final q = _q.text.trim();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    final list = PinyinEngine.instance.textSearch(q, limit: 36);
    setState(() => _results = list.map((e) => e.text).toList());
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final results = _results.isEmpty
        ? '你好豆包输入法智能语音手写五笔双拼'.split('')
        : _results;
    return _Shell(
      title: '手写找字',
      onClose: widget.onClose,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      controller: _q,
                      autofocus: false,
                      onSubmitted: (_) => _search(),
                      style: TextStyle(fontSize: 12, color: p.text),
                      decoration: InputDecoration(
                        hintText: '输入拼音或部件，例如 nihao / 亻',
                        filled: true,
                        fillColor: p.card,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '查找',
                  onPressed: _search,
                  icon: Icon(Icons.search_rounded, size: 20, color: p.primary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.only(top: 4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: results.length,
                itemBuilder: (context, i) {
                  final ch = results[i];
                  return InkWell(
                    onTap: () {
                      widget.c.insertText(ch);
                      widget.onClose();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: p.card,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(ch,
                            style: TextStyle(fontSize: ch.length > 2 ? 10 : 18, color: p.text)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// One hand
// ---------------------------------------------------------------------------
class _OneHandPanel extends StatelessWidget {
  final KeyboardController c;
  final VoidCallback onClose;
  const _OneHandPanel({required this.c, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return _Shell(
      title: '单手 / 悬浮',
      onClose: onClose,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Column(
          children: [
            Row(
              children: [
                for (final e in const [
                  ['off', '关闭', Icons.fullscreen_rounded],
                  ['left', '左手', Icons.align_horizontal_left_rounded],
                  ['right', '右手', Icons.align_horizontal_right_rounded],
                ])
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        AppState.I.setString(K.oneHand, e[0] as String);
                        toast(context, e[0] == 'off' ? '单手模式已关闭' : '${e[1]}模式已开启');
                      },
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        height: 74,
                        decoration: BoxDecoration(
                          color: AppState.I.oneHand == e[0] ? p.primary : p.card,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(e[2] as IconData,
                                size: 24,
                                color: AppState.I.oneHand == e[0] ? Colors.white : p.text),
                            const SizedBox(height: 5),
                            Text(e[1] as String,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppState.I.oneHand == e[0] ? Colors.white : p.text)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            SwitchRow(
              title: '悬浮键盘',
              subtitle: '可拖动、贴边与缩放',
              value: AppState.I.floating,
              onChanged: (v) {
                AppState.I.setBool(K.floating, v);
                toast(context, v ? '悬浮键盘已开启' : '悬浮键盘已关闭');
              },
            ),
            if (AppState.I.floating) ...[
              LabeledSlider(
                label: '悬浮缩放',
                value: AppState.I.floatingScale,
                min: 0.7,
                max: 1,
                divisions: 6,
                format: (v) => '${(v * 100).round()}%',
                onChanged: (v) => AppState.I.setDouble('floating_scale', v),
              ),
              Text('拖动悬浮栏可移动键盘，松手自动贴边',
                  style: TextStyle(fontSize: 10, color: p.textSecondary)),
            ],
            const SizedBox(height: 10),
            PrimaryButton('恢复默认设置', icon: Icons.restart_alt_rounded, onPressed: () {
              AppState.I.setString(K.oneHand, 'off');
              AppState.I.setBool(K.floating, false);
              AppState.I.setDouble('floating_scale', 1);
              toast(context, '已恢复默认布局');
              onClose();
            }),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Adjust
// ---------------------------------------------------------------------------
class _AdjustPanel extends StatelessWidget {
  final KeyboardController c;
  final VoidCallback onClose;
  const _AdjustPanel({required this.c, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return _Shell(
      title: '键盘调节',
      onClose: onClose,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Column(
          children: [
            LabeledSlider(
              label: '键盘高度',
              value: s.keyboardHeight.toDouble(),
              min: 260,
              max: 440,
              divisions: 18,
              format: (v) => '${v.toStringAsFixed(0)} dp',
              onChanged: (v) => s.setInt(K.keyboardHeight, v.round()),
            ),
            LabeledSlider(
              label: '底部间距',
              value: s.keyboardGap.toDouble(),
              min: 0,
              max: 24,
              divisions: 12,
              format: (v) => '${v.toStringAsFixed(0)} dp',
              onChanged: (v) => s.setInt('keyboard_gap', v.round()),
            ),
            LabeledSlider(
              label: '候选字号',
              value: s.candidateFontSize,
              min: 14,
              max: 28,
              divisions: 14,
              format: (v) => '${v.toStringAsFixed(0)} sp',
              onChanged: (v) => s.setDouble(K.candidateFontSize, v),
            ),
            SwitchRow(
              title: '悬浮键盘',
              subtitle: '拖动与缩放，关闭后恢复底部布局',
              value: s.floating,
              onChanged: (v) => s.setBool(K.floating, v),
            ),
            if (s.floating)
              LabeledSlider(
                label: '悬浮缩放',
                value: s.floatingScale,
                min: 0.7,
                max: 1,
                divisions: 6,
                format: (v) => '${(v * 100).round()}%',
                onChanged: (v) => s.setDouble('floating_scale', v),
              ),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton('恢复默认', icon: Icons.restart_alt_rounded, onPressed: () {
                    s.resetKeyboardTuning();
                    toast(context, '已恢复默认');
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(child: PrimaryButton('完成', onPressed: onClose)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Candidate detail
// ---------------------------------------------------------------------------
class _CandidateDetailPanel extends StatefulWidget {
  final KeyboardController c;
  final VoidCallback onClose;
  const _CandidateDetailPanel({required this.c, required this.onClose});

  @override
  State<_CandidateDetailPanel> createState() => _CandidateDetailPanelState();
}

class _CandidateDetailPanelState extends State<_CandidateDetailPanel> {
  bool _singleOnly = false;

  List<String> get _list {
    final c = widget.c;
    if (c.isHandwriting) return c.handwritingCandidates;
    if (c.isStroke) return c.strokeCandidates.map((e) => e.char).toList();
    var list = c.candidates.map((e) => e.text).toList();
    if (_singleOnly) list = list.where((e) => e.length == 1).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final list = _list;
    return _Shell(
      title: widget.c.composing.isEmpty ? '手写找字 / 全部候选' : '更多候选',
      onClose: widget.onClose,
      actions: [
        TextButton(
          onPressed: () => setState(() => _singleOnly = !_singleOnly),
          child: Text(_singleOnly ? '全部' : '单字', style: const TextStyle(fontSize: 11)),
        ),
        TextButton(
          onPressed: () => widget.c.setPanel('handwriting'),
          child: const Text('手写找字', style: TextStyle(fontSize: 11)),
        ),
      ],
      child: list.isEmpty
          ? EmptyState(
              title: widget.c.isHandwriting ? '手写结果会显示在这里' : '没有更多候选',
              subtitle: '继续输入，或使用手写找字',
              icon: Icons.grid_view_rounded,
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final t = list[i];
                return InkWell(
                  onTap: () {
                    if (widget.c.isHandwriting) {
                      widget.c.commitHandwriting(t);
                    } else {
                      final match = widget.c.candidates.where((e) => e.text == t);
                      if (match.isNotEmpty) {
                        widget.c.commitCandidate(match.first);
                      } else {
                        widget.c.insertText(t);
                      }
                    }
                    widget.onClose();
                  },
                  onLongPress: () {
                    final match = widget.c.candidates.where((e) => e.text == t);
                    if (match.isNotEmpty) widget.c.deleteCandidate(match.first);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(t,
                          style: TextStyle(fontSize: t.length > 1 ? 10 : 18, color: p.text)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
