import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/map_clustering.dart';
import '../../l10n/app_localizations.dart';
import '../../models/store.dart';
import '../../navigation/main_nav_shell.dart';
import '../../services/location_service.dart';

// Store search state
final searchQueryProvider = StateProvider<String>((ref) => '');
final isSearchingProvider = StateProvider<bool>((ref) => false);

// Current map center provider for nearby stores (Vienna as default)
final mapCenterProvider =
    StateProvider<LatLng>((ref) => const LatLng(48.2082, 16.3738));

// User's current location provider
final userLocationProvider = StateProvider<LatLng?>((ref) => null);

// Selected store provider
final selectedStoreProvider = StateProvider<Store?>((ref) => null);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final MapController _mapController = MapController();
  double _currentZoom = 12.0;
  Size _mapSize = const Size(400, 600);
  bool _isLoadingLocation = false;
  
  @override
  void initState() {
    super.initState();
    // Try to get user location on startup
    _getCurrentLocation(moveMap: true);
  }

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled. Please enable them.'),
          ),
        );
      }
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are denied'),
            ),
          );
        }
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Location permissions are permanently denied, please enable them in settings.',
            ),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => Geolocator.openAppSettings(),
            ),
          ),
        );
      }
      return false;
    }

    return true;
  }

  Future<void> _getCurrentLocation({bool moveMap = false}) async {
    if (_isLoadingLocation) return;
    
    setState(() => _isLoadingLocation = true);
    
    try {
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: true,
      );

      final userLocation = LatLng(position.latitude, position.longitude);
      
      // Update user location provider
      ref.read(userLocationProvider.notifier).state = userLocation;
      
      if (moveMap) {
        // Move map to user location
        _mapController.move(userLocation, 13);
        // Update the map center provider
        ref.read(mapCenterProvider.notifier).state = userLocation;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location updated'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final isSearching = ref.watch(isSearchingProvider);
    final selectedStore = ref.watch(selectedStoreProvider);
    final mapCenter = ref.watch(mapCenterProvider);
    final userLocation = ref.watch(userLocationProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // Use search results if searching, otherwise use nearby stores based on map center
    final storesAsync = isSearching && searchQuery.isNotEmpty
        ? ref.watch(searchStoresProvider(searchQuery))
        : ref.watch(nearbyStoresProvider(mapCenter));

    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText:
                      l10n?.translate('searchStores') ?? 'Search stores...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
                onSubmitted: (_) {
                  ref.read(isSearchingProvider.notifier).state = false;
                },
              )
            : Text(l10n?.translate('findReturnLocations') ??
                'Find Return Locations'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.bars),
          onPressed: () {
            MainNavShell.scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          if (isSearching)
            IconButton(
              icon: const Icon(CupertinoIcons.xmark),
              onPressed: () {
                ref.read(isSearchingProvider.notifier).state = false;
                ref.read(searchQueryProvider.notifier).state = '';
              },
            )
          else ...[
            IconButton(
              icon: const Icon(CupertinoIcons.search),
              onPressed: () {
                ref.read(isSearchingProvider.notifier).state = true;
              },
            ),
            IconButton(
              icon: _isLoadingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      userLocation != null
                          ? CupertinoIcons.location_fill
                          : CupertinoIcons.location,
                    ),
              onPressed: _isLoadingLocation
                  ? null
                  : () => _getCurrentLocation(moveMap: true),
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userLocation ?? const LatLng(48.2082, 16.3738), // Use user location or Vienna as default
              initialZoom: 12, // City-level zoom
              minZoom: 2, // Allow world view
              maxZoom: 18,
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  const LatLng(-85, -180), // Practical world bounds (avoid poles)
                  const LatLng(85, 180),
                ),
              ),
              onTap: (_, __) {
                ref.read(selectedStoreProvider.notifier).state = null;
              },
              onPositionChanged: (position, hasGesture) {
                // Update map center and zoom when user moves the map
                if (hasGesture && position.center != null) {
                  ref.read(mapCenterProvider.notifier).state = position.center!;
                  _currentZoom = position.zoom ?? _currentZoom;
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _getMapTileUrl(context),
                subdomains: const ['a', 'b', 'c', 'd'],
                additionalOptions: const {
                  'attribution': '© CartoDB © OpenStreetMap contributors',
                },
                userAgentPackageName: 'com.pfandler.app',
                maxZoom: 19,
                retinaMode: true,
              ),
              
              // User location marker
              if (userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80,
                      height: 80,
                      point: userLocation,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulsing circle animation
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                          ),
                          // Accuracy circle
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                          // Center dot
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              
              // Store markers
              storesAsync.when(
                data: (stores) {
                  // Get map size for clustering calculations
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final renderBox = context.findRenderObject() as RenderBox?;
                    if (renderBox != null) {
                      _mapSize = renderBox.size;
                    }
                  });

                  // Cluster the stores
                  final clusters = MapClustering.clusterStores(
                    stores,
                    _currentZoom,
                    mapCenter,
                    _mapSize.width,
                    _mapSize.height,
                  );

                  return MarkerLayer(
                    markers: clusters.map((cluster) {
                      if (cluster.isCluster) {
                        // Cluster marker
                        return Marker(
                          width: 60,
                          height: 60,
                          point: cluster.location,
                          child: GestureDetector(
                            onTap: () {
                              _showClusterDetails(context, cluster);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  cluster.storeCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      } else {
                        // Single store marker
                        final store = cluster.stores.first;
                        final isSelected = selectedStore?.id == store.id;

                        return Marker(
                          width: isSelected ? 70 : 50,
                          height: isSelected ? 70 : 50,
                          point: cluster.location,
                          child: GestureDetector(
                            onTap: () {
                              ref.read(selectedStoreProvider.notifier).state =
                                  store;
                              _showStoreDetails(context, store);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : AppColors.success,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: isSelected ? 3 : 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: isSelected ? 12 : 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                CupertinoIcons.location_solid,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        );
                      }
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Text('Error loading stores: $error'),
                ),
              ),
            ],
          ),
          
          // Floating action button for current location
          Positioned(
            bottom: AppSpacing.xl,
            right: AppSpacing.lg,
            child: FloatingActionButton(
              onPressed: _isLoadingLocation
                  ? null
                  : () => _getCurrentLocation(moveMap: true),
              backgroundColor: theme.colorScheme.primary,
              child: _isLoadingLocation
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                  : Icon(
                      userLocation != null
                          ? CupertinoIcons.location_fill
                          : CupertinoIcons.location,
                      color: Colors.white,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMapTileUrl(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      // Dark mode map tiles - CartoDB Dark Matter
      return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png';
    } else {
      // Light mode map tiles - CartoDB Positron
      return 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png';
    }
  }

  void _showStoreDetails(BuildContext context, Store store) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.xl),
          ),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.35,
          minChildSize: 0.25,
          maxChildSize: 0.75,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Store info
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                      ),
                      child: Icon(
                        CupertinoIcons.shopping_cart,
                        color: theme.colorScheme.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            store.chain.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Address
                _buildInfoRow(
                  context,
                  CupertinoIcons.location,
                  store.address,
                ),

                if (store.hours != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildInfoRow(
                    context,
                    CupertinoIcons.clock,
                    store.hours!.toString(),
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),

                // Accepted types
                Text(
                  l10n?.translate('acceptedTypes') ?? 'Accepted Types',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: store.acceptedTypes.map((type) {
                    return Chip(
                      label: Text(type.label),
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                        color: theme.colorScheme.primary,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openDirections(store),
                        icon: const Icon(CupertinoIcons.map),
                        label: Text(
                            l10n?.translate('getDirections') ?? 'Directions'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(AppSpacing.md),
                        ),
                      ),
                    ),
                    if (store.phoneNumber != null) ...[
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _callStore(store),
                          icon: const Icon(CupertinoIcons.phone),
                          label: Text(l10n?.translate('call') ?? 'Call'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(AppSpacing.md),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showClusterDetails(BuildContext context, ClusterMarker cluster) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.xl),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text(
              '${cluster.storeCount} ${l10n?.translate('stores') ?? 'Stores'}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // List of stores in cluster
            Expanded(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: cluster.stores.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final store = cluster.stores[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                      ),
                      child: Icon(
                        CupertinoIcons.shopping_cart,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: Text(store.name),
                    subtitle: Text(store.address),
                    trailing: const Icon(CupertinoIcons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(selectedStoreProvider.notifier).state = store;
                      _showStoreDetails(context, store);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Zoom in button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _mapController.move(cluster.location, _currentZoom + 2);
                },
                icon: const Icon(CupertinoIcons.zoom_in),
                label: Text(l10n?.translate('zoomIn') ?? 'Zoom In'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(AppSpacing.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Future<void> _openDirections(Store store) async {
    final userLocation = ref.read(userLocationProvider);
    String url;
    
    if (userLocation != null) {
      // If we have user location, create directions from current location
      url = 'https://www.google.com/maps/dir/${userLocation.latitude},${userLocation.longitude}/${store.location.latitude},${store.location.longitude}';
    } else {
      // Otherwise just show the store location
      url = 'https://www.google.com/maps/search/?api=1&query=${store.location.latitude},${store.location.longitude}';
    }
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    }
  }

  Future<void> _callStore(Store store) async {
    if (store.phoneNumber == null) return;

    final url = 'tel:${store.phoneNumber}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not make call')),
        );
      }
    }
  }
}

// Providers for stores
final nearbyStoresProvider =
    FutureProvider.family<List<Store>, LatLng>((ref, location) async {
  final locationService = ref.read(locationServiceProvider);
  return locationService.getNearbyLocations(
    lat: location.latitude,
    lng: location.longitude,
  );
});

final searchStoresProvider =
    FutureProvider.family<List<Store>, String>((ref, query) async {
  final locationService = ref.read(locationServiceProvider);
  return locationService.searchLocations(query);
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService(ref);
});