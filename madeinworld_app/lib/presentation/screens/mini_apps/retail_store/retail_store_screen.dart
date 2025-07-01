import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

import '../../../../data/models/category.dart';
import '../../../../data/services/api_service.dart';
import '../../../../data/models/product.dart';
import '../../../../core/enums/store_type.dart';
import '../../../../core/enums/mini_app_type.dart';
import '../../../widgets/common/product_card.dart';
import '../../../widgets/common/category_chip.dart';
import '../../../providers/cart_provider.dart';
import '../../cart/cart_screen.dart';

class RetailStoreScreen extends StatefulWidget {
  const RetailStoreScreen({super.key});

  @override
  State<RetailStoreScreen> createState() => _RetailStoreScreenState();
}

class _RetailStoreScreenState extends State<RetailStoreScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const _ProductsTab(),
    const _MessagesTab(),
    const _CartTab(),
    const _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '零售门店',
          style: AppTextStyles.majorHeader,
        ),
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Container(
            height: 80,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.shopping_bag,
                  label: '商品',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.message,
                  label: '消息',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.shopping_cart,
                  label: '购物车',
                  showBadge: true,
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.person,
                  label: '我的',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    bool showBadge = false,
  }) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? AppColors.themeRed : AppColors.secondaryText,
                ),
                if (showBadge)
                  Consumer<CartProvider>(
                    builder: (context, cartProvider, child) {
                      if (cartProvider.itemCount == 0) return const SizedBox.shrink();
                      
                      return Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.themeRed,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            cartProvider.itemCount.toString(),
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: isSelected ? AppTextStyles.navActive : AppTextStyles.navInactive,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductsTab extends StatefulWidget {
  const _ProductsTab();

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  String? _selectedCategoryId = 'featured'; // Default to featured/推荐
  final ApiService _apiService = ApiService();
  late Future<List<Category>> _categoriesFuture;
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _apiService.fetchCategoriesWithFilters(
      storeType: StoreType.exhibitionStore,
      miniAppType: MiniAppType.retailStore,
      includeSubcategories: true,
    );
    _productsFuture = _apiService.fetchProducts(storeType: StoreType.exhibitionStore);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([_categoriesFuture, _productsFuture]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.themeRed,
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(height: 16),
                Text(
                  '加载失败',
                  style: AppTextStyles.responsiveBodySmall(context).copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '请检查网络连接后重试',
                  style: AppTextStyles.responsiveBodySmall(context).copyWith(
                    color: AppColors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _categoriesFuture = _apiService.fetchCategoriesWithFilters(
                        storeType: StoreType.exhibitionStore,
                        miniAppType: MiniAppType.retailStore,
                        includeSubcategories: true,
                      );
                      _productsFuture = _apiService.fetchProducts(storeType: StoreType.exhibitionStore);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.themeRed,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        } else if (snapshot.hasData) {
          final categories = snapshot.data![0] as List<Category>;
          final allProducts = snapshot.data![1] as List<Product>;
          final filteredProducts = _selectedCategoryId == null
              ? allProducts
              : _selectedCategoryId == 'featured'
                  ? allProducts.where((product) =>
                      product.isMiniAppRecommendation &&
                      product.miniAppType == MiniAppType.retailStore).toList()
                  : allProducts.where((product) =>
                      product.categoryIds.contains(_selectedCategoryId)).toList();

          return Column(
            children: [
              // Categories
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _buildCategoriesWithFeatured(categories, allProducts).length,
                  itemBuilder: (context, index) {
                    final displayCategories = _buildCategoriesWithFeatured(categories, allProducts);
                    final category = displayCategories[index];

                    return CategoryChip(
                      category: category,
                      isSelected: _selectedCategoryId == category.id ||
                          (_selectedCategoryId == null && category.id == 'featured'),
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = category.id;
                        });
                      },
                    );
                  },
                ),
              ),

              // Products Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: MasonryGridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      return ProductCard(
                        product: filteredProducts[index],
                        onTap: () {
                          // Navigate to product detail
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        } else {
          return const Center(
            child: Text('暂无数据'),
          );
        }
      },
    );
  }

  /// Builds a list of categories with featured category, ensuring no duplicates
  List<Category> _buildCategoriesWithFeatured(List<Category> apiCategories, List<Product> allProducts) {
    final List<Category> result = [];

    // Check if there are any mini-app recommended products for retail store
    final hasFeaturedProducts = allProducts.any((product) =>
        product.isMiniAppRecommendation && product.miniAppType == MiniAppType.retailStore);

    // Always add featured category first if there are featured products
    if (hasFeaturedProducts) {
      result.add(Category(
        id: 'featured',
        name: '推荐',
        storeTypeAssociation: StoreTypeAssociation.all,
        miniAppAssociation: [],
      ));
    }

    // Add all API categories except any "推荐" categories (to avoid duplicates)
    for (final category in apiCategories) {
      if (category.name != '推荐' && category.id != 'featured') {
        result.add(category);
      }
    }

    return result;
  }
}

class _MessagesTab extends StatelessWidget {
  const _MessagesTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('消息功能开发中...'),
    );
  }
}

class _CartTab extends StatelessWidget {
  const _CartTab();

  @override
  Widget build(BuildContext context) {
    return const CartScreen();
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('个人中心功能开发中...'),
    );
  }
}
