import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/version_model.dart';
import '../widgets/update_dialog.dart';

class UpdateService {
  final String configUrl;
  final Dio _dio;

  UpdateService({required this.configUrl}) : _dio = Dio();

  Future<void> checkForUpdates(BuildContext context) async {
    try {
      final response = await _dio.get(configUrl);

      final Map<String, dynamic> data = response.data is String
          ? json.decode(response.data)
          : response.data;

      final updateInfo = VersionModel.fromJson(data);

      if (updateInfo.updateType == 'ota') {
        // Shorebird handles OTA internally, do nothing manually.
        debugPrint('UpdateType is OTA. Shorebird will handle it.');
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final isForceUpdate = _isVersionLower(
        currentVersion,
        updateInfo.minSupportedVersion,
      );
      final isOptionalUpdate =
          !isForceUpdate &&
          _isVersionLower(currentVersion, updateInfo.latestVersion);

      if (isForceUpdate) {
        if (context.mounted) {
          _showUpdateDialog(context, updateInfo, true);
        }
      } else if (isOptionalUpdate) {
        if (updateInfo.updateType == 'force_apk') {
          if (context.mounted) {
            _showUpdateDialog(context, updateInfo, true);
          }
        } else if (updateInfo.updateType == 'optional_apk') {
          if (context.mounted) {
            _showUpdateDialog(context, updateInfo, false);
          }
        }
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
  }

  void _showUpdateDialog(
    BuildContext context,
    VersionModel updateInfo,
    bool isForceUpdate,
  ) {
    showDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder: (context) => UpdateDialog(
        isForceUpdate: isForceUpdate,
        onUpdate: () {
          if (!isForceUpdate) Navigator.of(context).pop();
          _downloadAndInstallApk(context, updateInfo.apkUrl, isForceUpdate);
        },
      ),
    );
  }

  Future<void> _downloadAndInstallApk(
    BuildContext context,
    String apkUrl,
    bool isForceUpdate,
  ) async {
    if (Platform.isAndroid) {
      final status = await Permission.requestInstallPackages.request();
      if (!status.isGranted) {
        debugPrint('Install packages permission denied');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission is required to install updates.'),
            ),
          );
        }
        return;
      }
    }

    try {
      final ValueNotifier<double> progressNotifier = ValueNotifier(0.0);

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PopScope(
            canPop: false,
            child: AlertDialog(
              content: Row(
                children: [
                  ValueListenableBuilder<double>(
                    valueListenable: progressNotifier,
                    builder: (context, value, child) =>
                        CircularProgressIndicator(
                          value: value > 0 ? value : null,
                        ),
                  ),
                  const SizedBox(width: 20),
                  ValueListenableBuilder<double>(
                    valueListenable: progressNotifier,
                    builder: (context, value, child) => Text(
                      'Downloading: ${(value * 100).toStringAsFixed(0)}%',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      final dir = await getTemporaryDirectory();

      final savePath = '${dir.path}/app_update.apk';
      final file = File(savePath);
      if (file.existsSync()) {
        file.deleteSync();
      }

      await _dio.download(
        apkUrl,
        savePath,
        options: Options(
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(minutes: 5),
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            progressNotifier.value = received / total;
          }
        },
      );

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      final result = await OpenFile.open(savePath);
      if (result.type != ResultType.done) {
        debugPrint('Failed to open file: ${result.message}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Installation failed: ${result.message}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog on error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download failed. Please check your connection.'),
          ),
        );
      }
      debugPrint('Download failed: $e');
    }
  }

  bool _isVersionLower(String current, String target) {
    final cleanCurrent = current.split('+')[0].replaceAll(RegExp(r'[vV]'), '');
    final cleanTarget = target.split('+')[0].replaceAll(RegExp(r'[vV]'), '');

    final curParts = cleanCurrent
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    final targetParts = cleanTarget
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    for (int i = 0; i < 3; i++) {
      final c = i < curParts.length ? curParts[i] : 0;
      final t = i < targetParts.length ? targetParts[i] : 0;
      if (c < t) return true;
      if (c > t) return false;
    }
    return false;
  }
}
