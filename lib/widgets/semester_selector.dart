import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vtop_data_provider.dart';
import '../utils/app_theme.dart';

class SemesterSelectorWidget extends StatelessWidget {
  const SemesterSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
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
        final selected = provider.selectedSemesterId;

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
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.4)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selected ?? semesters.first.id,
                dropdownColor: AppTheme.surfaceColor,
                style: const TextStyle(color: Colors.white),
                icon: Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryColor),
                items: semesters.map((sem) {
                  return DropdownMenuItem<String>(
                    value: sem.id,
                    child: Text(
                      sem.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    provider.setSelectedSemester(value);
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
