import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../brand/brand_assets.dart';
import '../../brand/brand_copy.dart';
import '../../features/auth/auth_controller.dart';
import '../../routing/app_routes.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authControllerProvider.notifier).restoreSession();
      if (!mounted || _navigated) return;
      _navigated = true;
      context.go(AppRoutes.main);
    });
  }

  void _goMain() {
    if (_navigated) return;
    _navigated = true;
    context.go(AppRoutes.main);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final logo = isDark ? BrandAssets.logoWhiteHorizontal : BrandAssets.logoBlackHorizontal;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Center(
                child: Image.asset(
                  logo,
                  width: 220,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                BrandCopy.appName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                BrandCopy.slogan,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.82),
                      height: 1.35,
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              Center(
                child: FilledButton(
                  onPressed: _goMain,
                  child: const Text('Войти'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
