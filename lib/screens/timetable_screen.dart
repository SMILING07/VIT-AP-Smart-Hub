import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vtop_data_provider.dart';
import '../src/rust/api/vtop/types.dart';
import '../utils/app_theme.dart';
import '../widgets/semester_selector.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  String _slotFilter = 'All';

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
        p.fetchTimetable();
      });
    } else {
      _selectCurrentSemester(p);
      if (p.timetableData == null) {
        p.fetchTimetable();
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
    return Consumer<VtopDataProvider>(
      builder: (context, provider, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final slots = provider.timetableData?.slots ?? [];
        final Set<String> activeDayPrefixes = slots
            .map(
              (s) => s.day.toUpperCase().length >= 3
                  ? s.day.toUpperCase().substring(0, 3)
                  : '',
            )
            .where((s) => s.isNotEmpty)
            .toSet();

        final List<String> standardDays = [
          'MON',
          'TUE',
          'WED',
          'THU',
          'FRI',
          'SAT',
        ];
        final dynamicDays = standardDays
            .where((d) => activeDayPrefixes.contains(d))
            .toList();
        final tabsList = dynamicDays.isNotEmpty ? dynamicDays : ['MON'];

        // Calculate dates for the current week starting from Monday
        final now = DateTime.now();
        final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));

        final Map<String, String> dayToDate = {};
        for (int i = 0; i < 6; i++) {
          final date = firstDayOfWeek.add(Duration(days: i));
          final prefix = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'][i];
          dayToDate[prefix] = '${date.day}/${date.month}';
        }

        // Find current day index
        final dayPrefixes = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
        final currentDayPrefix = now.weekday <= 7
            ? dayPrefixes[now.weekday - 1]
            : 'MON';
        int initialIndex = tabsList.indexOf(currentDayPrefix);
        if (initialIndex == -1) initialIndex = 0;

        return DefaultTabController(
          length: tabsList.length,
          initialIndex: initialIndex,
          child: Column(
            children: [
              const SemesterSelectorWidget(),

              if (slots.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: ['All', 'Theory', 'Lab'].map((filter) {
                      final isSelected = _slotFilter == filter;
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
                            if (selected) setState(() => _slotFilter = filter);
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

              if (provider.selectedSemesterId != null &&
                  provider.timetableData?.semesterId !=
                      provider.selectedSemesterId)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => provider.fetchTimetable(),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Load Timetable'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),

              if (slots.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.surfaceColor
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.center,
                      labelColor: AppTheme.primaryColor,
                      unselectedLabelColor: isDark
                          ? Colors.white38
                          : Colors.black45,
                      indicatorColor: AppTheme.primaryColor,
                      indicatorPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                      ),
                      dividerColor: Colors.transparent,
                      tabs: tabsList
                          .map(
                            (d) => Tab(
                              height: 60,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    dayToDate[d] ?? '',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  Text(
                                    d,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: tabsList.map((day) {
                      var daySlots = slots.where(
                        (s) => s.day.toUpperCase().startsWith(day),
                      );
                      if (_slotFilter == 'Theory') {
                        daySlots = daySlots.where((s) => !s.isLab);
                      }
                      if (_slotFilter == 'Lab') {
                        daySlots = daySlots.where((s) => s.isLab);
                      }

                      final List<TimetableSlot> sortedSlots = daySlots.toList()
                        ..sort((a, b) => a.startTime.compareTo(b.startTime));
                      final finalSlots = _mergeLabSlots(sortedSlots);

                      if (finalSlots.isEmpty) {
                        return Center(
                          child: Text(
                            'No classes for this filter',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () => provider.fetchTimetable(force: true),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: finalSlots.length,
                          itemBuilder: (ctx, i) =>
                              _SlotCard(slot: finalSlots[i]),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ] else ...[
                Expanded(child: _buildEmptyOrLoading(context, provider)),
              ],
            ],
          ),
        );
      },
    );
  }

  List<TimetableSlot> _mergeLabSlots(List<TimetableSlot> slots) {
    if (slots.isEmpty) return [];

    final List<TimetableSlot> merged = [];
    int i = 0;

    while (i < slots.length) {
      final current = slots[i];

      // Look ahead to check for consecutive lab slots
      if (current.isLab && i + 1 < slots.length) {
        final next = slots[i + 1];
        if (next.isLab &&
            next.courseCode == current.courseCode &&
            next.startTime == current.endTime) {
          // Merge current and next
          merged.add(
            current.copyWith(
              endTime: next.endTime,
              slot: '${current.slot}+${next.slot}',
            ),
          );
          i += 2; // Skip next
          continue;
        }
      }

      merged.add(current);
      i++;
    }

    return merged;
  }

  Widget _buildEmptyOrLoading(BuildContext context, VtopDataProvider provider) {
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
              onPressed: () => provider.fetchTimetable(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_month_outlined,
            color: isDark ? Colors.white30 : Colors.black26,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No timetable data',
            style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => provider.fetchTimetable(),
            icon: const Icon(Icons.download),
            label: const Text('Fetch Timetable'),
          ),
        ],
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  final TimetableSlot slot;
  const _SlotCard({required this.slot});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLab = slot.isLab;
    final accentColor = isLab ? AppTheme.secondaryColor : AppTheme.primaryColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: accentColor, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    slot.startTime.isNotEmpty
                        ? '${slot.startTime} – ${slot.endTime}'
                        : slot.slot,
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isLab ? 'Lab' : 'Theory',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                slot.name.isNotEmpty ? slot.name : slot.courseCode,
                style: TextStyle(
                  color: Theme.of(context).textTheme.displayLarge?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (slot.courseCode.isNotEmpty)
                Text(
                  slot.courseCode,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: isDark ? Colors.white38 : Colors.black38,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${slot.roomNo} · ${slot.block}',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  if (slot.faculty.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.person,
                      color: isDark ? Colors.white38 : Colors.black38,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        slot.faculty,
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
