import 'package:flutter/material.dart';

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
        const Text(
          'KHÁCH HÀNG',
          style: TextStyle(
            fontSize: 11,
            color: muted,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Mọi hành trình, một nơi.',
          style: TextStyle(color: muted, fontSize: 14),
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
                    ['Tất cả', 'Đang thực hiện', 'Hoàn tất', 'Đã hủy'][i],
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
                    const Expanded(
                      child: Text(
                        'Chuyến đang thực hiện',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      t.status == TripStatus.approaching
                          ? 'Còn 6 phút'
                          : 'Đang giao',
                      style: const TextStyle(
                        color: blue,
                        fontWeight: FontWeight.w600,
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
                    child: const Text('Theo dõi chuyến'),
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
                ? 'Chuyến đã hoàn tất'
                : filter == 3
                ? 'Chuyến đã hủy'
                : 'Chuyến trước',
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
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Xem chi tiết',
                                  style: TextStyle(color: blue, fontSize: 12),
                                ),
                                SizedBox(width: 6),
                                AssetIcon('ic_continue', size: 16, color: blue),
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
          const Surface(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  AssetIcon('ic_history', color: muted, size: 40),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có chuyến phù hợp',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Các chuyến ở trạng thái này sẽ xuất hiện tại đây.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
