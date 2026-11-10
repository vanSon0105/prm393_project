import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/trip_colors.dart';
import '../../../../shared/widgets/asset_icon.dart';
import '../../data/models/trip_history_model.dart';
import '../providers/trip_history_provider.dart';

class LiveTripHistoryPage extends ConsumerStatefulWidget {
  const LiveTripHistoryPage({
    super.key,
    required this.profileId,
    required this.role,
    required this.onExit,
  });

  final int profileId;
  final Role role;
  final VoidCallback onExit;

  @override
  ConsumerState<LiveTripHistoryPage> createState() =>
      _LiveTripHistoryPageState();
}

class _LiveTripHistoryPageState extends ConsumerState<LiveTripHistoryPage> {
  final List<TripHistoryEntry> _moreEntries = [];
  int _filter = 0;
  int? _selectedTripId;
  bool _loadingMore = false;
  bool? _moreHasMore;
  bool _moreFailed = false;

  Future<void> _refresh() async {
    setState(() {
      _moreEntries.clear();
      _moreHasMore = null;
      _moreFailed = false;
      _selectedTripId = null;
    });
    ref.invalidate(tripHistoryProvider(widget.profileId));
    try {
      await ref.read(tripHistoryProvider(widget.profileId).future);
    } catch (_) {
      // The provider's error state displays the retry action.
    }
  }

  Future<void> _loadMore(int offset) async {
    if (_loadingMore) return;
    setState(() {
      _loadingMore = true;
      _moreFailed = false;
    });
    try {
      final page = await ref
          .read(tripHistoryRepositoryProvider)
          .getHistory(profileId: widget.profileId, offset: offset);
      if (!mounted) return;
      setState(() {
        _moreEntries.addAll(page.entries);
        _moreHasMore = page.hasMore;
      });
    } catch (_) {
      if (mounted) setState(() => _moreFailed = true);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  String _status(TripHistoryEntry trip) => trip.isCompleted
      ? LocaleKeys.trip_status_completed.tr()
      : LocaleKeys.trip_status_cancelled.tr();

  String _price(TripHistoryEntry trip) => trip.price == null
      ? LocaleKeys.trip_history_unavailable.tr()
      : LocaleKeys.trip_history_price_vnd.tr(
          namedArgs: {'amount': trip.price!.toStringAsFixed(0)},
        );

  String _location(double latitude, double longitude) =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

  String _counterpart(TripHistoryEntry trip) => widget.role == Role.driver
      ? trip.customerName
      : trip.driverName?.isNotEmpty == true
      ? trip.driverName!
      : LocaleKeys.trip_history_unassigned.tr();

  @override
  Widget build(BuildContext context) {
    ref.listen(tripHistoryProvider(widget.profileId), (previous, next) {
      if (previous?.hasValue == true &&
          next.hasValue &&
          !identical(previous?.value, next.value)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _moreEntries.clear();
            _moreHasMore = null;
            _moreFailed = false;
            _selectedTripId = null;
          });
        });
      }
    });
    final history = ref.watch(tripHistoryProvider(widget.profileId));
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: _selectedTripId == null
              ? LocaleKeys.trip_back_map.tr()
              : LocaleKeys.trip_back_history.tr(),
          onPressed: _selectedTripId == null
              ? widget.onExit
              : () => setState(() => _selectedTripId = null),
          icon: const AssetIcon('ic_back'),
        ),
        title: Text(
          _selectedTripId == null
              ? LocaleKeys.trip_history_title.tr()
              : LocaleKeys.trip_details_title.tr(),
        ),
        actions: [
          if (_selectedTripId == null)
            IconButton(
              tooltip: LocaleKeys.trip_history_refresh.tr(),
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: history.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _message(
                LocaleKeys.trip_history_load_error.tr(),
                LocaleKeys.trip_history_retry.tr(),
                _refresh,
              ),
              data: (firstPage) {
                final entries = [...firstPage.entries, ..._moreEntries];
                final selected = entries
                    .where((trip) => trip.tripId == _selectedTripId)
                    .firstOrNull;
                if (selected != null) return _details(selected);
                final visible = entries
                    .where(
                      (trip) =>
                          _filter == 0 ||
                          (_filter == 1 && trip.isCompleted) ||
                          (_filter == 2 && !trip.isCompleted),
                    )
                    .toList();
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      Text(
                        widget.role == Role.driver
                            ? LocaleKeys.trip_driver_upper.tr()
                            : LocaleKeys.trip_customer_upper.tr(),
                        style: const TextStyle(
                          color: muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children:
                            [
                                  LocaleKeys.trip_filter_all.tr(),
                                  LocaleKeys.trip_status_completed.tr(),
                                  LocaleKeys.trip_status_cancelled.tr(),
                                ]
                                .asMap()
                                .entries
                                .map(
                                  (item) => ChoiceChip(
                                    label: Text(item.value),
                                    selected: _filter == item.key,
                                    onSelected: (_) =>
                                        setState(() => _filter = item.key),
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 14),
                      if (visible.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: Text(LocaleKeys.trip_no_matching.tr()),
                          ),
                        ),
                      for (final trip in visible) _tripCard(trip),
                      if (_moreFailed)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            LocaleKeys.trip_history_load_error.tr(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (_moreHasMore ?? firstPage.hasMore)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: OutlinedButton(
                            onPressed: _loadingMore
                                ? null
                                : () => _loadMore(entries.length),
                            child: Text(
                              _loadingMore
                                  ? LocaleKeys.loading_txt.tr()
                                  : LocaleKeys.trip_history_load_more.tr(),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _message(String message, String action, VoidCallback onPressed) =>
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onPressed, child: Text(action)),
          ],
        ),
      );

  Widget _tripCard(TripHistoryEntry trip) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: () => setState(() => _selectedTripId = trip.tripId),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    LocaleKeys.trip_code.tr(
                      namedArgs: {'code': '${trip.tripId}'},
                    ),
                  ),
                ),
                Text(
                  _price(trip),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_counterpart(trip)),
            const SizedBox(height: 8),
            Text(
              _status(trip),
              style: TextStyle(
                color: trip.isCompleted ? green : red,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${LocaleKeys.trip_pickup.tr()}: '
              '${_location(trip.pickupLatitude, trip.pickupLongitude)}',
            ),
            Text(
              '${LocaleKeys.trip_destination.tr()}: '
              '${_location(trip.destinationLatitude, trip.destinationLongitude)}',
            ),
          ],
        ),
      ),
    ),
  );

  Widget _details(TripHistoryEntry trip) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
    children: [
      Text(
        LocaleKeys.trip_code.tr(namedArgs: {'code': '${trip.tripId}'}),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 16),
      _detailRow(LocaleKeys.trip_info.tr(), _status(trip)),
      _detailRow(
        widget.role == Role.driver
            ? LocaleKeys.trip_customer.tr()
            : LocaleKeys.trip_driver.tr(),
        _counterpart(trip),
      ),
      _detailRow(
        LocaleKeys.trip_pickup.tr(),
        _location(trip.pickupLatitude, trip.pickupLongitude),
      ),
      _detailRow(
        LocaleKeys.trip_destination.tr(),
        _location(trip.destinationLatitude, trip.destinationLongitude),
      ),
      _detailRow(
        LocaleKeys.trip_distance.tr(),
        trip.distanceKm == null
            ? LocaleKeys.trip_history_unavailable.tr()
            : LocaleKeys.trip_history_distance_km.tr(
                namedArgs: {'distance': '${trip.distanceKm}'},
              ),
      ),
      _detailRow(LocaleKeys.trip_total_fee.tr(), _price(trip)),
    ],
  );

  Widget _detailRow(String label, String value) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: muted)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );
}
