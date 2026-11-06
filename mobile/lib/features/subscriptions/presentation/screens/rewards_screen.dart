import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/models/reward_models.dart';
import '../../data/subscription_repository.dart';
import '../../subscription_paths.dart';
import '../format.dart';
import '../subscription_providers.dart';

/// Spin wheel (once a month) and the user's promo codes.
class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rewards')),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([ref.refresh(spinStatusProvider.future), ref.refresh(promoCodesProvider.future)]),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: const [_SpinWheelCard(), SizedBox(height: 12), _PromoCodesSection()],
        ),
      ),
    );
  }
}

class _SpinWheelCard extends ConsumerStatefulWidget {
  const _SpinWheelCard();

  @override
  ConsumerState<_SpinWheelCard> createState() => _SpinWheelCardState();
}

class _SpinWheelCardState extends ConsumerState<_SpinWheelCard> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4));
  late Animation<double> _rotation = const AlwaysStoppedAnimation(0);
  bool _spinning = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    setState(() => _spinning = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final userId = ref.read(authControllerProvider).value!.userId;
      final result = await ref.read(subscriptionRepositoryProvider).spin(userId);
      // Turn 5 times, then stop with the won slice under the pointer.
      final index = math.max(0, wheelDiscounts.indexOf(result.discountWon));
      final slice = 2 * math.pi / wheelDiscounts.length;
      final target = 10 * math.pi - (index + 0.5) * slice;
      _rotation = Tween<double>(
        begin: 0,
        end: target,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      await _controller.forward(from: 0);
      ref.invalidate(spinStatusProvider);
      ref.invalidate(promoCodesProvider);
      if (!mounted) return;
      await _showPrize(result);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _spinning = false);
    }
  }

  Future<void> _showPrize(SpinAttempt result) {
    final code = result.promoCode;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const IconBubble(icon: Icons.celebration_outlined, color: AppAccent.orange, size: 64, solid: true),
        title: Text('You won ${result.discountWon}% off!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (code != null) ...[
              SelectableText(code.code, style: Theme.of(context).textTheme.headlineSmall),
              if (code.expiresAt != null) Text('Valid until ${day(code.expiresAt!)}'),
            ],
            const SizedBox(height: 8),
            const Text('Use it on your next subscription payment.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
          if (code != null)
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: () {
                Navigator.pop(context);
                context.push(SubscriptionPaths.plans);
              },
              child: const Text('See plans'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = ref.watch(spinStatusProvider);
    final canSpin = status.value?.canSpin ?? false;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          children: [
            const IconBubble(icon: Icons.card_giftcard, color: AppAccent.orange, size: 52, solid: true),
            const SizedBox(height: 10),
            Text('Spin the wheel', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              'Once a month: win 5% to 25% off your subscription.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 260,
              width: 260,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => Transform.rotate(
                        angle: _rotation.value,
                        child: CustomPaint(size: const Size(250, 250), painter: _WheelPainter(theme.colorScheme)),
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 56, color: AppAccent.red),
                ],
              ),
            ),
            const SizedBox(height: 18),
            status.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(ApiException.from(e).message),
              data: (status) => SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: canSpin && !_spinning ? _spin : null,
                  icon: Icon(canSpin ? Icons.casino_outlined : Icons.hourglass_top),
                  label: Text(
                    canSpin
                        ? (_spinning ? 'Spinning…' : 'Spin')
                        : 'Next spin in ${status.daysUntilNextSpin} day${status.daysUntilNextSpin == 1 ? '' : 's'}',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.colors);

  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final slice = 2 * math.pi / wheelDiscounts.length;
    const fills = [AppAccent.green, AppAccent.blue, AppAccent.orange, AppAccent.purple, AppAccent.pink];
    canvas.drawCircle(center, radius, Paint()..color = colors.surfaceContainerHigh);
    final inner = radius - 6;
    for (var i = 0; i < wheelDiscounts.length; i++) {
      final start = -math.pi / 2 + i * slice;
      final rect = Rect.fromCircle(center: center, radius: inner);
      canvas.drawArc(rect, start, slice, true, Paint()..color = fills[i % fills.length]);
      canvas.drawArc(
        rect,
        start,
        slice,
        true,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      final mid = start + slice / 2;
      final label = TextPainter(
        text: TextSpan(
          text: '${wheelDiscounts[i]}%',
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final at = center + Offset(math.cos(mid), math.sin(mid)) * inner * 0.64;
      label.paint(canvas, at - Offset(label.width / 2, label.height / 2));
    }
    canvas.drawCircle(center, 24, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      24,
      Paint()
        ..color = colors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) => oldDelegate.colors != colors;
}

class _PromoCodesSection extends ConsumerWidget {
  const _PromoCodesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'My promo codes',
      child: AsyncValueView(
        value: ref.watch(promoCodesProvider),
        onRetry: () => ref.invalidate(promoCodesProvider),
        data: (codes) => codes.isEmpty
            ? Text(
                'No code yet. Spin the wheel to win one!',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              )
            : Column(
                children: [
                  for (final (i, code) in codes.indexed) ...[
                    if (i > 0) const Divider(height: 1, indent: 56),
                    _PromoCodeTile(code: code),
                  ],
                ],
              ),
      ),
    );
  }
}

class _PromoCodeTile extends ConsumerWidget {
  const _PromoCodeTile({required this.code});

  final PromoCode code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = code.isUsed ? 'Used' : (code.isExpired() ? 'Expired' : null);
    final usable = status == null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: IconBubble(icon: Icons.local_offer_outlined, color: usable ? AppAccent.green : AppAccent.grey, size: 42),
      title: Text(
        '${code.code} · ${code.label}',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          decoration: usable ? null : TextDecoration.lineThrough,
          color: usable ? null : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Text(
        [
          if ((code.description ?? '').isNotEmpty) code.description!,
          status ?? (code.expiresAt == null ? '' : 'Valid until ${day(code.expiresAt!)}'),
        ].where((s) => s.isNotEmpty).join('\n'),
      ),
      isThreeLine: (code.description ?? '').isNotEmpty,
      trailing: !usable
          ? PillTag(status, color: AppAccent.grey)
          : IconButton.filledTonal(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code.code));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied')));
              },
            ),
    );
  }
}
