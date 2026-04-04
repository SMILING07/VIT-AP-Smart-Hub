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
          create: (context) => VtopDataProvider(context.read<AuthProvider>().apiService),
          update: (context, auth, previous) {
            final provider = previous ?? VtopDataProvider(auth.apiService);
            if (auth.isAuthenticated) {
              // On every login or account switch, we want fresh data
              // We can check if the current data belongs to the new user 
              // but a simple reset is safer for now as per requirements.
              provider.initializePreferences();
              provider.fetchSemesters();
            } else {
              provider.resetState();
            }
            return provider;
          },
        ),
        ],
        child: const VitApSmartHubApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('FAILED TO START RUST LIB: $e');
    debugPrint(stack.toString());
    runApp(MaterialApp(
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
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'The app failed to initialize the Rust backend. \nError: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => main(),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

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
          title: 'VIT AP Smart Hub',
          themeMode: themeProvider.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: Consumer<AuthProvider>(
            builder: (context, auth, child) {
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
