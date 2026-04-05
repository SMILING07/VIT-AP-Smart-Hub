import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import 'attendance_screen.dart';
import 'timetable_screen.dart';
import 'settings_screen.dart';
import 'floor_map_screen.dart';
import 'file_converter_screen.dart';
import 'vtop_webview_screen.dart';
import 'cgpa_calculator_screen.dart';
import 'mess_menu_screen.dart';
import 'marks_screen.dart';
import 'grades_screen.dart';
import 'exam_schedule_screen.dart';
import '../services/update_service.dart';
import '../providers/vtop_data_provider.dart';
import '../src/rust/api/vtop/types.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _DashboardView(),
    const TimetableScreen(),
    const AttendanceScreen(),
    const ExamScheduleScreen(),
  ];

  Widget _buildToolsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('University Tools', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildGridIcon(Icons.score, 'Marks', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MarksScreen()),
              );
            }),
            _buildGridIcon(Icons.grade, 'Grades', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GradesScreen()),
              );
            }),
            _buildGridIcon(Icons.language, 'VTOP', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VtopWebviewScreen(),
                ),
              );
            }),
            _buildGridIcon(Icons.restaurant_menu, 'Menu', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MessMenuScreen()),
              );
            }),
            _buildGridIcon(Icons.map, 'Maps', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FloorMapScreen()),
              );
            }),
            _buildGridIcon(Icons.picture_as_pdf, 'Convert', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FileConverterScreen(),
                ),
              );
            }),
            _buildGridIcon(Icons.calculate, 'CGPA', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CgpaCalculatorScreen(),
                ),
              );
            }),
            _buildGridIcon(Icons.person, 'Profile', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildGridIcon(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 28),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : AppTheme.lightTextSecondaryColor,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
      // Preheat data for dashboard
      context.read<VtopDataProvider>().fetchSemesters().then((_) {
        if (!mounted) return;
        final p = context.read<VtopDataProvider>();
        Future.wait([p.fetchAttendance(), p.fetchTimetable()]);
      });
    });
  }

  Future<void> _checkForUpdates() async {
    final updateService = UpdateService(
      configUrl:
          'https://raw.githubusercontent.com/DARKSAPRO3x42/VIT-AP-Smart-Hub/main/update_config.json',
    );
    if (mounted) {
      await updateService.checkForUpdates(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Smart Hub',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            // Updated to be a scrollable row to fit more items
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard, 'Dashboard'),
                _buildNavItem(1, Icons.calendar_today, 'Timetable'),
                _buildNavItem(2, Icons.check_circle_outline, 'Attendance'),
                _buildNavItem(3, Icons.event_note, 'Exams'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label, {
    bool isAction = false,
  }) {
    bool isSelected = !isAction && _currentIndex == index;
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        if (isAction) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VtopWebviewScreen()),
          );
        } else {
          setState(() {
            _currentIndex = index;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.secondaryColor : AppTheme.primaryColor)
                    .withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                icon,
                key: ValueKey<bool>(isSelected),
                color: isSelected
                    ? (isDark ? AppTheme.secondaryColor : AppTheme.primaryColor)
                    : (isDark ? Colors.white54 : Colors.black54),
                size: isSelected ? 28 : 24,
              ),
            ),
            if (isSelected)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutQuint,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.secondaryColor
                          : AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Selector<
      VtopDataProvider,
      ({AttendanceData? attendanceData, TimetableData? timetableData})
    >(
      selector: (context, provider) => (
        attendanceData: provider.attendanceData,
        timetableData: provider.timetableData,
      ),
      builder: (context, data, child) {
        // Calculate overall attendance
        double overallPct = 0;
        if (data.attendanceData != null) {
          double totalAttended = 0, totalClasses = 0;
          for (final r in data.attendanceData!.records) {
            totalAttended += double.tryParse(r.classesAttended) ?? 0;
            totalClasses += double.tryParse(r.totalClasses) ?? 0;
          }
          overallPct = totalClasses > 0
              ? (totalAttended / totalClasses * 100)
              : 0.0;
        }

        // Calculate classes today
        int classesToday = 0;
        TimetableSlot? nextClass;
        if (data.timetableData != null) {
          final now = DateTime.now();
          final dayStrs = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
          final currentDay = dayStrs[now.weekday - 1];

          final todaysSlots =
              data.timetableData!.slots
                  .where((s) => s.day.toUpperCase().startsWith(currentDay))
                  .toList()
                ..sort((a, b) => a.startTime.compareTo(b.startTime));

          // Deduplicate consecutive slots of the same course in the same room
          int count = 0;
          TimetableSlot? lastSlot;
          for (final s in todaysSlots) {
            if (lastSlot == null ||
                s.courseCode != lastSlot.courseCode ||
                s.roomNo != lastSlot.roomNo ||
                s.startTime != lastSlot.endTime) {
              count++;
            }
            lastSlot = s;
          }
          classesToday = count;

          // Find the next class based on current time
          final currentTimeStr =
              "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

          // Find the next class (starts after now)
          try {
            nextClass = todaysSlots.firstWhere(
              (s) => s.startTime.compareTo(currentTimeStr) >= 0,
            );
          } catch (_) {
            // All classes done for today
            nextClass = null;
          }

          if (nextClass != null && nextClass.courseCode.isEmpty) {
            nextClass = null;
          }
        }

        return RefreshIndicator(
          onRefresh: () async {
            final p = context.read<VtopDataProvider>();
            await Future.wait([
              p.fetchAttendance(force: true),
              p.fetchTimetable(force: true),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer<VtopDataProvider>(
                  builder: (context, provider, _) {
                    final greeting =
                        provider.userName != null &&
                            provider.userName!.isNotEmpty
                        ? 'Welcome, ${provider.userName}!'
                        : 'Welcome back!';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (provider.isLoading)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: LinearProgressIndicator(
                              backgroundColor:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white10
                                  : Colors.black12,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        Text(
                          greeting,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Here is what is happening today',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Next Class Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, color: Colors.white, size: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nextClass != null
                                  ? 'Upcoming Class'
                                  : 'No upcoming classes',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nextClass != null
                                  ? '${nextClass.courseCode} - ${nextClass.roomNo}'
                                  : 'Enjoy your day!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                Text('Overview', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Overall Attendance',
                        value: data.attendanceData != null
                            ? '${overallPct.toStringAsFixed(1)}%'
                            : '--',
                        icon: Icons.pie_chart,
                        color: overallPct >= 75
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Classes Today',
                        value: data.timetableData != null
                            ? '$classesToday'
                            : '--',
                        icon: Icons.book,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                (context.findAncestorStateOfType<_HomeScreenState>()!)
                    ._buildToolsGrid(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
