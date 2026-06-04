import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_client.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/auth_models.dart';
import '../../features/cart/cart_controller.dart';
import '../../features/cart/cart_models.dart';
import '../../features/cart/checkout_providers.dart';
import '../../routing/app_routes.dart';
import '../../theme/grass_colors.dart';
import '../../ui/grass_cached_network_image.dart';
import '../../ui/navigation/shop_layer_app_bar.dart';
import '../../features/auth/sms_login_form.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _addressCtrl = TextEditingController();
  final _guestPhoneCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _guestPhoneCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFieldsFromAuth());
  }

  void _syncFieldsFromAuth() {
    final p = ref.read(authControllerProvider).profile;
    if (p != null) {
      _addressCtrl.text = p.address;
      _guestPhoneCtrl.text = p.phone;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (prev?.profile?.address != next.profile?.address ||
          prev?.profile?.phone != next.profile?.phone) {
        final p = next.profile;
        if (p != null) {
          _addressCtrl.text = p.address;
          _guestPhoneCtrl.text = p.phone;
        }
      }
    });

    final items = ref.watch(cartControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Корзина'),
        actions: shopLayerAppBarActions(context),
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 64,
                      color: scheme.primary.withValues(alpha: 0.65),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Корзина пуста',
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Добавьте товары из каталога',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => context.go(AppRoutes.catalog),
                      child: const Text('В каталог'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: items.length,
                    separatorBuilder: (context, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _CartLineCard(
                        item: item,
                        onOpenProduct: () =>
                            context.push(AppRoutes.productBySlug(item.slug)),
                        onDec: () => ref
                            .read(cartControllerProvider.notifier)
                            .setQty(item.key, item.qty - 1),
                        onInc: () => ref
                            .read(cartControllerProvider.notifier)
                            .setQty(item.key, item.qty + 1),
                      );
                    },
                  ),
                ),
                _CheckoutSection(
                  auth: auth,
                  addressCtrl: _addressCtrl,
                  guestPhoneCtrl: _guestPhoneCtrl,
                  submitting: _submitting,
                  scheme: scheme,
                  textTheme: textTheme,
                  onLogin: () => _showSmsLoginDialog(context),
                  onSubmit: () => _placeOrder(context),
                ),
              ],
            ),
    );
  }

  Future<void> _showSmsLoginDialog(BuildContext context) async {
    final phone = _guestPhoneCtrl.text.trim();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: SizedBox(
            width: 420,
            child: SmsLoginForm(
              initialPhone: phone,
              onVerified: () => Navigator.pop(ctx, true),
            ),
          ),
        ),
      ),
    );

    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вход выполнен')),
      );
    }
  }

  Future<void> _placeOrder(BuildContext context) async {
    final auth = ref.read(authControllerProvider);
    var token = auth.accessToken;
    if (token == null || token.isEmpty) {
      final phone = _guestPhoneCtrl.text.trim();
      if (phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Укажите телефон и подтвердите по SMS')),
        );
        return;
      }

      await _showSmsLoginDialog(context);
      if (!context.mounted) return;
      token = ref.read(authControllerProvider).accessToken;
      if (token == null || token.isEmpty) return;
    }
    final addr = _addressCtrl.text.trim();
    if (addr.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите адрес доставки')),
      );
      return;
    }
    final items = ref.read(cartControllerProvider);
    if (items.isEmpty) return;

    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).persistAddress(addr);
    } catch (_) {}

    final payload = <Map<String, dynamic>>[];
    for (final item in items) {
      final m = <String, dynamic>{
        'product_slug': item.slug,
        'quantity': item.qty,
      };
      final vid = item.variantId;
      if (vid != null && vid.isNotEmpty) {
        m['variant_id'] = vid;
      }
      payload.add(m);
    }

    try {
      await ref.read(checkoutRepositoryProvider).checkout(
            bearerToken: token,
            items: payload,
            deliveryAddress: addr,
          );
      ref.read(cartControllerProvider.notifier).clear();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заказ оформлен. Спасибо!')),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${e.body}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _CartLineCard extends StatelessWidget {
  const _CartLineCard({
    required this.item,
    required this.onOpenProduct,
    required this.onDec,
    required this.onInc,
  });

  final CartItem item;
  final VoidCallback onOpenProduct;
  final VoidCallback onDec;
  final VoidCallback onInc;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final subtitle = item.variantLabel ??
        (item.variantSku != null && item.variantSku!.isNotEmpty
            ? 'SKU: ${item.variantSku}'
            : null);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpenProduct,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: onOpenProduct,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: GrassColors.productImageBackground,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? GrassCachedNetworkImage(
                          url: item.imageUrl!,
                          width: 52,
                          height: 52,
                          fit: BoxFit.contain,
                          maxCacheSide: 160,
                        )
                      : Icon(Icons.image_outlined, color: scheme.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scheme.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: scheme.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '${item.unitPrice} ${item.currency}',
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  IconButton(
                    onPressed: onDec,
                    icon: const Icon(Icons.remove),
                  ),
                  Text('${item.qty}'),
                  IconButton(
                    onPressed: onInc,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutSection extends StatelessWidget {
  const _CheckoutSection({
    required this.auth,
    required this.addressCtrl,
    required this.guestPhoneCtrl,
    required this.submitting,
    required this.scheme,
    required this.textTheme,
    required this.onLogin,
    required this.onSubmit,
  });

  final AuthState auth;
  final TextEditingController addressCtrl;
  final TextEditingController guestPhoneCtrl;
  final bool submitting;
  final ColorScheme scheme;
  final TextTheme textTheme;
  final VoidCallback onLogin;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Доставка',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: guestPhoneCtrl,
                readOnly: auth.isAuthenticated,
                keyboardType: TextInputType.phone,
                inputFormatters: auth.isAuthenticated
                    ? null
                    : [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(9),
                      ],
                decoration: InputDecoration(
                  labelText: 'Телефон',
                  hintText: '9 рақам (бе +992)',
                  filled: auth.isAuthenticated,
                  fillColor: auth.isAuthenticated
                      ? scheme.surfaceContainerHighest.withValues(alpha: 0.35)
                      : null,
                  helperText: auth.isAuthenticated
                      ? 'Телефон привязан к аккаунту'
                      : 'Войдите — телефон подставится из профиля',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Адрес доставки',
                  hintText: 'Город, улица, дом, подъезд',
                ),
              ),
              const SizedBox(height: 12),
              if (!auth.isAuthenticated)
                OutlinedButton.icon(
                  onPressed: onLogin,
                  icon: const Icon(Icons.login),
                  label: const Text('Войти для оформления'),
                )
              else
                const SizedBox.shrink(),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: submitting ? null : onSubmit,
                child: submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Оформить заказ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
