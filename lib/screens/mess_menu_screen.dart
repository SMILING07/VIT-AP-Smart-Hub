import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/app_theme.dart';

class MessMenuScreen extends StatefulWidget {
  const MessMenuScreen({super.key});

  @override
  State<MessMenuScreen> createState() => _MessMenuScreenState();
}

class _MessMenuScreenState extends State<MessMenuScreen> {
  List<List<dynamic>> _menuData = [];
  List<String> _instructions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedMenu();
  }

  Future<void> _loadSavedMenu() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final File excelFile = File('${directory.path}/saved_mess_menu.xlsx');
      final File jsonFile = File('${directory.path}/saved_mess_menu.json');
      final File nameFile = File('${directory.path}/saved_mess_menu_name.txt');

      String savedName = 'saved_mess_menu';
      if (await nameFile.exists()) {
        savedName = await nameFile.readAsString();
      }

      if (await jsonFile.exists()) {
        await _parseFile(jsonFile.path, savedName, isJson: true);
      } else if (await excelFile.exists()) {
        await _parseFile(excelFile.path, savedName, isJson: false);
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> _findFirstList(dynamic node) {
    if (node is List) return node;
    if (node is Map) {
      for (var value in node.values) {
        var result = _findFirstList(value);
        if (result.isNotEmpty) return result;
      }
    }
    return [];
  }

  String _flattenCell(dynamic cell) {
    if (cell is List) {
      return cell.join(', ');
    }
    return cell?.toString() ?? '';
  }

  Future<void> _parseFile(
    String path,
    String fileName, {
    required bool isJson,
  }) async {
    try {
      List<List<dynamic>> extractedData = [];
      List<String> extractedInstructions = [];

      if (isJson) {
        String jsonString = await File(path).readAsString();
        dynamic decoded = jsonDecode(jsonString);

        List<dynamic> targetList = _findFirstList(decoded);
        if (targetList.isEmpty && decoded is Map) {
          targetList = [decoded];
        }

        if (targetList.isNotEmpty) {
          if (targetList.first is Map) {
            extractedData.add((targetList.first as Map).keys.toList());
            for (var row in targetList) {
              if (row is Map) {
                extractedData.add(
                  row.values.map((e) => _flattenCell(e)).toList(),
                );
              }
            }
          } else {
            for (var row in targetList) {
              if (row is List) {
                extractedData.add(row.map((e) => _flattenCell(e)).toList());
              } else if (row is Map) {
                extractedData.add(
                  row.values.map((e) => _flattenCell(e)).toList(),
                );
              } else {
                extractedData.add([row.toString()]);
              }
            }
          }
        }

        if (extractedData.isEmpty) {
          throw Exception(
            "Could not find table data in JSON file. Ensure it is a list of rows or objects.",
          );
        }
      } else {
        var bytes = File(path).readAsBytesSync();
        var decoder = SpreadsheetDecoder.decodeBytes(bytes);

        if (decoder.tables.keys.isNotEmpty) {
          String sheetName = decoder.tables.keys.first;
          var table = decoder.tables[sheetName];

          if (table != null) {
            for (var row in table.rows) {
              if (row.any(
                (element) =>
                    element != null && element.toString().trim().isNotEmpty,
              )) {
                extractedData.add(row);
              }
            }
          }
        }
      }

      // Unified extraction pass for BOTH JSON and Excel
      List<List<dynamic>> finalData = [];
      List<String> finalInstructions = [];
      bool foundInstructions = false;
      bool reachedTableSchema = false;

      for (var row in extractedData) {
        if (row.isEmpty) continue;
        String firstCellStr = row.first?.toString().trim().toUpperCase() ?? '';

        if (!reachedTableSchema) {
          bool hasMealCol = row.any(
            (element) =>
                element != null &&
                element.toString().toUpperCase().contains("BREAKFAST"),
          );
          if (!hasMealCol) {
            continue; // Skip junk title rows natively dumped by Excel before the table starts
          } else {
            reachedTableSchema = true;
          }
        }

        if (!foundInstructions &&
            (firstCellStr.contains('MESS SERVICE INSTRUCTIONS') ||
                firstCellStr.contains('INSTRUCTIONS:'))) {
          foundInstructions = true;
          String cellData = row.first.toString();
          if (cellData.contains('\n')) {
            var lines = cellData
                .split('\n')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
            for (var line in lines) {
              if (line.toUpperCase().contains('MESS SERVICE INSTRUCTIONS') ||
                  line.toUpperCase() == 'INSTRUCTIONS:') {
                continue;
              }
              finalInstructions.add(line);
            }
          } else {
            String restOfRow = row
                .skip(1)
                .where((e) => e != null && e.toString().trim().isNotEmpty)
                .map((e) => e.toString().trim())
                .join(' ');
            if (restOfRow.isNotEmpty) finalInstructions.add(restOfRow);
          }
          continue;
        }

        if (foundInstructions) {
          String instructionLine = row
              .where((e) => e != null && e.toString().trim().isNotEmpty)
              .map((e) => e.toString().trim())
              .join(' ');
          if (instructionLine.isNotEmpty) {
            finalInstructions.add(instructionLine);
          }
        } else {
          finalData.add(row);
        }
      }

      extractedData = finalData;
      extractedInstructions = finalInstructions;

      if (mounted) {
        setState(() {
          _menuData = extractedData;
          _instructions = extractedInstructions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error parsing file: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showFormatPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        bool isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose File Format',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'XLS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                title: const Text('Excel (.xlsx)'),
                subtitle: const Text('Standard spreadsheet layout'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndParseFile(isJson: false);
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '{ }',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                title: const Text('JSON (.json)'),
                subtitle: const Text('Structured data layout'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndParseFile(isJson: true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndParseFile({required bool isJson}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: isJson ? ['json'] : ['xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        if (mounted) {
          setState(() {
            _isLoading = true;
            _menuData = [];
            _instructions = [];
          });
        }

        String sourcePath = result.files.single.path!;
        String fileName = result.files.single.name;

        final directory = await getApplicationDocumentsDirectory();
        final File excelFile = File('${directory.path}/saved_mess_menu.xlsx');
        final File jsonFile = File('${directory.path}/saved_mess_menu.json');
        final File nameFile = File(
          '${directory.path}/saved_mess_menu_name.txt',
        );

        if (await excelFile.exists()) await excelFile.delete();
        if (await jsonFile.exists()) await jsonFile.delete();

        final File destinationFile = isJson ? jsonFile : excelFile;
        await File(sourcePath).copy(destinationFile.path);
        await nameFile.writeAsString(fileName);

        await _parseFile(destinationFile.path, fileName, isJson: isJson);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mess Menu'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: const [],
          bottom: TabBar(
            indicatorColor: isDark
                ? AppTheme.secondaryColor
                : AppTheme.primaryColor,
            labelColor: isDark
                ? AppTheme.secondaryColor
                : AppTheme.primaryColor,
            unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
            tabs: const [
              Tab(text: 'Mess Menu'),
              Tab(text: 'Night Mess'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Scaffold(
              backgroundColor: Colors.transparent,
              body: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _menuData.isEmpty
                  ? _buildEmptyState(isDark)
                  : _buildMainContent(isDark),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: _showFormatPicker,
                icon: const Icon(Icons.upload_file),
                label: Text(_menuData.isEmpty ? 'Upload Menu' : 'Change Menu'),
                backgroundColor: isDark
                    ? AppTheme.secondaryColor
                    : AppTheme.primaryColor,
              ),
            ),
            const NightMessView(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 80,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            'No Menu Loaded',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload a .xlsx or .json file to view your mess menu',
            style: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isDark) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildCurrentMeal(isDark),
                _buildMenuTable(isDark),
                if (_instructions.isNotEmpty) _buildInstructionsCard(isDark),
                const SizedBox(height: 32), // Bottom padding for scrolling
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<DateTime> _getMealTimes(DateTime now, String mealName) {
    if (mealName == "BREAKFAST") {
      return [
        DateTime(now.year, now.month, now.day, 7, 15),
        DateTime(now.year, now.month, now.day, 9, 0),
      ];
    } else if (mealName == "LUNCH") {
      return [
        DateTime(now.year, now.month, now.day, 12, 30),
        DateTime(now.year, now.month, now.day, 14, 15),
      ];
    } else if (mealName == "SNACKS") {
      return [
        DateTime(now.year, now.month, now.day, 16, 0),
        DateTime(now.year, now.month, now.day, 18, 0),
      ];
    } else if (mealName == "DINNER") {
      return [
        DateTime(now.year, now.month, now.day, 19, 30),
        DateTime(now.year, now.month, now.day, 21, 0),
      ];
    }
    return [now, now];
  }

  Widget _buildCurrentMeal(bool isDark) {
    if (_menuData.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final List<String> weekdays = [
      "MONDAY",
      "TUESDAY",
      "WEDNESDAY",
      "THURSDAY",
      "FRIDAY",
      "SATURDAY",
      "SUNDAY",
    ];
    final currentDayStr = weekdays[now.weekday - 1];

    // Wait, dart weekday: 1 = Monday to 7 = Sunday
    // Wait, dart weekday: 1 = Monday to 7 = Sunday
    final List<String> correctDisplayWeekdays = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];
    final List<String> displayMonths = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    final dayName = correctDisplayWeekdays[now.weekday - 1];
    final dateName = "${displayMonths[now.month - 1]} ${now.day}";

    List<dynamic> headerRow = [];
    int startRowIndex = 0;
    for (int i = 0; i < _menuData.length; i++) {
      if (_menuData[i].any(
        (element) =>
            element != null &&
            element.toString().toUpperCase().contains("BREAKFAST"),
      )) {
        headerRow = _menuData[i];
        startRowIndex = i + 1;
        break;
      }
    }

    if (headerRow.isEmpty) return const SizedBox.shrink();

    final List<String> shortWeekdays = [
      "MON",
      "TUE",
      "WED",
      "THU",
      "FRI",
      "SAT",
      "SUN",
    ];
    final currentShortDayStr = shortWeekdays[now.weekday - 1];

    List<dynamic>? todayRow;
    for (int i = startRowIndex; i < _menuData.length; i++) {
      var row = _menuData[i];
      if (row.isNotEmpty && row.first != null) {
        String firstCell = row.first.toString().toUpperCase();

        bool hasDigits = firstCell.contains(RegExp(r'\d'));

        if (hasDigits) {
          String dateStr = now.day.toString();
          if (RegExp(r'\b' + dateStr + r'\b').hasMatch(firstCell)) {
            todayRow = row;
            break;
          }
        } else {
          if (firstCell.contains(currentDayStr) ||
              firstCell.contains(currentShortDayStr)) {
            todayRow = row;
            break;
          }
        }
      }
    }

    if (todayRow == null) return const SizedBox.shrink();
    final List<dynamic> validTodayRow = todayRow;

    List<Widget> mealCards = [];
    final mealSpecs = [
      {
        "name": "BREAKFAST",
        "icon": Icons.local_cafe,
        "range": "7:15 - 9:00 AM",
      },
      {"name": "LUNCH", "icon": Icons.lunch_dining, "range": "12:30 - 2:15 PM"},
      {"name": "SNACKS", "icon": Icons.cookie, "range": "4:00 - 6:00 PM"},
      {"name": "DINNER", "icon": Icons.nights_stay, "range": "7:30 - 9:00 PM"},
    ];

    for (var spec in mealSpecs) {
      String mealName = spec["name"] as String;
      int colIndex = -1;
      for (int i = 0; i < headerRow.length; i++) {
        if (headerRow[i] != null &&
            headerRow[i].toString().toUpperCase().contains(mealName)) {
          colIndex = i;
          break;
        }
      }

      // Show card even if cell is empty/null — render 'Not specified' as fallback
      if (colIndex != -1) {
        final rawCell = colIndex < validTodayRow.length
            ? validTodayRow[colIndex]
            : null;
        final rawStr = rawCell?.toString().trim() ?? '';
        final displayItems = rawStr.isEmpty
            ? 'Not specified'
            : rawStr
                  .split('\n')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .join(', ');
        final times = _getMealTimes(now, mealName);
        mealCards.add(
          MealCard(
            mealName: mealName,
            timeRange: spec["range"] as String,
            items: displayItems,
            startTime: times[0],
            endTime: times[1],
            icon: spec["icon"] as IconData,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$dayName, ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.cyanAccent
                              : Colors.cyan.shade700,
                        ),
                      ),
                      TextSpan(
                        text: dateName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Today's mess menu",
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF8E8E93) : Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(children: mealCards),
        ),
      ],
    );
  }

  Widget _buildInstructionsCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceColor : AppTheme.lightSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: isDark ? AppTheme.secondaryColor : AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mess Service Instructions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppTheme.textColor
                        : AppTheme.lightTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          ..._instructions.asMap().entries.map((entry) {
            // Clean up numbers if they're already present in the extracted text
            String text = entry.value.replaceFirst(RegExp(r'^\d+\.\s*'), '');

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key + 1}.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppTheme.secondaryColor
                          : AppTheme.primaryColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMenuTable(bool isDark) {
    if (_menuData.isEmpty) return const SizedBox.shrink();

    int maxCols = 0;
    for (var row in _menuData) {
      if (row.length > maxCols) {
        maxCols = row.length;
      }
    }

    List<dynamic> headerRow = _menuData.first;
    List<dynamic> paddedHeader = List.from(headerRow);
    while (paddedHeader.length < maxCols) {
      paddedHeader.add('');
    }

    List<List<dynamic>> dataRows = _menuData.length > 1
        ? _menuData.sublist(1)
        : [];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceColor : AppTheme.lightSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Custom Header Row
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: paddedHeader.map((header) {
                          return _buildCell(
                            header?.toString().toUpperCase() ?? '',
                            isHeader: true,
                            isDark: isDark,
                          );
                        }).toList(),
                      ),
                    ),
                    // Custom Data Rows
                    ...dataRows.asMap().entries.map((entry) {
                      int rowIndex = entry.key;
                      List<dynamic> row = entry.value;

                      List<dynamic> paddedRow = List.from(row);
                      while (paddedRow.length < maxCols) {
                        paddedRow.add('');
                      }

                      bool isEvenRow = rowIndex % 2 == 0;
                      Color rowColor = isDark
                          ? (isEvenRow
                                ? AppTheme.backgroundColor.withValues(
                                    alpha: 0.4,
                                  )
                                : AppTheme.surfaceColor)
                          : (isEvenRow
                                ? AppTheme.lightBackgroundColor
                                : AppTheme.lightSurfaceColor);

                      return Material(
                        color: rowColor,
                        child: InkWell(
                          hoverColor:
                              (isDark
                                      ? AppTheme.secondaryColor
                                      : AppTheme.primaryColor)
                                  .withValues(alpha: 0.1),
                          splashColor:
                              (isDark
                                      ? AppTheme.secondaryColor
                                      : AppTheme.primaryColor)
                                  .withValues(alpha: 0.2),
                          onTap: () {},
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.05),
                                ),
                              ),
                            ),
                            child: Row(
                              children: paddedRow.map((cell) {
                                return _buildCell(
                                  cell?.toString() ?? '',
                                  isHeader: false,
                                  isDark: isDark,
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8), // Bottom padding
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(
    String text, {
    required bool isHeader,
    required bool isDark,
  }) {
    return Container(
      width:
          160, // Fixed width for uniform grid columns. Adjust as needed or calculate dynamically.
      constraints: const BoxConstraints(minHeight: 56), // Minimum row height
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      alignment: isHeader ? Alignment.center : Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          color: isHeader
              ? Colors.white
              : (isDark ? AppTheme.textColor : AppTheme.lightTextColor),
          fontWeight: isHeader ? FontWeight.w800 : FontWeight.w500,
          fontSize: isHeader ? 13 : 14,
          letterSpacing: isHeader ? 0.5 : 0,
        ),
        textAlign: isHeader ? TextAlign.center : TextAlign.left,
      ),
    );
  }
}

class NightMessView extends StatefulWidget {
  const NightMessView({super.key});

  @override
  State<NightMessView> createState() => _NightMessViewState();
}

class _NightMessViewState extends State<NightMessView> {
  String? _imagePath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedImage();
  }

  Future<void> _loadSavedImage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final File extFile = File('${directory.path}/night_mess_ext.txt');
      if (await extFile.exists()) {
        String ext = await extFile.readAsString();
        final File imageFile = File('${directory.path}/night_mess_image.$ext');
        if (await imageFile.exists()) {
          setState(() {
            _imagePath = imageFile.path;
          });
        }
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickAndSaveImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isLoading = true;
        });

        String sourcePath = result.files.single.path!;
        String ext = result.files.single.extension ?? 'jpg';

        final directory = await getApplicationDocumentsDirectory();
        final File destinationFile = File(
          '${directory.path}/night_mess_image.$ext',
        );
        final File extFile = File('${directory.path}/night_mess_ext.txt');

        await File(sourcePath).copy(destinationFile.path);
        await extFile.writeAsString(ext);

        if (mounted) {
          setState(() {
            _imagePath = destinationFile.path;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _imagePath == null
          ? _buildEmptyState(isDark)
          : _buildImageContent(isDark),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndSaveImage,
        icon: const Icon(Icons.add_photo_alternate),
        label: Text(_imagePath == null ? 'Upload Image' : 'Change Image'),
        backgroundColor: isDark
            ? AppTheme.secondaryColor
            : AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 80,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            'No Night Mess Menu',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload an image of the night mess menu',
            style: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80.0), // Padding for FAB
      child: InteractiveViewer(
        panEnabled: true,
        boundaryMargin: const EdgeInsets.all(20),
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Image.file(File(_imagePath!), fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class MealCard extends StatefulWidget {
  final String mealName;
  final String timeRange;
  final String items;
  final DateTime startTime;
  final DateTime endTime;
  final IconData icon;

  const MealCard({
    super.key,
    required this.mealName,
    required this.timeRange,
    required this.items,
    required this.startTime,
    required this.endTime,
    required this.icon,
  });

  @override
  State<MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<MealCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    bool isServing =
        now.isAfter(widget.startTime) && now.isBefore(widget.endTime);
    bool isSoon = now.isBefore(widget.startTime);

    Color mainColor = Colors.white;
    Color badgeColor = Colors.transparent;
    String badgeText = '';
    String footerLeft = '';
    String footerRight = '';

    if (isServing) {
      mainColor = Colors.greenAccent.shade400;
      badgeColor = mainColor;
      badgeText = 'SERVING';
      footerLeft = "● IT'S ${widget.mealName} TIME";
      final diff = widget.endTime.difference(now);
      footerRight = "END - ${_formatDuration(diff)}";
    } else if (isSoon) {
      mainColor = Colors.amber.shade400;
      badgeColor = mainColor;
      badgeText = 'SOON';
      footerLeft = "UPCOMING ${widget.mealName}";
      final diff = widget.startTime.difference(now);
      footerRight = "STARTS - ${_formatDuration(diff)}";
    }

    bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Using the flat solid dark grey/black color from your latest screenshot
    Color cardBg = isDark ? const Color(0xFF181818) : Colors.white;
    Color iconBgColor = isDark
        ? const Color(0xFF111111)
        : Colors.black.withValues(alpha: 0.05);
    Color iconColor = isDark ? Colors.cyanAccent : Colors.cyan.shade700;
    Color titleColor = isDark ? Colors.cyanAccent : Colors.cyan.shade800;
    Color timeColor = isDark ? Colors.cyan.shade200 : Colors.cyan.shade700;
    Color itemColor = isDark
        ? Colors.cyanAccent.shade100
        : Colors.cyan.shade900;

    if (isServing || isSoon) {
      titleColor = isDark ? Colors.white : Colors.black;
      itemColor = isDark ? Colors.white : Colors.black87;
    }

    Color borderColor = Colors.purpleAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.6),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        widget.mealName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.timeRange,
                        style: TextStyle(fontSize: 12, color: timeColor),
                      ),
                    ],
                  ),
                ),
                if (badgeText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 20.0),
            child: Text(
              widget.items,
              style: TextStyle(fontSize: 15, height: 1.5, color: itemColor),
            ),
          ),
          if (isServing || isSoon) ...[
            Divider(color: borderColor, height: 1),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 14.0,
              ),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    footerLeft.toUpperCase(),
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    footerRight.toUpperCase(),
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
