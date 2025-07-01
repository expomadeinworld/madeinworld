import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

import '../../../../data/models/category.dart';
import '../../../../data/services/api_service.dart';
import '../../../../data/models/product.dart';
import '../../../../data/models/store.dart';

import '../../../../core/enums/store_type.dart';
import '../../../../core/enums/mini_app_type.dart';
import '../../../widgets/common/product_card.dart';
import '../../../widgets/common/category_chip.dart';
import '../../../widgets/common/store_locator_header.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/location_provider.dart'; // Import LocationProvider
import '../../cart/cart_screen.dart';
import 'unmanned_store_locations_screen.dart';
import '../common/subcategory_grid_screen.dart';
import '../../../../core/navigation/custom_page_transitions.dart';

class UnmannedStoreScreen extends StatefulWidget {
  const UnmannedStoreScreen({super.key});

  @override
  State<UnmannedStoreScreen> createState() => _UnmannedStoreScreenState();
}

class _UnmannedStoreScreenState extends State<UnmannedStoreScreen> {
  int _currentIndex = 0;
  Store? _selectedStore;
  final GlobalKey<__ProductsTabState> _productsTabKey = GlobalKey<__ProductsTabState>();

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

  // Store locator header for unmanned store
  PreferredSizeWidget _buildAppBar(LocationProvider locationProvider) {
    return StoreLocatorHeader(
      miniAppName: '无人商店',
      allowedStoreTypes: const [StoreType.unmannedStore, StoreType.unmannedWarehouse],
      selectedStore: _selectedStore,
      onStoreSelected: _onStoreSelected,
      onClose: () => Navigator.of(context).pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access the LocationProvider here
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      // REPLACE the old appBar property with this conditional one:
      appBar: _currentIndex == 1 ? null : _buildAppBar(locationProvider),
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
                        icon: Icons.shopping_bag,
                        label: '商品',
                      ),
                      _buildNavItem(
                        index: 1,
                        icon: Icons.location_on,
                        label: '地点',
                      ),
                    ],
                  ),
                ),

                // Center FAB for cart
                Consumer<CartProvider>(
                  builder: (context, cartProvider, child) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CartScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: const BoxDecoration(
                          color: AppColors.themeRed,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            const Center(
                              child: Icon(
                                Icons.shopping_cart,
                                color: AppColors.white,
                                size: 24,
                              ),
                            ),
                            if (cartProvider.itemCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Text(
                                    cartProvider.itemCount.toString(),
                                    style: const TextStyle(
                                      color: AppColors.themeRed,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
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
  final Function(Store?) onStoreSelected;

  const _ProductsTab({super.key, required this.onStoreSelected});

  @override
  State<_ProductsTab> createState() => __ProductsTabState();
}

class __ProductsTabState extends State<_ProductsTab>
    with WidgetsBindingObserver {
  String? _selectedCategoryId = 'featured'; // Default to featured/推荐
  String? _selectedSubcategoryId;
  Store? _selectedStore; // Selected store for location-based categories
  final ApiService _apiService = ApiService();
  late Future<List<Category>> _categoriesFuture;
  late Future<List<Product>> _productsFuture;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Add lifecycle observer for automatic foreground refresh
    WidgetsBinding.instance.addObserver(this);
    // Initialize data with empty futures to prevent LateInitializationError
    _categoriesFuture = Future.value([]);
    _productsFuture = Future.value([]);
    // Initialize store selection
    _initializeStore();
    // Start periodic refresh timer (every 30 seconds)
    _startPeriodicRefresh();
  }

  void _initializeStore() async {
    try {
      // Get unmanned stores from API using mini_app_type filter
      final stores = await _apiService.fetchStores();
      // Filter for unmanned stores (无人商店 and 无人仓店)
      final unmannedStores = stores
          .where(
            (store) =>
                store.type == StoreType.unmannedStore ||
                store.type == StoreType.unmannedWarehouse,
          )
          .toList();

      if (unmannedStores.isNotEmpty && _selectedStore == null) {
        // Auto-select first store if none selected
        setState(() {
          _selectedStore = unmannedStores.first;
        });
        // Notify parent about the selected store
        widget.onStoreSelected(_selectedStore);
        // Fetch data after store is initialized
        fetchData();
      } else if (unmannedStores.isEmpty) {
        // No stores found, but still initialize with empty data
        debugPrint('DEBUG: No unmanned stores found');
        fetchData(); // This will fetch data without store filter
      }
    } catch (e) {
      debugPrint('Error loading stores: $e');
    }
  }

  @override
  void dispose() {
    // Remove lifecycle observer and cancel timer
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Automatically refresh data when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      fetchData();
      _startPeriodicRefresh(); // Restart timer when app resumes
    } else if (state == AppLifecycleState.paused) {
      _refreshTimer?.cancel(); // Stop timer when app is paused
    }
  }

  // Start periodic refresh timer
  void _startPeriodicRefresh() {
    _refreshTimer?.cancel(); // Cancel existing timer
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      fetchData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Data will be fetched after store initialization
    // No need to fetch data here to avoid race conditions
  }

  void fetchData() {
    final storeId = _selectedStore?.id != null ? int.tryParse(_selectedStore!.id) : null;
    debugPrint('DEBUG: Unmanned Store - Fetching data for store ID: $storeId');

    setState(() {
      _categoriesFuture = _apiService.fetchCategoriesWithFilters(
        storeType: StoreType.unmannedStore,
        miniAppType: MiniAppType.unmannedStore,
        storeId: storeId,
        includeSubcategories: true,
      ).then((categories) {
        debugPrint('DEBUG: Unmanned Store - Categories fetched: ${categories.length}');
        for (final category in categories) {
          debugPrint('DEBUG: Unmanned category: ${category.name}');
        }
        return categories;
      });

      // Pass the storeId to the products fetch call
      _productsFuture = _apiService.fetchProducts(
        storeType: StoreType.unmannedStore,
        storeId: storeId,
      ).then((products) {
        debugPrint('DEBUG: Unmanned Store - Products fetched: ${products.length}');
        for (int i = 0; i < products.length && i < 5; i++) {
          debugPrint('DEBUG: Unmanned product $i: ${products[i].title}');
        }
        return products;
      });
    });
  }

  // Method for pull-to-refresh
  Future<void> _refreshData() async {
    fetchData();
    // Wait for both futures to complete
    try {
      await Future.wait([_categoriesFuture, _productsFuture]);
    } catch (e) {
      // Handle errors silently for refresh
      // Error logging could be added here in production
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([_categoriesFuture, _productsFuture]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.themeRed),
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
                  style: AppTextStyles.responsiveBodySmall(
                    context,
                  ).copyWith(color: AppColors.secondaryText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: fetchData, // Use the new fetchData method
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
          final allCategories = snapshot.data![0] as List<Category>;
          final allProducts = snapshot.data![1] as List<Product>;

          // Filter categories that have products for the selected store
          final filteredCategories = allCategories.where((category) {
            return allProducts.any((product) =>
              product.categoryIds.contains(category.id)
            );
          }).toList();

          // Ensure "推荐" (featured) category is always first if there are featured products
          final categories = <Category>[];
          final hasFeaturedProducts = allProducts.any((product) => product.isFeatured);

          if (hasFeaturedProducts) {
            // Add featured category first
            categories.add(Category(
              id: 'featured',
              name: '推荐',
              storeTypeAssociation: StoreTypeAssociation.all,
              miniAppAssociation: [MiniAppType.unmannedStore],
              subcategories: [],
            ));
          }

          // Add other categories
          categories.addAll(filteredCategories.where((cat) => cat.id != 'featured'));

          // Filter products by category and subcategory
          List<Product> filteredProducts = allProducts;

          if (_selectedCategoryId != null && _selectedCategoryId != 'featured') {
            filteredProducts = filteredProducts
                .where(
                  (product) =>
                      product.categoryIds.contains(_selectedCategoryId),
                )
                .toList();
          } else if (_selectedCategoryId == 'featured') {
            // Show only featured products for the selected store
            filteredProducts = filteredProducts
                .where((product) => product.isFeatured)
                .toList();
          }

          if (_selectedSubcategoryId != null) {
            filteredProducts = filteredProducts
                .where(
                  (product) =>
                      product.subcategoryIds.contains(_selectedSubcategoryId),
                )
                .toList();
          }

          return RefreshIndicator(
            onRefresh: _refreshData,
            color: AppColors.themeRed,
            child: Column(
              children: [
                // Store selector moved to header
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
                          if (category.id == 'featured') {
                            // For featured category, just filter products
                            setState(() {
                              _selectedCategoryId = 'featured';
                              _selectedSubcategoryId = null;
                            });
                          } else {
                            // For other categories, navigate to subcategory grid
                            Navigator.of(context).push(
                              SlideRightRoute(
                                page: SubcategoryGridScreen(
                                  category: category,
                                  allProducts: allProducts,
                                  miniAppName: '无人商店',
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),

                // Subcategories navigation moved to separate screen

                // Products Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: MasonryGridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      itemCount: filteredProducts.length,
                      physics:
                          const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh works
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
            ),
          );
        } else {
          return const Center(child: Text('暂无数据'));
        }
      },
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
    return const UnmannedStoreLocationsScreen();
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
