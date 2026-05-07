import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/auth_controller.dart';
import 'features/settings/app_settings.dart';
import 'routing/app_router.dart';
import 'theme/grass_theme.dart';

class GrassApp extends ConsumerStatefulWidget {
  const GrassApp({super.key});

  @override
  ConsumerState<GrassApp> createState() => _GrassAppState();
}

class _GrassAppState extends ConsumerState<GrassApp> {
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).restoreSession();
      _initPushNotifications();
    });
  }

  Future<void> _initPushNotifications() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    _onMessageSub ??= FirebaseMessaging.onMessage.listen((message) {
      debugPrint('FCM foreground message: ${message.messageId}');
    });
    _onMessageOpenedSub ??= FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('FCM opened from notification: ${message.messageId}');
    });
    _onTokenRefreshSub ??= messaging.onTokenRefresh.listen((token) async {
      final bearer = ref.read(authControllerProvider).accessToken;
      if (bearer == null || bearer.isEmpty) return;
      try {
        await ref.read(authRepositoryProvider).registerPushToken(
              bearer: bearer,
              token: token,
              platform: _platformName(),
            );
      } catch (_) {}
    });
  }

  String _platformName() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => 'other',
    };
  }

  @override
  void dispose() {
    _onMessageSub?.cancel();
    _onMessageOpenedSub?.cancel();
    _onTokenRefreshSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter router = createAppRouter();
    final mode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Savdo.tech',
      theme: buildGrassTheme(Brightness.light),
      darkTheme: buildGrassTheme(Brightness.dark),
      themeMode: mode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru'),
        Locale('en'),
      ],
      locale: const Locale('ru'),
      routerConfig: router,
    );
  }
}

