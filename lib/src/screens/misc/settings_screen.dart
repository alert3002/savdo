import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/app_settings.dart';
import '../../ui/navigation/shop_layer_app_bar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final asyncSettings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        actions: shopLayerAppBarActions(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          asyncSettings.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text(
              'Ошибка: $e',
              style: textTheme.bodyMedium?.copyWith(color: scheme.error),
            ),
            data: (s) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle('Внешний вид'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Тема приложения',
                          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 10),
                        SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(value: ThemeMode.system, label: Text('Система'), icon: Icon(Icons.settings_suggest_outlined)),
                            ButtonSegment(value: ThemeMode.light, label: Text('Светлая'), icon: Icon(Icons.light_mode_outlined)),
                            ButtonSegment(value: ThemeMode.dark, label: Text('Тёмная'), icon: Icon(Icons.dark_mode_outlined)),
                          ],
                          selected: <ThemeMode>{s.themeMode},
                          onSelectionChanged: (sel) async {
                            final mode = sel.first;
                            await ref.read(appSettingsProvider.notifier).setThemeMode(mode);
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Клиент метавонад фонро сиёҳ ё сафед кунад.',
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.72),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle('Уведомления'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: s.notificationsSound,
                          onChanged: (v) => ref.read(appSettingsProvider.notifier).setNotificationsSound(v),
                          title: const Text('Звук'),
                          subtitle: const Text('Проигрывать звук при уведомлениях'),
                        ),
                        Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.22)),
                        SwitchListTile(
                          value: s.notificationsVibrate,
                          onChanged: (v) => ref.read(appSettingsProvider.notifier).setNotificationsVibrate(v),
                          title: const Text('Вибрация'),
                          subtitle: const Text('Вибрировать при уведомлениях'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle('Функции'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: s.showShopFeatures,
                          onChanged: (v) => ref.read(appSettingsProvider.notifier).setShowShopFeatures(v),
                          title: const Text('Интернет‑магазин'),
                          subtitle: const Text('Показывать функции магазина'),
                        ),
                        Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.22)),
                        SwitchListTile(
                          value: s.showMlmFeatures,
                          onChanged: (v) => ref.read(appSettingsProvider.notifier).setShowMlmFeatures(v),
                          title: const Text('MLM'),
                          subtitle: const Text('Показывать функции MLM'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
    );
  }
}
