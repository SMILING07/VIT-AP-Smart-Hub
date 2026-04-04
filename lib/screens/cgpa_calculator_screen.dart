import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class CourseItem {
  String name;
  double credits;
  String grade;

  CourseItem({required this.name, required this.credits, required this.grade});
}

class CgpaCalculatorScreen extends StatefulWidget {
  const CgpaCalculatorScreen({super.key});

  @override
  State<CgpaCalculatorScreen> createState() => _CgpaCalculatorScreenState();
}

class _CgpaCalculatorScreenState extends State<CgpaCalculatorScreen> {
  final List<CourseItem> _courses = [];

  // VIT Grading system mapping
  final Map<String, int> _gradePoints = {
    'S': 10,
    'A': 9,
    'B': 8,
    'C': 7,
    'D': 6,
    'E': 5,
    'F': 0,
    'N': 0,
  };

  void _addCourse() {
    setState(() {
      _courses.add(CourseItem(name: '', credits: 3.0, grade: 'S'));
    });
  }

  void _removeCourse(int index) {
    setState(() {
      _courses.removeAt(index);
    });
  }

  double _calculateCGPA() {
    if (_courses.isEmpty) return 0.0;

    double totalCreditPoints = 0.0;
    double totalCredits = 0.0;

    for (var course in _courses) {
      int gradePoint = _gradePoints[course.grade] ?? 0;
      totalCreditPoints += (course.credits * gradePoint);
      totalCredits += course.credits;
    }

    if (totalCredits == 0) return 0.0;

    return totalCreditPoints / totalCredits;
  }

  @override
  void initState() {
    super.initState();
    // Start with 0 courses as requested
  }

  @override
  Widget build(BuildContext context) {
    final cgpa = _calculateCGPA();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CGPA Calculator'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // CGPA Display Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
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
            child: Column(
              children: [
                const Text(
                  'Your Calculated CGPA',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  cgpa.toStringAsFixed(2),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Courses', style: Theme.of(context).textTheme.titleLarge),
                TextButton.icon(
                  onPressed: _addCourse,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Course'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Course List
          Expanded(
            child: _courses.isEmpty
                ? const Center(
                    child: Text('No courses added yet. Add a course to start.'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _courses.length,
                    itemBuilder: (context, index) {
                      return _buildCourseCard(index, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(int index, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delete button
            IconButton(
              onPressed: () => _removeCourse(index),
              icon: const Icon(Icons.remove_circle, color: AppTheme.errorColor),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),

            // Course Info
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      // Credits Input
                      Expanded(
                        child: DropdownButtonFormField<double>(
                          decoration: const InputDecoration(
                            labelText: 'Credits',
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          initialValue: _courses[index].credits,
                          items: [1.0, 1.5, 2.0, 3.0, 4.0, 5.0, 20.0]
                              .map(
                                (credit) => DropdownMenuItem(
                                  value: credit,
                                  child: Text(credit.toString()),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _courses[index].credits = val;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Grade Input
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Grade',
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          initialValue: _courses[index].grade,
                          items: _gradePoints.keys
                              .map(
                                (grade) => DropdownMenuItem(
                                  value: grade,
                                  child: Text('Grade $grade'),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _courses[index].grade = val;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
