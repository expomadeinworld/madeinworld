import '../../core/enums/store_type.dart';

class Product {
  final String id;
  final String sku;
  final String title;
  final String descriptionShort;
  final String descriptionLong;
  final String manufacturerId;
  final StoreType storeType;
  final double mainPrice;
  final double? strikethroughPrice;
  final bool isActive;
  final bool isFeatured;
  final List<String> imageUrls;
  final List<String> categoryIds;
  final List<String> subcategoryIds;
  final int? stockQuantity; // Only for unmanned stores

  Product({
    required this.id,
    required this.sku,
    required this.title,
    required this.descriptionShort,
    required this.descriptionLong,
    required this.manufacturerId,
    required this.storeType,
    required this.mainPrice,
    this.strikethroughPrice,
    this.isActive = true,
    this.isFeatured = false,
    required this.imageUrls,
    required this.categoryIds,
    this.subcategoryIds = const [],
    this.stockQuantity,
  });

  // Display stock with buffer (actual stock - 5)
  int? get displayStock {
    if (stockQuantity == null) return null;
    return (stockQuantity! - 5).clamp(0, stockQuantity!);
  }

  bool get hasStock {
    if (storeType == StoreType.retail) return true; // Retail always has stock
    return displayStock != null && displayStock! > 0;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(), // Convert int to string for compatibility
      sku: json['sku'],
      title: json['title'],
      descriptionShort: json['description_short'],
      descriptionLong: json['description_long'],
      manufacturerId: json['manufacturer_id'].toString(), // Convert int to string
      storeType: StoreType.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == json['store_type'].toString().toLowerCase(),
      ),
      mainPrice: json['main_price'].toDouble(),
      strikethroughPrice: json['strikethrough_price']?.toDouble(),
      isActive: json['is_active'] ?? true,
      isFeatured: json['is_featured'] ?? false,
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      categoryIds: List<String>.from(json['category_ids'] ?? []),
      subcategoryIds: List<String>.from(json['subcategory_ids'] ?? []),
      stockQuantity: json['stock_quantity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'title': title,
      'description_short': descriptionShort,
      'description_long': descriptionLong,
      'manufacturer_id': manufacturerId,
      'store_type': storeType.toString().split('.').last,
      'main_price': mainPrice,
      'strikethrough_price': strikethroughPrice,
      'is_active': isActive,
      'is_featured': isFeatured,
      'image_urls': imageUrls,
      'category_ids': categoryIds,
      'subcategory_ids': subcategoryIds,
      'stock_quantity': stockQuantity,
    };
  }
}


