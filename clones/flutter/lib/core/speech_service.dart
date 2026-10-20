import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum SpeechPhase { idle, starting, listening, processing, unavailable, denied, error }

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  bool available = false;
  String? lastError;
  SpeechPhase phase = SpeechPhase.idle;

  final _partialController = StreamController<String>.broadcast();
  final _phaseController = StreamController<SpeechPhase>.broadcast();
  Stream<String> get partials => _partialController.stream;
  Stream<SpeechPhase> get phases => _phaseController.stream;

  void _setPhase(SpeechPhase p) {
    phase = p;
    if (!_phaseController.isClosed) _phaseController.add(p);
  }

  Future<bool> ensureInitialized() async {
    if (_initialized) return available;
    try {
      available = await _speech.initialize(
        onError: (e) {
          lastError = e.errorMsg;
          if (e.permanent) {
            _setPhase(SpeechPhase.error);
          }
        },
        onStatus: (s) {
          if (s == 'notListening' && phase == SpeechPhase.listening) {
            _setPhase(SpeechPhase.processing);
          }
        },
      );
      _initialized = true;
    } catch (e) {
      available = false;
      lastError = e.toString();
      _initialized = true;
    }
    return available;
  }

  Future<bool> start({Duration listenFor = const Duration(seconds: 60)}) async {
    _setPhase(SpeechPhase.starting);
    final ok = await ensureInitialized();
    if (!ok) {
      _setPhase(SpeechPhase.unavailable);
      lastError ??= '当前设备没有可用的系统语音识别服务';
      return false;
    }
    try {
      final hasPermission = await _speech.hasPermission;
      if (!hasPermission) {
        _setPhase(SpeechPhase.denied);
        lastError = '麦克风或语音识别权限被拒绝';
        return false;
      }
      await _speech.listen(
        onResult: (SpeechRecognitionResult r) {
          if (r.recognizedWords.isNotEmpty && !_partialController.isClosed) {
            _partialController.add(r.recognizedWords);
          }
          if (r.finalResult) _setPhase(SpeechPhase.processing);
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
          localeId: 'zh_CN',
          listenFor: listenFor,
          pauseFor: const Duration(seconds: 4),
          autoPunctuation: true,
          onDevice: false,
        ),
      );
      _setPhase(SpeechPhase.listening);
      return true;
    } catch (e) {
      lastError = e.toString();
      _setPhase(SpeechPhase.error);
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _speech.stop();
    } catch (_) {}
    _setPhase(SpeechPhase.processing);
  }

  Future<void> cancel() async {
    try {
      await _speech.cancel();
    } catch (_) {}
    _setPhase(SpeechPhase.idle);
  }

  double get soundLevel => _speech.hasError ? 0 : 1;

  Future<void> dispose() async {
    try {
      await _speech.cancel();
    } catch (_) {}
    await _partialController.close();
    await _phaseController.close();
  }

  static String demoTranscript() =>
      '帮我整理一下今天的会议安排，明天下午三点和产品团队讨论复刻版键盘的交互细节。';

  static bool get supportedOnThisPlatform =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}
