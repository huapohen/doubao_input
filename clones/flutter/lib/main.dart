import 'package:flutter/material.dart';
import 'app.dart';
import 'core/app_state.dart';
import 'core/deep_link.dart';
import 'core/pinyin_engine.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = await AppState.load();
  try {
    await PinyinEngine.instance.load();
    debugPrint('pinyin dict loaded in ${PinyinEngine.instance.loadMillis} ms '
        '(${PinyinEngine.instance.entryCount} entries)');
  } catch (e) {
    debugPrint('pinyin dictionary failed to load: $e');
  }
  runApp(DoubaoApp(state: state));
  DeepLinkService.init();
}
