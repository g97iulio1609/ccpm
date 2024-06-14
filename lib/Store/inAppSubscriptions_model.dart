// inAppSubscriptions_model.dart

class Product {
  final String id;
  final String title;
  final String description;
  final String price;

  Product({required this.id, required this.title, required this.description, required this.price});
}

class Purchase {
  final String productId;
  final String purchaseId;
  final DateTime purchaseDate;

  Purchase({required this.productId, required this.purchaseId, required this.purchaseDate});
}
