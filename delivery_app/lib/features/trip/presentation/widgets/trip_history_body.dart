import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';

import '../../../../core/theme/trip_colors.dart';
import '../../../../shared/widgets/asset_icon.dart';
import '../../../../shared/widgets/surface.dart';
import '../../../../shared/widgets/status_dot.dart';
import '../../domain/entities/trip.dart';
import 'trip_summary.dart';

class TripHistoryBody extends StatelessWidget {
  const TripHistoryBody({
    super.key,
    required this.trips,
    required this.filter,
    required this.onFilterChanged,
    required this.onSelected,
  });
  final List<Trip> trips;
  final int filter;
  final ValueChanged<int> onFilterChanged;
  final ValueChanged<Trip> onSelected;
  @override
  Widget build(BuildContext context) {
    final visible = trips
        .where(
          (t) =>
              filter == 0 ||
              (filter == 1 && t.active) ||
              (filter == 2 && t.status == TripStatus.completed) ||
              (filter == 3 && t.status == TripStatus.cancelled),
        )
        .toList();
    final active = visible.where((t) => t.active);
    final past = visible.where((t) => !t.active);
    return ListView(
      key: ValueKey('history-$filter'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          LocaleKeys.trip_customer_upper.tr(),
          style: const TextStyle(
            fontSize: 11,
            color: muted,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          LocaleKeys.trip_tagline.tr(),
          style: const TextStyle(color: muted, fontSize: 14),
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              4,
              (i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    [
                      LocaleKeys.trip_filter_all.tr(),
                      LocaleKeys.trip_status_in_progress.tr(),
                      LocaleKeys.trip_status_completed.tr(),
                      LocaleKeys.trip_status_cancelled.tr(),
                    ][i],
                  ),
                  selected: filter == i,
                  showCheckmark: false,
                  selectedColor: pale,
                  onSelected: (_) => onFilterChanged(i),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        for (final t in active) ...[
          Surface(
            color: pale,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const StatusDot(blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        LocaleKeys.trip_active.tr(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        t.status == TripStatus.approaching
                            ? LocaleKeys.trip_six_minutes_left.tr()
                            : LocaleKeys.trip_delivering.tr(),
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                tripSummary(t),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => onSelected(t),
                    child: Text(LocaleKeys.trip_track.tr()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (past.isNotEmpty) ...[
          Text(
            filter == 2
                ? LocaleKeys.trip_completed_history.tr()
                : filter == 3
                ? LocaleKeys.trip_cancelled_history.tr()
                : LocaleKeys.trip_previous.tr(),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          for (final t in past)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Surface(
                padding: EdgeInsets.zero,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onSelected(t),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                t.date,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: muted,
                                ),
                              ),
                            ),
                            Text(
                              t.price,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        tripSummary(t),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            statusBadge(t),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  LocaleKeys.trip_view_details.tr(),
                                  style: const TextStyle(
                                    color: blue,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const AssetIcon(
                                  'ic_continue',
                                  size: 16,
                                  color: blue,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
        if (visible.isEmpty)
          Surface(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  const AssetIcon('ic_history', color: muted, size: 40),
                  const SizedBox(height: 16),
                  Text(
                    LocaleKeys.trip_no_matching.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    LocaleKeys.trip_empty_status.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: muted),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
