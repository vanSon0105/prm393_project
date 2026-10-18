import 'package:flutter/material.dart';

import '../../../../core/theme/trip_colors.dart';
import '../../../../shared/widgets/asset_icon.dart';
import '../../domain/entities/trip.dart';
import '../widgets/trip_history_body.dart';
import '../widgets/trip_details_body.dart';
import '../providers/trip_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class TripApp extends ConsumerStatefulWidget {
  const TripApp({super.key, this.onExit});
  final VoidCallback? onExit;
  @override
  ConsumerState<TripApp> createState() => _TripAppState();
}

class _TripAppState extends ConsumerState<TripApp> {
  List<Trip> get trips => ref.read(tripsProvider);
  bool driver = false;
  int tab = 1, filter = 0;
  String? selectedCode;
  Trip? get selected => selectedCode == null
      ? null
      : trips.where((t) => t.code == selectedCode).firstOrNull;
  Trip get trip => selected ?? trips.first;
  void notify(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<bool> confirm(String title, String message, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Quay lại'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> cancel() async {
    final t = trip;
    if (await confirm(
          'Hủy chuyến đi?',
          'Bạn có chắc muốn hủy chuyến ${t.code}?',
          'Hủy chuyến',
        ) &&
        mounted) {
      setState(() {
        ref.read(tripsProvider.notifier).cancel(t.code);
        selectedCode = null;
        tab = 1;
      });
      notify('Đã hủy chuyến đi');
    }
  }

  Future<void> advance() async {
    final t = trip;
    if (t.status == TripStatus.approaching) {
      ref.read(tripsProvider.notifier).advance(t.code);
      return;
    }
    if (await confirm(
          'Xác nhận hoàn tất',
          'Bạn đã giao hàng và thu ${t.price} tiền mặt?',
          'Đã giao và thu tiền',
        ) &&
        mounted) {
      ref.read(tripsProvider.notifier).advance(t.code);
      notify('Chuyến đi đã hoàn tất');
    }
  }

  Future<void> rate() async {
    final t = trip;
    int stars = 0;
    final result = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Chuyến đi thế nào?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đánh giá tài xế ${t.driver}',
                  style: const TextStyle(color: muted),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 4,
                  children: List.generate(
                    5,
                    (i) => IconButton(
                      tooltip: '${i + 1} sao',
                      onPressed: () => update(() => stars = i + 1),
                      icon: AssetIcon(
                        'ic_star',
                        size: 28,
                        color: i < stars ? blue : const Color(0xFFCBD4DE),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: stars == 0
                        ? null
                        : () => Navigator.pop(context, stars),
                    child: const Text('Gửi đánh giá'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      ref.read(tripsProvider.notifier).rate(t.code, result);
      notify('Cảm ơn bạn đã đánh giá');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(tripsProvider);
    final history = !driver && tab == 1 && selected == null;
    return Scaffold(
      appBar: AppBar(
        leading: selected == null && widget.onExit != null
            ? IconButton(
                tooltip: 'Về bản đồ',
                onPressed: widget.onExit,
                icon: const AssetIcon('ic_back'),
              )
            : selected == null
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: AssetIcon(
                  driver ? 'ic_driver' : 'ic_route',
                  color: blue,
                ),
              )
            : IconButton(
                tooltip: 'Quay lại lịch sử',
                onPressed: () => setState(() => selectedCode = null),
                icon: const AssetIcon('ic_back'),
              ),
        title: Text(
          history ? 'Lịch sử chuyến đi' : 'Chi tiết chuyến đi',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        actions: [
          PopupMenuButton<bool>(
            tooltip: 'Chọn vai trò',
            icon: AssetIcon(driver ? 'ic_driver' : 'ic_user', color: blue),
            initialValue: driver,
            onSelected: (value) => setState(() {
              driver = value;
              selectedCode = null;
            }),
            itemBuilder: (context) => [
              const PopupMenuItem(value: false, child: Text('Khách hàng')),
              const PopupMenuItem(value: true, child: Text('Tài xế')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: history
                ? TripHistoryBody(
                    trips: trips,
                    filter: filter,
                    onFilterChanged: (value) => setState(() => filter = value),
                    onSelected: (value) =>
                        setState(() => selectedCode = value.code),
                  )
                : TripDetailsBody(
                    trip: trip,
                    driver: driver,
                    cancel: cancel,
                    advance: advance,
                    rate: rate,
                  ),
          ),
        ),
      ),
      bottomNavigationBar: driver
          ? null
          : NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: (value) => setState(() {
                tab = value;
                selectedCode = null;
              }),
              destinations: const [
                NavigationDestination(
                  icon: AssetIcon('ic_map'),
                  selectedIcon: AssetIcon('ic_map', color: blue),
                  label: 'Chuyến hiện tại',
                ),
                NavigationDestination(
                  icon: AssetIcon('ic_history'),
                  selectedIcon: AssetIcon('ic_history', color: blue),
                  label: 'Lịch sử',
                ),
              ],
            ),
    );
  }
}
