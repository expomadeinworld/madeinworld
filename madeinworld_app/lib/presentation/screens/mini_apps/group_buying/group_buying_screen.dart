import 'dart:async';
import 'package:flutter/material.dart';
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

class GroupBuyingScreen extends StatefulWidget {
  const GroupBuyingScreen({super.key});

  @override
  State<GroupBuyingScreen> createState() => _GroupBuyingScreenState();
}

class _GroupBuyingScreenState extends State<GroupBuyingScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _ProductsTab(),
    const _GroupsTab(),
    const _MessagesTab(),
    const _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('团购团批', style: AppTextStyles.majorHeader),
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppColors.primaryText),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 80,
            child: Row(
              children: [
                // Left nav items
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        index: 0,
                        icon: Icons.shopping_basket,
                        label: '团购',
                      ),
                      _buildNavItem(index: 1, icon: Icons.group, label: '团组'),
                    ],
                  ),
                ),

                // Center floating action button
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: FloatingActionButton(
                    onPressed: () {
                      // Create new group buying
                    },
                    backgroundColor: AppColors.themeRed,
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),

                // Right nav items
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(index: 2, icon: Icons.message, label: '消息'),
                      _buildNavItem(index: 3, icon: Icons.person, label: '我的'),
                    ],
                  ),
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
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.themeRed : AppColors.secondaryText,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: isSelected
                  ? AppTextStyles.navActive
                  : AppTextStyles.navInactive,
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
  final ApiService _apiService = ApiService();
  late Future<List<Category>> _categoriesFuture;
  late Future<List<Product>> _productsFuture;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _categoriesFuture = _apiService.fetchCategoriesWithFilters(
        miniAppType: MiniAppType.groupBuying,
        includeSubcategories: true,
      );
      _productsFuture = _apiService.fetchProducts();
    });
  }

  Future<void> _refreshData() async {
    _fetchData();
    try {
      await Future.wait([_categoriesFuture, _productsFuture]);
    } catch (e) {
      // Handle errors silently for refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: FutureBuilder<List<dynamic>>(
        future: Future.wait([_categoriesFuture, _productsFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(height: 16),
                  Text('加载失败', style: AppTextStyles.body),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchData,
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData) {
            final categories = snapshot.data![0] as List<Category>;
            final products = snapshot.data![1] as List<Product>;

            // Check if there are any mini-app recommended products for group buying
            final hasRecommendedProducts = products.any((product) =>
                product.isMiniAppRecommendation && product.miniAppType == MiniAppType.groupBuying);

            // Build categories list with featured category if there are recommended products
            final displayCategories = _buildCategoriesWithFeatured(categories, hasRecommendedProducts);

            // Filter products by selected category
            final filteredProducts = _selectedCategoryId == null || _selectedCategoryId == 'featured'
                ? products.where((product) =>
                    product.isMiniAppRecommendation &&
                    product.miniAppType == MiniAppType.groupBuying).toList()
                : products
                      .where(
                        (product) =>
                            product.categoryIds.contains(_selectedCategoryId),
                      )
                      .toList();

            return Column(
              children: [
                // Categories horizontal list
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: displayCategories.length,
                    itemBuilder: (context, index) {
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
            return const Center(child: Text('暂无数据'));
          }
        },
      ),
    );
  }

  /// Builds a list of categories with featured category, ensuring no duplicates
  List<Category> _buildCategoriesWithFeatured(List<Category> apiCategories, bool hasRecommendedProducts) {
    final List<Category> result = [];

    // Always add featured category first if there are recommended products
    if (hasRecommendedProducts) {
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

class _GroupsTab extends StatelessWidget {
  const _GroupsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('团购组织功能开发中...'));
  }
}

class _MessagesTab extends StatelessWidget {
  const _MessagesTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('消息功能开发中...'));
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('个人中心功能开发中...'));
  }
}
