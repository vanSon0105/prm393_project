import 'dart:async';

import 'package:delivery_app/features/location/location_service.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocationPermissionGuard extends ConsumerStatefulWidget {
  const LocationPermissionGuard({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<LocationPermissionGuard> createState() =>
      _LocationPermissionGuardState();
}

class _LocationPermissionGuardState
    extends ConsumerState<LocationPermissionGuard>
    with WidgetsBindingObserver {
  LocationAccessStatus? _status;
  bool _checking = true;
  bool _checkAgain = false;
  bool _checkFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refresh(requestIfDenied: true));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refresh());
    }
  }

  Future<void> _refresh({bool requestIfDenied = false}) async {
    if (_checking && _status != null) {
      _checkAgain = true;
      return;
    }
    if (_checking && _status == null && !requestIfDenied) {
      _checkAgain = true;
      return;
    }

    setState(() {
      _checking = true;
      _checkFailed = false;
    });
    try {
      final status = await ref
          .read(locationServiceProvider)
          .checkPermission(requestIfDenied: requestIfDenied);
      if (mounted) {
        setState(() {
          // Android can report `denied` from checkPermission even after
          // requestPermission reported `deniedForever`. Keep the settings
          // action visible until permission is granted.
          _status =
              !requestIfDenied &&
                  status == LocationAccessStatus.denied &&
                  _status == LocationAccessStatus.deniedForever
              ? LocationAccessStatus.deniedForever
              : status;
        });
      }
    } catch (error) {
      debugPrint('Location permission check failed: $error');
      if (mounted) setState(() => _checkFailed = true);
    } finally {
      if (mounted) {
        setState(() => _checking = false);
        if (_checkAgain) {
          _checkAgain = false;
          unawaited(_refresh());
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_status == LocationAccessStatus.granted && !_checkFailed) {
      return widget.child;
    }

    final needsSettings = _status == LocationAccessStatus.deniedForever;
    return Scaffold(
      body: Center(
        child: AlertDialog(
          title: Text(LocaleKeys.location_required_title.tr()),
          content: Text(
            _checkFailed
                ? LocaleKeys.location_check_error.tr()
                : needsSettings
                ? LocaleKeys.location_settings_message.tr()
                : LocaleKeys.location_permission_message.tr(),
          ),
          actions: [
            if (needsSettings)
              TextButton(
                onPressed: () => unawaited(_refresh()),
                child: Text(LocaleKeys.location_check_again.tr()),
              ),
            FilledButton(
              onPressed: () async {
                if (needsSettings && !_checkFailed) {
                  try {
                    await ref.read(locationServiceProvider).openAppSettings();
                  } catch (error) {
                    debugPrint('Opening app settings failed: $error');
                  }
                } else {
                  await _refresh(requestIfDenied: true);
                }
              },
              child: Text(
                needsSettings && !_checkFailed
                    ? LocaleKeys.location_open_settings.tr()
                    : _checkFailed
                    ? LocaleKeys.location_try_again.tr()
                    : LocaleKeys.location_allow.tr(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
