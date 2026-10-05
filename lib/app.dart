import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/audio/audio_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/fx_layer.dart';
import 'domain/progress/progress_controller.dart';
import 'features/achievements/achievements_screen.dart';
import 'features/daily/time_up_screen.dart';
import 'features/game/game_screen.dart';
import 'features/home/home_screen.dart';
import 'features/letter_board/letter_board_screen.dart';
import 'features/madd/madd_lesson_screen.dart';
import 'features/parent/dashboard_screen.dart';
import 'features/parent/guide_screen.dart';
import 'features/parent_guide/pg_screens.dart';
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
  GoRoute(path: '/madd/:stage', builder: (_, s) => MaddLessonScreen(stageId: s.pathParameters['stage']!)),
  GoRoute(path: '/learn/:stage', builder: (_, s) => LetterBoardScreen(stageId: s.pathParameters['stage']!)),
  GoRoute(path: '/timeup', builder: (_, _) => const TimeUpScreen()),
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
  GoRoute(path: '/pg', builder: (_, _) => const PgHomeScreen()),
  GoRoute(path: '/pg/b/:id', builder: (_, s) => PgDetailScreen(id: s.pathParameters['id']!)),
  GoRoute(path: '/pg/goals', builder: (_, _) => const PgGoalsScreen()),
  GoRoute(path: '/pg/kids', builder: (_, _) => const KidHubScreen()),
  GoRoute(path: '/pg/play', builder: (_, s) => KidPlayScreen(ids: (s.extra as List?)?.cast<String>() ?? const ['hit'])),
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
          child: _MusicConductor(child: BadgeToaster(child: FxLayer(child: child!))),
        ),
      );
}

/// الموسيقى بتسكت في عالم القرآن وبتقف لما التطبيق يروح الخلفية.
class _MusicConductor extends ConsumerStatefulWidget {
  const _MusicConductor({required this.child});
  final Widget child;

  @override
  ConsumerState<_MusicConductor> createState() => _MusicConductorState();
}

class _MusicConductorState extends ConsumerState<_MusicConductor> {
  late final AppLifecycleListener _life;

  void _route() {
    final path = _router.routerDelegate.currentConfiguration.uri.path;
    ref.read(musicProvider).quiet(path.startsWith('/quran'));
  }

  @override
  void initState() {
    super.initState();
    _router.routerDelegate.addListener(_route);
    _life = AppLifecycleListener(
      onHide: () => ref.read(musicProvider).background(true),
      onShow: () => ref.read(musicProvider).background(false),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_route);
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// إشعار "إنجاز جديد!" فوق الشاشة — واحد ورا التاني بفرق ١.٨ ثانية.
class BadgeToaster extends ConsumerStatefulWidget {
  const BadgeToaster({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<BadgeToaster> createState() => _BadgeToasterState();
}

class _BadgeToasterState extends ConsumerState<BadgeToaster> {
  final _shown = <(int, _Toast)>[];
  final _subs = <StreamSubscription<Object>>[];
  int _seq = 0;
  DateTime _next = DateTime.now();

  @override
  void initState() {
    super.initState();
    _subs
      ..add(ref.read(badgeEventsProvider).stream.listen((b) => _queue(_Toast(b.icon, 'إنجاز جديد!', b.name, null))))
      // كأس جديد: احتفال أكبر (Rewards.rankToast في الويب)
      ..add(ref.read(rankEventsProvider).stream.listen((r) => _queue(_Toast(r.icon, 'مرحلة جديدة!', r.name, r.color))));
  }

  /// الإشعارات واحد ورا التاني بفرق ١.٨ ثانية.
  void _queue(_Toast t) {
    final now = DateTime.now();
    final at = _next.isAfter(now) ? _next : now;
    _next = at.add(const Duration(milliseconds: 1800));
    Timer(at.difference(now), () => _show(t));
  }

  void _show(_Toast t) {
    if (!mounted) return;
    final id = _seq++;
    final rank = t.color != null;
    setState(() => _shown.add((id, t)));
    ref.read(sfxProvider).win();
    if (rank) ref.read(fxProvider).confetti(80);
    ref.read(speechProvider).speak(rank ? 'مبروك! وصلت ${t.name}' : 'إنجاز جديد! ${t.name}');
    Timer(Duration(milliseconds: rank ? 4700 : 3700), () {
      if (mounted) setState(() => _shown.removeWhere((e) => e.$1 == id));
    });
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        widget.child,
        for (final (id, t) in _shown)
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
                  decoration: t.color == null
                      ? BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: AppColors.goldDark, offset: Offset(0, 8))],
                        )
                      : BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(22),
                          border: BorderDirectional(start: BorderSide(color: t.color!, width: 9)),
                          boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 10))],
                        ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(t.icon, style: TextStyle(fontSize: t.color == null ? 34 : 38)),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text('${t.title}\n${t.name}',
                          style: kidText(17,
                              weight: t.color == null ? FontWeight.w700 : FontWeight.w800,
                              color: t.color == null ? const Color(0xFF4A2B00) : AppColors.ink)),
                    ),
                  ]),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .moveY(begin: -18, end: 0, duration: 400.ms)
                  .then(delay: (t.color == null ? 2800 : 3800).ms)
                  .fadeOut(duration: 500.ms)
                  .moveY(begin: 0, end: -24, duration: 500.ms),
            ),
          ),
      ]);
}

class _Toast {
  const _Toast(this.icon, this.title, this.name, this.color);
  final String icon;
  final String title;
  final String name;

  /// لون الكأس — null = إنجاز عادي (كارت دهبي).
  final Color? color;
}
