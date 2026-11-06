import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/brand.dart';
import '../../../shared/widgets/workify_logo.dart';

/// True once the splash animation has played. Until then the router keeps the splash screen.
final splashDoneProvider = NotifierProvider<SplashDone, bool>(SplashDone.new);

class SplashDone extends Notifier<bool> {
  @override
  bool build() => false;

  void finish() => state = true;
}

/// Green splash screen. It starts plain green like the Android launch screen, then the logo is drawn
/// like with a pen (the W from the left, on up the arrow, then its head) while faint job icons appear.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const duration = Duration(milliseconds: 2600);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: SplashScreen.duration);
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _play(reduceMotion: MediaQuery.disableAnimationsOf(context));
  }

  Future<void> _play({required bool reduceMotion}) async {
    if (reduceMotion) {
      _controller.value = 1;
      await Future<void>.delayed(const Duration(milliseconds: 700));
    } else {
      // Start once the first frame is on screen, a moment later. On a slow start (first launch, debug
      // build) the clock would otherwise run while nothing is drawn, and the drawing would begin halfway.
      await SchedulerBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      await _controller.forward();
    }
    if (mounted) ref.read(splashDoneProvider.notifier).finish();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: Brand.green,
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            double phase(double begin, double end, [Curve curve = Curves.easeOutCubic]) =>
                Interval(begin, end, curve: curve).transform(_controller.value);
            // About 2.1 s of drawing, then the finished logo stays a moment.
            final draw = phase(0, 0.8, Curves.easeInOut);
            return Stack(
              fit: StackFit.expand,
              children: [
                for (final (i, icon) in _icons.indexed)
                  _Decoration(icon: icon, opacity: phase(0.1 + i * 0.03, 0.5 + i * 0.03, Curves.easeOut)),
                Center(
                  child: WorkifyLogo(size: 210, color: Colors.white, arrowColor: Brand.paleGreen, progress: draw),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A faint outlined icon scattered on the green background, placed as a fraction of the screen.
typedef _Icon = ({double x, double y, IconData icon});

const _icons = <_Icon>[
  (x: 0.13, y: 0.10, icon: Icons.engineering_outlined),
  (x: 0.84, y: 0.09, icon: Icons.laptop_mac_outlined),
  (x: 0.52, y: 0.18, icon: Icons.badge_outlined),
  (x: 0.22, y: 0.27, icon: Icons.photo_camera_outlined),
  (x: 0.80, y: 0.29, icon: Icons.brush_outlined),
  (x: 0.11, y: 0.45, icon: Icons.trending_up),
  (x: 0.90, y: 0.53, icon: Icons.lightbulb_outline),
  (x: 0.16, y: 0.66, icon: Icons.code),
  (x: 0.75, y: 0.70, icon: Icons.handshake_outlined),
  (x: 0.30, y: 0.80, icon: Icons.payments_outlined),
  (x: 0.87, y: 0.86, icon: Icons.chat_bubble_outline),
  (x: 0.09, y: 0.88, icon: Icons.star_outline),
];

class _Decoration extends StatelessWidget {
  const _Decoration({required this.icon, required this.opacity});

  final _Icon icon;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Positioned(
      left: icon.x * size.width - 14,
      top: icon.y * size.height - 14,
      child: Opacity(
        opacity: opacity,
        child: Icon(icon.icon, size: 28, color: Colors.white.withValues(alpha: 0.3)),
      ),
    );
  }
}
