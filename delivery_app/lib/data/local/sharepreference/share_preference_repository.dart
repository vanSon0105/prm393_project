import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'model/data_saved.dart';

// Define Preference key here
enum SharePreferenceKey { isLogged, charlesIp, dataKey }

typedef SPKey = SharePreferenceKey;

class SharePreferenceRepository {
  final SharedPreferences _pref;

  SharePreferenceRepository(this._pref);

  String getString(SPKey key, {String defaultValue = ''}) =>
      _pref.getString(key.name) ?? defaultValue;

  Future<bool> setString(SPKey key, String? value) =>
      value != null ? _pref.setString(key.name, value) : _pref.remove(key.name);

  bool getBool(SPKey key) => _pref.getBool(key.name) ?? false;

  Future<bool> setBool(SPKey key, {bool value = false}) =>
      _pref.setBool(key.name, value);

  int getInt(SPKey key) => _pref.getInt(key.name) ?? 0;

  Future<bool> setInt(SPKey key, {int value = 0}) =>
      _pref.setInt(key.name, value);

  Future<void> clear() async {
    await _pref.clear();
  }
}

extension AppSharePreferences on SharePreferenceRepository {
  Future<void> saveData(DataSaved? data) async {
    await setString(SPKey.dataKey, data == null ? '' : jsonEncode(data.toJson));
  }

  DataSaved? get data {
    final json = getString(SPKey.dataKey);
    if (json.isEmpty) return null;
    return DataSaved.fromJson(json);
  }

  String get charlesIp => getString(SPKey.charlesIp);
}
