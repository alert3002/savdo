import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.notificationsSound,
    required this.notificationsVibrate,
    required this.showMlmFeatures,
    required this.showShopFeatures,
  });

  final ThemeMode themeMode;
  final bool notificationsSound;
  final bool notificationsVibrate;
  final bool showMlmFeatures;
  final bool showShopFeatures;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? notificationsSound,
    bool? notificationsVibrate,
    bool? showMlmFeatures,
    bool? showShopFeatures,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      notificationsSound: notificationsSound ?? this.notificationsSound,
      notificationsVibrate: notificationsVibrate ?? this.notificationsVibrate,
      showMlmFeatures: showMlmFeatures ?? this.showMlmFeatures,
      showShopFeatures: showShopFeatures ?? this.showShopFeatures,
    );
  }
}

class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  static const _kThemeMode = 'settings.theme_mode';
  static const _kNotifSound = 'settings.notifications_sound';
  static const _kNotifVibrate = 'settings.notifications_vibrate';
  static const _kShowMlm = 'settings.show_mlm';
  static const _kShowShop = 'settings.show_shop';

  @override
  Future<AppSettings> build() async {
    final p = await SharedPreferences.getInstance();
    final rawMode = p.getString(_kThemeMode) ?? 'system';
    final themeMode = switch (rawMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return AppSettings(
      themeMode: themeMode,
      notificationsSound: p.getBool(_kNotifSound) ?? true,
      notificationsVibrate: p.getBool(_kNotifVibrate) ?? true,
      showMlmFeatures: p.getBool(_kShowMlm) ?? true,
      showShopFeatures: p.getBool(_kShowShop) ?? true,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final current = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (current == null) return;
    state = AsyncData(current.copyWith(themeMode: mode));
    final p = await SharedPreferences.getInstance();
    final raw = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await p.setString(_kThemeMode, raw);
  }

  Future<void> setNotificationsSound(bool v) async {
    final current = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (current == null) return;
    state = AsyncData(current.copyWith(notificationsSound: v));
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kNotifSound, v);
  }

  Future<void> setNotificationsVibrate(bool v) async {
    final current = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (current == null) return;
    state = AsyncData(current.copyWith(notificationsVibrate: v));
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kNotifVibrate, v);
  }

  Future<void> setShowMlmFeatures(bool v) async {
    final current = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (current == null) return;
    state = AsyncData(current.copyWith(showMlmFeatures: v));
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kShowMlm, v);
  }

  Future<void> setShowShopFeatures(bool v) async {
    final current = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (current == null) return;
    state = AsyncData(current.copyWith(showShopFeatures: v));
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kShowShop, v);
  }
}

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(AppSettingsNotifier.new);

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(appSettingsProvider).maybeWhen(
        data: (s) => s.themeMode,
        orElse: () => ThemeMode.system,
      );
});

