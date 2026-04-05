import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vtop_data_provider.dart';
import '../src/rust/api/vtop/types.dart';
import '../utils/app_theme.dart';
import '../widgets/semester_selector.dart';

class MarksScreen extends StatefulWidget {
  const MarksScreen({super.key});

  @override
  State<MarksScreen> createState() => _MarksScreenState();
}

class _MarksScreenState extends State<MarksScreen> {
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
        p.fetchMarks();
      });
    } else {
      _selectCurrentSemester(p);
      if (p.marksData == null) {
        p.fetchMarks();
      }
    }
  }

  void _selectCurrentSemester(VtopDataProvider p) {
    if (p.defaultSemesterId != null) {
      if (p.selectedSemesterId == null) {
        p.setSelectedSemester(p.defaultSemesterId!);
      }
    } else if (p.semesterData != null && p.semesterData!.semesters.isNotEmpty) {
      if (p.selectedSemesterId == null) {
        p.setSelectedSemester(p.semesterData!.semesters.first.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Marks',
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
                  provider.marksData?.semesterId != provider.selectedSemesterId)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => provider.fetchMarks(),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Load Marks'),
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
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => provider.fetchMarks(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final records = provider.marksData?.records ?? [];
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.score_outlined,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white30
                  : Colors.black26,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No marks data',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white54
                    : Colors.black45,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => provider.fetchMarks(),
              icon: const Icon(Icons.download),
              label: const Text('Fetch Marks'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchMarks(force: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: records.length,
        itemBuilder: (ctx, i) => _MarksCard(record: records[i]),
      ),
    );
  }
}

class _MarksCard extends StatefulWidget {
  final MarksRecord record;
  const _MarksCard({required this.record});

  @override
  State<_MarksCard> createState() => _MarksCardState();
}

class _MarksCardState extends State<_MarksCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final marks = widget.record.marks;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.record.coursecode,
                          style: const TextStyle(
                            color: AppTheme.secondaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.record.coursetitle,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.displayLarge?.color,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.record.coursetype}  ·  Slot: ${widget.record.slot}',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded && marks.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Assessment',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black45,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Max',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black45,
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Scored',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black45,
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Wtg',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black45,
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...marks.map(
                    (m) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              m.markstitle,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              m.maxmarks,
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              m.scoredmark.isEmpty ? '-' : m.scoredmark,
                              style: TextStyle(
                                color: m.scoredmark.isEmpty
                                    ? (isDark ? Colors.white30 : Colors.black26)
                                    : AppTheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              m.weightagemark.isEmpty ? '-' : m.weightagemark,
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
