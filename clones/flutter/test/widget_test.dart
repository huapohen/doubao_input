import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doubao_input_flutter/theme.dart';

void main() {
  test('design tokens are wired into the theme', () {
    final theme = buildTheme(Brightness.light);
    expect(theme.scaffoldBackgroundColor, T.pageBg);
    expect(theme.extension<AppPalette>()!.primary, T.primary);
  });
}
