import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

import '../../../../data/models/category.dart';
import '../../../../data/models/store.dart';
import '../../../../data/services/api_service.dart';
import '../../../../data/models/product.dart';
import '../../../../core/enums/store_type.dart';
import '../../../../core/enums/mini_app_type.dart';
import '../../../widgets/common/product_card.dart';
import '../../../widgets/common/category_chip.dart';
import '../../../widgets/common/store_locator_header.dart';
import 'exhibition_sales_locations_screen.dart';
import '../common/subcategory_grid_screen.dart';
import '../../../../core/navigation/custom_page_transitions.dart';

class ExhibitionSalesScreen extends StatefulWidget {
  const ExhibitionSalesScreen({super.key});

  @override
  State<ExhibitionSalesScreen> createState() => _ExhibitionSalesScreenState();
}

class _ExhibitionSalesScreenState extends State<ExhibitionSalesScreen> {
  int _currentIndex = 0;
  Store? _selectedStore;
  final GlobalKey<_ProductsTabState> _productsTabKey = GlobalKey<_ProductsTabState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _ProductsTab(key: _productsTabKey, onStoreSelected: _onStoreSelected),
      const _LocationsTab(),
      const _MessagesTab(),
      const _ProfileTab(),
    ];
  }

  void _onStoreSelected(Store? store) {
    setState(() {
      _selectedStore = store;
    });
    // Refresh data when store changes
    _productsTabKey.currentState?.fetchData();
  }

  // Store locator header for exhibition sales
  PreferredSizeWidget _buildAppBar() {
    return StoreLocatorHeader(
      miniAppName: '展销展消',
      allowedStoreTypes: const [StoreType.exhibitionStore, StoreType.exhibitionMall],
      selectedStore: _selectedStore,
      onStoreSelected: _onStoreSelected,
      onClose: () => Navigator.of(context).pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // REPLACE the old appBar with this conditional line
      appBar: _currentIndex == 1 ? null : _buildAppBar(),
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
                        icon: Icons.storefront,
                        label: '展销',
                      ),
                      _buildNavItem(
                        index: 1,
                        icon: Icons.location_on,
                        label: '地点',
                      ),
                    ],
                  ),
                ),

                // Removed QR scanner as per requirements

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
  final Function(Store?) onStoreSelected;

  const _ProductsTab({super.key, required this.onStoreSelected});

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  String? _selectedCategoryId = 'featured'; // Default to featured/推荐
  Store? _selectedStore; // Selected store for location-based categories
  final ApiService _apiService = ApiService();
  late Future<List<Category>> _categoriesFuture;
  late Future<List<Product>> _productsFuture;
  @override
  void initState() {
    super.initState();
    // Initialize data with empty futures to prevent LateInitializationError
    _categoriesFuture = Future.value([]);
    _productsFuture = Future.value([]);
    // Initialize store selection
    _initializeStore();
  }

  void _initializeStore() async {
    try {
      // Get exhibition sales stores from API using mini_app_type filter
      final stores = await _apiService.fetchStores();
      debugPrint('DEBUG: Exhibition Sales - Total stores fetched: ${stores.length}');

      // Filter for exhibition sales stores (展销商店 and 展销商城)
      final exhibitionStores = stores
          .where(
            (store) =>
                store.type == StoreType.exhibitionStore ||
                store.type == StoreType.exhibitionMall,
          )
          .toList();

      debugPrint('DEBUG: Exhibition Sales - Exhibition stores found: ${exhibitionStores.length}');
      for (final store in exhibitionStores) {
        debugPrint('DEBUG: Exhibition store: ${store.name} (${store.type.displayName})');
      }

      if (exhibitionStores.isNotEmpty && _selectedStore == null) {
        // Auto-select first store if none selected
        setState(() {
          _selectedStore = exhibitionStores.first;
        });
        debugPrint('DEBUG: Exhibition Sales - Selected store: ${_selectedStore!.name}');
        // Notify parent about the selected store
        widget.onStoreSelected(_selectedStore);
        // Fetch data after store is initialized
        fetchData();
      } else if (exhibitionStores.isEmpty) {
        debugPrint('DEBUG: Exhibition Sales - No exhibition stores found! Please create exhibition stores in the admin panel.');
        // Still fetch data without store filter to show any available data
        fetchData();
      }
    } catch (e) {
      debugPrint('ERROR: Exhibition Sales - Error loading stores: $e');
    }
  }

  void fetchData() {
    final storeId = _selectedStore?.id != null ? int.tryParse(_selectedStore!.id) : null;
    debugPrint('DEBUG: Exhibition Sales - Fetching data for store ID: $storeId');

    setState(() {
      _categoriesFuture = _apiService.fetchCategoriesWithFilters(
        miniAppType: MiniAppType.exhibitionSales,
        storeId: storeId,
        includeSubcategories: true,
      ).then((categories) {
        debugPrint('DEBUG: Exhibition Sales - Categories fetched: ${categories.length}');
        for (final category in categories) {
          debugPrint('DEBUG: Exhibition category: ${category.name}');
        }
        return categories;
      });

      // Pass the storeId to the products fetch call
      _productsFuture = _apiService.fetchProducts(
        storeType: StoreType.exhibitionStore,
        storeId: storeId,
      ).then((products) {
        debugPrint('DEBUG: Exhibition Sales - Products fetched: ${products.length}');
        for (int i = 0; i < products.length && i < 5; i++) {
          debugPrint('DEBUG: Exhibition product $i: ${products[i].title}');
        }
        return products;
      });
    });
  }

  Future<void> _refreshData() async {
    fetchData();
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
        future: Future.wait([
          _categoriesFuture,
          _productsFuture,
        ]),
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
                    onPressed: fetchData,
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData) {
            final allCategories = snapshot.data![0] as List<Category>;
            final allProducts = snapshot.data![1] as List<Product>;

            // Use the proper category building method with deduplication
            final categories = _buildCategoriesWithFeatured(allCategories, allProducts);

            // Filter products by selected category
            final filteredProducts = _selectedCategoryId == null || _selectedCategoryId == 'featured'
                ? allProducts.where((product) => product.isFeatured).toList()
                : allProducts
                      .where(
                        (product) =>
                            product.categoryIds.contains(_selectedCategoryId),
                      )
                      .toList();

            return Column(
              children: [
                // Store selector moved to header

                // Categories horizontal list
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];

                      return CategoryChip(
                        category: category,
                        isSelected: _selectedCategoryId == category.id ||
                            (_selectedCategoryId == null && category.id == 'featured'),
                        onTap: () {
                          if (category.id == 'featured') {
                            // For featured category, just filter products
                            setState(() {
                              _selectedCategoryId = 'featured';
                            });
                          } else {
                            // For other categories, navigate to subcategory grid
                            Navigator.of(context).push(
                              SlideRightRoute(
                                page: SubcategoryGridScreen(
                                  category: category,
                                  allProducts: allProducts,
                                  miniAppName: '展销展消',
                                ),
                              ),
                            );
                          }
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
  List<Category> _buildCategoriesWithFeatured(List<Category> apiCategories, List<Product> allProducts) {
    final List<Category> result = [];

    // Check if there are any featured products
    final hasFeaturedProducts = allProducts.any((product) => product.isFeatured);

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

class _LocationsTab extends StatelessWidget {
  const _LocationsTab();

  @override
  Widget build(BuildContext context) {
    return const ExhibitionSalesLocationsScreen();
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
