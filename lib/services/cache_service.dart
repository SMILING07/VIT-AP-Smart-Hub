import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CacheService {
  static const _storage = FlutterSecureStorage();

  static String _getKey(String regNo, String dataType) =>
      'cache_${regNo}_$dataType';
  static String _getTimestampKey(String regNo, String dataType) =>
      'ts_${regNo}_$dataType';

  static Future<void> saveData(
    String regNo,
    String dataType,
    dynamic data,
  ) async {
    final jsonStr = jsonEncode(data);
    await _storage.write(key: _getKey(regNo, dataType), value: jsonStr);
    await _storage.write(
      key: _getTimestampKey(regNo, dataType),
      value: DateTime.now().toIso8601String(),
    );
  }

  static Future<dynamic> getData(String regNo, String dataType) async {
    final jsonStr = await _storage.read(key: _getKey(regNo, dataType));
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr);
    } catch (_) {
      return null;
    }
  }

  static Future<DateTime?> getLastUpdateTime(
    String regNo,
    String dataType,
  ) async {
    final tsStr = await _storage.read(key: _getTimestampKey(regNo, dataType));
    if (tsStr == null) return null;
    return DateTime.tryParse(tsStr);
  }

  static Future<bool> isCacheStale(
    String regNo,
    String dataType,
    Duration threshold,
  ) async {
    final lastUpdate = await getLastUpdateTime(regNo, dataType);
    if (lastUpdate == null) return true;
    return DateTime.now().difference(lastUpdate) > threshold;
  }

  static const _knownDataTypes = [
    'SemesterData',
    'AttendanceData',
    'TimetableData',
    'MarksData',
    'GradeViewData',
    'GradeHistoryData',
    'ExamScheduleData',
    'GradeDetailsData',
  ];

  static Future<void> clearCache(String regNo) async {
    for (final dt in _knownDataTypes) {
      await _storage.delete(key: _getKey(regNo, dt));
      await _storage.delete(key: _getTimestampKey(regNo, dt));
    }
  }
}
