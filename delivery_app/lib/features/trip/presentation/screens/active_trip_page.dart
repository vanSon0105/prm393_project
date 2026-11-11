import 'package:delivery_app/features/app_view_model.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:delivery_app/features/map/map_state.dart';
import 'package:delivery_app/features/map/map_view_model.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:delivery_app/routes/app_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/trip_colors.dart';
import '../../../../core/theme/trip_theme.dart';
import '../../../../shared/widgets/status_dot.dart';
import '../../../../shared/widgets/surface.dart';

/// Whether [state] holds a trip worth showing on the progress screen.
bool hasTripProgress(MapState state) =>
    state.tripId != null &&
    (state.tripStatus == MapTripStatus.waitingForDriver ||
        state.tripStatus == MapTripStatus.driverComing ||
        state.tripStatus == MapTripStatus.goingToDestination ||
        state.tripStatus == MapTripStatus.completed);

/// Full-screen trip progress, opened from the map.
class ActiveTripPage extends ConsumerWidget {
  const ActiveTripPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(appViewModelProvider.select((app) => app.role));
    return Theme(
      data: createAppTheme(),
      child: Scaffold(
        appBar: AppBar(title: Text(LocaleKeys.active_trip_title.tr())),
        body: SafeArea(
          child: role == Role.customer || role == Role.driver
              ? ActiveTripView(role: role!)
              : Center(child: Text(LocaleKeys.trip_history_sign_in.tr())),
        ),
      ),
    );
  }
}

/// Live progress of the current trip, driven by the shared map state so it
/// updates as soon as the realtime socket reports a change.
class ActiveTripView extends ConsumerWidget {
  const ActiveTripView({super.key, required this.role});

  final Role role;

  bool get _isDriver => role == Role.driver;

  void _openMap(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(AppRoute.map.rawValue);
    }
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocaleKeys.map_cancel_title.tr()),
        content: Text(
          _isDriver
              ? LocaleKeys.map_cancel_driver_message.tr()
              : LocaleKeys.map_cancel_customer_message.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(LocaleKeys.trip_back.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(LocaleKeys.map_cancel_trip.tr()),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(mapViewModelProvider(role).notifier).cancelTrip();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapViewModelProvider(role));
    if (!hasTripProgress(state)) return _empty(context);

    final status = state.tripStatus;
    final notifier = ref.read(mapViewModelProvider(role).notifier);
    final canCancel = _isDriver
        ? status == MapTripStatus.driverComing
        : status == MapTripStatus.waitingForDriver ||
              status == MapTripStatus.driverComing;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Text(
          LocaleKeys.map_trip_number.tr(namedArgs: {'id': '${state.tripId}'}),
          style: const TextStyle(color: muted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        _statusCard(state),
        const SizedBox(height: 20),
        _stepper(status),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            state.errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: red),
          ),
        ],
        const SizedBox(height: 24),
        _isDriver ? _customerCard(state) : _driverCard(state),
        const SizedBox(height: 24),
        _sectionTitle(LocaleKeys.trip_route.tr()),
        const SizedBox(height: 12),
        Surface(
          child: Column(
            children: [
              _stop(
                LocaleKeys.trip_pickup.tr(),
                _address(state.pickupAddress, state),
                blue,
              ),
              const SizedBox(height: 18),
              _stop(
                LocaleKeys.trip_destination.tr(),
                _address(state.destinationAddress, state),
                red,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle(LocaleKeys.trip_info.tr()),
        const SizedBox(height: 12),
        Surface(
          child: Column(
            children: [
              _infoRow(LocaleKeys.trip_distance.tr(), _distance(state)),
              const SizedBox(height: 12),
              _infoRow(LocaleKeys.trip_total_fee.tr(), _price(state)),
              const SizedBox(height: 12),
              _infoRow(
                LocaleKeys.trip_payment.tr(),
                LocaleKeys.payment_cash.tr(),
              ),
            ],
          ),
        ),
        if (status != MapTripStatus.completed)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              _isDriver
                  ? LocaleKeys.active_trip_cash_note_driver.tr()
                  : LocaleKeys.active_trip_cash_note_customer.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted, fontSize: 12),
            ),
          ),
        const SizedBox(height: 24),
        if (_isDriver && status == MapTripStatus.driverComing)
          _primaryButton(LocaleKeys.map_start_trip.tr(), notifier.startTrip),
        if (_isDriver && status == MapTripStatus.goingToDestination)
          _primaryButton(LocaleKeys.map_complete_trip.tr(), () async {
            await notifier.completeTrip();
            if (!context.mounted) return;
            final finished =
                ref.read(mapViewModelProvider(role)).tripId == null;
            if (finished) _openMap(context);
          }),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
          onPressed: () => _openMap(context),
          icon: const Icon(Icons.map_outlined),
          label: Text(LocaleKeys.active_trip_view_map.tr()),
        ),
        if (canCancel)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              style: TextButton.styleFrom(foregroundColor: red),
              onPressed: () => _confirmCancel(context, ref),
              child: Text(LocaleKeys.map_cancel_trip.tr()),
            ),
          ),
      ],
    );
  }

  Widget _empty(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.route_outlined, size: 56, color: muted),
          const SizedBox(height: 16),
          Text(
            LocaleKeys.active_trip_empty_title.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            _isDriver
                ? LocaleKeys.active_trip_empty_driver.tr()
                : LocaleKeys.active_trip_empty_customer.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _openMap(context),
            icon: const Icon(Icons.map_outlined),
            label: Text(LocaleKeys.active_trip_open_map.tr()),
          ),
        ],
      ),
    ),
  );

  Widget _statusCard(MapState state) {
    final status = state.tripStatus;
    final completed = status == MapTripStatus.completed;
    final color = completed ? green : blue;
    final title = switch (status) {
      MapTripStatus.waitingForDriver =>
        LocaleKeys.active_trip_status_finding.tr(),
      MapTripStatus.driverComing =>
        _isDriver
            ? LocaleKeys.active_trip_status_coming_driver.tr()
            : LocaleKeys.active_trip_status_coming_customer.tr(),
      MapTripStatus.goingToDestination =>
        LocaleKeys.active_trip_status_on_trip.tr(),
      _ => LocaleKeys.active_trip_status_completed.tr(),
    };
    final route = state.route;
    final showEta =
        route != null &&
        (status == MapTripStatus.driverComing ||
            status == MapTripStatus.goingToDestination);
    final subtitle = showEta
        ? LocaleKeys.active_trip_eta.tr(
            namedArgs: {
              'minutes': '${(route.durationSeconds / 60).ceil().clamp(1, 999)}',
            },
          )
        : status == MapTripStatus.waitingForDriver
        ? LocaleKeys.active_trip_finding_hint.tr()
        : completed
        ? LocaleKeys.active_trip_completed_hint.tr()
        : null;

    return Surface(
      color: color.withValues(alpha: .08),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: status == MapTripStatus.waitingForDriver
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    completed
                        ? Icons.check_rounded
                        : status == MapTripStatus.driverComing
                        ? Icons.near_me_rounded
                        : Icons.directions_car_filled_rounded,
                    color: Colors.white,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepper(MapTripStatus status) {
    final labels = [
      if (!_isDriver) LocaleKeys.active_trip_step_finding.tr(),
      LocaleKeys.active_trip_step_coming.tr(),
      LocaleKeys.active_trip_step_on_trip.tr(),
      LocaleKeys.active_trip_step_done.tr(),
    ];
    final offset = _isDriver ? 1 : 0;
    // Index of the step currently in progress; every step before it is done.
    final current =
        (switch (status) {
          MapTripStatus.waitingForDriver => 0,
          MapTripStatus.driverComing => 1,
          MapTripStatus.goingToDestination => 2,
          _ => 4,
        }) -
        offset;
    final count = labels.length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(count, (i) {
        final done = i < current || current >= count;
        final active = i == current;
        final reached = done || active;
        final dotColor = done ? green : (active ? blue : surfaceMuted);
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i == 0
                          ? Colors.transparent
                          : reached
                          ? (done ? green : blue)
                          : line,
                    ),
                  ),
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                    child: done
                        ? const Icon(Icons.check, size: 15, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: active ? Colors.white : muted,
                              fontSize: 12,
                            ),
                          ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i == count - 1
                          ? Colors.transparent
                          : done
                          ? green
                          : line,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                labels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: done ? green : (active ? blue : muted),
                  fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _driverCard(MapState state) {
    final driverId = state.driverId;
    final data = state.activeTrip?.data;
    final details = data != null && data.tripId == state.tripId ? data : null;
    if (driverId == null) {
      return _personCard(
        title: LocaleKeys.trip_driver.tr(),
        name: LocaleKeys.active_trip_waiting_driver.tr(),
        lines: const [],
        icon: Icons.person_search_outlined,
      );
    }
    final vehicle = switch (details?.vehicleType) {
      'BIKE' => LocaleKeys.active_trip_vehicle_bike.tr(),
      'CAR_4_SEAT' => LocaleKeys.active_trip_vehicle_car.tr(),
      final other? when other.trim().isNotEmpty => other,
      _ => null,
    };
    final plate = details?.licensePlate?.trim();
    return _personCard(
      title: LocaleKeys.trip_driver.tr(),
      name:
          details?.driverDisplayName ??
          LocaleKeys.active_trip_driver_fallback.tr(
            namedArgs: {'id': '$driverId'},
          ),
      lines: [
        [if (plate != null && plate.isNotEmpty) plate, ?vehicle].join(' · '),
        details?.driverPhone?.trim() ?? '',
      ],
      phone: details?.driverPhone,
      icon: Icons.person_outline,
    );
  }

  Widget _customerCard(MapState state) {
    final customer = state.customerProfile;
    if (customer == null) {
      return _personCard(
        title: LocaleKeys.trip_customer.tr(),
        name: state.customerProfileLoaded
            ? LocaleKeys.map_trip_customer_unavailable.tr()
            : LocaleKeys.map_trip_customer_loading.tr(),
        lines: const [],
        icon: Icons.person_outline,
      );
    }
    final hasFullName = customer.fullName.trim().isNotEmpty;
    return _personCard(
      title: LocaleKeys.trip_customer.tr(),
      name: hasFullName ? customer.fullName : customer.userName,
      lines: [
        if (hasFullName && customer.userName.trim().isNotEmpty)
          '@${customer.userName}',
        customer.phoneNumber,
      ],
      phone: customer.phoneNumber,
      icon: Icons.person_outline,
    );
  }

  Widget _personCard({
    required String title,
    required String name,
    required List<String> lines,
    required IconData icon,
    String? phone,
  }) {
    final visibleLines = lines.where((line) => line.trim().isNotEmpty);
    final callable = phone != null && phone.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(title),
        const SizedBox(height: 12),
        Surface(
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: pale,
                child: Icon(icon, color: blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    for (final line in visibleLines) ...[
                      const SizedBox(height: 4),
                      Text(
                        line,
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              if (callable)
                IconButton.filledTonal(
                  tooltip: LocaleKeys.active_trip_call.tr(),
                  onPressed: () =>
                      launchUrl(Uri(scheme: 'tel', path: phone.trim())),
                  icon: const Icon(Icons.phone_outlined),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _address(String address, MapState state) {
    if (address.trim().isNotEmpty) return address;
    return _isDriver && state.driverAddressesLoaded
        ? LocaleKeys.map_trip_address_unavailable.tr()
        : LocaleKeys.map_trip_address_loading.tr();
  }

  String _distance(MapState state) {
    final data = state.activeTrip?.data;
    final km = (data != null && data.tripId == state.tripId)
        ? data.tripDistance
        : state.tripDistance;
    return km == null
        ? LocaleKeys.trip_history_unavailable.tr()
        : LocaleKeys.trip_history_distance_km.tr(
            namedArgs: {'distance': km.toStringAsFixed(km % 1 == 0 ? 0 : 1)},
          );
  }

  String _price(MapState state) {
    final data = state.activeTrip?.data;
    final price = (data != null && data.tripId == state.tripId)
        ? data.tripPrice
        : state.tripPrice;
    return price == null
        ? LocaleKeys.trip_history_unavailable.tr()
        : LocaleKeys.trip_history_price_vnd.tr(
            namedArgs: {'amount': price.toStringAsFixed(0)},
          );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
  );

  Widget _stop(String label, String address, Color color) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(padding: const EdgeInsets.only(top: 4), child: StatusDot(color)),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: muted)),
            const SizedBox(height: 5),
            Text(
              address,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _infoRow(String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(label, style: const TextStyle(color: muted, fontSize: 13)),
      ),
      const SizedBox(width: 16),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    ],
  );

  Widget _primaryButton(String label, VoidCallback onPressed) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: FilledButton(
      style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
      onPressed: onPressed,
      child: Text(label),
    ),
  );
}
