import 'package:flutter/material.dart';
import 'core/app_state.dart';
import 'core/deep_link.dart';
import 'theme.dart';
import 'ui/keyboard/keyboard_demo.dart';
import 'ui/onboarding.dart';
import 'ui/pages/keyboard_pages.dart';
import 'ui/pages/privacy_pages.dart';
import 'ui/pages/tool_pages.dart';
import 'ui/pages/voice_pages.dart';
import 'ui/settings_home.dart';
import 'ui/widgets.dart';

class DoubaoApp extends StatelessWidget {
  final AppState state;
  const DoubaoApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          return MaterialApp(
            title: '豆包输入法（复刻）',
            navigatorKey: DeepLinkService.navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            themeMode: state.themeMode,
            locale: const Locale('zh', 'CN'),
            onGenerateRoute: _route,
          );
        },
      ),
    );
  }

  Route<dynamic>? _route(RouteSettings settings) {
    final name = settings.name ?? '/';
    final args = settings.arguments;
    Widget builder;
    switch (name) {
      case '/':
        builder = const RootGate();
        break;
      case '/onboarding':
        builder = const OnboardingPage();
        break;
      case '/privacy':
        builder = const PrivacyConsentPage();
        break;
      case '/keyboard-types':
        builder = KeyboardTypePickerPage(
          firstRun: args is Map && args['firstRun'] == true,
        );
        break;
      case '/voice-settings':
        builder = const VoiceSettingsPage();
        break;
      case '/voice-action':
        builder = const VoiceActionPage();
        break;
      case '/offline-voice':
        builder = const OfflineVoicePage();
        break;
      case '/double-pinyin':
        builder = const DoublePinyinPage();
        break;
      case '/wubi':
        builder = const WubiPage();
        break;
      case '/layout':
        builder = const LayoutSettingsPage();
        break;
      case '/custom-symbols':
        builder = const CustomSymbolsPage();
        break;
      case '/fuzzy':
        builder = const FuzzyPinyinPage();
        break;
      case '/association':
        builder = const AssociationPage();
        break;
      case '/prediction':
        builder = const PredictionTypesPage();
        break;
      case '/key-feedback':
        builder = const KeyFeedbackPage();
        break;
      case '/quick-format':
        builder = const QuickFormatPage();
        break;
      case '/clipboard-settings':
        builder = const ClipboardSettingsPage();
        break;
      case '/lexicon':
        builder = const LexiconManagementPage();
        break;
      case '/input-mode':
        builder = const InputModePage();
        break;
      case '/smart-input':
        builder = const SmartInputPage();
        break;
      case '/permissions':
        builder = const SystemPermissionsPage();
        break;
      case '/transfer':
        builder = const SuperTransferPage();
        break;
      case '/account':
        builder = const AccountPage();
        break;
      case '/login':
        builder = const LoginPage();
        break;
      case '/messages':
        builder = const MessageCenterPage();
        break;
      case '/desktop':
        builder = const DesktopAppPage();
        break;
      case '/help':
        builder = const HelpFeedbackPage();
        break;
      case '/about':
        builder = const AboutPage();
        break;
      case '/ai-settings':
        builder = const AISettingsPage();
        break;
      case '/ime-test':
        builder = const ImeTestPage();
        break;
      case '/keyboard':
        final map = args is Map ? args : const {};
        builder = KeyboardDemoPage(
          initialPanel: map['panel']?.toString(),
          initialMode: map['mode']?.toString(),
          initialComposing: map['composing']?.toString(),
        );
        break;
      case '/settings':
        builder = const SettingsHomePage();
        break;
      case '/text':
        final map = args is Map ? args : const {};
        builder = PolicyTextPage(
          title: (map['title'] ?? '说明').toString(),
          content: (map['content'] ?? '').toString(),
        );
        break;
      default:
        return null;
    }
    return PageRouteBuilder(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondary) => builder,
      transitionsBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.035, 0), end: Offset.zero)
                .animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

class RootGate extends StatefulWidget {
  const RootGate({super.key});
  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  bool _splash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _splash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    if (_splash) return const _Splash();
    if (!s.onboardingDone) return const OnboardingPage();
    if (!s.hasKeyboardType) return const KeyboardTypePickerPage(firstRun: true);
    return const SettingsHomePage();
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.pageBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppMark(size: 76),
            const SizedBox(height: 18),
            Text('豆包输入法（复刻）',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: p.text)),
            const SizedBox(height: 6),
            Text('净室行为复刻 · 非官方产品',
                style: TextStyle(fontSize: 12, color: p.textSecondary)),
            const SizedBox(height: 28),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.6, color: p.primary),
            ),
          ],
        ),
      ),
    );
  }
}
