import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../data/models/product.dart';
import '../../providers/cart_provider.dart';

class ProductActionBar extends StatelessWidget {
  final Product product;

  const ProductActionBar({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveUtils.getResponsiveSpacing(context, 16),
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Left side - MOQ display
            if (product.minimumOrderQuantity > 1) _buildMOQDisplay(context),
            
            // Spacer to push button to the right
            const Spacer(),
            
            // Right side - Add to cart button/stepper
            _buildAddToCartSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMOQDisplay(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.responsiveBody(context),
        children: [
          const TextSpan(
            text: '最小起订量: ',
          ),
          TextSpan(
            text: product.minimumOrderQuantity.toString(),
            style: AppTextStyles.responsiveBody(context).copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.themeRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartSection(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final quantity = cartProvider.getProductQuantity(product.id);
        
        if (quantity == 0) {
          // Show "加入购物车" button
          return _buildAddToCartButton(context, cartProvider);
        } else {
          // Show quantity stepper
          return _buildQuantityStepper(context, cartProvider, quantity);
        }
      },
    );
  }

  Widget _buildAddToCartButton(BuildContext context, CartProvider cartProvider) {
    return GestureDetector(
      onTap: () {
        // Add product with MOQ quantity
        final initialQuantity = product.minimumOrderQuantity;
        for (int i = 0; i < initialQuantity; i++) {
          cartProvider.addProduct(product);
        }
        _showAddToCartFeedback(context);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getResponsiveSpacing(context, 24),
          vertical: ResponsiveUtils.getResponsiveSpacing(context, 12),
        ),
        decoration: BoxDecoration(
          color: AppColors.themeRed,
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '加入购物车',
          style: AppTextStyles.responsiveButton(context),
        ),
      ),
    );
  }

  Widget _buildQuantityStepper(BuildContext context, CartProvider cartProvider, int quantity) {
    final canDecrease = quantity > product.minimumOrderQuantity;
    
    return Container(
      height: ResponsiveUtils.getResponsiveSpacing(context, 44),
      decoration: BoxDecoration(
        color: AppColors.themeRed,
        borderRadius: BorderRadius.circular(22),
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
            onTap: canDecrease 
                ? () => cartProvider.removeProduct(product.id)
                : null,
            child: Container(
              width: ResponsiveUtils.getResponsiveSpacing(context, 44),
              height: ResponsiveUtils.getResponsiveSpacing(context, 44),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.remove,
                color: canDecrease ? AppColors.white : AppColors.white.withValues(alpha: 0.5),
                size: ResponsiveUtils.getResponsiveSpacing(context, 18),
              ),
            ),
          ),
          
          // Quantity display
          Container(
            constraints: BoxConstraints(
              minWidth: ResponsiveUtils.getResponsiveSpacing(context, 32),
            ),
            child: Text(
              quantity.toString(),
              textAlign: TextAlign.center,
              style: AppTextStyles.responsiveButton(context),
            ),
          ),
          
          // Plus button
          GestureDetector(
            onTap: () {
              cartProvider.addProduct(product);
              _showAddToCartFeedback(context);
            },
            child: Container(
              width: ResponsiveUtils.getResponsiveSpacing(context, 44),
              height: ResponsiveUtils.getResponsiveSpacing(context, 44),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                color: AppColors.white,
                size: ResponsiveUtils.getResponsiveSpacing(context, 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddToCartFeedback(BuildContext context) {
    // Simple haptic feedback or animation could be added here
    // For now, we'll keep it simple like the existing AddToCartButton
  }
}
