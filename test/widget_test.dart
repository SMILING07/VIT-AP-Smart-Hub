import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vit_ap_smart_hub/main.dart';
import 'package:vit_ap_smart_hub/providers/auth_provider.dart';
import 'package:vit_ap_smart_hub/providers/theme_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const VitApSmartHubApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(VitApSmartHubApp), findsOneWidget);
  });
}
