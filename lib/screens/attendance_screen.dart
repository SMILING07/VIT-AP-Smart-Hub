import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for UI demonstration
    final List<Map<String, dynamic>> attendanceData = [
      {
        'course': 'Problem Solving and OOP',
        'code': 'CSE1001',
        'percent': 85.5,
        'attended': 30,
        'total': 35,
      },
      {
        'course': 'Data Structures',
        'code': 'CSE2001',
        'percent': 74.2,
        'attended': 26,
        'total': 35,
      },
      {
        'course': 'Calculus for Engineers',
        'code': 'MAT1001',
        'percent': 90.0,
        'attended': 36,
        'total': 40,
      },
      {
        'course': 'Physics',
        'code': 'PHY1001',
        'percent': 65.0,
        'attended': 26,
        'total': 40,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: attendanceData.length,
      itemBuilder: (context, index) {
        final data = attendanceData[index];
        final percent = data['percent'] as double;
        final bool isWarning = percent < 75.0;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: AppTheme.surfaceColor,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: percent / 100,
                        backgroundColor: Colors.white10,
                        color: isWarning
                            ? AppTheme.errorColor
                            : AppTheme.successColor,
                        strokeWidth: 6,
                      ),
                      Center(
                        child: Text(
                          '${percent.toInt()}%',
                          style: TextStyle(
                            color: isWarning
                                ? AppTheme.errorColor
                                : Colors.white,
                            fontWeight: FontWeight.bold,
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
                        data['code'],
                        style: const TextStyle(
                          color: AppTheme.secondaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['course'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Classes: ${data['attended']} / ${data['total']}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
