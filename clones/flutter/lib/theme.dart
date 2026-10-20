import 'package:flutter/material.dart';

/// Design tokens from the shared clone specification.
class T {
  static const primary = Color(0xFF4F84FF);
  static const primaryPressed = Color(0xFF3051F2);
  static const pageBg = Color(0xFFF2F7FF);
  static const card = Colors.white;
  static const text = Color(0xFF111111);
  static const textSecondary = Color(0xFF666666);
  static const divider = Color(0x1A394C5A);
  static const keyboardBg = Color(0xFFEBEBEB);
  static const key = Colors.white;
  static const keyFunc = Color(0xFFBDC2C8);
  static const danger = Color(0xFFFF5353);
  static const radiusCard = 18.0;
  static const radiusKey = 10.0;
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color pageBg;
  final Color card;
  final Color text;
  final Color textSecondary;
  final Color divider;
  final Color keyboardBg;
  final Color key;
  final Color keyFunc;
  final Color primary;
  final Color primaryPressed;
  final Color danger;

  const AppPalette({
    required this.pageBg,
    required this.card,
    required this.text,
    required this.textSecondary,
    required this.divider,
    required this.keyboardBg,
    required this.key,
    required this.keyFunc,
    required this.primary,
    required this.primaryPressed,
    required this.danger,
  });

  static const light = AppPalette(
    pageBg: T.pageBg,
    card: T.card,
    text: T.text,
    textSecondary: T.textSecondary,
    divider: T.divider,
    keyboardBg: T.keyboardBg,
    key: T.key,
    keyFunc: T.keyFunc,
    primary: T.primary,
    primaryPressed: T.primaryPressed,
    danger: T.danger,
  );

  static const dark = AppPalette(
    pageBg: Color(0xFF101418),
    card: Color(0xFF1B2027),
    text: Color(0xFFF2F4F7),
    textSecondary: Color(0xFFA5AFBD),
    divider: Color(0x33FFFFFF),
    keyboardBg: Color(0xFF20252B),
    key: Color(0xFF343B45),
    keyFunc: Color(0xFF55606E),
    primary: Color(0xFF6E9BFF),
    primaryPressed: Color(0xFF4F84FF),
    danger: Color(0xFFFF6B6B),
  );

  @override
  AppPalette copyWith({
    Color? pageBg,
    Color? card,
    Color? text,
    Color? textSecondary,
    Color? divider,
    Color? keyboardBg,
    Color? key,
    Color? keyFunc,
    Color? primary,
    Color? primaryPressed,
    Color? danger,
  }) {
    return AppPalette(
      pageBg: pageBg ?? this.pageBg,
      card: card ?? this.card,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      divider: divider ?? this.divider,
      keyboardBg: keyboardBg ?? this.keyboardBg,
      key: key ?? this.key,
      keyFunc: keyFunc ?? this.keyFunc,
      primary: primary ?? this.primary,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      pageBg: Color.lerp(pageBg, other.pageBg, t)!,
      card: Color.lerp(card, other.card, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      keyboardBg: Color.lerp(keyboardBg, other.keyboardBg, t)!,
      key: Color.lerp(key, other.key, t)!,
      keyFunc: Color.lerp(keyFunc, other.keyFunc, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryPressed: Color.lerp(primaryPressed, other.primaryPressed, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

extension PaletteX on BuildContext {
  AppPalette get pal => Theme.of(this).extension<AppPalette>()!;
}

ThemeData buildTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: p.primary,
      brightness: brightness,
      primary: p.primary,
      surface: p.card,
    ),
  );
  return base.copyWith(
    scaffoldBackgroundColor: p.pageBg,
    canvasColor: p.pageBg,
    dividerColor: p.divider,
    splashFactory: InkSparkle.splashFactory,
    textTheme: base.textTheme
        .apply(bodyColor: p.text, displayColor: p.text)
        .copyWith(
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: p.text,
            letterSpacing: 0,
          ),
          titleMedium: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: p.text,
          ),
          bodyMedium: TextStyle(fontSize: 15, color: p.text, height: 1.35),
          bodySmall: TextStyle(fontSize: 13, color: p.textSecondary, height: 1.3),
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.pageBg,
      foregroundColor: p.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: p.text,
      ),
    ),
    extensions: [p],
    cardTheme: CardThemeData(
      color: p.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(T.radiusCard)),
    ),
  );
}
