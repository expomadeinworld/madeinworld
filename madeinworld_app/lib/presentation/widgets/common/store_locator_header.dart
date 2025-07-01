import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/store.dart';
import '../../../core/enums/store_type.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/location_service.dart';
import '../../providers/location_provider.dart';

class StoreLocatorHeader extends StatefulWidget implements PreferredSizeWidget {
  final String miniAppName;
  final List<StoreType> allowedStoreTypes;
  final Store? selectedStore;
  final Function(Store?) onStoreSelected;
  final VoidCallback onClose;

  const StoreLocatorHeader({
    super.key,
    required this.miniAppName,
    required this.allowedStoreTypes,
    required this.selectedStore,
    required this.onStoreSelected,
    required this.onClose,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<StoreLocatorHeader> createState() => _StoreLocatorHeaderState();
}

class _StoreLocatorHeaderState extends State<StoreLocatorHeader> {
  bool _isDropdownOpen = false;
  OverlayEntry? _overlayEntry;
  final GlobalKey _storeLocatorKey = GlobalKey();

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isDropdownOpen = false;
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _removeOverlay();
    } else {
      _showDropdown();
    }
  }

  void _showDropdown() async {
    // Get location provider before async operations
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final userPosition = locationProvider.currentPosition;

    try {
      // Fetch stores directly from API based on allowed store types
      final apiService = ApiService();
      final allStores = await apiService.fetchStores();
      final filteredStores = allStores
          .where((store) => widget.allowedStoreTypes.contains(store.type))
          .toList();

      // Check if widget is still mounted after async operation
      if (!mounted) return;

      final stores = <StoreWithDistance>[];
      for (final store in filteredStores) {
        double distance = 0.0;
        if (userPosition != null) {
          distance = LocationService.calculateDistance(
            userPosition.latitude,
            userPosition.longitude,
            store.latitude,
            store.longitude,
          );
        }
        stores.add(StoreWithDistance(store: store, distance: distance));
      }

      // Sort by distance if location is available
      if (userPosition != null) {
        stores.sort((a, b) => a.distance.compareTo(b.distance));
      }

      // Check if widget is still mounted before using context
      if (!mounted) return;

      if (stores.isEmpty) return;

      _buildAndShowDropdown(stores);
    } catch (e) {
      debugPrint('Error fetching stores for dropdown: $e');
      // Fallback to empty list or show error
      return;
    }
  }

  void _buildAndShowDropdown(List<StoreWithDistance> stores) {

    final RenderBox renderBox = _storeLocatorKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 16,
        right: 16,
        top: position.dy + size.height + 8,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: stores.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey.shade200,
              ),
              itemBuilder: (context, index) {
                final storeWithDistance = stores[index];
                final store = storeWithDistance.store;
                final distance = storeWithDistance.distance;
                final isSelected = widget.selectedStore?.id == store.id;

                return ListTile(
                  onTap: () {
                    widget.onStoreSelected(store);
                    _removeOverlay();
                  },
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getStoreTypeColor(store.type),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    store.name,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppColors.themeRed : AppColors.primaryText,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.type.displayName,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                      Text(
                        '${distance.toStringAsFixed(1)}km',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: AppColors.themeRed,
                          size: 20,
                        )
                      : null,
                );
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isDropdownOpen = true;
    });
  }

  Color _getStoreTypeColor(StoreType storeType) {
    switch (storeType) {
      case StoreType.unmannedStore:
        return const Color(0xFF2196F3); // Light blue
      case StoreType.unmannedWarehouse:
        return const Color(0xFF4CAF50); // Light green
      case StoreType.exhibitionStore:
        return const Color(0xFFFFD556); // Light yellow
      case StoreType.exhibitionMall:
        return const Color(0xFFF38900); // Vivid orange
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.lightBackground,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Left: Mini-app name
          Text(
            widget.miniAppName,
            style: AppTextStyles.majorHeader,
          ),
          
          const Spacer(),
          
          // Center: Store locator
          GestureDetector(
            key: _storeLocatorKey,
            onTap: _toggleDropdown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isDropdownOpen ? AppColors.themeRed : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.selectedStore != null 
                          ? _getStoreTypeColor(widget.selectedStore!.type)
                          : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.selectedStore?.name ?? '选择门店',
                    style: AppTextStyles.body.copyWith(
                      color: widget.selectedStore != null 
                          ? AppColors.primaryText 
                          : AppColors.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.secondaryText,
                  ),
                ],
              ),
            ),
          ),
          
          const Spacer(),
        ],
      ),
      actions: [
        IconButton(
          onPressed: widget.onClose,
          icon: const Icon(Icons.close, color: AppColors.primaryText),
        ),
      ],
    );
  }
}
