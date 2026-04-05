import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vtop_data_provider.dart';
import '../src/rust/api/vtop/types.dart';
import '../utils/app_theme.dart';
import '../widgets/semester_selector.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final p = context.read<VtopDataProvider>();
    if (p.semesterData == null) {
      p.fetchSemesters().then((_) {
        if (p.defaultSemesterId != null) {
          p.setSelectedSemester(p.defaultSemesterId!);
        }
        p.fetchAttendance();
      });
    } else {
      if (p.selectedSemesterId == null && p.defaultSemesterId != null) {
        p.setSelectedSemester(p.defaultSemesterId!);
      }
      if (p.attendanceData == null) {
        p.fetchAttendance();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VtopDataProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            const SemesterSelectorWidget(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: ['All', 'Theory', 'Lab'].map((filter) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedFilter = filter);
                      },
                      selectedColor: AppTheme.primaryColor,
                      backgroundColor: isDark
                          ? AppTheme.surfaceColor
                          : Colors.grey.shade200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: BorderSide.none,
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(child: _buildContent(provider)),
          ],
        );
      },
    );
  }

  Widget _buildContent(VtopDataProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
            const SizedBox(height: 12),
            Text(
              provider.error!,
              style: TextStyle(
                color: (Theme.of(context).brightness == Brightness.dark)
                    ? Colors.white70
                    : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => provider.fetchAttendance(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final rawRecords = provider.attendanceData?.records ?? [];
    final records = rawRecords.where((r) {
      if (_selectedFilter == 'All') return true;
      final category = r.category.toUpperCase();
      final type = r.courseType.toUpperCase();

      final isTheory =
          category.contains('THEORY') ||
          category.contains('ETH') ||
          type.contains('THEORY') ||
          type.contains('ETH') ||
          category.contains('EMBEDDED') ||
          type.contains('EMBEDDED');

      final isLab =
          category.contains('LAB') ||
          category.contains('ELA') ||
          type.contains('LAB') ||
          type.contains('ELA') ||
          category.contains('PRACTICAL') ||
          type.contains('PRACTICAL');

      if (_selectedFilter == 'Theory') return isTheory && !isLab;
      if (_selectedFilter == 'Lab') return isLab;
      return true;
    }).toList();

    if (records.isEmpty && rawRecords.isNotEmpty) {
      return Center(
        child: Text(
          'No courses match this filter',
          style: TextStyle(
            color: (Theme.of(context).brightness == Brightness.dark)
                ? Colors.white38
                : Colors.black38,
          ),
        ),
      );
    }

    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              color: isDark ? Colors.white30 : Colors.black26,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No attendance data',
              style: TextStyle(
                color: (Theme.of(context).brightness == Brightness.dark)
                    ? Colors.white54
                    : Colors.black45,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => provider.fetchAttendance(),
              icon: const Icon(Icons.download),
              label: const Text('Fetch Attendance'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchAttendance(force: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: records.length,
        itemBuilder: (ctx, i) => _AttendanceCard(record: records[i]),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final AttendanceRecord record;
  const _AttendanceCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pctStr = record.attendancePercentage.replaceAll('%', '').trim();
    final pct = double.tryParse(pctStr) ?? 0.0;
    final isWarning = pct < 75.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FullAttendancePage(record: record)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: pct.clamp(0.0, 100.0) / 100,
                      backgroundColor: isDark ? Colors.white10 : Colors.black12,
                      color: isWarning
                          ? AppTheme.errorColor
                          : AppTheme.successColor,
                      strokeWidth: 6,
                    ),
                    Center(
                      child: Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: isWarning
                              ? AppTheme.errorColor
                              : (isDark ? Colors.white : Colors.black),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.courseCode,
                      style: const TextStyle(
                        color: AppTheme.secondaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.courseName,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.displayLarge?.color,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${record.classesAttended}/${record.totalClasses} classes',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (isWarning
                                        ? AppTheme.errorColor
                                        : AppTheme.successColor)
                                    .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            record.category,
                            style: TextStyle(
                              fontSize: 10,
                              color: isWarning
                                  ? AppTheme.errorColor
                                  : AppTheme.successColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.white30 : Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Full Attendance Drilldown ───────────────────────────────────────────────
class FullAttendancePage extends StatefulWidget {
  final AttendanceRecord record;
  const FullAttendancePage({super.key, required this.record});

  @override
  State<FullAttendancePage> createState() => _FullAttendancePageState();
}

class _FullAttendancePageState extends State<FullAttendancePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VtopDataProvider>().fetchFullAttendance(
        widget.record.courseId,
        widget.record.courseType,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.record.courseCode,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<VtopDataProvider>(
        builder: (context, provider, _) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = provider.getFullAttendance(
            widget.record.courseId,
            widget.record.courseType,
          );
          if (data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: isDark ? Colors.white30 : Colors.black26,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No detail data',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => provider.fetchFullAttendance(
                      widget.record.courseId,
                      widget.record.courseType,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final records = data.records;
          final presentCount = records
              .where((r) => r.status.toLowerCase().contains('present'))
              .length;
          final absentCount = records
              .where((r) => r.status.toLowerCase().contains('absent'))
              .length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                widget.record.courseName,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatChip(
                    label: 'Present',
                    value: presentCount,
                    color: AppTheme.successColor,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    label: 'Absent',
                    value: absentCount,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    label: 'Total',
                    value: records.length,
                    color: AppTheme.secondaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...records.map((r) => _FullAttRow(record: r)),
            ],
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 11),
        ),
      ],
    ),
  );
}

class _FullAttRow extends StatelessWidget {
  final FullAttendanceRecord record;
  const _FullAttRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusLower = record.status.toLowerCase();
    final isPresent = statusLower.contains('present');
    final isOD = statusLower.contains('od') || statusLower.contains('on duty');

    Color statusColor = AppTheme.errorColor;
    if (isPresent) statusColor = AppTheme.successColor;
    if (isOD) statusColor = Colors.amber;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.date,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${record.slot}  ·  ${record.dayTime}',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              record.status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
