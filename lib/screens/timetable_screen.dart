import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for UI demonstration
    final List<Map<String, String>> todayClasses = [
      {
        'time': '08:00 AM - 09:30 AM',
        'course': 'CSE1001',
        'type': 'Theory',
        'venue': 'AB1-402',
      },
      {
        'time': '10:00 AM - 11:30 AM',
        'course': 'MAT2001',
        'type': 'Theory',
        'venue': 'CB-210',
      },
      {
        'time': '02:00 PM - 03:30 PM',
        'course': 'CSE2005',
        'type': 'Lab',
        'venue': 'Lab-12',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: todayClasses.length,
      itemBuilder: (context, index) {
        final classInfo = todayClasses[index];
        final isLab = classInfo['type'] == 'Lab';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: AppTheme.surfaceColor,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border(
                left: BorderSide(
                  color: isLab
                      ? AppTheme.secondaryColor
                      : AppTheme.primaryColor,
                  width: 6,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        classInfo['time']!,
                        style: const TextStyle(
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isLab
                              ? AppTheme.secondaryColor.withValues(alpha: 0.1)
                              : AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          classInfo['type']!,
                          style: TextStyle(
                            color: isLab
                                ? AppTheme.secondaryColor
                                : AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    classInfo['course']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white54,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        classInfo['venue']!,
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
