import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class FloorMapScreen extends StatelessWidget {
  const FloorMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('First Floor Map'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate an appropriate map size based on screen constraints
          final mapWidth = 400.0;
          final mapHeight = 800.0;

          return Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              boundaryMargin: const EdgeInsets.all(100),
              constrained: false, // allow panning beyond screen size
              child: Container(
                width: mapWidth,
                height: mapHeight,
                color:
                    AppTheme.surfaceColor, // Assuming a dark theme background
                child: Stack(
                  children: [
                    // Central Corridor
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: mapWidth / 2 - 30, // 60 width corridor
                      width: 60,
                      child: Container(color: Colors.grey[300]),
                    ),

                    // Top Left Stairs
                    _buildStairs(left: 20, top: 20),
                    // Top Right Stairs
                    _buildStairs(right: 20, top: 20),
                    // Bottom Left Stairs
                    _buildStairs(left: 20, bottom: 20),
                    // Bottom Right Stairs
                    _buildStairs(right: 20, bottom: 20),

                    // Rooms 101-110 (Left Side)
                    ...List.generate(10, (index) {
                      return _buildRoom(
                        context: context,
                        roomNumber: 101 + index,
                        left: 40,
                        top: 100.0 + (index * 60),
                      );
                    }),

                    // Rooms 111-120 (Right Side)
                    ...List.generate(10, (index) {
                      return _buildRoom(
                        context: context,
                        roomNumber: 111 + index,
                        right: 40,
                        top: 100.0 + (index * 60),
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStairs({
    double? left,
    double? right,
    double? top,
    double? bottom,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: 80,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: const Text(
          'STAIRS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildRoom({
    required BuildContext context,
    required int roomNumber,
    double? left,
    double? right,
    required double top,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      child: GestureDetector(
        onTap: () {
          _showRoomDetails(context, roomNumber);
        },
        child: Container(
          width: 70,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.lightBlue[100],
            border: Border.all(color: Colors.black, width: 1.5),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 2,
                offset: const Offset(1, 1),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '$roomNumber',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  void _showRoomDetails(BuildContext context, int roomNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppTheme.surfaceColor,
          title: Text(
            'Room $roomNumber',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: const Text(
            'Room details here',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Close',
                style: TextStyle(color: AppTheme.secondaryColor),
              ),
            ),
          ],
        );
      },
    );
  }
}
