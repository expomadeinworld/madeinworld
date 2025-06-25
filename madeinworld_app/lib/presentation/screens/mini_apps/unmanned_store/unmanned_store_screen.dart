import 'dart:async';
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
import '../../../providers/location_provider.dart'; // Import LocationProvider
import '../../cart/cart_screen.dart';

class UnmannedStoreScreen extends StatefulWidget {
  const UnmannedStoreScreen({super.key});

  @override
  State<UnmannedStoreScreen> createState() => _UnmannedStoreScreenState();
}

class _UnmannedStoreScreenState extends State<UnmannedStoreScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const _ProductsTab(),
    const _LocationsTab(),
    const _MessagesTab(),
    const _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    // Access the LocationProvider here
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '无人门店',
          style: AppTextStyles.majorHeader,
        ),
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.primaryText,
          ),
        ),
        actions: [
          // Location selector
          GestureDetector(
            onTap: () {
              // Show location selector
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.lightRed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppColors.themeRed,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  // Use the displayStoreName from the provider
                  Text(
                    locationProvider.displayStoreName,
                    style: AppTextStyles.locationStore.copyWith(fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.themeRed,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              // QR Scanner
            },
            icon: const Icon(
              Icons.qr_code_scanner,
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
                      _buildNavItem(
                        index: 2,
                        icon: Icons.message,
                        label: '消息',
                      ),
                      _buildNavItem(
                        index: 3,
                        icon: Icons.person,
                        label: '我的',
                      ),
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
  State<_ProductsTab> createState() => __ProductsTabState();
}

class __ProductsTabState extends State<_ProductsTab> with WidgetsBindingObserver {
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  final ApiService _apiService = ApiService();
  late Future<List<Category>> _categoriesFuture;
  late Future<List<Product>> _productsFuture;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Add lifecycle observer for automatic foreground refresh
    WidgetsBinding.instance.addObserver(this);
    // Start periodic refresh timer (every 30 seconds)
    _startPeriodicRefresh();
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
      _fetchData();
      _startPeriodicRefresh(); // Restart timer when app resumes
    } else if (state == AppLifecycleState.paused) {
      _refreshTimer?.cancel(); // Stop timer when app is paused
    }
  }

  // Start periodic refresh timer
  void _startPeriodicRefresh() {
    _refreshTimer?.cancel(); // Cancel existing timer
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch data here using the provider
    _fetchData();
  }

  void _fetchData() {
    // Get the current storeId from the provider
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final storeId = locationProvider.nearestStore?.id;

    setState(() {
      _categoriesFuture = _apiService.fetchCategoriesWithFilters(
        storeType: StoreType.unmanned,
        miniAppType: MiniAppType.unmannedStore,
        includeSubcategories: true,
      );
      // Pass the storeId to the products fetch call
      _productsFuture = _apiService.fetchProducts(
        storeType: StoreType.unmanned,
        storeId: storeId,
      );
    });
  }

  // Method for pull-to-refresh
  Future<void> _refreshData() async {
    _fetchData();
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
                  onPressed: _fetchData, // Use the new fetchData method
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

          // Filter products by category and subcategory
          List<Product> filteredProducts = allProducts;

          if (_selectedCategoryId != null) {
            filteredProducts = filteredProducts.where((product) =>
                product.categoryIds.contains(_selectedCategoryId)).toList();
          }

          if (_selectedSubcategoryId != null) {
            filteredProducts = filteredProducts.where((product) =>
                product.subcategoryIds.contains(_selectedSubcategoryId)).toList();
          }

          return RefreshIndicator(
            onRefresh: _refreshData,
            color: AppColors.themeRed,
            child: Column(
              children: [
                // Categories
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length + 1, // +1 for "All" category
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return CategoryChip(
                        category: Category(
                          id: '',
                          name: '全部',
                          storeTypeAssociation: StoreTypeAssociation.all,
                          miniAppAssociation: [],
                        ),
                        isSelected: _selectedCategoryId == null,
                        onTap: () {
                          setState(() {
                            _selectedCategoryId = null;
                            _selectedSubcategoryId = null;
                          });
                        },
                      );
                    }

                    final category = categories[index - 1];
                    return CategoryChip(
                      category: category,
                      isSelected: _selectedCategoryId == category.id,
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = category.id;
                          _selectedSubcategoryId = null; // Reset subcategory when category changes
                        });
                      },
                    );
                  },
                ),
              ),

              // Subcategories (show when a category is selected)
              if (_selectedCategoryId != null)
                Builder(
                  builder: (context) {
                    final selectedCategory = categories.firstWhere(
                      (cat) => cat.id == _selectedCategoryId,
                      orElse: () => categories.first,
                    );

                    if (selectedCategory.subcategories.isNotEmpty) {
                      return Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: selectedCategory.subcategories.length + 1, // +1 for "All" subcategory
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: const Text('全部'),
                                  selected: _selectedSubcategoryId == null,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedSubcategoryId = null;
                                    });
                                  },
                                ),
                              );
                            }

                            final subcategory = selectedCategory.subcategories[index - 1];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(subcategory.name),
                                selected: _selectedSubcategoryId == subcategory.id,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedSubcategoryId = selected ? subcategory.id : null;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
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
                    physics: const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh works
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
          return const Center(
            child: Text('暂无数据'),
          );
        }
      },
    );
  }
}

class _LocationsTab extends StatelessWidget {
  const _LocationsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('地点功能开发中...'),
    );
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

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('个人中心功能开发中...'),
    );
  }
}