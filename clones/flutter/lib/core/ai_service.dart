import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'app_state.dart';
import 'local_tools.dart';

class AiResult {
  final String text;
  final bool local;
  final String? error;
  const AiResult(this.text, {this.local = false, this.error});
}

class AiException implements Exception {
  final String message;
  final bool retryable;
  const AiException(this.message, {this.retryable = true});
  @override
  String toString() => message;
}

class AiService {
  static const _timeout = Duration(seconds: 20);

  static String get _base {
    final b = AppState.I.aiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return b.isEmpty ? 'https://api.deepseek.com' : b;
  }

  static Uri get _endpoint {
    final b = _base;
    if (b.endsWith('/v1')) return Uri.parse('$b/chat/completions');
    return Uri.parse('$b/v1/chat/completions');
  }

  /// OpenAI-compatible chat completions. The key is read at runtime only and
  /// never logged. User setting takes priority over --dart-define injection.
  static Future<String> complete({
    required String system,
    required String user,
    double temperature = 0.7,
    int maxTokens = 900,
  }) async {
    final key = AppState.I.aiKeyEffective;
    if (key.isEmpty) {
      throw const AiException('未配置 API Key', retryable: false);
    }
    final client = http.Client();
    try {
      final resp = await client
          .post(
            _endpoint,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $key',
            },
            body: jsonEncode({
              'model': AppState.I.aiModel,
              'messages': [
                {'role': 'system', 'content': system},
                {'role': 'user', 'content': user},
              ],
              'temperature': temperature,
              'max_tokens': maxTokens,
              'stream': false,
            }),
          )
          .timeout(_timeout);
      if (resp.statusCode == 401 || resp.statusCode == 403) {
        throw const AiException('鉴权失败（401/403），请检查 API Key', retryable: false);
      }
      if (resp.statusCode == 429) {
        throw const AiException('请求过于频繁（429），请稍后重试');
      }
      if (resp.statusCode >= 500) {
        throw AiException('服务端错误（${resp.statusCode}），请稍后重试');
      }
      if (resp.statusCode != 200) {
        String msg = '请求失败（${resp.statusCode}）';
        try {
          final m = jsonDecode(utf8.decode(resp.bodyBytes)) as Map;
          if (m['error'] is Map && m['error']['message'] != null) {
            msg = m['error']['message'].toString();
          }
        } catch (_) {}
        throw AiException(msg, retryable: resp.statusCode >= 500);
      }
      final body = jsonDecode(utf8.decode(resp.bodyBytes));
      final content = body['choices']?[0]?['message']?['content'];
      if (content is! String || content.trim().isEmpty) {
        throw const AiException('返回内容为空');
      }
      return content.trim();
    } on TimeoutException {
      throw const AiException('请求超时（20 秒），请检查网络后重试');
    } on SocketException {
      throw const AiException('网络不可用，请检查连接');
    } on HandshakeException {
      throw const AiException('TLS 握手失败，请检查 Base URL');
    } finally {
      client.close();
    }
  }

  static Future<String> testConnection() async {
    return complete(
      system: '你是一个连接测试助手。只回复“OK”。',
      user: 'ping',
      temperature: 0,
      maxTokens: 8,
    );
  }

  static Future<AiResult> organize(
    String text, {
    required bool aggressive,
    required bool blankLine,
    required String punctuation,
    required String mode,
  }) async {
    final local = localOrganize(
      text,
      aggressive: aggressive,
      blankLine: blankLine,
      punctuation: punctuation,
      mode: mode,
    );
    if (!AppState.I.aiUsable) {
      return AiResult(local, local: true,
          error: AppState.I.isSmartMode ? '未配置 Key，已使用离线整理' : '基础输入模式下 AI 不可用');
    }
    final prompt = '''整理下面的中文口语文本。
要求：
- 分段方式：${blankLine ? '分段后保留空行' : '分段后不空行'}
- 标点策略：$punctuation
- 口水词处理：${aggressive ? '激进（尽量删除）' : '正常'}
- 风格：$mode
只输出整理后的文本，不要解释。

原文：
$text''';
    try {
      final out = await complete(
        system: '你是专业的中文文字整理助手，擅长把口语转成清晰、自然、可直接发送的书面文本。',
        user: prompt,
        temperature: 0.3,
      );
      return AiResult(out);
    } catch (e) {
      return AiResult(local, local: true, error: e.toString());
    }
  }

  static Future<AiResult> translate(
    String text, {
    required bool toEnglish,
  }) async {
    final local = localTranslate(text, toEnglish: toEnglish);
    if (!AppState.I.aiUsable) {
      return AiResult(local, local: true,
          error: AppState.I.isSmartMode ? '未配置 Key，已使用离线词库' : '基础输入模式下 AI 不可用');
    }
    try {
      final out = await complete(
        system: '你是专业翻译。只输出译文，保留原意与语气，不添加解释。',
        user: toEnglish ? '把下面的中文翻译成自然英文：\n$text' : '把下面的英文翻译成自然中文：\n$text',
        temperature: 0.2,
      );
      return AiResult(out);
    } catch (e) {
      return AiResult(local, local: true, error: e.toString());
    }
  }

  static Future<AiResult> write(
    String action,
    String topic, {
    int variant = 0,
  }) async {
    final local = localWrite(action, topic, variant: variant);
    if (!AppState.I.aiUsable) {
      return AiResult(local, local: true,
          error: AppState.I.isSmartMode ? '未配置 Key，已使用离线模板' : '基础输入模式下 AI 不可用');
    }
    final prompts = <String, String>{
      '写祝福': '写一段真诚、有画面感的中文祝福语，80 字左右。',
      '高赞动态': '写一条适合朋友圈/社交平台的高赞动态，真实、有共鸣，100 字以内。',
      '写评论': '针对给定主题写一条自然、有观点的评论，50 字以内。',
      '自我介绍': '写一段简洁、有个性的自我介绍，80 字左右。',
      '宴席邀请': '写一份得体、热情的中文宴席邀请，包含时间地点占位符。',
      '写邮件': '写一封结构完整、语气得体的中文商务邮件，包含称呼、正文、结尾。',
      '爆款文案': '写一条有钩子、有节奏感的中文爆款文案，适合短视频口播。',
    };
    try {
      final out = await complete(
        system: '你是资深中文内容创作者，文字自然、不空洞、不堆砌网络热词。',
        user: '${prompts[action] ?? prompts['高赞动态']}\n主题：${topic.trim().isEmpty ? '日常生活与成长' : topic.trim()}',
        temperature: 0.9,
      );
      return AiResult(out);
    } catch (e) {
      return AiResult(local, local: true, error: e.toString());
    }
  }

  static Future<AiResult> assist(String mode, String text) async {
    final local = switch (mode) {
      '重写' => localRewrite(text),
      '总结' => localSummary(text),
      '关键点' => localKeyPoints(text),
      '列表' => localList(text),
      '检查' => localCheck(text),
      _ => text,
    };
    if (!AppState.I.aiUsable) {
      return AiResult(local, local: true,
          error: AppState.I.isSmartMode ? '未配置 Key，已使用离线处理' : '基础输入模式下 AI 不可用');
    }
    final prompt = switch (mode) {
      '重写' => '在不改变原意的前提下重写下面的文本，使表达更流畅自然。只输出结果：\n$text',
      '总结' => '用两句话总结下面的文本。只输出结果：\n$text',
      '关键点' => '提取下面文本的关键点，用短句列出，每行一个。\n$text',
      '列表' => '把下面文本改写成编号列表，保留信息，语言简洁。\n$text',
      '检查' => '检查下面文本的错别字、标点和中英文空格问题，列出问题并给出修改后的文本。\n$text',
      _ => text,
    };
    try {
      final out = await complete(system: '你是严谨的中文写作助手。', user: prompt, temperature: 0.4);
      return AiResult(out);
    } catch (e) {
      return AiResult(local, local: true, error: e.toString());
    }
  }

  static Future<AiResult> chat(String context) async {
    final local = localChatReply(context);
    if (!AppState.I.aiUsable) {
      return AiResult(local, local: true,
          error: AppState.I.isSmartMode ? '未配置 Key，已使用本地快捷回复' : '基础输入模式下 AI 不可用');
    }
    try {
      final out = await complete(
        system: '你是输入法里的 AI 聊天助手，回复简短、自然、有帮助，控制在 80 字以内。',
        user: context,
        temperature: 0.8,
      );
      return AiResult(out);
    } catch (e) {
      return AiResult(local, local: true, error: e.toString());
    }
  }
}
