import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/navigation/custom_page_transitions.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../data/models/store.dart';
import '../../../data/services/mock_data_service.dart';
import '../../providers/location_provider.dart';
import 'main_screen.dart';


class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;
  Store? _selectedStore;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map
          _buildFullScreenMap(),

          // Floating search bar
          if (_isSearchVisible) _buildFloatingSearchBar(),

          // Top controls
          _buildTopControls(),

          // Store details bottom sheet
          if (_selectedStore != null) _buildStoreDetailsSheet(),
        ],
      ),
    );
  }

  Widget _buildFullScreenMap() {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        final userPosition = locationProvider.currentPosition;
        final stores = MockDataService.getUnmannedStores();

        // Create markers for unmanned stores
        final markers = <Marker>{};

        // Add store markers with custom styling
        for (final store in stores) {
          markers.add(
            Marker(
              markerId: MarkerId(store.id),
              position: LatLng(store.latitude, store.longitude),
              // Remove info window completely - only show bottom sheet
              infoWindow: InfoWindow.noText,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              onTap: () {
                setState(() {
                  _selectedStore = store;
                });
              },
            ),
          );
        }

        // Add user location marker if available
        if (userPosition != null) {
          markers.add(
            Marker(
              markerId: const MarkerId('user_location'),
              position: LatLng(userPosition.latitude, userPosition.longitude),
              // Remove info window - user location is shown by blue dot
              infoWindow: InfoWindow.noText,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            ),
          );
        }

        // Default camera position (Lugano, Switzerland)
        const defaultPosition = CameraPosition(
          target: LatLng(46.0037, 8.9511), // Lugano coordinates
          zoom: 13.0,
        );

        // Use user position if available, otherwise default to Lugano
        final cameraPosition = userPosition != null
            ? CameraPosition(
                target: LatLng(userPosition.latitude, userPosition.longitude),
                zoom: 14.0,
              )
            : defaultPosition;

        return GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            // Fit bounds to show all stores and user location
            if (stores.isNotEmpty) {
              _fitMapToStores(controller, stores, userPosition);
            }
          },
          initialCameraPosition: cameraPosition,
          markers: markers,
          myLocationEnabled: true, // Always enable to show blue dot
          myLocationButtonEnabled: false, // We have our own custom button
          zoomControlsEnabled: false, // We have custom zoom controls
          mapToolbarEnabled: false,
          compassEnabled: true,
          rotateGesturesEnabled: true,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          tiltGesturesEnabled: true,
          mapType: MapType.normal,
          onTap: (_) {
            // Hide store details when tapping on empty map area
            if (_selectedStore != null) {
              setState(() {
                _selectedStore = null;
              });
            }
            // Hide search bar when tapping on map
            if (_isSearchVisible) {
              setState(() {
                _isSearchVisible = false;
              });
            }
          },
          onCameraMove: (CameraPosition position) {
            // Optional: Handle camera movement for real-time updates
          },
        );
      },
    );
  }

  // Helper method to fit map bounds to show all stores
  void _fitMapToStores(GoogleMapController controller, List<Store> stores, Position? userPosition) {
    if (stores.isEmpty) return;

    double minLat = stores.first.latitude;
    double maxLat = stores.first.latitude;
    double minLng = stores.first.longitude;
    double maxLng = stores.first.longitude;

    // Find bounds of all stores
    for (final store in stores) {
      minLat = math.min(minLat, store.latitude);
      maxLat = math.max(maxLat, store.latitude);
      minLng = math.min(minLng, store.longitude);
      maxLng = math.max(maxLng, store.longitude);
    }

    // Include user position in bounds if available
    if (userPosition != null) {
      minLat = math.min(minLat, userPosition.latitude);
      maxLat = math.max(maxLat, userPosition.latitude);
      minLng = math.min(minLng, userPosition.longitude);
      maxLng = math.max(maxLng, userPosition.longitude);
    }

    // Add padding to bounds
    const padding = 0.01; // Roughly 1km
    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;

    // Animate camera to fit bounds
    Future.delayed(const Duration(milliseconds: 500), () {
      controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          100.0, // padding
        ),
      );
    });
  }

  Widget _buildTopControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Back button
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  // Safely navigate back with proper iOS-style animation
                  try {
                    if (Navigator.of(context).canPop()) {
                      // Use default pop which will automatically reverse the slide-away transition
                      Navigator.of(context).pop();
                    } else {
                      // If can't pop, navigate to home screen with slide-away transition
                      Navigator.of(context).pushReplacement(
                        SlideAwayRoute(page: const MainScreen()),
                      );
                    }
                  } catch (e) {
                    debugPrint('Navigation error: $e');
                    // Force navigation to home as fallback
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  }
                },
                icon: const Icon(Icons.chevron_left, size: 28),
              ),
            ),

            const Spacer(),

            // Search button
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _isSearchVisible = !_isSearchVisible;
                  });
                },
                icon: Icon(
                  _isSearchVisible ? Icons.close : Icons.search,
                  color: AppColors.primaryText,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // My location button
            Consumer<LocationProvider>(
              builder: (context, locationProvider, child) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _centerOnUserLocation, // Always allow tapping - method will handle permission/location logic
                    icon: Icon(
                      Icons.my_location,
                      color: locationProvider.hasLocationPermission
                          ? AppColors.themeRed
                          : AppColors.secondaryText,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingSearchBar() {
    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: '搜索无人商店名称或地址',
            hintStyle: AppTextStyles.bodySmall.copyWith(
              color: AppColors.secondaryText,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: AppColors.themeRed,
              size: 20,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    icon: Icon(
                      Icons.clear,
                      color: AppColors.secondaryText,
                      size: 20,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  // Handle search functionality
  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      // Show all stores when search is cleared
      setState(() {});
      return;
    }

    final stores = MockDataService.getUnmannedStores();
    final matchingStores = stores.where((store) =>
      store.name.toLowerCase().contains(query.toLowerCase()) ||
      store.address.toLowerCase().contains(query.toLowerCase())
    ).toList();

    if (matchingStores.isNotEmpty) {
      // Focus map on first matching store
      final firstMatch = matchingStores.first;
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(firstMatch.latitude, firstMatch.longitude),
            zoom: 16.0,
          ),
        ),
      );

      // Show store details for first match
      setState(() {
        _selectedStore = firstMatch;
      });
    }
  }

  Widget _buildStoreDetailsSheet() {
    if (_selectedStore == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () {}, // Prevent tap-through to map
        child: Container(
          // ADDED: A max-height constraint to prevent the sheet from being too tall,
          // while still allowing it to fit its content.
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6, // Max 60% of screen height
          ),
          // REMOVED: The fixed height property is gone. The height is now intrinsic.
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false, // Correct: disables top safe area padding
            child: Column(
              // IMPORTANT: This makes the sheet's height wrap its content.
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar (non-scrolling part)
                Padding(
                  padding: EdgeInsets.only(
                    top: ResponsiveUtils.getResponsiveSpacing(context, 8),
                    bottom: ResponsiveUtils.getResponsiveSpacing(context, 4),
                  ),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),

                // All content is now in a Flexible, scrollable container
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        ResponsiveUtils.getResponsiveSpacing(context, 20),
                        ResponsiveUtils.getResponsiveSpacing(context, 16),
                        ResponsiveUtils.getResponsiveSpacing(context, 20),
                        ResponsiveUtils.getResponsiveSpacing(context, 24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Store info header
                          Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.lightRed,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.store,
                                  color: AppColors.themeRed,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedStore!.name,
                                      style: AppTextStyles.responsiveMajorHeader(context).copyWith(
                                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.lightRed,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '无人门店',
                                        style: AppTextStyles.responsiveBodySmall(context).copyWith(
                                          color: AppColors.themeRed,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  _mapController?.animateCamera(
                                    CameraUpdate.newCameraPosition(
                                      CameraPosition(
                                        target: LatLng(
                                          _selectedStore!.latitude,
                                          _selectedStore!.longitude,
                                        ),
                                        zoom: 17.0,
                                      ),
                                    ),
                                  );
                                },
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightRed,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.center_focus_strong,
                                    color: AppColors.themeRed,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 20)),
                          // Address and distance info
                          Container(
                            padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context, 16)),
                            decoration: BoxDecoration(
                              color: AppColors.lightBackground,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: AppColors.themeRed,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _selectedStore!.address,
                                        style: AppTextStyles.responsiveBody(context),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 12)),
                                Consumer<LocationProvider>(
                                  builder: (context, locationProvider, child) {
                                    final distance = locationProvider.getFormattedDistanceToStore(_selectedStore!);
                                    final walkingTime = locationProvider.getFormattedWalkingTimeToStore(_selectedStore!);
                                    if (distance != null && walkingTime != null) {
                                      return Row(
                                        children: [
                                          Icon(
                                            Icons.directions_walk,
                                            color: AppColors.themeRed,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '$distance • $walkingTime',
                                            style: AppTextStyles.responsiveBody(context).copyWith(
                                              color: AppColors.themeRed,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 24)),
                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedStore = null;
                                    });
                                  },
                                  icon: const Icon(Icons.close),
                                  label: const Text('关闭'),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      vertical: ResponsiveUtils.getResponsiveSpacing(context, 14),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 16)),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _setAsMainStore(_selectedStore!);
                                  },
                                  icon: const Icon(Icons.home),
                                  label: const Text('设置为主店'),
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      vertical: ResponsiveUtils.getResponsiveSpacing(context, 14),
                                    ),
                                    backgroundColor: AppColors.themeRed,
                                    foregroundColor: AppColors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Set selected store as main store for order pickup
  void _setAsMainStore(Store store) {
    // Update the location provider with the selected main store
    final locationProvider = context.read<LocationProvider>();
    locationProvider.setMainStore(store);

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已设置 ${store.name} 为主店'),
        backgroundColor: AppColors.themeRed,
        duration: const Duration(seconds: 2),
      ),
    );

    // Close store details
    setState(() {
      _selectedStore = null;
    });
  }

  void _centerOnUserLocation() async {
    final locationProvider = context.read<LocationProvider>();

    debugPrint('_centerOnUserLocation called - hasPermission: ${locationProvider.hasLocationPermission}, controller: $_mapController');

    // First try to get fresh location if we don't have permission
    if (!locationProvider.hasLocationPermission) {
      debugPrint('No location permission, requesting...');
      final granted = await locationProvider.requestLocationPermission();
      if (!granted) {
        debugPrint('Location permission denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('请在设置中允许位置权限，然后重新打开应用'),
              backgroundColor: AppColors.themeRed,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: '设置',
                textColor: Colors.white,
                onPressed: () {
                  // This will open the app settings
                  openAppSettings();
                },
              ),
            ),
          );
        }
        return;
      }
    }

    // Try to refresh location if we don't have a current position
    if (locationProvider.currentPosition == null) {
      debugPrint('No current position, refreshing location...');
      await locationProvider.updateLocation();
    }

    final userPosition = locationProvider.currentPosition;

    if (userPosition != null && _mapController != null) {
      debugPrint('Centering map on user location: ${userPosition.latitude}, ${userPosition.longitude}');

      try {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(userPosition.latitude, userPosition.longitude),
              zoom: 17.0,
            ),
          ),
        );
        debugPrint('Successfully centered map on user location');
      } catch (e) {
        debugPrint('Error animating camera: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('地图定位失败'),
              backgroundColor: AppColors.themeRed,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      debugPrint('Cannot center on user location: position=$userPosition, controller=$_mapController');

      // Show feedback to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('无法获取当前位置'),
            backgroundColor: AppColors.themeRed,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

}
