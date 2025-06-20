import 'package:flutter/foundation.dart';
import '../../data/models/cart_item.dart';
import '../../data/models/product.dart';
import '../../core/enums/store_type.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  bool get isEmpty => _items.isEmpty;

  bool get isNotEmpty => _items.isNotEmpty;

  // Get quantity of a specific product in cart
  int getProductQuantity(String productId) {
    final item = _items.firstWhere(
      (item) => item.product.id == productId,
      orElse: () => CartItem(product: Product(
        id: '',
        sku: '',
        title: '',
        descriptionShort: '',
        descriptionLong: '',
        manufacturerId: '',
        storeType: StoreType.retail,
        mainPrice: 0,
        imageUrls: [],
        categoryIds: [],
      ), quantity: 0),
    );
    return item.product.id.isEmpty ? 0 : item.quantity;
  }

  // Add product to cart
  void addProduct(Product product) {
    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(product: product, quantity: 1));
    }
    
    notifyListeners();
  }

  // Remove one quantity of product from cart
  void removeProduct(String productId) {
    final existingIndex = _items.indexWhere(
      (item) => item.product.id == productId,
    );

    if (existingIndex >= 0) {
      if (_items[existingIndex].quantity > 1) {
        _items[existingIndex].quantity--;
      } else {
        _items.removeAt(existingIndex);
      }
      notifyListeners();
    }
  }

  // Remove all quantities of a product from cart
  void removeAllOfProduct(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  // Update product quantity directly
  void updateProductQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeAllOfProduct(productId);
      return;
    }

    final existingIndex = _items.indexWhere(
      (item) => item.product.id == productId,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity = quantity;
    } else {
      // This shouldn't happen in normal usage, but handle it gracefully
      return;
    }
    
    notifyListeners();
  }

  // Clear entire cart
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // Check if product is in cart
  bool isProductInCart(String productId) {
    return _items.any((item) => item.product.id == productId);
  }
}
