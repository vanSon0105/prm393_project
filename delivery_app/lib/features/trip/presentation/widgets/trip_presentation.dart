import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';

import '../../../../core/theme/trip_colors.dart';
import '../../domain/entities/trip.dart';

extension TripPresentation on Trip {
  String get dateLabel =>
      date == LocaleKeys.trip_demo_today_time ? date.tr() : date;
  String get serviceLabel => switch (service) {
    LocaleKeys.trip_demo_service_goods ||
    LocaleKeys.trip_demo_service_food ||
    LocaleKeys.trip_demo_service_special => service.tr(),
    _ => service,
  };
  String get driverLabel =>
      driver == LocaleKeys.trip_demo_unassigned ? driver.tr() : driver;
  String get plateLabel =>
      plate == LocaleKeys.trip_demo_no_driver ? plate.tr() : plate;

  String get statusLabel => switch (status) {
    TripStatus.approaching => LocaleKeys.trip_status_approaching.tr(),
    TripStatus.pickedUp => LocaleKeys.trip_status_in_progress.tr(),
    TripStatus.completed => LocaleKeys.trip_status_completed.tr(),
    TripStatus.cancelled => LocaleKeys.trip_status_cancelled.tr(),
  };
  Color get color => status == TripStatus.cancelled
      ? red
      : status == TripStatus.completed
      ? green
      : blue;
}
