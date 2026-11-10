import 'package:delivery_app/features/app_view_model.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fl;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'map_state.dart';
import 'map_view_model.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final fl.MapController _mapController = fl.MapController();
  bool _mapReady = false;
  bool _hasTripPickup = false;
  LatLng? _pendingMapTarget;

  final TextEditingController _pickupController = TextEditingController(
    text: 'Cầu đông trù',
  );

  final TextEditingController _destinationController = TextEditingController(
    text: 'Cầu long biên',
  );

  void _moveMap(LatLng target) {
    if (!_mapReady) {
      _pendingMapTarget = target;
      return;
    }

    _mapController.move(target, 15);
  }

  void _moveMapToPickup(LatLng pickup) {
    _hasTripPickup = true;
    _pendingMapTarget = pickup;
    _moveMap(pickup);
  }

  Future<void> _moveMapToCurrentLocation(Role role) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      final latestState = ref.read(mapViewModelProvider(role));
      if (_hasTripPickup || latestState.pickup != null) {
        return;
      }
      final currentLocation = LatLng(position.latitude, position.longitude);
      _moveMap(currentLocation);
    } catch (e) {
      debugPrint('Không thể lấy vị trí hiện tại: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final role = ref.read(appViewModelProvider).role;
      if (role == null) return;
      if (role == Role.customer) {
        final provider = mapViewModelProvider(role);
        await ref.read(provider.notifier).restoreActiveCustomerTrip();
        if (!mounted) return;
        final state = ref.read(provider);
        if (state.pickup != null) {
          _moveMapToPickup(state.pickup!);
        } else {
          await _moveMapToCurrentLocation(role);
        }
      } else {
        await _moveMapToCurrentLocation(role);
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appViewModelProvider);
    final role = appState.role;

    if (role == null) {
      return const Scaffold(
        body: Center(child: Text('Không xác định được vai trò')),
      );
    }

    final provider = mapViewModelProvider(role);
    final state = ref.watch(provider);
    ref.listen<MapState>(provider, (previous, next) {
      final pickup = next.pickup;

      if (pickup == null) return;

      final pickupChanged = previous?.pickup != pickup;

      final tripChanged =
          next.tripId != null && previous?.tripId != next.tripId;

      if (pickupChanged || tripChanged) {
        _moveMapToPickup(pickup);
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(state),

          if (role == Role.customer)
            _buildCustomerPanel(
              state,
              onBook: () {
                ref
                    .read(provider.notifier)
                    .setAddresses(
                      pickup: _pickupController.text,
                      destination: _destinationController.text,
                    );

                ref.read(provider.notifier).bookTrip();
              },
              onCancel: () {
                ref.read(provider.notifier).cancelTrip();
              },
            ),

          if (role == Role.driver)
            _buildDriverPanel(
              state,
              onOnline: () {
                ref.read(provider.notifier).goOnline();
              },
              onAccept: (tripId) {
                ref.read(provider.notifier).acceptTrip(tripId);
              },
              onStart: () {
                ref.read(provider.notifier).startTrip();
              },
              onComplete: () {
                ref.read(provider.notifier).completeTrip();
              },
              onOffline: () {
                ref.read(provider.notifier).goOffline();
              },
            ),

          if (state.errorMessage != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap(MapState state) {
    final markers = <fl.Marker>[];

    if (state.pickup != null) {
      markers.add(
        fl.Marker(
          point: state.pickup!,
          width: 45,
          height: 45,
          child: const Icon(Icons.location_on, color: Colors.green, size: 40),
        ),
      );
    }

    if (state.destination != null) {
      markers.add(
        fl.Marker(
          point: state.destination!,
          width: 45,
          height: 45,
          child: const Icon(Icons.flag, color: Colors.red, size: 38),
        ),
      );
    }

    if (state.driverLocation != null) {
      markers.add(
        fl.Marker(
          point: state.driverLocation!,
          width: 45,
          height: 45,
          child: const Icon(Icons.directions_car, color: Colors.blue, size: 38),
        ),
      );
    }

    return fl.FlutterMap(
      mapController: _mapController,
      options: fl.MapOptions(
        initialZoom: 14,
        minZoom: 5,
        maxZoom: 18,
        onMapReady: () {
          _mapReady = true;

          final target = _pendingMapTarget;
          if (target != null) {
            _pendingMapTarget = null;
            _mapController.move(target, 15);
          }
        },
      ),

      children: [
        fl.TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.delivery_app',
        ),
        if (state.route != null)
          fl.PolylineLayer(
            polylines: [
              fl.Polyline(
                points: state.route!.points,
                strokeWidth: 5,
                color: Colors.blue,
              ),
            ],
          ),
        fl.MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildCustomerPanel(
    MapState state, {
    required VoidCallback onBook,
    required VoidCallback onCancel,
  }) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 12,
      right: 12,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _pickupController,
                decoration: const InputDecoration(
                  labelText: 'Điểm đón',
                  prefixIcon: Icon(Icons.my_location),
                ),
              ),
              TextField(
                controller: _destinationController,
                decoration: const InputDecoration(
                  labelText: 'Điểm đến',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 12),
              if (state.tripStatus == MapTripStatus.idle ||
                  state.tripStatus == MapTripStatus.cancelled)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onBook,
                    child: const Text('Đặt chuyến'),
                  ),
                ),
              if (state.tripStatus == MapTripStatus.booking)
                const Text('Đang tính tuyến đường...'),
              if (state.tripStatus == MapTripStatus.waitingForDriver)
                const Text('Đang tìm tài xế...'),
              if (state.tripStatus == MapTripStatus.driverComing)
                const Text('Tài xế đang đến điểm đón'),
              if (state.tripStatus == MapTripStatus.goingToDestination)
                const Text('Đang trên đường đến điểm đến'),
              if (state.tripStatus == MapTripStatus.completed)
                const Text('Chuyến đi đã hoàn thành'),
              if (state.tripId != null &&
                  state.tripStatus != MapTripStatus.completed &&
                  state.tripStatus != MapTripStatus.cancelled)
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Hủy chuyến'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverPanel(
    MapState state, {
    required VoidCallback onOnline,
    required VoidCallback onOffline,
    required ValueChanged<int> onAccept,
    required VoidCallback onStart,
    required VoidCallback onComplete,
  }) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 20,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.tripId == null) ...[
                const Text(
                  'Các chuyến đang chờ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onOnline,
                        child: const Text('Bật online'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onOffline,
                        child: const Text('Tắt online'),
                      ),
                    ),
                  ],
                ),
                if (state.pendingTrips.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Chưa có chuyến nào'),
                  ),
                ...state.pendingTrips.map((trip) {
                  final tripId = (trip['trip_id'] as num).toInt();

                  return ListTile(
                    title: Text('Chuyến #$tripId'),
                    subtitle: Text(
                      'Điểm đón: '
                      '${trip['trip_latitude']}, '
                      '${trip['trip_longitude']}',
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => onAccept(tripId),
                      child: const Text('Nhận'),
                    ),
                  );
                }),
              ] else ...[
                Text('Đang thực hiện chuyến #${state.tripId}'),
                if (state.tripStatus == MapTripStatus.driverComing)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onStart,
                      child: const Text('Đã đón khách - Bắt đầu chuyến'),
                    ),
                  ),
                if (state.tripStatus == MapTripStatus.goingToDestination)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onComplete,
                      child: const Text('Hoàn thành chuyến'),
                    ),
                  ),
                if (state.tripStatus == MapTripStatus.completed)
                  const Text('Chuyến đi đã hoàn thành'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
