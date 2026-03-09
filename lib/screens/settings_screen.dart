import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _regNoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    setState(() => _isLoading = true);
    final regNo = await _secureStorage.read(key: 'vtop_regNo');
    final password = await _secureStorage.read(key: 'vtop_password');

    if (regNo != null) _regNoController.text = regNo;
    if (password != null) _passwordController.text = password;

    setState(() => _isLoading = false);
  }

  Future<void> _saveCredentials() async {
    final regNo = _regNoController.text.trim();
    final password = _passwordController.text.trim();

    if (regNo.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both Registration Number and Password.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    await _secureStorage.write(key: 'vtop_regNo', value: regNo);
    await _secureStorage.write(key: 'vtop_password', value: password);

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('VTOP Credentials saved securely!')),
      );
    }
  }

  Future<void> _clearCredentials() async {
    setState(() => _isLoading = true);
    await _secureStorage.delete(key: 'vtop_regNo');
    await _secureStorage.delete(key: 'vtop_password');
    _regNoController.clear();
    _passwordController.clear();
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('VTOP Credentials cleared.')),
      );
    }
  }

  @override
  void dispose() {
    _regNoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Settings',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 24),

          // App Appearance
          Card(
            color: Theme.of(context).cardColor,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.palette, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        'App Appearance',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.titleLarge?.color,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      final isDark = themeProvider.themeMode == ThemeMode.dark;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isDark ? 'Dark Mode' : 'Light Mode',
                            style: TextStyle(
                              color:
                                  Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color ??
                                  Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          Switch(
                            value: isDark,
                            activeTrackColor: AppTheme.primaryColor,
                            onChanged: (bool value) {
                              themeProvider.setThemeMode(
                                value ? ThemeMode.dark : ThemeMode.light,
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Credentials
          Card(
            color: Theme.of(context).cardColor,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              leading: const Icon(Icons.security, color: AppTheme.primaryColor),
              title: Text(
                'VTOP Credentials',
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Save your VTOP registration number and password to fetch real timetable and attendance data.',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 13,
                ),
              ),
              childrenPadding: const EdgeInsets.all(20.0),
              children: [
                TextField(
                  controller: _regNoController,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'VTOP Registration Number',
                    prefixIcon: Icon(
                      Icons.person,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'VTOP Password',
                    prefixIcon: Icon(Icons.lock, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clearCredentials,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.errorColor),
                          foregroundColor: AppTheme.errorColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _saveCredentials,
                        child: const Text('Save Credentials'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Account Actions
          Card(
            color: Theme.of(context).cardColor,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.account_circle,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Account Actions',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.titleLarge?.color,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      ).logout();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Log Out'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
