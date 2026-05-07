// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:grass_app/src/app.dart';
import 'package:grass_app/src/api/api_client.dart';
import 'package:grass_app/src/features/search/product_search_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('App builds smoke test', (WidgetTester tester) async {
    final mock = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/api/v1/categories/')) {
        return http.Response(
          '{"count":6,"next":null,"previous":null,"results":[{"id":"1","name":"Для дома","slug":"home","image_url":null},{"id":"2","name":"Косметика","slug":"cosm","image_url":null},{"id":"3","name":"Для авто","slug":"auto","image_url":null},{"id":"4","name":"Оборудование","slug":"equip","image_url":null},{"id":"5","name":"Для бизнеса","slug":"biz","image_url":null},{"id":"6","name":"Промо","slug":"promo","image_url":null}]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (path.endsWith('/api/v1/notifications/unread-count/')) {
        return http.Response('{"count":0}', 200, headers: {'content-type': 'application/json'});
      }
      if (path.endsWith('/api/v1/notifications/')) {
        return http.Response(
          '{"count":0,"next":null,"previous":null,"results":[]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (path.endsWith('/api/v1/products/')) {
        return http.Response(
          '{"count":0,"next":null,"previous":null,"results":[]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('{"count":0,"results":[]}', 200, headers: {'content-type': 'application/json'});
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(ApiClient(httpClient: mock)),
        ],
        child: const GrassApp(),
      ),
    );
    expect(find.text('Войти'), findsOneWidget);

    // Splash auto-navigates after 600ms.
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pumpAndSettle();

    // Shop demo-loading finishes after 800ms.
    await tester.pump(const Duration(milliseconds: 850));
    await tester.pumpAndSettle();
  });
}
