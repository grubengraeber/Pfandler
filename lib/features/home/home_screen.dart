import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/map_clustering.dart';
import '../../models/store.dart';
import '../../navigation/main_nav_shell.dart';
import '../../services/location_service.dart';

// Store search state
final searchQueryProvider = StateProvider<String>((ref) => '');
final isSearchingProvider = StateProvider<bool>((ref) => false);

// Current map center provider for nearby stores
final mapCenterProvider =
    StateProvider<LatLng>((ref) => LatLng(48.2082, 16.3738));

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

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final isSearching = ref.watch(isSearchingProvider);
    final selectedStore = ref.watch(selectedStoreProvider);
    final mapCenter = ref.watch(mapCenterProvider);
    final theme = Theme.of(context);

    // Use search results if searching, otherwise use nearby stores based on map center
    final storesAsync = isSearching && searchQuery.isNotEmpty
        ? ref.watch(searchStoresProvider(searchQuery))
        : ref.watch(nearbyStoresProvider(mapCenter));

    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search stores...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
                onSubmitted: (_) {
                  ref.read(isSearchingProvider.notifier).state = false;
                },
              )
            : const Text('Find Return Locations'),
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
              icon: const Icon(CupertinoIcons.location),
              onPressed: () {
                // Move to Vienna as default location
                // In a real app, you'd get user's current location
                final newLocation = LatLng(48.2082, 16.3738);
                _mapController.move(newLocation, 13);
                // Update the map center provider
                ref.read(mapCenterProvider.notifier).state = newLocation;
              },
            ),
          ],
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(48.2082, 16.3738), // Vienna - default start
          initialZoom: 12, // City-level zoom
          minZoom: 2, // Allow world view
          maxZoom: 18,
          cameraConstraint: CameraConstraint.contain(
            bounds: LatLngBounds(
              LatLng(-85, -180), // Practical world bounds (avoid poles)
              LatLng(85, 180),
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
                    final store = cluster.singleStore;
                    final isSelected = selectedStore?.id == store.id;
                    return Marker(
                      width: isSelected ? 50 : 40,
                      height: isSelected ? 50 : 40,
                      point: store.location,
                      child: GestureDetector(
                        onTap: () {
                          ref.read(selectedStoreProvider.notifier).state = store;
                          _showStoreDetails(context, store);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : _getChainColor(store.chain),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
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
                            child: Icon(
                              CupertinoIcons.location_solid,
                              color: Colors.white,
                              size: isSelected ? 24 : 20,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                }).toList(),
              );
            },
            loading: () => const MarkerLayer(markers: []),
            error: (error, stack) => const MarkerLayer(markers: []),
          ),
        ],
      ),
    );
  }

  void _showStoreDetails(BuildContext context, Store store) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.lg),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _getChainColor(store.chain)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.md),
                          ),
                          child: Icon(
                            CupertinoIcons.location_solid,
                            color: _getChainColor(store.chain),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                store.name,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                store.chain.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Store address
                    Text(
                      'Address',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.location,
                            color: theme.colorScheme.primary,
                            size: 16,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              store.address,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Accepted types
                    Text(
                      'Accepted Deposit Types',
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
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openGoogleMaps(store),
                            icon: const Icon(CupertinoIcons.map),
                            label: const Text('Get Directions'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(CupertinoIcons.cube_box),
                            label: const Text('Return Here'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMapTileUrl(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (isDarkMode) {
      // CartoDB Dark Matter - Beautiful dark theme
      return 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_all/{z}/{x}/{y}{r}.png';
    } else {
      // CartoDB Positron - Clean light theme
      return 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}{r}.png';
    }
  }

  void _showClusterDetails(BuildContext context, ClusterMarker cluster) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.lg),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        cluster.storeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cluster.storeCount} stores in this area',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Tap a store to view details',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: cluster.stores.length,
                itemBuilder: (context, index) {
                  final store = cluster.stores[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getChainColor(store.chain).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.xs),
                        ),
                        child: Icon(
                          CupertinoIcons.location_solid,
                          color: _getChainColor(store.chain),
                          size: 20,
                        ),
                      ),
                      title: Text(store.name),
                      subtitle: Text('${store.chain.name} • ${store.address}'),
                      trailing: IconButton(
                        icon: const Icon(CupertinoIcons.map),
                        onPressed: () => _openGoogleMaps(store),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(selectedStoreProvider.notifier).state = store;
                        _showStoreDetails(context, store);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openGoogleMaps(Store store) async {
    final lat = store.location.latitude;
    final lng = store.location.longitude;
    final query = Uri.encodeComponent('${store.name}, ${store.address}');
    
    // Try different URL schemes in order of preference
    final urls = [
      'comgooglemaps://?q=$lat,$lng($query)', // Google Maps app
      'maps://maps.google.com/maps?q=$lat,$lng($query)', // iOS Maps with Google
      'https://maps.google.com/maps?q=$lat,$lng($query)', // Web fallback
    ];
    
    for (final urlString in urls) {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    
    // Final fallback - show error
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open maps application'),
        ),
      );
    }
  }

  Color _getChainColor(StoreChain chain) {
    switch (chain) {
      case StoreChain.billa:
      case StoreChain.billaPlus:
        return const Color(0xFFFFE400); // Billa yellow
      case StoreChain.spar:
      case StoreChain.eurospar:
      case StoreChain.interspar:
        return const Color(0xFF00823C); // Spar green
      case StoreChain.hofer:
        return const Color(0xFF1E4B90); // Hofer blue
      case StoreChain.lidl:
        return const Color(0xFF0050AA); // Lidl blue
      case StoreChain.penny:
        return const Color(0xFFE30613); // Penny red
      case StoreChain.merkur:
        return const Color(0xFF82BE00); // Merkur green
      case StoreChain.mpreis:
        return const Color(0xFFE4002B); // MPreis red
      default:
        return AppColors.primaryLight;
    }
  }
}
