import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flMap;
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final flMap.MapController _mapController = flMap.MapController();

  final LatLng _initialPosition = const LatLng(21.0167, 105.7839);
  final mb.Position _initialPositionMapBox = mb.Position(105.7839, 21.0167);

  final List<LatLng> _driverPositions = [
    const LatLng(21.0180, 105.7850),
    const LatLng(21.0150, 105.7820),
    const LatLng(21.0195, 105.7815),
  ];

  bool isSwap = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Visibility(
            visible: !isSwap,
            child: flMap.FlutterMap(
              mapController: _mapController,
              options: flMap.MapOptions(
                initialCenter: _initialPosition,
                initialZoom: 15.0,
                maxZoom: 18.0,
                minZoom: 5.0,
              ),
              children: [
                flMap.TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.delivery_app',
                ),

                flMap.MarkerLayer(
                  markers: [
                    flMap.Marker(
                      point: _initialPosition,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 32,
                      ),
                    ),

                    ..._driverPositions.map(
                      (pos) => flMap.Marker(
                        point: pos,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.directions_bike,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Visibility(
            visible: isSwap,
            child: mb.MapWidget(
              viewport: mb.CameraViewportState(
                center: mb.Point(coordinates: _initialPositionMapBox),
                zoom: 15.0,
              ),
              styleUri: mb.MapboxStyles.MAPBOX_STREETS,
            ),
          ),

          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'btn_gps',
              backgroundColor: Colors.white,
              elevation: 4,
              shape: const CircleBorder(),
              onPressed: () {
                setState(() {
                  isSwap = !isSwap;
                });
              },
              child: const Icon(Icons.swap_horiz, color: Colors.black87),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    'Bạn muốn đi đâu?',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
