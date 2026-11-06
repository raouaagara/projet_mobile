import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_paths.dart';
import '../../../core/theme/brand.dart';
import '../data/onboarding_store.dart';

typedef _Slide = ({String image, String title, String text});

// Illustrations from unDraw (undraw.co, free license, no credit needed), colored in Workify green on the site.
const _slides = <_Slide>[
  (
    image: 'assets/onboarding/find_projects.svg',
    title: 'Find interesting projects',
    text: 'Browse jobs that match your skills and send a proposal in a few taps.',
  ),
  (
    image: 'assets/onboarding/work_safely.svg',
    title: 'Work safely, get paid',
    text: 'Contracts, secure payments and chat keep every job clear from start to finish.',
  ),
  (
    image: 'assets/onboarding/get_started.svg',
    title: 'Get started free',
    text: 'Join as a client or a freelancer and start today.',
  ),
];

const _ink = Color(0xFF1D2A1B);
const _muted = Color(0xFF6E7A6B);
const _mint = Color(0xFFEAF6E2);

/// The 3 intro pages, shown once on the first launch. Finishing or skipping them opens the login.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> with SingleTickerProviderStateMixin {
  final _pages = PageController();
  late final _tap = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  var _index = 0;

  bool get _last => _index == _slides.length - 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _tap.stop();
    } else if (!_tap.isAnimating) {
      _tap.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    _tap.dispose();
    super.dispose();
  }

  void _next() => _pages.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);

  /// "Get started" opens the sign-up, "Skip" the login.
  void _finish(String next) {
    ref.read(onboardingDoneProvider.notifier).complete();
    context.go(next);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: AnimatedOpacity(
                    opacity: _last ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: TextButton(
                      onPressed: _last ? null : () => _finish(AppPaths.login),
                      style: TextButton.styleFrom(foregroundColor: _muted),
                      child: const Text('Skip', style: TextStyle(fontSize: 15)),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (i) => setState(() => _index = i),
                  children: [for (final slide in _slides) _SlideView(slide)],
                ),
              ),
              SizedBox(
                height: 96,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _last
                        ? Padding(
                            key: const ValueKey('start'),
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: FilledButton(
                              onPressed: () => _finish(AppPaths.register),
                              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                              child: const Text('Get started'),
                            ),
                          )
                        : _TapToContinue(key: const ValueKey('next'), animation: _tap, onTap: _next),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _Dots(count: _slides.length, index: _index),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView(this.slide);

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              final disc = math.min(constraints.maxWidth, constraints.maxHeight) * 0.9;
              // Low in its space, close to the title.
              return Stack(
                alignment: const Alignment(0, 0.6),
                children: [
                  Container(
                    width: disc,
                    height: disc,
                    decoration: const BoxDecoration(color: _mint, shape: BoxShape.circle),
                  ),
                  SvgPicture.asset(
                    slide.image,
                    width: constraints.maxWidth,
                    height: disc * 0.72,
                    excludeFromSemantics: true,
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 28),
          // Same height on every page, so the titles don't jump while swiping.
          SizedBox(
            height: 132,
            child: Column(
              children: [
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _ink),
                ),
                const SizedBox(height: 12),
                Text(
                  slide.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15.5, height: 1.5, color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The green hand of the design: tapping it shows the next page.
class _TapToContinue extends StatelessWidget {
  const _TapToContinue({super.key, required this.animation, required this.onTap});

  final Animation<double> animation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Next',
      child: InkResponse(
        onTap: onTap,
        radius: 40,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ScaleTransition(
            scale: Tween(begin: 1.0, end: 0.88).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
            child: const Icon(Icons.touch_app_outlined, size: 56, color: Brand.green),
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == index ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index ? Brand.green : const Color(0xFFD5DDD2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
