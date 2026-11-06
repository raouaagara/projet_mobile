import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/models/subscription_models.dart';
import '../../data/subscription_repository.dart';
import '../../subscription_paths.dart';
import '../format.dart';
import '../subscription_providers.dart';
import 'plans_screens.dart' show planStyle;

/// Pay for a plan: promo code, price computed by the server, Flouci payment, then the plan
/// is activated (or renewed) by the server once it has verified the payment.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, required this.planId, this.initialCode});

  final int planId;
  final String? initialCode;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  late final _code = TextEditingController(text: widget.initialCode);
  AsyncValue<CheckoutQuote> _quote = const AsyncLoading();
  String? _codeError;
  bool _paying = false;

  SubscriptionRepository get _repository => ref.read(subscriptionRepositoryProvider);

  /// Waits for the session (this page can be the first one opened).
  Future<int> _userId() async => (await ref.read(authControllerProvider.future))!.userId;

  @override
  void initState() {
    super.initState();
    _loadQuote(widget.initialCode);
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  /// Price with [code]; if the code is refused, the price without it and the reason.
  Future<void> _loadQuote(String? code) async {
    final trimmed = code?.trim();
    setState(() => _codeError = null);
    try {
      final quote = await _repository.quote(
        userId: await _userId(),
        planId: widget.planId,
        promoCode: trimmed == null || trimmed.isEmpty ? null : trimmed,
      );
      if (mounted) setState(() => _quote = AsyncData(quote));
    } on ApiException catch (e) {
      if (!mounted) return;
      if (trimmed != null && trimmed.isNotEmpty && e.statusCode == 400) {
        await _loadQuote(null); // the price without the code…
        if (mounted) setState(() => _codeError = e.message); // …and why the code was refused
      } else {
        setState(() => _quote = AsyncError(e, StackTrace.current));
      }
    }
  }

  Future<void> _pay(CheckoutQuote quote) async {
    setState(() => _paying = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final userId = await _userId();
      final start = await _repository.start(userId: userId, planId: widget.planId, promoCode: quote.promoCode);
      String? paymentId;
      if (!start.free) {
        if (start.testMode) {
          paymentId = start.paymentId; // simulated: nothing to show
        } else {
          if (!mounted) return;
          paymentId = await Navigator.of(
            context,
          ).push<String>(MaterialPageRoute(builder: (_) => FlouciPaymentScreen(link: start.link!)));
          if (paymentId == null) {
            messenger.showSnackBar(const SnackBar(content: Text('Payment cancelled.')));
            return;
          }
        }
      }
      final result = await _repository.confirm(
        userId: userId,
        planId: widget.planId,
        promoCode: quote.promoCode,
        paymentId: paymentId,
        email: ref.read(authControllerProvider).value?.email,
      );
      refreshAfterCheckout(ref);
      if (!mounted) return;
      setState(() => _paying = false); // no spinner behind the dialog
      await _showSuccess(result);
      if (mounted) context.go(SubscriptionPaths.mine);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _showSuccess(CheckoutResult result) {
    final sub = result.subscription;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.celebration_outlined),
        title: Text(result.renewed ? '${sub.plan.name} renewed' : 'Welcome to ${sub.plan.name}!'),
        content: Text(sub.endDate == null ? 'Your plan is active.' : 'Your plan is active until ${day(sub.endDate!)}.'),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () => Navigator.pop(context),
            child: const Text('Great'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = ref.watch(plansProvider).value?.where((p) => p.id == widget.planId).firstOrNull;
    final active = ref.watch(activeSubscriptionProvider).value;
    final usableCodes = ref.watch(promoCodesProvider).value?.where((c) => c.isUsable).toList() ?? const [];
    final renewing = active != null && active.plan.id == widget.planId;

    final (icon, color) = planStyle(plan?.type ?? PlanType.unknown);
    return Scaffold(
      appBar: AppBar(title: Text(renewing ? 'Renew' : 'Checkout')),
      body: AsyncValueView(
        value: _quote,
        onRetry: () => _loadQuote(_code.text),
        data: (quote) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconBubble(icon: icon, color: color, size: 52, solid: true),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quote.planName ?? plan?.name ?? 'Plan',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          if (plan != null)
                            Text(
                              '${money(plan.price)} / ${plan.period} · ${plan.aiLabel}',
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (active != null && !renewing) ...[
              const SizedBox(height: 12),
              InfoBanner('It replaces your ${active.plan.name} plan.', icon: Icons.swap_horiz, color: AppAccent.orange),
            ],
            if (renewing && active.endDate != null) ...[
              const SizedBox(height: 12),
              InfoBanner(
                'Adds one ${plan?.period ?? 'month'} after ${day(active.endDate!)}.',
                icon: Icons.event_repeat,
              ),
            ],
            const SizedBox(height: 12),
            SectionCard(
              title: 'Promo code',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _code,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'e.g. SPIN5SHT9E',
                      errorText: _codeError,
                      prefixIcon: const Icon(Icons.local_offer_outlined),
                      suffixIcon: quote.promoCode != null
                          ? IconButton(
                              tooltip: 'Remove the code',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _code.clear();
                                _loadQuote(null);
                              },
                            )
                          : TextButton(onPressed: () => _loadQuote(_code.text), child: const Text('Apply')),
                    ),
                    onSubmitted: _loadQuote,
                  ),
                  if (usableCodes.isNotEmpty && quote.promoCode == null) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final code in usableCodes)
                          ActionChip(
                            avatar: const Icon(Icons.card_giftcard, size: 16, color: AppAccent.green),
                            label: Text('${code.code} · ${code.label}'),
                            onPressed: () {
                              _code.text = code.code;
                              _loadQuote(code.code);
                            },
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Summary',
              child: Column(
                children: [
                  _Line('Price', money(quote.price)),
                  if (quote.discount > 0)
                    _Line(
                      quote.promoDescription ?? 'Promo ${quote.promoCode}',
                      '−${money(quote.discount)}',
                      color: theme.colorScheme.primary,
                    ),
                  const Divider(height: 20),
                  _Line('Total', money(quote.total), strong: true),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const InfoBanner(
              'The payment is checked by our server before your plan changes. '
              'While Flouci is in test mode, payments are simulated and nothing is charged.',
              icon: Icons.verified_user_outlined,
              color: AppAccent.blue,
            ),
          ],
        ),
      ),
      bottomNavigationBar: switch (_quote) {
        AsyncData(:final value) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton.icon(
              onPressed: _paying ? null : () => _pay(value),
              icon: _paying
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(value.total <= 0 ? Icons.check : Icons.lock_outline),
              label: Text(value.total <= 0 ? 'Activate for free' : 'Pay ${money(value.total)} with Flouci'),
            ),
          ),
        ),
        _ => null,
      },
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.strong = false, this.color});

  final String label;
  final String value;
  final bool strong;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = strong
        ? Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)
        : TextStyle(color: color, fontWeight: color == null ? null : FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

/// Flouci's payment page. Pops with the payment id when Flouci sends the user back to
/// [CheckoutUrls.success], or with null on [CheckoutUrls.fail] / back.
class FlouciPaymentScreen extends StatefulWidget {
  const FlouciPaymentScreen({super.key, required this.link});

  final String link;

  @override
  State<FlouciPaymentScreen> createState() => _FlouciPaymentScreenState();
}

class _FlouciPaymentScreenState extends State<FlouciPaymentScreen> {
  late final WebViewController _controller;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) => setState(() => _progress = progress),
          onNavigationRequest: (request) {
            final uri = Uri.parse(request.url);
            if (request.url.startsWith(CheckoutUrls.success)) {
              Navigator.pop(context, uri.queryParameters['payment_id']);
              return NavigationDecision.prevent;
            }
            if (request.url.startsWith(CheckoutUrls.fail)) {
              Navigator.pop(context);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.link));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flouci payment'),
        bottom: _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(value: _progress / 100),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
