import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const VitApSmartHubApp(),
    ),
  );
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
