import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vtop_data_provider.dart';
import '../src/rust/api/vtop/types.dart';
import '../utils/app_theme.dart';
import '../widgets/semester_selector.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  String? _localSemesterId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final p = context.read<VtopDataProvider>();
    if (p.semesterData == null) {
      p.fetchSemesters().then((_) {
        _localSemesterId ??= p.previousSemesterId ?? p.defaultSemesterId;
        if (_localSemesterId != null) {
          p.fetchGradeView(semId: _localSemesterId);
        }
      });
    } else {
      _localSemesterId ??= p.previousSemesterId ?? p.defaultSemesterId;
      if (p.gradeViewData == null ||
          p.gradeViewData?.semesterId != _localSemesterId) {
        if (_localSemesterId != null) {
          p.fetchGradeView(semId: _localSemesterId);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Grades',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<VtopDataProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              SemesterSelectorWidget(
                selectedSemId: _localSemesterId,
                onChanged: (semId) {
                  setState(() => _localSemesterId = semId);
                  provider.fetchGradeView(semId: semId);
                },
              ),
              if (_localSemesterId != null &&
                  provider.gradeViewData?.semesterId != _localSemesterId)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          provider.fetchGradeView(semId: _localSemesterId),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Load Grades'),
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
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => provider.fetchGradeView(semId: _localSemesterId),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final courses = provider.gradeViewData?.courses ?? [];
    if (courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grade_outlined, color: Colors.white30, size: 64),
            const SizedBox(height: 16),
            const Text(
              'No grade data',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => provider.fetchGradeView(semId: _localSemesterId),
              icon: const Icon(Icons.download),
              label: const Text('Fetch Grades'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchGradeView(force: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: courses.length,
        itemBuilder: (ctx, i) => _GradeCard(course: courses[i]),
      ),
    );
  }
}

Color _gradeColor(String grade) {
  switch (grade.toUpperCase()) {
    case 'S':
      return const Color(0xFF00e676);
    case 'A':
      return const Color(0xFF69f0ae);
    case 'B':
      return const Color(0xFF40c4ff);
    case 'C':
      return const Color(0xFFffff00);
    case 'D':
      return const Color(0xFFffab40);
    case 'E':
      return const Color(0xFFff6e40);
    case 'F':
      return const Color(0xFFff1744);
    default:
      return Colors.white54;
  }
}

class _GradeCard extends StatelessWidget {
  final GradeCourseRecord course;
  const _GradeCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradeColor = _gradeColor(course.grade);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (course.courseId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GradeDetailPage(
                  course: course,
                  semesterId: context
                      .read<_GradesScreenState>()
                      ._localSemesterId,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: gradeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: gradeColor.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    course.grade.isEmpty ? '?' : course.grade,
                    style: TextStyle(
                      color: gradeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.courseCode,
                      style: const TextStyle(
                        color: AppTheme.secondaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      course.courseTitle,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.displayLarge?.color,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          course.courseType,
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 11,
                          ),
                        ),
                        if (course.grandTotal.isNotEmpty) ...[
                          Text(
                            '  ·  ',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                          Text(
                            'Total: ${course.grandTotal}',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.white30 : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Grade Detail Page ───────────────────────────────────────────────────────
class GradeDetailPage extends StatefulWidget {
  final GradeCourseRecord course;
  final String? semesterId;
  const GradeDetailPage({super.key, required this.course, this.semesterId});

  @override
  State<GradeDetailPage> createState() => _GradeDetailPageState();
}

class _GradeDetailPageState extends State<GradeDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VtopDataProvider>().fetchGradeDetails(
        widget.course.courseId,
        semId: widget.semesterId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.course.courseCode,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<VtopDataProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = provider.getGradeDetails(widget.course.courseId);
          if (data == null) {
            return Center(
              child: FilledButton(
                onPressed: () => provider.fetchGradeDetails(
                  widget.course.courseId,
                  semId: widget.semesterId,
                ),
                child: const Text('Load Details'),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                widget.course.courseTitle,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _InfoChip(
                    'Grade',
                    widget.course.grade,
                    _gradeColor(widget.course.grade),
                  ),
                  const SizedBox(width: 8),
                  _InfoChip('Total', data.grandTotal, AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  _InfoChip(
                    'Type',
                    data.classCourseType,
                    AppTheme.secondaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (data.marks.isNotEmpty) ...[
                const Text(
                  'Assessment Breakdown',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                ...data.marks.map((m) => _MarkRow(mark: m)),
              ],
              if (data.gradeRanges.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Grade Ranges',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: data.gradeRanges
                      .map(
                        (gr) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _gradeColor(
                              gr.grade,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _gradeColor(
                                gr.grade,
                              ).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                gr.grade,
                                style: TextStyle(
                                  color: _gradeColor(gr.grade),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                gr.range,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _InfoChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Column(
      children: [
        Text(
          value.isEmpty ? '—' : value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 11),
        ),
      ],
    ),
  );
}

class _MarkRow extends StatelessWidget {
  final GradeDetailMark mark;
  const _MarkRow({required this.mark});

  @override
  Widget build(BuildContext context) {
    final scored = double.tryParse(mark.scoredMark);
    final max = double.tryParse(mark.maxMark);
    final fraction = (scored != null && max != null && max > 0)
        ? scored / max
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  mark.markTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                mark.scoredMark.isEmpty
                    ? 'Pending'
                    : '${mark.scoredMark} / ${mark.maxMark}',
                style: TextStyle(
                  color: mark.scoredMark.isEmpty
                      ? Colors.white38
                      : AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (fraction != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction.clamp(0.0, 1.0),
                backgroundColor: Colors.white12,
                color: fraction > 0.6
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
