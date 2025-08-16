import 'dart:math' as math;
import 'dart:ui';
import 'package:latlong2/latlong.dart';
import '../../models/store.dart';

class ClusterMarker {
  final LatLng location;
  final List<Store> stores;
  final bool isCluster;

  ClusterMarker({
    required this.location,
    required this.stores,
    this.isCluster = false,
  });

  bool get isSingleStore => stores.length == 1;
  Store get singleStore => stores.first;
  int get storeCount => stores.length;
}

class MapClustering {
  static const double _clusterDistance = 50.0; // pixels
  
  /// Clusters stores based on their pixel distance on the map
  static List<ClusterMarker> clusterStores(
    List<Store> stores,
    double zoom,
    LatLng mapCenter,
    double mapWidth,
    double mapHeight,
  ) {
    if (stores.isEmpty) return [];
    
    // Don't cluster at high zoom levels
    if (zoom >= 15) {
      return stores.map((store) => ClusterMarker(
        location: store.location,
        stores: [store],
        isCluster: false,
      )).toList();
    }

    final List<ClusterMarker> clusters = [];
    final List<Store> processedStores = [];

    for (final store in stores) {
      if (processedStores.contains(store)) continue;

      final nearbyStores = <Store>[store];
      processedStores.add(store);

      // Find nearby stores within cluster distance
      for (final otherStore in stores) {
        if (processedStores.contains(otherStore)) continue;

        final distance = _calculatePixelDistance(
          store.location,
          otherStore.location,
          zoom,
          mapCenter,
          mapWidth,
          mapHeight,
        );

        if (distance <= _clusterDistance) {
          nearbyStores.add(otherStore);
          processedStores.add(otherStore);
        }
      }

      // Create cluster or single marker
      if (nearbyStores.length > 1) {
        // Calculate cluster center (centroid)
        final centerLat = nearbyStores.map((s) => s.location.latitude).reduce((a, b) => a + b) / nearbyStores.length;
        final centerLng = nearbyStores.map((s) => s.location.longitude).reduce((a, b) => a + b) / nearbyStores.length;
        
        clusters.add(ClusterMarker(
          location: LatLng(centerLat, centerLng),
          stores: nearbyStores,
          isCluster: true,
        ));
      } else {
        clusters.add(ClusterMarker(
          location: store.location,
          stores: [store],
          isCluster: false,
        ));
      }
    }

    return clusters;
  }

  /// Calculate pixel distance between two geographic points
  static double _calculatePixelDistance(
    LatLng point1,
    LatLng point2,
    double zoom,
    LatLng mapCenter,
    double mapWidth,
    double mapHeight,
  ) {
    // Convert lat/lng to pixel coordinates at current zoom level
    final point1Pixel = _latLngToPixel(point1, zoom, mapCenter, mapWidth, mapHeight);
    final point2Pixel = _latLngToPixel(point2, zoom, mapCenter, mapWidth, mapHeight);

    // Calculate Euclidean distance
    final dx = point1Pixel.dx - point2Pixel.dx;
    final dy = point1Pixel.dy - point2Pixel.dy;
    
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Convert lat/lng to pixel coordinates
  static Offset _latLngToPixel(
    LatLng latLng,
    double zoom,
    LatLng mapCenter,
    double mapWidth,
    double mapHeight,
  ) {
    const double tileSize = 256.0;
    final double scale = math.pow(2, zoom).toDouble();
    
    // Convert to world coordinates
    final worldX = (latLng.longitude + 180) / 360 * tileSize * scale;
    final worldY = (1 - math.log(math.tan(latLng.latitude * math.pi / 180) + 1 / math.cos(latLng.latitude * math.pi / 180)) / math.pi) / 2 * tileSize * scale;
    
    // Convert map center to world coordinates
    final centerWorldX = (mapCenter.longitude + 180) / 360 * tileSize * scale;
    final centerWorldY = (1 - math.log(math.tan(mapCenter.latitude * math.pi / 180) + 1 / math.cos(mapCenter.latitude * math.pi / 180)) / math.pi) / 2 * tileSize * scale;
    
    // Convert to screen coordinates
    final screenX = worldX - centerWorldX + mapWidth / 2;
    final screenY = worldY - centerWorldY + mapHeight / 2;
    
    return Offset(screenX, screenY);
  }
}