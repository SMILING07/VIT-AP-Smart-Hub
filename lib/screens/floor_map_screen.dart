import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class FloorMapScreen extends StatefulWidget {
  const FloorMapScreen({super.key});

  @override
  State<FloorMapScreen> createState() => _FloorMapScreenState();
}

class _FloorMapScreenState extends State<FloorMapScreen> {
  int _selectedFloor = 1;
  final List<int> _floors = [1, 2, 3, 4];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Floor $_selectedFloor Map'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Row(
        children: [
          Expanded(
            child: LayoutBuilder(
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
                      color: AppTheme
                          .surfaceColor, // Assuming a dark theme background
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

                          // Rooms 1-10 on current floor (Left Side)
                          ...List.generate(10, (index) {
                            final roomNum = (_selectedFloor * 100) + index + 1;
                            return _buildRoom(
                              context: context,
                              roomNumber: roomNum,
                              left: 40,
                              top: 100.0 + (index * 60),
                            );
                          }),

                          // Rooms 11-20 on current floor (Right Side)
                          ...List.generate(10, (index) {
                            final roomNum = (_selectedFloor * 100) + index + 11;
                            return _buildRoom(
                              context: context,
                              roomNumber: roomNum,
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
          ),
          // Floor Sidebar
          Container(
            width: 60,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              border: const Border(left: BorderSide(color: Colors.white10)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _floors
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: FloatingActionButton.small(
                        heroTag: 'floor_$f',
                        onPressed: () => setState(() => _selectedFloor = f),
                        backgroundColor: _selectedFloor == f
                            ? AppTheme.secondaryColor
                            : Colors.white10,
                        child: Text(
                          '$f',
                          style: TextStyle(
                            color: _selectedFloor == f
                                ? Colors.black
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
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
