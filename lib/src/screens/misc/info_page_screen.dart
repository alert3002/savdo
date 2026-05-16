import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../config/app_config.dart';
import '../../ui/navigation/shop_layer_app_bar.dart';

enum InfoPageKey {
  about,
  delivery,
  payment,
  returns,
  privacy,
  support,
}

class InfoPageScreen extends StatefulWidget {
  const InfoPageScreen({
    super.key,
    required this.page,
  });

  final InfoPageKey page;

  @override
  State<InfoPageScreen> createState() => _InfoPageScreenState();
}

class _InfoPageScreenState extends State<InfoPageScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final url = _urlForPage(widget.page);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  static String _urlForPage(InfoPageKey page) {
    final base = AppConfig.publicBaseUrl.replaceAll(RegExp(r'\/+$'), '');
    return switch (page) {
      InfoPageKey.privacy => '$base/politika/',
      InfoPageKey.support => '$base/podderzhka/',
      InfoPageKey.about => '$base/politika/',
      InfoPageKey.delivery => '$base/politika/',
      InfoPageKey.payment => '$base/politika/',
      InfoPageKey.returns => '$base/politika/',
    };
  }

  static String _titleForPage(InfoPageKey page) => switch (page) {
        InfoPageKey.about => 'О нас',
        InfoPageKey.delivery => 'Условия доставки',
        InfoPageKey.payment => 'Как оплатить',
        InfoPageKey.returns => 'Возврат',
        InfoPageKey.privacy => 'Политика конфиденциальности',
        InfoPageKey.support => 'Поддержка',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForPage(widget.page)),
        actions: shopLayerAppBarActions(context),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
