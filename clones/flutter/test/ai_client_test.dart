import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doubao_input_flutter/core/ai_service.dart';
import 'package:doubao_input_flutter/core/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  test('OpenAI-compatible client sends auth/model and parses content', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    String? auth;
    Map<String, dynamic>? body;
    server.listen((request) async {
      auth = request.headers.value('authorization');
      body = jsonDecode(await utf8.decoder.bind(request).join()) as Map<String, dynamic>;
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'choices': [
            {'message': {'content': 'OK'}}
          ]
        }));
      await request.response.close();
    });

    SharedPreferences.setMockInitialValues({
      'flutter.ai_base_url': 'http://127.0.0.1:${server.port}',
      'flutter.ai_model': 'mock-model',
      'flutter.ai_key_fallback': 'test-key',
      'flutter.privacy_mode': 'smart',
      'flutter.input_mode': 'smart',
    });
    final state = await AppState.load();
    expect(state.aiKeyEffective, 'test-key');
    expect(state.aiUsable, true);

    final reply = await AiService.testConnection();
    expect(reply, 'OK');
    expect(auth, 'Bearer test-key');
    expect(body?['model'], 'mock-model');
    expect(body?['messages'], isA<List>());

    await server.close(force: true);
  });

  test('local fallback is used without a key', () async {
    SharedPreferences.setMockInitialValues({
      'flutter.ai_base_url': 'http://127.0.0.1:1',
      'flutter.ai_model': 'mock-model',
      'flutter.privacy_mode': 'smart',
      'flutter.input_mode': 'smart',
    });
    final state = await AppState.load();
    await state.clearAiKey();
    final r = await AiService.write('写祝福', '朋友生日');
    expect(r.local, true);
    expect(r.text.contains('生日') || r.text.contains('愿你'), true);
  });
}
