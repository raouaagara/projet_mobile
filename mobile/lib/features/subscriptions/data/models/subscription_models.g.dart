// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionPlan _$SubscriptionPlanFromJson(Map<String, dynamic> json) => SubscriptionPlan(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String? ?? '',
  price: (json['price'] as num?)?.toDouble() ?? 0,
  type: $enumDecodeNullable(_$PlanTypeEnumMap, json['type'], unknownValue: PlanType.unknown) ?? PlanType.unknown,
  duration: json['duration'] as String? ?? 'monthly',
  description: json['description'] as String?,
  benefitsText: json['benefits'] as String?,
  hasAiCvAccess: json['hasAiCvAccess'] as bool? ?? false,
  aiCvLimit: (json['aiCvLimit'] as num?)?.toInt(),
);

const _$PlanTypeEnumMap = {
  PlanType.base: 'BASE',
  PlanType.premium: 'PREMIUM',
  PlanType.enterprise: 'ENTERPRISE',
  PlanType.unknown: 'UNKNOWN',
};

SubscriptionPayment _$SubscriptionPaymentFromJson(Map<String, dynamic> json) => SubscriptionPayment(
  id: (json['id'] as num).toInt(),
  amount: (json['amount'] as num?)?.toDouble() ?? 0,
  paymentMethod: json['paymentMethod'] as String?,
  status: json['status'] as String?,
  paidAt: parseApiDate(json['paidAt']),
  invoiceRef: json['invoiceRef'] as String?,
);

UserSubscription _$UserSubscriptionFromJson(Map<String, dynamic> json) => UserSubscription(
  id: (json['id'] as num).toInt(),
  plan: SubscriptionPlan.fromJson(json['plan'] as Map<String, dynamic>),
  status:
      $enumDecodeNullable(_$SubscriptionStatusEnumMap, json['status'], unknownValue: SubscriptionStatus.unknown) ??
      SubscriptionStatus.pending,
  startDate: parseApiDate(json['startDate']),
  endDate: parseApiDate(json['endDate']),
  autoRenew: json['autoRenew'] as bool? ?? false,
  payments:
      (json['payments'] as List<dynamic>?)
          ?.map((e) => SubscriptionPayment.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

const _$SubscriptionStatusEnumMap = {
  SubscriptionStatus.active: 'ACTIVE',
  SubscriptionStatus.pending: 'PENDING',
  SubscriptionStatus.expired: 'EXPIRED',
  SubscriptionStatus.cancelled: 'CANCELLED',
  SubscriptionStatus.unknown: 'UNKNOWN',
};

CheckoutQuote _$CheckoutQuoteFromJson(Map<String, dynamic> json) => CheckoutQuote(
  planId: (json['planId'] as num).toInt(),
  price: (json['price'] as num).toDouble(),
  total: (json['total'] as num).toDouble(),
  planName: json['planName'] as String?,
  discount: (json['discount'] as num?)?.toDouble() ?? 0,
  promoCode: json['promoCode'] as String?,
  promoDescription: json['promoDescription'] as String?,
);

CheckoutStart _$CheckoutStartFromJson(Map<String, dynamic> json) => CheckoutStart(
  total: (json['total'] as num).toDouble(),
  testMode: json['testMode'] as bool? ?? false,
  free: json['free'] as bool? ?? false,
  paymentId: json['paymentId'] as String?,
  link: json['link'] as String?,
);

CheckoutResult _$CheckoutResultFromJson(Map<String, dynamic> json) => CheckoutResult(
  subscription: UserSubscription.fromJson(json['subscription'] as Map<String, dynamic>),
  total: (json['total'] as num).toDouble(),
  renewed: json['renewed'] as bool? ?? false,
);
