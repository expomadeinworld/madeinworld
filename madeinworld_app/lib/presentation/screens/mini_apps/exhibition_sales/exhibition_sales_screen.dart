import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import '../../../providers/cart_provider.dart';
import '../../cart/cart_screen.dart';
import 'exhibition_sales_locations_screen.dart';

class ExhibitionSalesScreen extends StatefulWidget {
  const ExhibitionSalesScreen({super.key});

  @override
  State<ExhibitionSalesScreen> createState() => _ExhibitionSalesScreenState();
}

class _ExhibitionSalesScreenState extends State<ExhibitionSalesScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _ProductsTab(),
    const _LocationsTab(),
    const _MessagesTab(),
    const _ProfileTab(),
  ];

  // ADD THIS NEW HELPER METHOD INSIDE _ExhibitionSalesScreenState
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        '展销展消',
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
        IconButton(
          onPressed: () {
            // Search functionality
          },
          icon: const Icon(
            Icons.search,
            color: AppColors.primaryText,
          ),
        ),
        IconButton(
          onPressed: () {
            // Notifications
          },
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.primaryText,
          ),
        ),
        Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            return Stack(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: AppColors.primaryText,
                  ),
                ),
                if (cartProvider.itemCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.themeRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${cartProvider.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // REPLACE the old appBar with this conditional line
      appBar: _currentIndex == 1 ? null : _buildAppBar(),
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
                
                // Center floating action button
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: FloatingActionButton(
                    onPressed: () {
                      // QR Code scanner
                    },
                    backgroundColor: AppColors.themeRed,
                    child: const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                    ),
                  ),
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
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  String? _selectedCategoryId = 'featured'; // Default to featured/推荐
  Store? _selectedStore; // Selected store for location-based categories
  final ApiService _apiService = ApiService();
  late Future<List<Category>> _categoriesFuture;
  late Future<List<Product>> _productsFuture;
  late Future<List<Store>> _storesFuture;

  @override
  void initState() {
    super.initState();
    // Initialize stores future
    _storesFuture = _loadStores();
    _fetchData();
  }

  Future<List<Store>> _loadStores() async {
    try {
      // Get exhibition sales stores from API using mini_app_type filter
      final stores = await _apiService.fetchStores();
      // Filter for exhibition sales stores (展销商店 and 展销商城)
      final exhibitionStores = stores.where((store) =>
        store.type == StoreType.exhibitionStore ||
        store.type == StoreType.exhibitionMall
      ).toList();

      if (exhibitionStores.isNotEmpty && _selectedStore == null) {
        // Auto-select first store if none selected
        setState(() {
          _selectedStore = exhibitionStores.first;
        });
      }
      return exhibitionStores;
    } catch (e) {
      debugPrint('Error loading stores: $e');
      return [];
    }
  }

  void _fetchData() {
    setState(() {
      _categoriesFuture = _apiService.fetchCategoriesWithFilters(
        miniAppType: MiniAppType.exhibitionSales,
        includeSubcategories: true,
      );
      // Pass the storeId to the products fetch call
      _productsFuture = _apiService.fetchProducts(
        storeType: StoreType.exhibitionStore,
        storeId: _selectedStore?.id,
      );
    });
  }

  Future<void> _refreshData() async {
    _fetchData();
    try {
      await Future.wait([_categoriesFuture, _productsFuture, _storesFuture]);
    } catch (e) {
      // Handle errors silently for refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: FutureBuilder<List<dynamic>>(
        future: Future.wait([_categoriesFuture, _productsFuture, _storesFuture]),
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
                  Text(
                    '加载失败',
                    style: AppTextStyles.body,
                  ),
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

            // Filter products by selected category
            final filteredProducts = _selectedCategoryId == null
                ? products
                : products.where((product) => 
                    product.categoryIds.contains(_selectedCategoryId)).toList();

            return Column(
              children: [
                // Store Selection Section
                FutureBuilder<List<Store>>(
                  future: _storesFuture,
                  builder: (context, storeSnapshot) {
                    if (storeSnapshot.hasData && storeSnapshot.data!.isNotEmpty) {
                      final stores = storeSnapshot.data!;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.secondaryText.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '选择门店',
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<Store>(
                              value: _selectedStore,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: stores.map((store) {
                                return DropdownMenuItem<Store>(
                                  value: store,
                                  child: Text(
                                    '${store.name} - ${store.city}',
                                    style: AppTextStyles.body,
                                  ),
                                );
                              }).toList(),
                              onChanged: (Store? newStore) {
                                setState(() {
                                  _selectedStore = newStore;
                                });
                                _fetchData(); // Refresh data when store changes
                              },
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink(); // Hide if no stores
                  },
                ),

                // Categories horizontal list
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length + 1, // +1 for "All" category
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return CategoryChip(
                          category: Category(
                            id: 'featured',
                            name: '推荐',
                            storeTypeAssociation: StoreTypeAssociation.all,
                            miniAppAssociation: [],
                          ),
                          isSelected: _selectedCategoryId == null || _selectedCategoryId == 'featured',
                          onTap: () {
                            setState(() {
                              _selectedCategoryId = 'featured';
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
      ),
    );
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
