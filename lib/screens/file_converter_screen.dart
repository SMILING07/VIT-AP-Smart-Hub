import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/app_theme.dart';

class FileConverterScreen extends StatefulWidget {
  const FileConverterScreen({super.key});

  @override
  State<FileConverterScreen> createState() => _FileConverterScreenState();
}

class _FileConverterScreenState extends State<FileConverterScreen> {
  String? _selectedFilePath;
  String? _selectedFileName;
  String _targetFormat = 'PDF';
  bool _isConverting = false;

  final List<String> _supportedFormats = ['PDF', 'Word (.docx)'];

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any, // Allow any file for the mockup
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _selectedFileName = result.files.single.name;
      });
    }
  }

  Future<void> _convertFile() async {
    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file to convert first.')),
      );
      return;
    }

    setState(() {
      _isConverting = true;
    });

    // Simulate network or processing delay
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isConverting = false;
    });

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            'Conversion Complete',
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          content: Text(
            'Successfully converted "$_selectedFileName" to $_targetFormat.\n\n(This is a simulated mockup)',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _selectedFilePath = null;
                  _selectedFileName = null;
                });
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doc Converter'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Convert Files',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: 28),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Easily change your files to Word or PDF formats',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Upload Area
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedFilePath != null
                        ? AppTheme.successColor
                        : AppTheme.primaryColor.withValues(alpha: 0.5),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedFilePath != null
                          ? Icons.insert_drive_file
                          : Icons.cloud_upload,
                      size: 64,
                      color: _selectedFilePath != null
                          ? AppTheme.successColor
                          : AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        _selectedFileName ?? 'Tap to browse files',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (_selectedFilePath == null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Supports images, documents, and spreadsheets',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Format Selection
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    'Convert to:',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _targetFormat,
                        isExpanded: true,
                        dropdownColor: Theme.of(context).cardColor,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w500,
                        ),
                        items: _supportedFormats.map((String format) {
                          return DropdownMenuItem<String>(
                            value: format,
                            child: Text(format),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _targetFormat = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Convert Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: (_selectedFilePath != null && !_isConverting)
                    ? _convertFile
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isConverting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Convert File',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
