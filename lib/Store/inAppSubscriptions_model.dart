class Product {
  final String id;
  final String title;
  final String description;
  final String price;
  final String? couponCode; // Aggiungi questo campo

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.couponCode,
  });
}

class Purchase {
  final String productId;
  final String purchaseId;
  final DateTime purchaseDate;
  final String? couponCode; // Aggiungi questo campo

  Purchase({
    required this.productId,
    required this.purchaseId,
    required this.purchaseDate,
    this.couponCode,
  });
}
