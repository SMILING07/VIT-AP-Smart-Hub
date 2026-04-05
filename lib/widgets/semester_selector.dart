import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vtop_data_provider.dart';
import '../utils/app_theme.dart';

class SemesterSelectorWidget extends StatelessWidget {
  final String? selectedSemId;
  final void Function(String)? onChanged;

  const SemesterSelectorWidget({super.key, this.selectedSemId, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<VtopDataProvider>(
      builder: (context, provider, _) {
        if (provider.semesterData == null && !provider.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              provider.fetchSemesters();
            }
          });
        }

        final semesters = provider.semesterData?.semesters ?? [];
        final selected = selectedSemId ?? provider.selectedSemesterId;

        if (provider.isLoading && semesters.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(),
          );
        }

        if (semesters.isEmpty) {
          return TextButton.icon(
            onPressed: () => provider.fetchSemesters(),
            icon: const Icon(Icons.refresh),
            label: const Text('Load Semesters'),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selected ?? semesters.first.id,
                dropdownColor: isDark ? AppTheme.surfaceColor : Colors.white,
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextColor,
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: AppTheme.primaryColor,
                ),
                iconSize: 24,
                items: semesters.map((sem) {
                  return DropdownMenuItem<String>(
                    value: sem.id,
                    child: Text(
                      sem.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.lightTextColor,
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    if (onChanged != null) {
                      onChanged!(value);
                    } else {
                      provider.setSelectedSemester(value);
                    }
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
