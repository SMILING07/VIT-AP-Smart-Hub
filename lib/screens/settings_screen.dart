import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/vtop_data_provider.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<Map<String, String>> _accounts = [];
  String? _activeRegNo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final active = await authProvider.getActiveRegNo();
    final accounts = await authProvider.getSavedAccounts();

    if (mounted) {
      setState(() {
        _activeRegNo = active;
        _accounts = accounts;
        _isLoading = false;
      });
    }
  }

  Future<void> _switchAccount(String regNo, String password) async {
    if (regNo == _activeRegNo) return; // already active

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final dataProv = Provider.of<VtopDataProvider>(context, listen: false);

    // Clear data but keep semester
    dataProv.clearAllData();

    setState(() => _isLoading = true);
    await auth.login(regNo, password);

    if (auth.isAuthenticated) {
      await _loadAccounts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Switched to $regNo seamlessly!')),
        );
        Navigator.pop(context); // Return to Dashboard for fresh reload
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to login with $regNo')));
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeAccount(String regNo) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.removeAccount(regNo);
    await _loadAccounts();
    if (!auth.isAuthenticated && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (r) => false,
      );
    }
  }

  void _showAddAccountDialog() {
    final regCtrl = TextEditingController();
    final pwdCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : AppTheme.lightTextColor;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.surfaceColor : Colors.white,
          title: Text('Add Account', style: TextStyle(color: textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: regCtrl,
                style: TextStyle(color: textColor),
                decoration: const InputDecoration(labelText: 'Registration No'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pwdCtrl,
                obscureText: true,
                style: TextStyle(color: textColor),
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _switchAccount(regCtrl.text.trim(), pwdCtrl.text.trim());
              },
              child: const Text('Add & Switch'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.lightTextColor;
    final secondaryTextColor = isDark
        ? Colors.white54
        : AppTheme.lightTextSecondaryColor;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.backgroundColor
          : AppTheme.lightBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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

                  // Profile & Preferences
                  Consumer<VtopDataProvider>(
                    builder: (context, provider, child) {
                      return Card(
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
                                    Icons.person_pin,
                                    color: AppTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Profile & Preferences',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.color,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller:
                                    TextEditingController(
                                        text: provider.userName,
                                      )
                                      ..selection = TextSelection.fromPosition(
                                        TextPosition(
                                          offset:
                                              provider.userName?.length ?? 0,
                                        ),
                                      ),
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Your Name',
                                  hintText: 'Enter your name for the dashboard',
                                  prefixIcon: Icon(
                                    Icons.badge,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                onChanged: (val) =>
                                    provider.setUserName(val.trim()),
                              ),
                              const SizedBox(height: 20),
                              DropdownButtonFormField<String>(
                                initialValue: provider.userHostel,
                                dropdownColor: Theme.of(context).cardColor,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Select Hostel',
                                  prefixIcon: Icon(
                                    Icons.hotel,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                items:
                                    [
                                          'MH1',
                                          'MH2',
                                          'MH3',
                                          'MH4',
                                          'MH5',
                                          'LH1',
                                          'LH2',
                                          'LH3',
                                          'LH4',
                                        ]
                                        .map(
                                          (h) => DropdownMenuItem(
                                            value: h,
                                            child: Text(h),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (val) {
                                  if (val != null) provider.setUserHostel(val);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

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
                              const Icon(
                                Icons.palette,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'App Appearance',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.color,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Consumer<ThemeProvider>(
                            builder: (context, themeProvider, child) {
                              final isDark =
                                  themeProvider.themeMode == ThemeMode.dark;
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isDark ? 'Dark Mode' : 'Light Mode',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Switch(
                                    value: isDark,
                                    activeTrackColor: AppTheme.primaryColor,
                                    onChanged: (bool value) {
                                      themeProvider.setThemeMode(
                                        value
                                            ? ThemeMode.dark
                                            : ThemeMode.light,
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

                  // Accounts Manager
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.people_alt,
                                    color: AppTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Saved Accounts',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.color,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.person_add,
                                  color: AppTheme.primaryColor,
                                ),
                                onPressed: _showAddAccountDialog,
                                tooltip: 'Add Account',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_accounts.isEmpty)
                            Text(
                              'No accounts saved.',
                              style: TextStyle(color: secondaryTextColor),
                            ),
                          ..._accounts.map((acc) {
                            final isAct = acc['regNo'] == _activeRegNo;
                            return Container(
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: isAct
                                    ? AppTheme.primaryColor.withValues(
                                        alpha: 0.15,
                                      )
                                    : (isDark
                                          ? AppTheme.surfaceColor
                                          : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isAct
                                      ? AppTheme.primaryColor
                                      : Colors.transparent,
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isAct
                                      ? AppTheme.primaryColor
                                      : (isDark
                                            ? Colors.white12
                                            : Colors.black12),
                                  child: Icon(
                                    Icons.person,
                                    color: isAct
                                        ? Colors.white
                                        : (isDark
                                              ? Colors.white70
                                              : Colors.black54),
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  acc['regNo']!,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  isAct ? 'Active Account' : 'Tap to switch',
                                  style: TextStyle(
                                    color: isAct
                                        ? AppTheme.primaryColor
                                        : secondaryTextColor,
                                    fontSize: 12,
                                  ),
                                ),
                                onTap: () => _switchAccount(
                                  acc['regNo']!,
                                  acc['password']!,
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: isAct
                                        ? Colors.white70
                                        : AppTheme.errorColor,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      _removeAccount(acc['regNo']!),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
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
                                  color: Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.color,
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
            ),
    );
  }
}
