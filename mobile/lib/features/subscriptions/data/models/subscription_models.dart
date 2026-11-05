import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/json_utils.dart';

part 'subscription_models.g.dart';

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum PlanType { base, premium, enterprise, unknown }

/// A plan (SubscriptionMicroService `SubscriptionPlan`). Prices are shown in USD, like the web app.
@JsonSerializable(createToJson: false)
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    this.type = PlanType.unknown,
    this.duration = 'monthly',
    this.description,
    this.benefitsText,
    this.hasAiCvAccess = false,
    this.aiCvLimit,
  });

  final int id;
  @JsonKey(defaultValue: '')
  final String name;
  @JsonKey(unknownEnumValue: PlanType.unknown)
  final PlanType type;
  @JsonKey(defaultValue: 0)
  final double price;
  @JsonKey(defaultValue: 'monthly')
  final String duration;
  final String? description;

  /// Comma-separated on the backend.
  @JsonKey(name: 'benefits')
  final String? benefitsText;
  @JsonKey(defaultValue: false)
  final bool hasAiCvAccess;

  /// Null = unlimited (when [hasAiCvAccess]).
  final int? aiCvLimit;

  List<String> get benefits =>
      (benefitsText ?? '').split(RegExp(r'[,\n]')).map((b) => b.trim()).where((b) => b.isNotEmpty).toList();

  String get aiLabel =>
      !hasAiCvAccess ? 'No AI tools' : (aiCvLimit == null ? 'Unlimited AI tools' : '$aiCvLimit AI uses / month');

  String get period => duration == 'yearly' ? 'year' : 'month';

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) => _$SubscriptionPlanFromJson(json);
}

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum SubscriptionStatus {
  active('Active'),
  pending('Pending'),
  expired('Ended'),
  cancelled('Cancelled'),
  unknown('Unknown');

  const SubscriptionStatus(this.label);

  final String label;
}

@JsonSerializable(createToJson: false)
class SubscriptionPayment {
  const SubscriptionPayment({
    required this.id,
    required this.amount,
    this.paymentMethod,
    this.status,
    this.paidAt,
    this.invoiceRef,
  });

  final int id;
  @JsonKey(defaultValue: 0)
  final double amount;
  final String? paymentMethod;
  final String? status;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? paidAt;
  final String? invoiceRef;

  /// "Flouci (test)", "Promo code", "Card"...
  String get methodLabel => switch (paymentMethod) {
    'flouci' => 'Flouci',
    'flouci-test' => 'Flouci (test)',
    'promo-code' => 'Promo code',
    'free' => 'Free',
    null || '' => '—',
    final other => other[0].toUpperCase() + other.substring(1),
  };

  factory SubscriptionPayment.fromJson(Map<String, dynamic> json) => _$SubscriptionPaymentFromJson(json);
}

@JsonSerializable(createToJson: false)
class UserSubscription {
  const UserSubscription({
    required this.id,
    required this.plan,
    this.status = SubscriptionStatus.pending,
    this.startDate,
    this.endDate,
    this.autoRenew = false,
    this.payments = const [],
  });

  final int id;
  final SubscriptionPlan plan;
  @JsonKey(unknownEnumValue: SubscriptionStatus.unknown)
  final SubscriptionStatus status;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? startDate;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? endDate;
  @JsonKey(defaultValue: false)
  final bool autoRenew;
  @JsonKey(defaultValue: [])
  final List<SubscriptionPayment> payments;

  /// Days until [endDate] (0 on the last day).
  int? daysLeft([DateTime? now]) {
    if (endDate == null) return null;
    final n = now ?? DateTime.now();
    return endDate!.difference(DateTime(n.year, n.month, n.day)).inDays;
  }

  factory UserSubscription.fromJson(Map<String, dynamic> json) => _$UserSubscriptionFromJson(json);
}

/// Price of a plan for the user, computed by the server (`/checkout/quote`).
@JsonSerializable(createToJson: false)
class CheckoutQuote {
  const CheckoutQuote({
    required this.planId,
    required this.price,
    required this.total,
    this.planName,
    this.discount = 0,
    this.promoCode,
    this.promoDescription,
  });

  final int planId;
  final String? planName;
  final double price;
  @JsonKey(defaultValue: 0)
  final double discount;
  final double total;
  final String? promoCode;
  final String? promoDescription;

  factory CheckoutQuote.fromJson(Map<String, dynamic> json) => _$CheckoutQuoteFromJson(json);
}

/// A started payment (`/checkout/start`): open [link], or nothing to pay when [free].
@JsonSerializable(createToJson: false)
class CheckoutStart {
  const CheckoutStart({required this.total, this.testMode = false, this.free = false, this.paymentId, this.link});

  final double total;
  @JsonKey(defaultValue: false)
  final bool testMode;
  @JsonKey(defaultValue: false)
  final bool free;
  final String? paymentId;
  final String? link;

  factory CheckoutStart.fromJson(Map<String, dynamic> json) => _$CheckoutStartFromJson(json);
}

@JsonSerializable(createToJson: false)
class CheckoutResult {
  const CheckoutResult({required this.subscription, required this.total, this.renewed = false});

  final UserSubscription subscription;
  final double total;
  @JsonKey(defaultValue: false)
  final bool renewed;

  factory CheckoutResult.fromJson(Map<String, dynamic> json) => _$CheckoutResultFromJson(json);
}
