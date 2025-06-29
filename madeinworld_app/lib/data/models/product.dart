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
  final int? stockLeft; // Only for unmanned stores

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
    this.stockLeft,
  });

  // Display stock with buffer (actual stock - 5)
  int? get displayStock {
    if (stockLeft == null) return null;
    return (stockLeft! - 5).clamp(0, stockLeft!);
  }

  bool get hasStock {
    // Exhibition stores and malls always show as having stock
    if (storeType == StoreType.exhibitionStore || storeType == StoreType.exhibitionMall) {
      return true;
    }
    // Unmanned stores and warehouses check actual stock
    return displayStock != null && displayStock! > 0;
  }

  // Helper method to safely parse store type from API response
  static StoreType _parseStoreType(dynamic storeTypeValue) {
    if (storeTypeValue == null) return StoreType.exhibitionStore; // Default fallback

    final storeTypeStr = storeTypeValue.toString();

    // Try to parse Chinese values from backend
    try {
      return StoreTypeExtension.fromChineseValue(storeTypeStr);
    } catch (e) {
      // Fallback: try English enum values
      try {
        return StoreTypeExtension.fromApiValue(storeTypeStr);
      } catch (e) {
        // Final fallback: try enum name matching
        try {
          return StoreType.values.firstWhere(
            (e) => e.toString().split('.').last.toLowerCase() == storeTypeStr.toLowerCase(),
          );
        } catch (e) {
          // Ultimate fallback
          return StoreType.exhibitionStore;
        }
      }
    }
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(), // Convert int to string for compatibility
      sku: json['sku'],
      title: json['title'],
      descriptionShort: json['description_short'],
      descriptionLong: json['description_long'],
      manufacturerId: json['manufacturer_id'].toString(), // Convert int to string
      storeType: _parseStoreType(json['store_type']),
      mainPrice: json['main_price'].toDouble(),
      strikethroughPrice: json['strikethrough_price']?.toDouble(),
      isActive: json['is_active'] ?? true,
      isFeatured: json['is_featured'] ?? false,
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      categoryIds: List<String>.from(json['category_ids'] ?? []),
      subcategoryIds: List<String>.from(json['subcategory_ids'] ?? []),
      stockLeft: json['stock_left'],
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
      'stock_left': stockLeft,
    };
  }
}


