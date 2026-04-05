import 'dart:convert';
import 'dart:io';
import 'dart:math';

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
      // Track received bytes, total, speed and ETA.
      final ValueNotifier<int> receivedNotifier = ValueNotifier(0);
      final ValueNotifier<int> totalNotifier = ValueNotifier(-1);
      final ValueNotifier<double> speedNotifier = ValueNotifier(0); // MB/s
      final ValueNotifier<int> etaNotifier = ValueNotifier(-1); // seconds

      int lastReceived = 0;
      DateTime lastTime = DateTime.now();

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PopScope(
            canPop: false,
            child: AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Big circular indicator with % in the centre
                  ValueListenableBuilder<int>(
                    valueListenable: totalNotifier,
                    builder: (context, total, _) => ValueListenableBuilder<int>(
                      valueListenable: receivedNotifier,
                      builder: (context, received, _) {
                        final progress = total > 0 ? received / total : null;
                        final pctLabel = total > 0
                            ? '${((received / total) * 100).toStringAsFixed(0)}%'
                            : '...';
                        return SizedBox(
                          width: 80,
                          height: 80,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 6,
                              ),
                              Center(
                                child: Text(
                                  pctLabel,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // MB received / speed / ETA
                  ValueListenableBuilder<int>(
                    valueListenable: totalNotifier,
                    builder: (context, total, _) => ValueListenableBuilder<int>(
                      valueListenable: receivedNotifier,
                      builder: (context, received, _) =>
                          ValueListenableBuilder<double>(
                            valueListenable: speedNotifier,
                            builder: (context, speed, _) =>
                                ValueListenableBuilder<int>(
                                  valueListenable: etaNotifier,
                                  builder: (context, eta, _) {
                                    final receivedMb =
                                        (received / (1024 * 1024))
                                            .toStringAsFixed(1);
                                    final totalMb = total > 0
                                        ? (total / (1024 * 1024))
                                              .toStringAsFixed(1)
                                        : null;
                                    final sizeStr = totalMb != null
                                        ? '$receivedMb / $totalMb MB'
                                        : '$receivedMb MB';
                                    final speedStr = speed > 0
                                        ? '${speed.toStringAsFixed(1)} MB/s'
                                        : null;
                                    final etaStr = eta > 0
                                        ? 'ETA ${eta}s'
                                        : null;
                                    return Column(
                                      children: [
                                        Text(
                                          sizeStr,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        if (speedStr != null || etaStr != null)
                                          Text(
                                            [
                                              speedStr,
                                              etaStr,
                                            ].whereType<String>().join('  •  '),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                          ),
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

      // Fresh Dio with redirect following and HTTP keep-alive.
      final downloadDio = Dio(
        BaseOptions(
          followRedirects: true,
          maxRedirects: 10,
          receiveTimeout: const Duration(minutes: 10),
          sendTimeout: const Duration(minutes: 2),
          headers: {
            'Connection': 'keep-alive',
            'Accept-Encoding':
                'identity', // Disable gzip so progress is accurate
          },
        ),
      );

      await downloadDio.download(
        apkUrl,
        savePath,
        onReceiveProgress: (received, total) {
          receivedNotifier.value = received;
          totalNotifier.value = total;

          // Calculate speed and ETA every update tick
          final now = DateTime.now();
          final elapsed = now.difference(lastTime).inMilliseconds;
          if (elapsed >= 500) {
            final bytesDelta = received - lastReceived;
            final speedBps = bytesDelta / (elapsed / 1000);
            final speedMbps = speedBps / (1024 * 1024);
            speedNotifier.value = double.parse(
              max(0.0, speedMbps).toStringAsFixed(1),
            );
            if (total > 0 && speedBps > 0) {
              etaNotifier.value = ((total - received) / speedBps).round();
            } else {
              etaNotifier.value = -1;
            }
            lastReceived = received;
            lastTime = now;
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
    // Split into version and build number: "1.2.3+4" -> ["1.2.3", "4"]
    final currentParts = current.split('+');
    final targetParts = target.split('+');

    final cleanCurrentVer = currentParts[0]
        .replaceAll(RegExp(r'[vV]'), '')
        .trim();
    final cleanTargetVer = targetParts[0]
        .replaceAll(RegExp(r'[vV]'), '')
        .trim();

    final curVerList = cleanCurrentVer
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    final targetVerList = cleanTargetVer
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    // Compare semantic version parts (major.minor.patch)
    for (int i = 0; i < 3; i++) {
      final c = i < curVerList.length ? curVerList[i] : 0;
      final t = i < targetVerList.length ? targetVerList[i] : 0;
      if (c < t) return true;
      if (c > t) return false;
    }

    // If semantic versions are identical, compare build numbers
    final int curBuild = (currentParts.length > 1)
        ? (int.tryParse(currentParts[1]) ?? 0)
        : 0;
    final int targetBuild = (targetParts.length > 1)
        ? (int.tryParse(targetParts[1]) ?? 0)
        : 0;

    return curBuild < targetBuild;
  }
}
