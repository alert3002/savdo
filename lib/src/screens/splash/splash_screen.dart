import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../brand/brand_assets.dart';
import '../../brand/brand_copy.dart';
import '../../routing/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      context.go(AppRoutes.main);
    });
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
              Center(
                child: FilledButton(
                  onPressed: () => context.go(AppRoutes.main),
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

