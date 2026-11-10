import 'package:delivery_app/core/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapboxMapView extends StatefulWidget {
  const MapboxMapView({
    super.key,
    required this.routePoints,
    required this.pickup,
    required this.destination,
    required this.driverLocation,
    required this.initialLocation,
    this.cameraTarget,
    this.cameraRequestId = 0,
  });

  final List<LatLng> routePoints;
  final LatLng? pickup;
  final LatLng? destination;
  final LatLng? driverLocation;
  final LatLng initialLocation;

  // Vị trí MapPage muốn camera di chuyển tới.
  final LatLng? cameraTarget;

  // Tăng mỗi lần gọi move camera, kể cả khi target không đổi.
  final int cameraRequestId;

  @override
  State<MapboxMapView> createState() => _MapboxMapViewState();
}

class _MapboxMapViewState extends State<MapboxMapView> {
  MapboxMap? _mapboxMap;

  PolylineAnnotationManager? _routeManager;
  CircleAnnotationManager? _markerManager;

  bool _styleLoaded = false;

  @override
  void didUpdateWidget(covariant MapboxMapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_styleLoaded) return;

    if (!listEquals(oldWidget.routePoints, widget.routePoints)) {
      _drawRoute();
    }

    if (oldWidget.pickup != widget.pickup ||
        oldWidget.destination != widget.destination ||
        oldWidget.driverLocation != widget.driverLocation) {
      _drawMarkers();
    }

    if (oldWidget.cameraRequestId != widget.cameraRequestId &&
        widget.cameraTarget != null) {
      _moveCamera(widget.cameraTarget!);
    }
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData event) async {
    final map = _mapboxMap;
    if (map == null) return;

    _routeManager = await map.annotations.createPolylineAnnotationManager();

    _markerManager = await map.annotations.createCircleAnnotationManager();

    if (!mounted) return;

    _styleLoaded = true;

    // Ưu tiên cameraTarget nếu MapPage đã yêu cầu di chuyển.
    final initialTarget = widget.cameraTarget ?? widget.initialLocation;

    await map.setCamera(
      CameraOptions(
        center: Point(
          coordinates: Position(
            initialTarget.longitude,
            initialTarget.latitude,
          ),
        ),
        zoom: widget.cameraTarget != null ? 15 : 14,
      ),
    );

    await _drawRoute();
    await _drawMarkers();
  }

  Future<void> _drawRoute() async {
    final manager = _routeManager;
    if (!_styleLoaded || manager == null) return;

    await manager.deleteAll();

    if (widget.routePoints.length < 2) return;

    final coordinates = widget.routePoints.map((point) {
      return Position(point.longitude, point.latitude);
    }).toList();

    debugPrint('------- load : ${coordinates}');
    await manager.create(
      PolylineAnnotationOptions(
        geometry: LineString(coordinates: coordinates),
        lineColor: AppColors.blue.value,
        lineWidth: 6,
        lineOpacity: 1,
        lineJoin: LineJoin.ROUND,
        lineBorderColor: Colors.white.value,
        lineBorderWidth: 2,
      ),
    );
  }

  Future<void> _drawMarkers() async {
    final manager = _markerManager;
    if (!_styleLoaded || manager == null) return;

    await manager.deleteAll();

    final options = <CircleAnnotationOptions>[];

    void addMarker(LatLng? location, Color color) {
      if (location == null) return;

      options.add(
        CircleAnnotationOptions(
          geometry: Point(
            coordinates: Position(location.longitude, location.latitude),
          ),
          circleRadius: 9,
          circleColor: color.value,
          circleStrokeColor: Colors.white.value,
          circleStrokeWidth: 3,
        ),
      );
    }

    addMarker(widget.pickup, AppColors.blue);
    addMarker(widget.destination, AppColors.text);
    addMarker(widget.driverLocation, Colors.orange);

    if (options.isNotEmpty) {
      await manager.createMulti(options);
    }
  }

  Future<void> _moveCamera(LatLng target) async {
    final map = _mapboxMap;
    if (!_styleLoaded || map == null) return;

    await map.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(target.longitude, target.latitude)),
        zoom: 15,
      ),
      MapAnimationOptions(duration: 700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      key: const ValueKey('mapbox-map'),
      styleUri: MapboxStyles.STANDARD,
      viewport: CameraViewportState(
        center: Point(
          coordinates: Position(
            widget.initialLocation.longitude,
            widget.initialLocation.latitude,
          ),
        ),
        zoom: 14,
      ),
      onMapCreated: _onMapCreated,
      onStyleLoadedListener: _onStyleLoaded,
    );
  }
}
