import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/product.dart';
import '../../providers/cart_provider.dart';

class AddToCartButton extends StatelessWidget {
  final Product product;

  const AddToCartButton({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final quantity = cartProvider.getProductQuantity(product.id);
        
        if (quantity == 0) {
          // Show circular "+" button
          return GestureDetector(
            onTap: () {
              cartProvider.addProduct(product);
              _showAddToCartFeedback(context);
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.themeRed,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.white,
                size: 20,
              ),
            ),
          );
        } else {
          // Show pill-shaped quantity controls
          return Container(
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.themeRed,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Minus button
                GestureDetector(
                  onTap: () => cartProvider.removeProduct(product.id),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.remove,
                      color: AppColors.white,
                      size: 16,
                    ),
                  ),
                ),
                
                // Quantity display
                Container(
                  constraints: const BoxConstraints(minWidth: 24),
                  child: Text(
                    quantity.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                
                // Plus button
                GestureDetector(
                  onTap: () {
                    cartProvider.addProduct(product);
                    _showAddToCartFeedback(context);
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: AppColors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  void _showAddToCartFeedback(BuildContext context) {
    // Simple scale animation feedback
    // In a real app, you might want to show a snackbar or more elaborate animation
  }
}
