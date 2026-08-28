import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'storage_service.dart';

class DogGoPreferences {
  final ThemeMode themeMode;
  final double textScale;
  final bool notificationsEnabled;
  final bool walkRemindersEnabled;
  final int reminderMinutes;

  const DogGoPreferences({
    this.themeMode = ThemeMode.system,
    this.textScale = 1,
    this.notificationsEnabled = true,
    this.walkRemindersEnabled = true,
    this.reminderMinutes = 60,
  });

  DogGoPreferences copyWith({
    ThemeMode? themeMode,
    double? textScale,
    bool? notificationsEnabled,
    bool? walkRemindersEnabled,
    int? reminderMinutes,
  }) {
    return DogGoPreferences(
      themeMode: themeMode ?? this.themeMode,
      textScale: textScale ?? this.textScale,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      walkRemindersEnabled: walkRemindersEnabled ?? this.walkRemindersEnabled,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    );
  }
}

class AppPreferencesService {
  static const _themeKey = 'doggo_preferences_theme';
  static const _textScaleKey = 'doggo_preferences_text_scale';
  static const _notificationsKey = 'doggo_preferences_notifications';
  static const _remindersKey = 'doggo_preferences_walk_reminders';
  static const _reminderMinutesKey = 'doggo_preferences_reminder_minutes';

  static Future<DogGoPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeKey) ?? ThemeMode.system.name;
    final theme = ThemeMode.values.firstWhere(
      (value) => value.name == themeName,
      orElse: () => ThemeMode.system,
    );
    return DogGoPreferences(
      themeMode: theme,
      textScale: (prefs.getDouble(_textScaleKey) ?? 1).clamp(.9, 1.25),
      notificationsEnabled: prefs.getBool(_notificationsKey) ?? true,
      walkRemindersEnabled: prefs.getBool(_remindersKey) ?? true,
      reminderMinutes: prefs.getInt(_reminderMinutesKey) ?? 60,
    );
  }

  static Future<void> save(DogGoPreferences value) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_themeKey, value.themeMode.name),
      prefs.setDouble(_textScaleKey, value.textScale),
      prefs.setBool(_notificationsKey, value.notificationsEnabled),
      prefs.setBool(_remindersKey, value.walkRemindersEnabled),
      prefs.setInt(_reminderMinutesKey, value.reminderMinutes),
    ]);
  }

  static Future<String> _userKey(String suffix) async {
    final userId = await StorageService.obtenerUsuarioId();
    return 'doggo_user_${userId ?? 0}_$suffix';
  }

  static Future<void> saveJson(String suffix, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(await _userKey(suffix), jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> loadJson(String suffix) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(await _userKey(suffix));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> remove(String suffix) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(await _userKey(suffix));
  }

  static Future<Set<int>> favoriteWalkerIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(await _userKey('favorite_walkers')) ?? const [])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
  }

  static Future<bool> toggleFavoriteWalker(int walkerId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _userKey('favorite_walkers');
    final ids = await favoriteWalkerIds();
    final isFavorite = ids.contains(walkerId);
    isFavorite ? ids.remove(walkerId) : ids.add(walkerId);
    await prefs.setStringList(key, ids.map((id) => '$id').toList());
    return !isFavorite;
  }

  static Future<void> setFavoriteWalker(int walkerId, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _userKey('favorite_walkers');
    final ids = await favoriteWalkerIds();
    value ? ids.add(walkerId) : ids.remove(walkerId);
    await prefs.setStringList(key, ids.map((id) => '$id').toList());
  }

  static Future<void> replaceFavoriteWalkerIds(Iterable<int> walkerIds) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _userKey('favorite_walkers');
    final ids = walkerIds.where((id) => id > 0).toSet();
    await prefs.setStringList(key, ids.map((id) => '$id').toList());
  }

  static Future<List<int>> recentWalkerIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(await _userKey('recent_walkers')) ?? const [])
        .map(int.tryParse)
        .whereType<int>()
        .toList();
  }

  static Future<void> rememberWalker(int walkerId) async {
    if (walkerId <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final key = await _userKey('recent_walkers');
    final ids = await recentWalkerIds();
    ids.remove(walkerId);
    ids.insert(0, walkerId);
    await prefs.setStringList(key, ids.take(8).map((id) => '$id').toList());
  }

  static Future<bool> hasSeenOnboarding(String contextKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(await _userKey('onboarding_$contextKey')) ?? false;
  }

  static Future<void> markOnboardingSeen(String contextKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(await _userKey('onboarding_$contextKey'), true);
  }

  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in ['home', 'pets', 'walk_request', 'tracking']) {
      await prefs.remove(await _userKey('onboarding_$key'));
    }
  }
}

class AppPreferencesController extends ChangeNotifier {
  AppPreferencesController._();

  static final instance = AppPreferencesController._();
  DogGoPreferences value = const DogGoPreferences();

  Future<void> initialize() async {
    value = await AppPreferencesService.load();
    notifyListeners();
  }

  Future<void> update(DogGoPreferences next) async {
    value = next;
    notifyListeners();
    await AppPreferencesService.save(next);
  }
}
