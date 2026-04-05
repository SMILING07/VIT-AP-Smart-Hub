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

  String _statusMessage = 'Select a file to begin';
  double _uploadProgress = 0;
  final List<String> _supportedFormats = [
    'PDF',
    'Word (.docx)',
    'Excel (.xlsx)',
    'Image (.jpg)',
  ];

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(type: FileType.any);

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _selectedFileName = result.files.single.name;
        _statusMessage = 'File selected: $_selectedFileName';
      });
    }
  }

  Future<void> _convertFile() async {
    if (_selectedFilePath == null) return;

    setState(() {
      _isConverting = true;
      _uploadProgress = 0;
      _statusMessage = 'Initializing converter...';
    });

    try {
      // Step 1: Validation
      await Future.delayed(const Duration(milliseconds: 500));
      final extension = _selectedFileName?.split('.').last.toLowerCase() ?? '';
      if (_targetFormat.toLowerCase().contains(extension) &&
          extension.isNotEmpty) {
        throw 'File is already in $_targetFormat format';
      }

      // Step 2: Simulated Upload
      for (int i = 1; i <= 5; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        setState(() {
          _uploadProgress = i * 0.1;
          _statusMessage = 'Uploading file... ${(i * 10)}%';
        });
      }

      // Step 3: Simulated Processing/Conversion
      final steps = [
        'Parsing document structure...',
        'Extracting text and assets...',
        'Applying $_targetFormat layout engine...',
        'Optimizing output file size...',
        'Finalizing conversion...',
      ];

      for (int i = 0; i < steps.length; i++) {
        if (!mounted) return;
        setState(() => _statusMessage = steps[i]);
        for (int j = 0; j < 5; j++) {
          await Future.delayed(const Duration(milliseconds: 200));
          if (!mounted) return;
          setState(() => _uploadProgress = 0.5 + (i * 0.1) + (j * 0.02));
        }
      }

      setState(() {
        _uploadProgress = 1.0;
        _statusMessage = 'Conversion successful!';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File successfully converted to $_targetFormat!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OPEN',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = 'Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConverting = false;
        });
      }
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

            if (_isConverting) ...[
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _uploadProgress,
                  minHeight: 8,
                  backgroundColor: Colors.white10,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],

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
