import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/audio/audio_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/fx_layer.dart';
import 'domain/progress/badges.dart';
import 'domain/progress/progress_controller.dart';
import 'features/achievements/achievements_screen.dart';
import 'features/game/game_screen.dart';
import 'features/home/home_screen.dart';
import 'features/letter_board/letter_board_screen.dart';
import 'features/parent/dashboard_screen.dart';
import 'features/parent/guide_screen.dart';
import 'features/quran/quran_check_screen.dart';
import 'features/quran/quran_modes.dart';
import 'features/quran/quran_screens.dart';
import 'features/world_map/world_map_screen.dart';

/// للتجربة: `flutter run --dart-define=START=/play/counting` يفتح على شاشة معيّنة.
const _start = String.fromEnvironment('START', defaultValue: '/');

final _router = GoRouter(initialLocation: _start, routes: [
  GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
  GoRoute(path: '/world/:id', builder: (_, s) => WorldMapScreen(world: s.pathParameters['id']!)),
  GoRoute(
    path: '/play/:stage',
    builder: (_, s) => GameScreen(key: ValueKey(s.pathParameters['stage']), stageId: s.pathParameters['stage']!),
  ),
  GoRoute(path: '/learn/:stage', builder: (_, s) => LetterBoardScreen(stageId: s.pathParameters['stage']!)),
  GoRoute(path: '/achievements', builder: (_, _) => const AchievementsScreen()),
  GoRoute(path: '/quran', builder: (_, _) => const QuranHomeScreen()),
  GoRoute(path: '/quran-check', builder: (_, _) => const QuranCheckScreen()),
  GoRoute(path: '/quran/:surah', builder: (_, s) => SurahScreen(surah: int.parse(s.pathParameters['surah']!))),
  GoRoute(
    path: '/quran/:surah/:mode',
    builder: (_, s) => QuranModeScreen(surah: int.parse(s.pathParameters['surah']!), mode: s.pathParameters['mode']!),
  ),
  GoRoute(path: '/parent', builder: (_, _) => const DashboardScreen()),
  GoRoute(path: '/guide', builder: (_, _) => const GuideScreen()),
]);

class RehlatiApp extends StatelessWidget {
  const RehlatiApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'رحلتي',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        // العربي بيخلّي التطبيق كله RTL تلقائيًا
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: _router,
        builder: (context, child) => MediaQuery(
          // الطفل محتاج خط كبير بس من غير ما الكروت تتكسر لو خط النظام ضخم
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
          ),
          child: BadgeToaster(child: FxLayer(child: child!)),
        ),
      );
}

/// إشعار "إنجاز جديد!" فوق الشاشة — واحد ورا التاني بفرق ١.٨ ثانية.
class BadgeToaster extends ConsumerStatefulWidget {
  const BadgeToaster({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<BadgeToaster> createState() => _BadgeToasterState();
}

class _BadgeToasterState extends ConsumerState<BadgeToaster> {
  final _shown = <(int, Achievement)>[];
  StreamSubscription<Achievement>? _sub;
  int _seq = 0;
  DateTime _next = DateTime.now();

  @override
  void initState() {
    super.initState();
    _sub = ref.read(badgeEventsProvider).stream.listen((b) {
      final now = DateTime.now();
      final at = _next.isAfter(now) ? _next : now;
      _next = at.add(const Duration(milliseconds: 1800));
      Timer(at.difference(now), () => _show(b));
    });
  }

  void _show(Achievement b) {
    if (!mounted) return;
    final id = _seq++;
    setState(() => _shown.add((id, b)));
    ref.read(sfxProvider).win();
    ref.read(speechProvider).speak('إنجاز جديد! ${b.name}');
    Timer(const Duration(milliseconds: 3700), () {
      if (mounted) setState(() => _shown.removeWhere((e) => e.$1 == id));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        widget.child,
        for (final (id, b) in _shown)
          Positioned(
            key: ValueKey(id),
            top: MediaQuery.paddingOf(context).top + 16,
            left: 16,
            right: 16,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: AppColors.goldDark, offset: Offset(0, 8))],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(b.icon, style: const TextStyle(fontSize: 34)),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text('إنجاز جديد!\n${b.name}',
                          style: kidText(17, weight: FontWeight.w700, color: const Color(0xFF4A2B00))),
                    ),
                  ]),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .moveY(begin: -18, end: 0, duration: 400.ms)
                  .then(delay: 2800.ms)
                  .fadeOut(duration: 500.ms)
                  .moveY(begin: 0, end: -24, duration: 500.ms),
            ),
          ),
      ]);
}
