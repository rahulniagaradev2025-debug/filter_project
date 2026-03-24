import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/filters/data/models/filter_config_model.dart';
import '../../features/filters/domain/entities/filter_config_entity.dart';

class AppConfigPreferences {
  AppConfigPreferences._();

  static final AppConfigPreferences instance = AppConfigPreferences._();

  static const _configKey = 'saved_filter_config';

  SharedPreferences? _preferences;
  final ValueNotifier<FilterConfigModel?> configNotifier =
      ValueNotifier<FilterConfigModel?>(null);

  Future<void> init() async {
    _preferences ??= await SharedPreferences.getInstance();
    await loadSavedConfig();
  }

  Future<FilterConfigModel?> loadSavedConfig() async {
    _preferences ??= await SharedPreferences.getInstance();
    final raw = _preferences!.getString(_configKey);
    if (raw == null || raw.isEmpty) {
      configNotifier.value = null;
      return null;
    }

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final config = FilterConfigModel.fromJson(json);
      configNotifier.value = config;
      return config;
    } catch (_) {
      configNotifier.value = null;
      return null;
    }
  }

  Future<void> saveConfig(FilterConfigEntity config) async {
    _preferences ??= await SharedPreferences.getInstance();
    final model = FilterConfigModel.fromEntity(config);
    await _preferences!.setString(_configKey, jsonEncode(model.toJson()));
    configNotifier.value = model;
  }

  Future<void> clearConfig() async {
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.remove(_configKey);
    configNotifier.value = null;
  }
}
