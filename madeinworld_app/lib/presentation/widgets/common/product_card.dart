import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../data/models/product.dart';
import '../../../core/enums/store_type.dart';
import 'add_to_cart_button.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context, 12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              AspectRatio(
                aspectRatio: 1.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrls.isNotEmpty 
                        ? product.imageUrls.first 
                        : 'https://placehold.co/300x300/E2E8F0/6A7485?text=No+Image', // Fallback URL
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.lightRed,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.themeRed,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.lightRed,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: AppColors.themeRed,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 8)),

              // Product Title
              Text(
                product.title,
                style: AppTextStyles.responsiveCardTitle(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 4)),

              // Product Description
              Text(
                product.descriptionShort,
                style: AppTextStyles.responsiveBodySmall(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              // FIX: Stock Info (only for unmanned stores and warehouses)
              if (product.storeType == StoreType.unmannedStore || product.storeType == StoreType.unmannedWarehouse) ...[
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 4)),
                Text(
                  '剩余 ${product.displayStock ?? 0} 件', // Use ?? 0 to handle null gracefully
                  style: AppTextStyles.responsiveBodySmall(context).copyWith(
                    color: AppColors.themeRed,
                  ),
                ),
              ],

              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 8)),
              
              // Price and Add Button Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Price Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.strikethroughPrice != null)
                          Text(
                            '€${product.strikethroughPrice!.toStringAsFixed(2)}',
                            style: AppTextStyles.responsiveBodySmall(context).copyWith(
                              color: AppColors.secondaryText,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Text(
                          '€${product.mainPrice.toStringAsFixed(2)}',
                          style: AppTextStyles.responsivePriceMain(context),
                        ),
                      ],
                    ),
                  ),
                  
                  // Add to Cart Button
                  AddToCartButton(product: product),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}