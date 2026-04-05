import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/vtop_data_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'utils/app_theme.dart';
import 'src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await RustLib.init();
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProxyProvider<AuthProvider, VtopDataProvider>(
            create: (context) {
              final auth = context.read<AuthProvider>();
              return VtopDataProvider(auth.apiService, auth.activeRegNoSync);
            },
            update: (context, auth, previous) {
              final newRegNo = auth.activeRegNoSync;
              final oldRegNo = previous?.currentRegNo;

              if (auth.isAuthenticated &&
                  newRegNo != null &&
                  newRegNo != oldRegNo) {
                // Account switched or first login — create fresh provider with new regNo
                // The new provider will pre-load from cache in its constructor
                return VtopDataProvider(auth.apiService, newRegNo);
              }

              if (!auth.isAuthenticated) {
                previous?.resetState();
              }

              return previous ?? VtopDataProvider(auth.apiService, null);
            },
          ),
        ],
        child: const VitApSmartHubApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('FAILED TO START RUST LIB: $e');
    debugPrint(stack.toString());

    // Simple retry tracker
    _retryCount++;

    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    'Initialization Error',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The app failed to initialize the Rust backend. \nError: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (_retryCount > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Retry Attempt: $_retryCount',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => main(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

int _retryCount = 0;

class VitApSmartHubApp extends StatefulWidget {
  const VitApSmartHubApp({super.key});

  @override
  State<VitApSmartHubApp> createState() => _VitApSmartHubAppState();
}

class _VitApSmartHubAppState extends State<VitApSmartHubApp> {
  @override
  void initState() {
    super.initState();
    // Initialize auth state on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Smart Hub',
          themeMode: themeProvider.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: Consumer<AuthProvider>(
            builder: (context, auth, child) {
              if (!auth.isInitialized) {
                return const Scaffold(
                  backgroundColor: Color(0xFF121212),
                  body: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                );
              }
              if (auth.isAuthenticated) {
                return const HomeScreen();
              }
              return const LoginScreen();
            },
          ),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
