import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';

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
              child: Text(LocaleKeys.trip_back.tr()),
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
          LocaleKeys.trip_cancel_question.tr(),
          LocaleKeys.trip_cancel_confirm.tr(namedArgs: {'code': t.code}),
          LocaleKeys.trip_cancel.tr(),
        ) &&
        mounted) {
      setState(() {
        ref.read(tripsProvider.notifier).cancel(t.code);
        selectedCode = null;
        tab = 1;
      });
      notify(LocaleKeys.trip_cancelled_notice.tr());
    }
  }

  Future<void> advance() async {
    final t = trip;
    if (t.status == TripStatus.approaching) {
      ref.read(tripsProvider.notifier).advance(t.code);
      return;
    }
    if (await confirm(
          LocaleKeys.trip_confirm_finish.tr(),
          LocaleKeys.trip_cash_confirm.tr(namedArgs: {'price': t.price}),
          LocaleKeys.trip_delivered_paid.tr(),
        ) &&
        mounted) {
      ref.read(tripsProvider.notifier).advance(t.code);
      notify(LocaleKeys.trip_finished_notice.tr());
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
                Text(
                  LocaleKeys.trip_how_was_it.tr(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  LocaleKeys.trip_rate_driver_name.tr(
                    namedArgs: {'driver': t.driver},
                  ),
                  style: const TextStyle(color: muted),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 4,
                  children: List.generate(
                    5,
                    (i) => IconButton(
                      tooltip: LocaleKeys.trip_stars_count.tr(
                        namedArgs: {'count': '${i + 1}'},
                      ),
                      onPressed: () => update(() => stars = i + 1),
                      icon: AssetIcon(
                        'ic_star',
                        size: 28,
                        color: i < stars ? blue : lineStrong,
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
                    child: Text(LocaleKeys.trip_send_rating.tr()),
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
      notify(LocaleKeys.trip_thank_rating.tr());
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
                tooltip: LocaleKeys.trip_back_map.tr(),
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
                tooltip: LocaleKeys.trip_back_history.tr(),
                onPressed: () => setState(() => selectedCode = null),
                icon: const AssetIcon('ic_back'),
              ),
        title: Text(
          history
              ? LocaleKeys.trip_history_title.tr()
              : LocaleKeys.trip_details_title.tr(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        actions: [
          PopupMenuButton<bool>(
            tooltip: LocaleKeys.trip_choose_role.tr(),
            icon: AssetIcon(driver ? 'ic_driver' : 'ic_user', color: blue),
            initialValue: driver,
            onSelected: (value) => setState(() {
              driver = value;
              selectedCode = null;
            }),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: false,
                child: Text(LocaleKeys.trip_customer.tr()),
              ),
              PopupMenuItem(
                value: true,
                child: Text(LocaleKeys.trip_driver.tr()),
              ),
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
              destinations: [
                NavigationDestination(
                  icon: const AssetIcon('ic_map'),
                  selectedIcon: const AssetIcon('ic_map', color: blue),
                  label: LocaleKeys.trip_current.tr(),
                ),
                NavigationDestination(
                  icon: const AssetIcon('ic_history'),
                  selectedIcon: const AssetIcon('ic_history', color: blue),
                  label: LocaleKeys.trip_history_nav.tr(),
                ),
              ],
            ),
    );
  }
}
