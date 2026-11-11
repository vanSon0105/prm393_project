import 'package:delivery_app/core/theme/app_theme.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class DriverPendingTripSheet extends StatefulWidget {
  const DriverPendingTripSheet({
    super.key,
    required this.trip,
    required this.available,
    required this.reverseGeocode,
    required this.onAccept,
  });

  final Map<String, dynamic> trip;
  final bool available;
  final Future<String?> Function(LatLng) reverseGeocode;
  final VoidCallback onAccept;

  @override
  State<DriverPendingTripSheet> createState() => _DriverPendingTripSheetState();
}

class _DriverPendingTripSheetState extends State<DriverPendingTripSheet> {
  late final Future<List<String?>> _addresses = Future.wait([
    _address('trip_latitude', 'trip_longitude'),
    _address('destination_latitude', 'destination_longitude'),
  ]);

  Future<String?> _address(String latitudeKey, String longitudeKey) async {
    final latitude = widget.trip[latitudeKey];
    final longitude = widget.trip[longitudeKey];
    if (latitude is! num || longitude is! num) return null;
    try {
      final address = await widget.reverseGeocode(
        LatLng(latitude.toDouble(), longitude.toDouble()),
      );
      return address?.trim().isNotEmpty == true ? address!.trim() : null;
    } catch (_) {
      return null;
    }
  }

  String _fare(num? amount) {
    if (amount == null) return '—';
    final formatted = amount.round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return LocaleKeys.trip_history_price_vnd.tr(
      namedArgs: {'amount': formatted},
    );
  }

  Widget _addressRow(
    IconData icon,
    String label,
    String? address, {
    required bool loading,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                loading
                    ? LocaleKeys.map_trip_address_loading.tr()
                    : address ?? LocaleKeys.map_trip_address_unavailable.tr(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripId = widget.trip['trip_id'];
    final distance = widget.trip['trip_distance'];
    final fare = widget.trip['trip_price'];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                LocaleKeys.map_trip_number.tr(namedArgs: {'id': '$tripId'}),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              FutureBuilder<List<String?>>(
                future: _addresses,
                builder: (context, snapshot) {
                  final addresses = snapshot.data;
                  final loading =
                      snapshot.connectionState != ConnectionState.done;
                  return Column(
                    children: [
                      _addressRow(
                        Icons.place_outlined,
                        LocaleKeys.map_pickup.tr(),
                        addresses?[0],
                        loading: loading,
                      ),
                      const Divider(height: 28),
                      _addressRow(
                        Icons.flag_outlined,
                        LocaleKeys.map_destination.tr(),
                        addresses?[1],
                        loading: loading,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(LocaleKeys.trip_distance.tr()),
                        Text(
                          distance is num
                              ? LocaleKeys.trip_history_distance_km.tr(
                                  namedArgs: {'distance': '$distance'},
                                )
                              : '—',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(LocaleKeys.trip_fare.tr()),
                        Text(
                          _fare(fare is num ? fare : null),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!widget.available)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(LocaleKeys.map_trip_unavailable.tr()),
                ),
              FilledButton(
                onPressed: widget.available ? widget.onAccept : null,
                child: Text(LocaleKeys.map_accept_trip.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
