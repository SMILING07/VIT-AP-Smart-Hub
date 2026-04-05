import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vit_ap_smart_hub/main.dart';
import 'package:vit_ap_smart_hub/providers/auth_provider.dart';
import 'package:vit_ap_smart_hub/providers/theme_provider.dart';
import 'package:vit_ap_smart_hub/providers/vtop_data_provider.dart';
import 'package:vit_ap_smart_hub/services/vtop_api_service.dart';

// Simple mock to avoid native dependencies in tests
class MockAuthProvider extends AuthProvider {
  @override
  Future<void> checkAuthStatus() async {
    // Do nothing/Already initialized for test
  }
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final mockAuth = MockAuthProvider();
    
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(
            create: (context) => VtopDataProvider(VtopApiService(), null),
          ),
        ],
        child: const VitApSmartHubApp(),
      ),
    );

    await tester.pump();

    expect(find.byType(VitApSmartHubApp), findsOneWidget);
  });
}
