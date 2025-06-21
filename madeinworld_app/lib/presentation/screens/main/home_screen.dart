import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/product.dart';
import '../../widgets/decorative_backdrop.dart';
import '../../widgets/common/product_card.dart';
import '../../providers/location_provider.dart';
import '../mini_apps/retail_store/retail_store_screen.dart';
import '../mini_apps/unmanned_store/unmanned_store_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Product>> _featuredProductsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Location services are now automatically initialized by LocationProvider constructor
    // No manual initialization needed

    // Initialize the featured products future
    _featuredProductsFuture = _apiService.fetchProducts(featured: true);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Stack(
        children: [
          // Decorative backdrop
          const DecorativeBackdrop(),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: ResponsiveUtils.getResponsiveSpacing(context, 24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  _buildHeader(context),

                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),

                  // Search Bar Section
                  _buildSearchBar(context),

                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 24)),

                  // Service Modules Grid
                  _buildServiceModules(context),

                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 32)),

                  // Hot Recommendations Section with FutureBuilder
                  FutureBuilder<List<Product>>(
                    future: _featuredProductsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoadingRecommendations(context);
                      } else if (snapshot.hasError) {
                        return _buildErrorRecommendations(context, snapshot.error.toString());
                      } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        return _buildHotRecommendations(context, snapshot.data!);
                      } else {
                        return _buildEmptyRecommendations(context);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context, 16)),
      child: Consumer<LocationProvider>(
        builder: (context, locationProvider, child) {
          return Row(
            children: [
              // Left cluster
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppColors.themeRed,
                      size: ResponsiveUtils.getResponsiveSpacing(context, 24),
                    ),
                    SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 8)),

                    // City name with automatic loading state
                    if (locationProvider.isLoading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.themeRed,
                        ),
                      )
                    else
                      Text(
                        locationProvider.displayCity,
                        style: AppTextStyles.responsiveLocationCity(context),
                      ),

                    SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 8)),

                    // Store selector with loading state
                    GestureDetector(
                      onTap: () {
                        // Navigate to locations screen (switch to locations tab)
                        // This will be handled by the main screen's bottom navigation
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.getResponsiveSpacing(context, 12),
                          vertical: ResponsiveUtils.getResponsiveSpacing(context, 6),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightRed,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (locationProvider.isLoading)
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppColors.themeRed,
                                ),
                              )
                            else
                              Text(
                                locationProvider.displayStoreName,
                                style: AppTextStyles.responsiveLocationStore(context),
                              ),
                            SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 4)),
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.themeRed,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Right element
              IconButton(
                onPressed: () {
                  // Navigate to notifications
                },
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.primaryText,
                  size: 24,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Search bar
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: '搜索商品...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.secondaryText,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // QR Scanner button
          GestureDetector(
            onTap: () {
              // Open QR scanner
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                color: AppColors.primaryText,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceModules(BuildContext context) {
    final modules = [
      {
        'title': '零售门店',
        'icon': Icons.shopping_bag,
        'color': AppColors.themeRed,
        'bgColor': AppColors.redModuleBg,
        'onTap': () => _navigateToMiniApp(context, const RetailStoreScreen()),
      },
      {
        'title': '无人门店',
        'icon': Icons.store,
        'color': AppColors.blueModule,
        'bgColor': AppColors.blueModuleBg,
        'onTap': () => _navigateToMiniApp(context, const UnmannedStoreScreen()),
      },
      {
        'title': '无人仓店',
        'icon': Icons.warehouse,
        'color': AppColors.greenModule,
        'bgColor': AppColors.greenModuleBg,
        'onTap': () {},
      },
      {
        'title': '展销商店',
        'icon': Icons.storefront,
        'color': AppColors.purpleModule,
        'bgColor': AppColors.purpleModuleBg,
        'onTap': () {},
      },
      {
        'title': '展销商城',
        'icon': Icons.shopping_cart,
        'color': AppColors.yellowModule,
        'bgColor': AppColors.yellowModuleBg,
        'onTap': () {},
      },
      {
        'title': '团购团批',
        'icon': Icons.group,
        'color': AppColors.indigoModule,
        'bgColor': AppColors.indigoModuleBg,
        'onTap': () {},
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getResponsiveSpacing(context, 16)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, 12),
          mainAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, 12),
          childAspectRatio: 1.0,
        ),
        itemCount: modules.length,
        itemBuilder: (context, index) {
          final module = modules[index];
          return GestureDetector(
            onTap: module['onTap'] as VoidCallback,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: module['bgColor'] as Color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      module['icon'] as IconData,
                      color: module['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    module['title'] as String,
                    style: AppTextStyles.moduleLabel,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHotRecommendations(BuildContext context, List<dynamic> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getResponsiveSpacing(context, 16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '热门推荐',
                style: AppTextStyles.responsiveMajorHeader(context),
              ),
              GestureDetector(
                onTap: () {
                  // Navigate to see all products
                },
                child: Text(
                  '查看全部',
                  style: AppTextStyles.responsiveBodySmall(context).copyWith(
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getResponsiveSpacing(context, 16)),
          child: MasonryGridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, 12),
            mainAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, 12),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return ProductCard(
                product: products[index],
                onTap: () {
                  // Navigate to product detail
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingRecommendations(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getResponsiveSpacing(context, 16)),
          child: Text(
            '热门推荐',
            style: AppTextStyles.responsiveMajorHeader(context),
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getResponsiveSpacing(context, 16)),
          child: Center(
            child: Column(
              children: [
                CircularProgressIndicator(
                  color: AppColors.themeRed,
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),
                Text(
                  '正在加载推荐商品...',
                  style: AppTextStyles.responsiveBodySmall(context).copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorRecommendations(BuildContext context, String error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getResponsiveSpacing(context, 16)),
          child: Text(
            '热门推荐',
            style: AppTextStyles.responsiveMajorHeader(context),
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getResponsiveSpacing(context, 16)),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.secondaryText,
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),
                Text(
                  '加载失败',
                  style: AppTextStyles.responsiveBodySmall(context).copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 8)),
                Text(
                  '请检查网络连接后重试',
                  style: AppTextStyles.responsiveBodySmall(context).copyWith(
                    color: AppColors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _featuredProductsFuture = _apiService.fetchProducts(featured: true);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.themeRed,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyRecommendations(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getResponsiveSpacing(context, 16)),
          child: Text(
            '热门推荐',
            style: AppTextStyles.responsiveMajorHeader(context),
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getResponsiveSpacing(context, 16)),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 48,
                  color: AppColors.secondaryText,
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),
                Text(
                  '暂无推荐商品',
                  style: AppTextStyles.responsiveBodySmall(context).copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 8)),
                Text(
                  '请稍后再试或浏览其他商品',
                  style: AppTextStyles.responsiveBodySmall(context).copyWith(
                    color: AppColors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToMiniApp(BuildContext context, Widget miniApp) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => miniApp,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide-away transition: current screen slides out to the right
          // revealing the new screen underneath

          // New screen fades in gently underneath
          var fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
          );

          // Current screen slides out to the right when going back
          var slideOut = Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(1.0, 0.0), // Slide out to the right
          ).animate(
            CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeInOut,
            ),
          );

          return SlideTransition(
            position: slideOut,
            child: FadeTransition(
              opacity: fadeIn,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
