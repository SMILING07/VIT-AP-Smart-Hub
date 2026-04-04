import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vtop_data_provider.dart';
import '../src/rust/api/vtop/types.dart';
import '../utils/app_theme.dart';
import '../widgets/semester_selector.dart';

class ExamScheduleScreen extends StatefulWidget {
  const ExamScheduleScreen({super.key});

  @override
  State<ExamScheduleScreen> createState() => _ExamScheduleScreenState();
}

class _ExamScheduleScreenState extends State<ExamScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final p = context.read<VtopDataProvider>();
    if (p.semesterData == null) {
      p.fetchSemesters().then((_) {
        _selectCurrentSemester(p);
        p.fetchExamSchedule();
      });
    } else {
      _selectCurrentSemester(p);
      if (p.examScheduleData == null) {
        p.fetchExamSchedule();
      }
    }
  }

  /// Always set the exam schedule to the current (date-based) semester,
  /// not the first one in the list which is usually the oldest.
  void _selectCurrentSemester(VtopDataProvider p) {
    final bestId = p.defaultSemesterId;
    if (bestId != null && p.selectedSemesterId != bestId) {
      p.setSelectedSemester(bestId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Exam Schedule',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<VtopDataProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              const SemesterSelectorWidget(),
              if (provider.selectedSemesterId != null &&
                  provider.examScheduleData?.semesterId !=
                      provider.selectedSemesterId)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => provider.fetchExamSchedule(),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Load Exam Schedule'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
              Expanded(child: _buildContent(provider)),
            ],
          );
        },
      ),
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
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => provider.fetchExamSchedule(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final exams = provider.examScheduleData?.exams ?? [];
    if (exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              color: isDark ? Colors.white30 : Colors.black26,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No exam schedule data',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => provider.fetchExamSchedule(),
              icon: const Icon(Icons.download),
              label: const Text('Fetch Schedule'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchExamSchedule(force: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: exams.length,
        itemBuilder: (ctx, i) => _ExamTypeSection(examTypeRecord: exams[i]),
      ),
    );
  }
}

class _ExamTypeSection extends StatelessWidget {
  final PerExamScheduleRecord examTypeRecord;
  const _ExamTypeSection({required this.examTypeRecord});

  @override
  Widget build(BuildContext context) {
    if (examTypeRecord.records.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
          child: Text(
            examTypeRecord.examType.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1,
            ),
          ),
        ),
        ...examTypeRecord.records.map((e) => _ExamCard(exam: e)),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ExamCard extends StatelessWidget {
  final ExamScheduleRecord exam;
  const _ExamCard({required this.exam});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    exam.examDate.isEmpty ? 'TBD' : exam.examDate,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  exam.examSession,
                  style: const TextStyle(
                    color: AppTheme.secondaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              exam.courseName,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  exam.courseCode,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '  ·  ',
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                Text(
                  exam.courseType,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '  ·  ',
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                Text(
                  'Slot: ${exam.slot}',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: isDark ? Colors.white10 : Colors.black12),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _InfoCol(
                    icon: Icons.access_time,
                    label: 'Reporting',
                    value: exam.reportingTime,
                  ),
                ),
                Expanded(
                  child: _InfoCol(
                    icon: Icons.timer,
                    label: 'Exam Time',
                    value: exam.examTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InfoCol(
                    icon: Icons.location_on,
                    label: 'Venue',
                    value: exam.venue,
                  ),
                ),
                Expanded(
                  child: _InfoCol(
                    icon: Icons.event_seat,
                    label: 'Seat',
                    value: '${exam.seatLocation} - ${exam.seatNo}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCol extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoCol({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: isDark ? Colors.white24 : Colors.black26, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
