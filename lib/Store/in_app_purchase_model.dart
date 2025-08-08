enum SubscriptionStatus { active, canceled, gracePeriod, expired }

abstract class BaseInAppPurchaseService {
  Future<List<Product>> getProducts();
  Future<void> handleSuccessfulPayment(String purchaseId, String productId);
  Future<Map<String, dynamic>> createCheckoutSession(
    String userId,
    String productId,
  );
  Future<void> initialize();
}

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
  final String platform;
  final List<SubscriptionItem> items;

  SubscriptionDetails({
    required this.id,
    required this.status,
    required this.currentPeriodEnd,
    required this.platform,
    required this.items,
  });

  factory SubscriptionDetails.fromJson(Map<String, dynamic> json) {
    return SubscriptionDetails(
      id: json['id'] as String? ?? '',
      status: json['status'] as String,
      currentPeriodEnd: json['currentPeriodEnd'] as DateTime,
      platform: json['platform'] as String,
      items: (json['items'] as List)
          .map((item) => SubscriptionItem.fromJson(item))
          .toList(),
    );
  }
}

class SubscriptionItem {
  final String productId;
  final String priceId;
  final int quantity;

  SubscriptionItem({
    required this.productId,
    required this.priceId,
    required this.quantity,
  });

  factory SubscriptionItem.fromJson(Map<String, dynamic> json) {
    return SubscriptionItem(
      productId: json['productId'] as String,
      priceId: json['priceId'] as String,
      quantity: json['quantity'] as int,
    );
  }
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
