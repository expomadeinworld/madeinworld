import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/category.dart';
import '../../../../data/models/subcategory.dart';
import '../../../../data/models/product.dart';
import '../../../widgets/common/product_card.dart';

class ProductListScreen extends StatelessWidget {
  final Category category;
  final Subcategory subcategory;
  final List<Product> allProducts;
  final String miniAppName;

  const ProductListScreen({
    super.key,
    required this.category,
    required this.subcategory,
    required this.allProducts,
    required this.miniAppName,
  });

  @override
  Widget build(BuildContext context) {
    // Filter products for this subcategory
    final products = allProducts
        .where((product) => 
            product.subcategoryIds.contains(subcategory.id.toString()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$miniAppName: ${category.name}: ${subcategory.name}',
          style: AppTextStyles.majorHeader,
        ),
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left, color: AppColors.primaryText),
        ),
      ),
      body: products.isEmpty
          ? _buildEmptyState()
          : _buildProductGrid(products),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: AppColors.secondaryText,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无商品',
            style: AppTextStyles.body.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '该子分类下暂时没有商品',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            product: product,
            onTap: () {
              // Handle product tap - could navigate to product detail
              _showProductDetail(context, product);
            },
          );
        },
      ),
    );
  }

  void _showProductDetail(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Product detail content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product image
                        if (product.imageUrls.isNotEmpty)
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: AppColors.lightBackground,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                product.imageUrls.first,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.image_not_supported,
                                    size: 64,
                                    color: AppColors.secondaryText,
                                  );
                                },
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: 16),
                        
                        // Product name
                        Text(
                          product.title,
                          style: AppTextStyles.majorHeader,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Product price
                        Text(
                          '¥${product.mainPrice.toStringAsFixed(2)}',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.themeRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Product description
                        if (product.descriptionLong.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '商品描述',
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                product.descriptionLong,
                                style: AppTextStyles.body,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
