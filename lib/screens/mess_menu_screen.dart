import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import '../utils/app_theme.dart';

class MessMenuScreen extends StatefulWidget {
  const MessMenuScreen({super.key});

  @override
  State<MessMenuScreen> createState() => _MessMenuScreenState();
}

class _MessMenuScreenState extends State<MessMenuScreen> {
  List<List<dynamic>> _menuData = [];
  List<String> _instructions = [];
  bool _isLoading = false;
  String? _fileName;

  Future<void> _pickAndParseExcelFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isLoading = true;
          _fileName = result.files.single.name;
          _menuData = [];
          _instructions = [];
        });

        String path = result.files.single.path!;
        var bytes = File(path).readAsBytesSync();
        var decoder = SpreadsheetDecoder.decodeBytes(bytes);

        List<List<dynamic>> extractedData = [];
        List<String> extractedInstructions = [];
        bool isInstructionsSection = false;

        // Typically mess menus are on the first sheet, or we take the first available
        if (decoder.tables.keys.isNotEmpty) {
          String sheetName = decoder.tables.keys.first;
          var table = decoder.tables[sheetName];

          if (table != null) {
            for (var row in table.rows) {
              // Check if row is not completely empty
              if (row.any(
                (element) =>
                    element != null && element.toString().trim().isNotEmpty,
              )) {
                // Identify the start of the instructions block
                String firstCellStr =
                    row.first?.toString().trim().toUpperCase() ?? '';
                if (firstCellStr.contains('MESS SERVICE INSTRUCTIONS') ||
                    firstCellStr.contains('INSTRUCTIONS:')) {
                  isInstructionsSection = true;
                  continue; // Skip the header row itself for instructions
                }

                if (isInstructionsSection) {
                  // Extract all non-empty text from the row and join as an instruction line
                  String instructionLine = row
                      .where((e) => e != null && e.toString().trim().isNotEmpty)
                      .map((e) => e.toString().trim())
                      .join(' ');

                  if (instructionLine.isNotEmpty) {
                    extractedInstructions.add(instructionLine);
                  }
                } else {
                  extractedData.add(row);
                }
              }
            }
          }
        }

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
        ).showSnackBar(SnackBar(content: Text('Error parsing Excel file: $e')));
      }
      setState(() {
        _isLoading = false;
        _fileName = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mess Menu'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: _pickAndParseExcelFile,
            tooltip: 'Upload Excel file',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _menuData.isEmpty
          ? _buildEmptyState(isDark)
          : _buildMainContent(isDark),
      floatingActionButton: _menuData.isEmpty
          ? FloatingActionButton.extended(
              onPressed: _pickAndParseExcelFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Menu (.xlsx)'),
              backgroundColor: isDark
                  ? AppTheme.secondaryColor
                  : AppTheme.primaryColor,
            )
          : null,
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
            'Upload a .xlsx file to view your mess menu',
            style: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isDark) {
    return Column(
      children: [
        if (_fileName != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.surfaceColor
                  : AppTheme.lightSurfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    (isDark ? AppTheme.secondaryColor : AppTheme.primaryColor)
                        .withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      (isDark ? AppTheme.secondaryColor : AppTheme.primaryColor)
                          .withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppTheme.successColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Excel Data Loaded',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppTheme.textSecondaryColor
                              : AppTheme.lightTextSecondaryColor,
                        ),
                      ),
                      Text(
                        _fileName!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.upload_file),
                  onPressed: _pickAndParseExcelFile,
                  color: isDark
                      ? AppTheme.secondaryColor
                      : AppTheme.primaryColor,
                  tooltip: 'Upload new file',
                ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
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
