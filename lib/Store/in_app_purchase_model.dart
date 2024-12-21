enum SubscriptionStatus { active, canceled, gracePeriod, expired }

// lib/Store/in_app_purchase_model.dart

class Product {
  final String id;
  final String title;
  final String description;
  final String price;
  final double rawPrice;
  final String currencyCode;
  final String stripePriceId;
  final String role;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rawPrice,
    required this.currencyCode,
    required this.stripePriceId,
    required this.role,
  });
}

class SubscriptionDetails {
  final String id;
  final String status;
  final DateTime currentPeriodEnd;
  final List<SubscriptionItem> items;
  final String platform;

  SubscriptionDetails({
    required this.id,
    required this.status,
    required this.currentPeriodEnd,
    required this.items,
    required this.platform,
  });
}

class SubscriptionItem {
  final String priceId;
  final String productId;
  final int quantity;

  SubscriptionItem({
    required this.priceId,
    required this.productId,
    required this.quantity,
  });
}

class SubscriptionPlan {
  final String kId;
  final String displayName;
  final String? description;
  final Duration duration;
  final String? roleOnPurchase;
  final String? roleOnExpire;
  final int gracePeriodDays;

  SubscriptionPlan({
    required this.kId,
    required this.displayName,
    this.description,
    required this.duration,
    this.roleOnPurchase,
    this.roleOnExpire,
    required this.gracePeriodDays,
  });
}

class Subscription {
  final String id;
  final SubscriptionPlan plan;
  final DateTime startDate;
  DateTime? endDate;
  SubscriptionStatus status;

  Subscription({
    required this.id,
    required this.plan,
    required this.startDate,
    this.endDate,
    this.status = SubscriptionStatus.active,
  });
}

class Purchase {
  final String productId;
  final String purchaseId;
  final DateTime purchaseDate;
  final String? couponCode;

  Purchase({
    required this.productId,
    required this.purchaseId,
    required this.purchaseDate,
    this.couponCode,
  });
}
