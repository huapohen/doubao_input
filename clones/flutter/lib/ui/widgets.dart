import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_state.dart';
import '../theme.dart';

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing');
    return scope!.notifier!;
  }
}

void toast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontSize: 14)),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 1800),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String ok = '确定',
  String cancel = '取消',
  bool danger = false,
}) async {
  final p = context.pal;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: p.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: p.text)),
      content: Text(message, style: TextStyle(fontSize: 14, color: p.textSecondary, height: 1.5)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(cancel)),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: danger ? p.danger : p.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ok),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<String?> promptText(
  BuildContext context, {
  required String title,
  String? hint,
  String? subtitle,
  String initial = '',
  String ok = '保存',
  TextInputType keyboardType = TextInputType.text,
}) async {
  final ctrl = TextEditingController(text: initial);
  final p = context.pal;
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: p.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: p.text)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle != null) ...[
            Text(subtitle, style: TextStyle(fontSize: 13, color: p.textSecondary)),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: keyboardType,
            maxLines: keyboardType == TextInputType.multiline ? 4 : 1,
            style: TextStyle(color: p.text, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: p.pageBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: p.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
          child: Text(ok),
        ),
      ],
    ),
  );
  ctrl.dispose();
  return result;
}

class PageScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool center;
  final double maxWidth;
  final EdgeInsets padding;
  final Widget? header;

  const PageScaffold({
    super.key,
    required this.title,
    required this.children,
    this.actions,
    this.floatingActionButton,
    this.center = true,
    this.maxWidth = 760,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 32),
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.pageBg,
      appBar: AppBar(
        title: Text(title),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                tooltip: '返回',
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: center
            ? Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: ListView(
                    padding: padding,
                    children: [
                      if (header != null) header!,
                      ...children,
                    ],
                  ),
                ),
              )
            : ListView(padding: padding, children: [if (header != null) header!, ...children]),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.icon, this.trailing});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: p.text),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.text)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets margin;
  const SettingsGroup({super.key, required this.children, this.margin = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final list = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        list.add(Divider(height: 1, thickness: 0.7, color: p.divider, indent: 16, endIndent: 16));
      }
      list.add(children[i]);
    }
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(T.radiusCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: list),
    );
  }
}

class NavRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? trailing;
  final Widget? trailingWidget;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool showChevron;
  final bool enabled;

  const NavRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.trailingWidget,
    this.onTap,
    this.icon,
    this.showChevron = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: enabled ? p.primary : p.textSecondary),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: enabled ? p.text : p.textSecondary,
                      )),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(subtitle!,
                        style: TextStyle(fontSize: 13, color: p.textSecondary, height: 1.3)),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(trailing!,
                    style: TextStyle(fontSize: 13, color: p.textSecondary)),
              ),
            if (trailingWidget != null) ...[
              const SizedBox(width: 8),
              trailingWidget!,
            ],
            if (showChevron)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(Icons.chevron_right_rounded,
                    size: 21, color: p.textSecondary.withValues(alpha: 0.7)),
              ),
          ],
        ),
      ),
    );
  }
}

class SwitchRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const SwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, color: p.text)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(subtitle!,
                        style: TextStyle(fontSize: 13, color: p.textSecondary, height: 1.3)),
                  ],
                ],
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: p.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class ValueRow extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;
  const ValueRow({super.key, required this.title, required this.value, this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return NavRow(
      title: title,
      subtitle: subtitle,
      trailing: value,
      onTap: onTap,
      showChevron: false,
    );
  }
}

class InfoBanner extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? color;
  const InfoBanner(this.text, {super.key, this.icon = Icons.info_outline_rounded, this.color});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final c = color ?? p.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: c),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13, color: p.textSecondary, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  const PrimaryButton(this.label,
      {super.key, this.onPressed, this.icon, this.expanded = true});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final child = Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 19), const SizedBox(width: 8)],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
    return SizedBox(
      width: expanded ? double.infinity : null,
      height: 50,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          disabledBackgroundColor: p.primary.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: child,
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  const SecondaryButton(this.label, {super.key, this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          side: BorderSide(color: p.primary.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class ChoiceChips extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final bool wrap;
  const ChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.wrap = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final chips = options.map((o) {
      final active = o == selected;
      return Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: InkWell(
          onTap: () => onSelected(o),
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: active ? p.primary : p.card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: active ? p.primary : p.divider),
            ),
            child: Text(o,
                style: TextStyle(
                  fontSize: 14,
                  color: active ? Colors.white : p.text,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                )),
          ),
        ),
      );
    }).toList();
    if (wrap) return Wrap(children: chips);
    return Row(children: chips);
  }
}

class RadioOptionRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  const RadioOptionRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              size: 21,
              color: selected ? p.primary : p.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, color: p.text)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(subtitle!,
                        style: TextStyle(fontSize: 13, color: p.textSecondary, height: 1.3)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LabeledSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final String Function(double)? format;
  const LabeledSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
    this.format,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: TextStyle(fontSize: 15, color: p.text)),
              ),
              Text(format?.call(value) ?? value.toStringAsFixed(0),
                  style: TextStyle(fontSize: 13, color: p.primary, fontWeight: FontWeight.w600)),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            activeColor: p.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;
  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: 52, color: p.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 14),
          Text(title, style: TextStyle(fontSize: 16, color: p.text)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: p.textSecondary)),
          ],
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  final String text;
  final Color? color;
  const TagChip(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final c = color ?? p.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
    );
  }
}

class AppMark extends StatelessWidget {
  final double size;
  const AppMark({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: const LinearGradient(
          colors: [Color(0xFF6DA0FF), Color(0xFF3051F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: T.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(Icons.keyboard_alt_outlined, color: Colors.white, size: size * 0.56),
    );
  }
}

class IconSquare extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;
  const IconSquare(this.icon, {super.key, this.color, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.pal.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: c, size: size * 0.55),
    );
  }
}

void copyText(BuildContext context, String text, [String message = '已复制']) {
  Clipboard.setData(ClipboardData(text: text));
  toast(context, message);
}
