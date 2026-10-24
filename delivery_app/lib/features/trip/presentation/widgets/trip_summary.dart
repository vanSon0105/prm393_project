import 'package:flutter/material.dart';

import '../../../../core/theme/trip_colors.dart';
import '../../../../shared/widgets/asset_icon.dart';
import '../../domain/entities/trip.dart';
import 'trip_presentation.dart';

Widget tripSummary(Trip t) => Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(13),
      ),
      child: AssetIcon(t.icon, color: blue, size: 25),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.service, style: const TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 5),
          Text(t.pickup, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(
            '→ ${t.destination}',
            style: const TextStyle(fontSize: 13, color: muted),
          ),
        ],
      ),
    ),
  ],
);

Widget statusBadge(Trip t) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  decoration: BoxDecoration(
    color: t.color.withValues(alpha: .09),
    borderRadius: BorderRadius.circular(7),
  ),
  child: Text(
    t.statusLabel,
    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.color),
  ),
);
