import 'dart:async';

import 'package:delivery_app/features/app_view_model.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:delivery_app/gen/assets.gen.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:delivery_app/core/theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fl;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'data/models/place_suggestion.dart';
import 'map_state.dart';
import 'map_view_model.dart';
import 'service/current_map_location_provider.dart';

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
  Offset _pendingMapOffset = Offset.zero;

  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  Timer? _suggestionTimer;
  Timer? _errorTimer;
  int _suggestionRequest = 0;
  int? _activeSearchField;
  bool _searchingPlaces = false;
  bool _searchedPlaces = false;
  bool _placeSearchFailed = false;
  List<PlaceSuggestion> _suggestions = const [];
  LatLng? _selectedPickupLocation;
  LatLng? _manualPickupLocationDraft;
  LatLng? _selectedDestinationLocation;
  bool _usingCurrentPickup = false;
  bool _locatingPickup = false;
  String _manualPickupDraft = '';
  int _pickupLocationRequest = 0;

  void _onAddressChanged(int field, String value) {
    if (field == 0) {
      _selectedPickupLocation = null;
      _manualPickupLocationDraft = null;
      _manualPickupDraft = value;
    } else {
      _selectedDestinationLocation = null;
    }
    ref
        .read(mapViewModelProvider(Role.customer).notifier)
        .setAddresses(
          pickup: _pickupController.text,
          destination: _destinationController.text,
        );
    _searchPlaces(field, value);
  }

  void _searchPlaces(int field, String value) {
    _suggestionTimer?.cancel();
    final request = ++_suggestionRequest;
    setState(() {
      _activeSearchField = field;
      _suggestions = const [];
      _searchingPlaces = false;
      _searchedPlaces = false;
      _placeSearchFailed = false;
    });
    if (value.trim().length < 3) return;
    _suggestionTimer = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted || request != _suggestionRequest) return;
      setState(() => _searchingPlaces = true);
      try {
        final results = await ref
            .read(mapViewModelProvider(Role.customer).notifier)
            .suggestPlaces(value);
        if (!mounted || request != _suggestionRequest) return;
        setState(() {
          _suggestions = results;
          _searchingPlaces = false;
          _searchedPlaces = true;
        });
      } catch (_) {
        if (!mounted || request != _suggestionRequest) return;
        setState(() {
          _searchingPlaces = false;
          _placeSearchFailed = true;
        });
      }
    });
  }

  void _selectPlace(int field, PlaceSuggestion place) {
    _suggestionTimer?.cancel();
    ++_suggestionRequest;
    setState(() {
      if (field == 0) {
        _pickupController.text = place.address;
        _selectedPickupLocation = place.location;
        _manualPickupLocationDraft = place.location;
        _manualPickupDraft = place.address;
      } else {
        _destinationController.text = place.address;
        _selectedDestinationLocation = place.location;
      }
      _activeSearchField = null;
      _suggestions = const [];
    });
    FocusScope.of(context).unfocus();
    ref
        .read(mapViewModelProvider(Role.customer).notifier)
        .setAddresses(
          pickup: _pickupController.text,
          destination: _destinationController.text,
        );
    _moveMap(place.location);
  }

  void _selectManualPickup() {
    ++_pickupLocationRequest;
    setState(() {
      _usingCurrentPickup = false;
      _locatingPickup = false;
      _selectedPickupLocation = _manualPickupLocationDraft;
      _pickupController.text = _manualPickupDraft;
    });
    ref
        .read(mapViewModelProvider(Role.customer).notifier)
        .setAddresses(
          pickup: _pickupController.text,
          destination: _destinationController.text,
        );
  }

  Future<void> _useCurrentPickup() async {
    if (_usingCurrentPickup || _locatingPickup) return;
    final request = ++_pickupLocationRequest;
    _manualPickupDraft = _pickupController.text;
    _manualPickupLocationDraft = _selectedPickupLocation;
    _suggestionTimer?.cancel();
    ++_suggestionRequest;
    FocusScope.of(context).unfocus();
    setState(() {
      _usingCurrentPickup = true;
      _locatingPickup = true;
      _activeSearchField = null;
      _suggestions = const [];
      _searchingPlaces = false;
      _selectedPickupLocation = null;
      _pickupController.clear();
    });
    ref
        .read(mapViewModelProvider(Role.customer).notifier)
        .setAddresses(pickup: '', destination: _destinationController.text);

    try {
      final location = await ref.read(currentMapLocationProvider)();
      if (!mounted || request != _pickupLocationRequest) return;
      final label =
          '${LocaleKeys.map_current_location_label.tr()} '
          '(${location.latitude.toStringAsFixed(5)}, '
          '${location.longitude.toStringAsFixed(5)})';
      setState(() {
        _locatingPickup = false;
        _selectedPickupLocation = location;
        _pickupController.text = label;
      });
      ref
          .read(mapViewModelProvider(Role.customer).notifier)
          .setAddresses(
            pickup: label,
            destination: _destinationController.text,
          );
      _moveMap(location);
      unawaited(_resolveCurrentPickupAddress(location, request));
    } catch (error) {
      if (!mounted || request != _pickupLocationRequest) return;
      setState(() {
        _usingCurrentPickup = false;
        _locatingPickup = false;
        _selectedPickupLocation = _manualPickupLocationDraft;
        _pickupController.text = _manualPickupDraft;
      });
      ref
          .read(mapViewModelProvider(Role.customer).notifier)
          .setAddresses(
            pickup: _manualPickupDraft,
            destination: _destinationController.text,
          );
      ref
          .read(mapViewModelProvider(Role.customer).notifier)
          .showLocationError(
            error is MapLocationException
                ? error.message
                : LocaleKeys.map_current_location_failed.tr(),
          );
    }
  }

  Future<void> _resolveCurrentPickupAddress(
    LatLng location,
    int request,
  ) async {
    try {
      final address = await ref
          .read(mapViewModelProvider(Role.customer).notifier)
          .reverseGeocode(location);
      if (!mounted ||
          request != _pickupLocationRequest ||
          !_usingCurrentPickup ||
          _selectedPickupLocation != location ||
          address == null ||
          address.trim().isEmpty) {
        return;
      }
      _pickupController.text = address;
      ref
          .read(mapViewModelProvider(Role.customer).notifier)
          .setAddresses(
            pickup: address,
            destination: _destinationController.text,
          );
    } catch (error) {
      debugPrint('Could not resolve current pickup address: $error');
    }
  }

  Widget _placeSuggestions(int field) {
    if (_activeSearchField != field ||
        (!_searchingPlaces && !_searchedPlaces && !_placeSearchFailed)) {
      return const SizedBox.shrink();
    }
    if (_searchingPlaces) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_placeSearchFailed || _suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          _placeSearchFailed
              ? LocaleKeys.map_place_search_failed.tr()
              : LocaleKeys.map_no_place_suggestions.tr(),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final place in _suggestions)
          ListTile(
            dense: true,
            leading: const Icon(Icons.place_outlined, color: AppColors.blue),
            title: Text(
              place.address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _selectPlace(field, place),
          ),
      ],
    );
  }

  Future<void> _confirmCancellation(Role role, VoidCallback onConfirm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleKeys.map_cancel_title.tr()),
        content: Text(
          role == Role.driver
              ? LocaleKeys.map_cancel_driver_message.tr()
              : LocaleKeys.map_cancel_customer_message.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocaleKeys.btn_cancel.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(LocaleKeys.map_cancel_trip.tr()),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) onConfirm();
  }

  void _moveMap(LatLng target, {Offset offset = Offset.zero}) {
    if (!_mapReady) {
      _pendingMapTarget = target;
      _pendingMapOffset = offset;
      return;
    }

    _mapController.move(target, 15, offset: offset);
  }

  void _moveMapToPickup(LatLng pickup) {
    _hasTripPickup = true;
    final role = ref.read(appViewModelProvider).role;
    _moveMap(pickup, offset: Offset(0, role == Role.driver ? -120 : 140));
  }

  Future<void> _moveMapToCurrentLocation(Role role) async {
    try {
      final currentLocation = await ref.read(currentMapLocationProvider)();

      if (!mounted) return;
      final latestState = ref.read(mapViewModelProvider(role));
      if (_hasTripPickup ||
          latestState.pickup != null ||
          _selectedPickupLocation != null) {
        return;
      }
      _moveMap(currentLocation);
    } catch (e) {
      debugPrint('Could not get current location: $e');
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
      } else if (role == Role.driver) {
        final provider = mapViewModelProvider(role);
        await ref.read(provider.notifier).restoreActiveDriverTrip();
        if (!mounted) return;
        final state = ref.read(provider);
        final target = state.tripStatus == MapTripStatus.goingToDestination
            ? state.destination
            : state.pickup;
        if (target != null) {
          _moveMap(target);
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
    _suggestionTimer?.cancel();
    _errorTimer?.cancel();
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
      return Scaffold(
        body: Center(child: Text(LocaleKeys.map_role_unknown.tr())),
      );
    }

    final provider = mapViewModelProvider(role);
    final state = ref.watch(provider);
    ref.listen<MapState>(provider, (previous, next) {
      if (role == Role.customer && next.tripId != null) {
        if (next.pickupAddress != previous?.pickupAddress &&
            _pickupController.text != next.pickupAddress) {
          _pickupController.text = next.pickupAddress;
        }
        if (next.destinationAddress != previous?.destinationAddress &&
            _destinationController.text != next.destinationAddress) {
          _destinationController.text = next.destinationAddress;
        }
      }
      if (previous?.errorMessage != next.errorMessage) {
        _errorTimer?.cancel();
        final message = next.errorMessage;
        if (message != null) {
          _errorTimer = Timer(const Duration(seconds: 6), () {
            if (!mounted) return;
            if (ref.read(provider).errorMessage == message) {
              ref.read(provider.notifier).clearError();
            }
          });
        }
      }
      if (previous?.tripId != null && next.tripId == null) {
        _hasTripPickup = false;
        _moveMapToCurrentLocation(role);
      }
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

                ref
                    .read(provider.notifier)
                    .bookTrip(
                      pickupLocation: _selectedPickupLocation,
                      destinationLocation: _selectedDestinationLocation,
                    );
              },
              onCancel: () => _confirmCancellation(
                role,
                () => ref.read(provider.notifier).cancelTrip(),
              ),
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
              onCancel: () => _confirmCancellation(
                role,
                () => ref.read(provider.notifier).cancelTrip(),
              ),
              onOffline: () {
                ref.read(provider.notifier).goOffline();
              },
            ),

          if (role == Role.driver && state.errorMessage != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      IconButton(
                        tooltip: LocaleKeys.map_dismiss_warning.tr(),
                        onPressed: () =>
                            ref.read(provider.notifier).clearError(),
                        icon: const Icon(Icons.close, color: Colors.red),
                      ),
                    ],
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

    final pickupMarker = state.pickup ?? _selectedPickupLocation;
    final destinationMarker = state.destination ?? _selectedDestinationLocation;
    if (pickupMarker != null) {
      markers.add(
        fl.Marker(
          point: pickupMarker,
          width: 46,
          height: 46,
          child: _mapMarker(
            asset: Assets.images.icLocation,
            label: LocaleKeys.map_pickup.tr(),
            color: AppColors.blue,
          ),
        ),
      );
    }

    if (destinationMarker != null) {
      markers.add(
        fl.Marker(
          point: destinationMarker,
          width: 46,
          height: 46,
          child: _mapMarker(
            asset: Assets.images.icNavigation,
            label: LocaleKeys.map_destination.tr(),
            color: AppColors.text,
          ),
        ),
      );
    }

    if (state.driverLocation != null) {
      markers.add(
        fl.Marker(
          point: state.driverLocation!,
          width: 46,
          height: 46,
          child: _mapMarker(
            asset: Assets.images.icCar,
            label: LocaleKeys.map_driver_location.tr(),
            color: AppColors.blue,
            filled: true,
          ),
        ),
      );
    }

    return fl.FlutterMap(
      mapController: _mapController,
      options: fl.MapOptions(
        initialCenter:
            state.pickup ??
            state.driverLocation ??
            const LatLng(21.0285, 105.8542),
        initialZoom: 14,
        minZoom: 5,
        maxZoom: 18,
        onMapReady: () {
          _mapReady = true;

          final target = _pendingMapTarget;
          if (target != null) {
            _pendingMapTarget = null;
            _mapController.move(target, 15, offset: _pendingMapOffset);
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
                color: AppColors.blue,
              ),
            ],
          ),
        fl.MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _mapMarker({
    required SvgGenImage asset,
    required String label,
    required Color color,
    bool filled = false,
  }) {
    return Semantics(
      label: label,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? color : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x330F172A),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: asset.svg(
          width: 23,
          height: 23,
          colorFilter: ColorFilter.mode(
            filled ? Colors.white : color,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  Widget _fieldIcon(SvgGenImage asset) => Padding(
    padding: const EdgeInsets.all(13),
    child: asset.svg(
      width: 22,
      height: 22,
      colorFilter: const ColorFilter.mode(AppColors.blue, BlendMode.srcIn),
    ),
  );

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
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.62,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text(LocaleKeys.map_pickup_manual_option.tr()),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(
                          _locatingPickup
                              ? LocaleKeys.map_locating_pickup.tr()
                              : LocaleKeys.map_pickup_current_option.tr(),
                        ),
                      ),
                    ],
                    selected: {_usingCurrentPickup},
                    onSelectionChanged:
                        state.tripStatus == MapTripStatus.idle ||
                            state.tripStatus == MapTripStatus.cancelled
                        ? (selection) {
                            if (selection.first) {
                              unawaited(_useCurrentPickup());
                            } else {
                              _selectManualPickup();
                            }
                          }
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pickupController,
                    enabled: !_usingCurrentPickup,
                    onChanged: (value) => _onAddressChanged(0, value),
                    onTap: () => _searchPlaces(0, _pickupController.text),
                    decoration: InputDecoration(
                      labelText: LocaleKeys.map_pickup.tr(),
                      hintText: LocaleKeys.map_pickup_hint.tr(),
                      prefixIcon: _fieldIcon(Assets.images.icLocation),
                    ),
                  ),
                  _placeSuggestions(0),
                  TextField(
                    controller: _destinationController,
                    onChanged: (value) => _onAddressChanged(1, value),
                    onTap: () => _searchPlaces(1, _destinationController.text),
                    decoration: InputDecoration(
                      labelText: LocaleKeys.map_destination.tr(),
                      hintText: LocaleKeys.map_destination_hint.tr(),
                      prefixIcon: _fieldIcon(Assets.images.icNavigation),
                    ),
                  ),
                  _placeSuggestions(1),
                  if (state.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  state.errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: LocaleKeys.map_dismiss_warning.tr(),
                              onPressed: () => ref
                                  .read(
                                    mapViewModelProvider(Role.customer)
                                        .notifier,
                                  )
                                  .clearError(),
                              icon: const Icon(Icons.close, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (state.tripStatus == MapTripStatus.idle ||
                      state.tripStatus == MapTripStatus.cancelled)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _locatingPickup ? null : onBook,
                        child: Text(LocaleKeys.map_book_trip.tr()),
                      ),
                    ),
                  if (state.tripStatus == MapTripStatus.booking)
                    Text(LocaleKeys.map_calculating_route.tr()),
                  if (state.tripStatus == MapTripStatus.waitingForDriver)
                    Text(LocaleKeys.map_finding_driver.tr()),
                  if (state.tripStatus == MapTripStatus.driverComing)
                    Text(LocaleKeys.map_driver_coming.tr()),
                  if (state.tripStatus == MapTripStatus.goingToDestination)
                    Text(LocaleKeys.map_going_to_destination.tr()),
                  if (state.tripStatus == MapTripStatus.completed)
                    Text(LocaleKeys.map_trip_completed.tr()),
                  if (state.tripId != null &&
                      (state.tripStatus == MapTripStatus.waitingForDriver ||
                          state.tripStatus == MapTripStatus.driverComing))
                    TextButton(
                      onPressed: onCancel,
                      child: Text(LocaleKeys.map_cancel_trip.tr()),
                    ),
                ],
              ),
            ),
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
    required VoidCallback onCancel,
  }) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 20,
      child: Card(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.55,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.tripId == null) ...[
                    Text(
                      LocaleKeys.map_pending_trips.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      avatar:
                          state.driverOnlineStatus ==
                                  DriverOnlineStatus.connecting ||
                              state.driverOnlineStatus ==
                                  DriverOnlineStatus.disconnecting
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.circle,
                              size: 12,
                              color:
                                  state.driverOnlineStatus ==
                                      DriverOnlineStatus.online
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                      label: Text(switch (state.driverOnlineStatus) {
                        DriverOnlineStatus.offline =>
                          LocaleKeys.map_status_offline.tr(),
                        DriverOnlineStatus.connecting =>
                          LocaleKeys.map_status_connecting.tr(),
                        DriverOnlineStatus.online =>
                          LocaleKeys.map_status_online.tr(),
                        DriverOnlineStatus.disconnecting =>
                          LocaleKeys.map_status_disconnecting.tr(),
                      }),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                state.driverOnlineStatus ==
                                    DriverOnlineStatus.offline
                                ? onOnline
                                : null,
                            child: Text(LocaleKeys.map_go_online.tr()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                state.driverOnlineStatus ==
                                    DriverOnlineStatus.online
                                ? onOffline
                                : null,
                            child: Text(LocaleKeys.map_go_offline.tr()),
                          ),
                        ),
                      ],
                    ),
                    if (state.pendingTrips.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(LocaleKeys.map_no_pending_trips.tr()),
                      ),
                    ...state.pendingTrips.map((trip) {
                      final tripId = (trip['trip_id'] as num).toInt();

                      return ListTile(
                        leading: _fieldIcon(Assets.images.icRoute),
                        title: Text(
                          LocaleKeys.map_trip_number.tr(
                            namedArgs: {'id': '$tripId'},
                          ),
                        ),
                        subtitle: Text(
                          LocaleKeys.map_pickup_coordinates.tr(
                            namedArgs: {
                              'latitude': '${trip['trip_latitude']}',
                              'longitude': '${trip['trip_longitude']}',
                            },
                          ),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => onAccept(tripId),
                          child: Text(LocaleKeys.map_accept_trip.tr()),
                        ),
                      );
                    }),
                  ] else ...[
                    Text(
                      LocaleKeys.map_active_trip.tr(
                        namedArgs: {'id': '${state.tripId}'},
                      ),
                    ),
                    Text(
                      state.tripStatus == MapTripStatus.goingToDestination
                          ? LocaleKeys.map_driver_trip_in_progress.tr()
                          : LocaleKeys.map_driver_trip_to_pickup.tr(),
                    ),
                    if (state.pickup != null)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.place_outlined),
                        title: Text(LocaleKeys.map_pickup.tr()),
                        subtitle: Text(
                          '${state.pickup!.latitude.toStringAsFixed(5)}, '
                          '${state.pickup!.longitude.toStringAsFixed(5)}',
                        ),
                      ),
                    if (state.destination != null)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.flag_outlined),
                        title: Text(LocaleKeys.map_destination.tr()),
                        subtitle: Text(
                          '${state.destination!.latitude.toStringAsFixed(5)}, '
                          '${state.destination!.longitude.toStringAsFixed(5)}',
                        ),
                      ),
                    if (state.tripStatus == MapTripStatus.driverComing)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onStart,
                          child: Text(LocaleKeys.map_start_trip.tr()),
                        ),
                      ),
                    if (state.tripStatus == MapTripStatus.driverComing)
                      TextButton(
                        onPressed: onCancel,
                        child: Text(LocaleKeys.map_cancel_trip.tr()),
                      ),
                    if (state.tripStatus == MapTripStatus.goingToDestination)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onComplete,
                          child: Text(LocaleKeys.map_complete_trip.tr()),
                        ),
                      ),
                    if (state.tripStatus == MapTripStatus.completed)
                      Text(LocaleKeys.map_trip_completed.tr()),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
