import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';

import '../../../../core/theme/trip_colors.dart';
import '../../../../shared/widgets/asset_icon.dart';
import '../../../../shared/widgets/surface.dart';
import '../../../../shared/widgets/status_dot.dart';
import '../../domain/entities/trip.dart';
import 'trip_presentation.dart';
import 'trip_summary.dart';

class TripDetailsBody extends StatelessWidget {
  const TripDetailsBody({
    super.key,
    required this.trip,
    required this.driver,
    required this.cancel,
    required this.advance,
    required this.rate,
  });
  final Trip trip;
  final bool driver;
  final VoidCallback cancel, advance, rate;
  @override
  Widget build(BuildContext context) {
    final t = trip;
    final stage = switch (t.status) {
      TripStatus.approaching => 0,
      TripStatus.pickedUp => 1,
      _ => 2,
    };
    return ListView(
      key: ValueKey('details-$driver-${t.code}'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                LocaleKeys.trip_code.tr(namedArgs: {'code': t.code}),
                style: const TextStyle(color: muted, fontSize: 13),
              ),
            ),
            Text(
              driver
                  ? LocaleKeys.trip_driver_upper.tr()
                  : LocaleKeys.trip_customer_upper.tr(),
              style: const TextStyle(
                color: blue,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Surface(
          color: t.color.withValues(alpha: .08),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: AssetIcon(
                  t.status == TripStatus.cancelled ? 'ic_close' : t.icon,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.active && driver
                          ? (stage == 0
                                ? LocaleKeys.trip_go_pickup.tr()
                                : LocaleKeys.trip_deliver_customer.tr())
                          : t.statusLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      t.active
                          ? (stage == 0
                                ? LocaleKeys.trip_arrive_six_minutes.tr()
                                : LocaleKeys.trip_deliver_eighteen_minutes.tr())
                          : t.date,
                      style: const TextStyle(fontSize: 12, color: muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (t.status != TripStatus.cancelled) ...[
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              3,
              (i) => Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 2,
                            color: i == 0
                                ? Colors.transparent
                                : i <= stage
                                ? blue
                                : line,
                          ),
                        ),
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: i <= stage ? blue : surfaceMuted,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: i <= stage ? Colors.white : muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 2,
                            color: i == 2
                                ? Colors.transparent
                                : i < stage
                                ? blue
                                : line,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      [
                        LocaleKeys.trip_step_pickup.tr(),
                        LocaleKeys.trip_delivering.tr(),
                        LocaleKeys.trip_status_completed.tr(),
                      ][i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: i <= stage ? blue : muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Surface(
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: pale,
                child: Text(
                  driver
                      ? 'MA'
                      : t.driver
                            .split(' ')
                            .where((s) => s.isNotEmpty)
                            .take(2)
                            .map((s) => s[0])
                            .join(),
                  style: const TextStyle(
                    color: blue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver ? 'Nguyễn Minh An' : t.driver,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      driver
                          ? LocaleKeys.trip_customer_contact.tr(
                              namedArgs: const {'phone': '090 123 4567'},
                            )
                          : t.plate,
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (t.active)
                IconButton(
                  tooltip: LocaleKeys.trip_contact_tooltip.tr(),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                        driver
                            ? LocaleKeys.trip_contact_customer.tr()
                            : LocaleKeys.trip_contact_driver.tr(),
                      ),
                      content: Text(
                        driver
                            ? 'Nguyễn Minh An\n090 123 4567'
                            : '${t.driver}\n091 286 0456',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(LocaleKeys.trip_close.tr()),
                        ),
                      ],
                    ),
                  ),
                  icon: const AssetIcon('ic_info', color: blue),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          LocaleKeys.trip_route.tr(),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Surface(
          child: Column(
            children: [
              stop(LocaleKeys.trip_pickup.tr(), t.pickup, blue),
              const Padding(
                padding: EdgeInsets.only(left: 5),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 24,
                    child: VerticalDivider(width: 1, color: Color(0xFFCBD4DE)),
                  ),
                ),
              ),
              stop(LocaleKeys.trip_destination.tr(), t.destination, ink),
              if (driver) ...[
                const Divider(height: 28),
                Row(
                  children: [
                    const AssetIcon('ic_user', size: 18, color: muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        LocaleKeys.trip_recipient.tr(
                          namedArgs: const {
                            'name': 'Minh An',
                            'phone': '090 123 4567',
                          },
                        ),
                        style: const TextStyle(fontSize: 13, color: muted),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          LocaleKeys.trip_info.tr(),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Surface(
          child: Column(
            children: [
              detailRow(LocaleKeys.trip_service.tr(), t.service),
              const Divider(height: 24),
              detailRow(
                LocaleKeys.trip_distance.tr(),
                t.code == 'NS2408'
                    ? LocaleKeys.trip_distance_estimate.tr()
                    : '—',
              ),
              const Divider(height: 24),
              detailRow(
                LocaleKeys.trip_payment.tr(),
                t.status == TripStatus.cancelled
                    ? LocaleKeys.trip_no_charge.tr()
                    : t.paid
                    ? LocaleKeys.trip_paid.tr()
                    : LocaleKeys.trip_cash_uncollected.tr(),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      driver
                          ? LocaleKeys.trip_fare.tr()
                          : LocaleKeys.trip_total_fee.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    t.status == TripStatus.cancelled ? '0đ' : t.price,
                    style: const TextStyle(
                      fontSize: 24,
                      color: blue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (driver && t.active) ...[
          const SizedBox(height: 16),
          Text(
            LocaleKeys.trip_confirm_warning.tr(),
            style: const TextStyle(color: muted, fontSize: 12),
          ),
        ],
        const SizedBox(height: 24),
        if (driver && t.active)
          FilledButton(
            onPressed: advance,
            child: Text(
              stage == 0
                  ? LocaleKeys.trip_confirm_pickup.tr()
                  : LocaleKeys.trip_finish.tr(),
            ),
          ),
        if (!driver && t.status == TripStatus.approaching)
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 52),
              foregroundColor: red,
            ),
            onPressed: cancel,
            child: Text(LocaleKeys.trip_cancel.tr()),
          ),
        if (!driver && t.active)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              t.status == TripStatus.approaching
                  ? LocaleKeys.trip_prepare_items.tr()
                  : LocaleKeys.trip_tracking_note.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: muted),
            ),
          ),
        if (!driver && t.status == TripStatus.completed)
          FilledButton(
            onPressed: t.rating == null ? rate : null,
            child: Text(
              t.rating == null
                  ? LocaleKeys.trip_rate_driver.tr()
                  : LocaleKeys.trip_rating_done.tr(
                      namedArgs: {'stars': '${t.rating}'},
                    ),
            ),
          ),
        if (driver && !t.active) statusBadge(t),
      ],
    );
  }

  Widget stop(String label, String address, Color color) => Row(
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
  Widget detailRow(String label, String value) => Row(
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
}
