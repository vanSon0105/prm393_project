import 'package:flutter/material.dart';

import '../../../../core/theme/trip_colors.dart';
import '../../domain/entities/trip.dart';

extension TripPresentation on Trip {
  String get statusLabel => switch (status) {
    TripStatus.approaching => 'Tài xế đang đến',
    TripStatus.pickedUp => 'Đang thực hiện',
    TripStatus.completed => 'Hoàn tất',
    TripStatus.cancelled => 'Đã hủy',
  };
  Color get color => status == TripStatus.cancelled
      ? red
      : status == TripStatus.completed
      ? green
      : blue;
}
