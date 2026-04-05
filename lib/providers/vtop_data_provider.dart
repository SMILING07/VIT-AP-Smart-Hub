import 'package:flutter/material.dart';
import '../services/cache_service.dart';
import '../services/preferences_service.dart';
import '../services/vtop_api_service.dart';
import '../src/rust/api/vtop/types.dart';

class VtopDataProvider extends ChangeNotifier {
  final VtopApiService _apiService;
  final String? _currentRegNo;

  VtopDataProvider(this._apiService, [this._currentRegNo]) {
    initializePreferences();
  }

  String? get currentRegNo => _currentRegNo;

  int _loadingCount = 0;
  bool get isLoading => _loadingCount > 0;

  String? _error;
  String? get error => _error;

  String? _userName;
  String? get userName => _userName;

  String? _userHostel;
  String? get userHostel => _userHostel;

  Future<void> initializePreferences() async {
    _userName = await PreferencesService.getUserName();
    _userHostel = await PreferencesService.getUserHostel();

    if (_currentRegNo != null) {
      final regNo = _currentRegNo;

      // Mandatory: Pre-load Semester Data first as most features depend on it
      final semD = await CacheService.getData(regNo, 'SemesterData');
      if (semD != null) {
        _semesterData = SemesterData.fromJson(semD);
        _selectedSemesterId = _findBestSemester(_semesterData!);
      }

      // Pre-load all other key data types from cache
      final futures = [
        CacheService.getData(regNo, 'AttendanceData').then((d) {
          if (d != null) _attendanceData = AttendanceData.fromJson(d);
        }),
        CacheService.getData(regNo, 'TimetableData').then((d) {
          if (d != null) _timetableData = TimetableData.fromJson(d);
        }),
        CacheService.getData(regNo, 'MarksData').then((d) {
          if (d != null) _marksData = MarksData.fromJson(d);
        }),
        CacheService.getData(regNo, 'GradeViewData').then((d) {
          if (d != null) _gradeViewData = GradeViewData.fromJson(d);
        }),
        CacheService.getData(regNo, 'GradeHistoryData').then((d) {
          if (d != null) _gradeHistoryData = GradeHistoryData.fromJson(d);
        }),
        CacheService.getData(regNo, 'ExamScheduleData').then((d) {
          if (d != null) _examScheduleData = ExamScheduleData.fromJson(d);
        }),
      ];

      await Future.wait(futures);
    }

    notifyListeners();

    // After loading cache, kick off a background semester fetch
    // so dropdown and screens are ready even on first run
    if (_currentRegNo != null) {
      fetchSemesters();
    }
  }

  Future<void> setUserName(String name) async {
    _userName = name;
    await PreferencesService.setUserName(name);
    notifyListeners();
  }

  Future<void> setUserHostel(String hostel) async {
    _userHostel = hostel;
    await PreferencesService.setUserHostel(hostel);
    notifyListeners();
  }

  String? _selectedSemesterId;
  String? get selectedSemesterId => _selectedSemesterId;

  /// Returns the best semester ID based on the current date.
  /// Useful for screens like Exam Schedule that need the current semester.
  String? get defaultSemesterId =>
      _semesterData != null ? _findBestSemester(_semesterData!) : null;

  /// Returns the semester BEFORE the current one in the list.
  /// Useful for the Grades screen.
  String? get previousSemesterId {
    if (_semesterData == null) return null;
    final currentId = defaultSemesterId;
    if (currentId == null) return null;

    final index = _semesterData!.semesters.indexWhere((s) => s.id == currentId);
    if (index != -1 && index + 1 < _semesterData!.semesters.length) {
      return _semesterData!.semesters[index + 1].id;
    }
    return null;
  }

  SemesterData? _semesterData;
  SemesterData? get semesterData => _semesterData;

  AttendanceData? _attendanceData;
  AttendanceData? get attendanceData => _attendanceData;

  final Map<String, FullAttendanceData> _fullAttendanceCache = {};
  FullAttendanceData? getFullAttendance(String courseId, String courseType) =>
      _fullAttendanceCache["${courseId}_$courseType"];

  TimetableData? _timetableData;
  TimetableData? get timetableData => _timetableData;

  MarksData? _marksData;
  MarksData? get marksData => _marksData;

  GradeViewData? _gradeViewData;
  GradeViewData? get gradeViewData => _gradeViewData;

  final Map<String, GradeDetailsData> _gradeDetailsCache = {};
  GradeDetailsData? getGradeDetails(String courseId) =>
      _gradeDetailsCache[courseId];

  GradeHistoryData? _gradeHistoryData;
  GradeHistoryData? get gradeHistoryData => _gradeHistoryData;

  ExamScheduleData? _examScheduleData;
  ExamScheduleData? get examScheduleData => _examScheduleData;

  void setSelectedSemester(String semId) {
    if (_selectedSemesterId != semId) {
      _selectedSemesterId = semId;
      // Clear stale data for the old semester
      _attendanceData = null;
      _timetableData = null;
      _marksData = null;
      _gradeViewData = null;
      _fullAttendanceCache.clear();
      _gradeDetailsCache.clear();
      _examScheduleData = null;
      notifyListeners();
    }
  }

  String? get _activeSemId =>
      _selectedSemesterId ?? _semesterData?.semesters.firstOrNull?.id;

  Future<bool> _shouldFetch(String dataType, bool force) async {
    if (force) return true;
    if (_currentRegNo == null) return true;
    return await CacheService.isCacheStale(
      _currentRegNo,
      dataType,
      const Duration(hours: 24),
    );
  }

  Future<void> _saveToCache(String dataType, dynamic data) async {
    if (_currentRegNo != null && data != null) {
      await CacheService.saveData(_currentRegNo, dataType, data.toJson());
    }
  }

  Future<void> fetchSemesters({bool force = false}) async {
    if (!force && _semesterData != null) {
      // Even if we have data, check if we should refresh in background
      if (await _shouldFetch('SemesterData', false)) {
        // Fetch but don't set loading if we already have some data
        _apiService.getSemesters().then((data) {
          if (data != null) {
            _semesterData = data;
            _saveToCache('SemesterData', data);
            notifyListeners();
          }
        });
      }
      return;
    }

    _setLoading(true);
    try {
      final data = await _apiService.getSemesters();
      if (data != null) {
        _semesterData = data;
        _selectedSemesterId ??= _findBestSemester(data);
        _saveToCache('SemesterData', data);
      } else if (_semesterData == null) {
        _error = 'Failed to fetch semesters';
      }
    } catch (e) {
      if (_semesterData == null) _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchAttendance({String? semId, bool force = false}) async {
    final id = semId ?? _activeSemId;
    if (id == null) return;

    final cacheKey = 'AttendanceData_$id';
    if (!force && _attendanceData != null) {
      if (await _shouldFetch(cacheKey, false)) {
        _apiService.getAttendance(id).then((data) {
          if (data != null) {
            _attendanceData = data;
            _saveToCache(cacheKey, data);
            notifyListeners();
          }
        });
      }
      return;
    }

    _setLoading(true);
    try {
      final data = await _apiService.getAttendance(id);
      if (data != null) {
        _attendanceData = data;
        _saveToCache(cacheKey, data);
      } else if (_attendanceData == null) {
        _error = 'Failed to fetch attendance';
      }
    } catch (e) {
      if (_attendanceData == null) _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchFullAttendance(
    String courseId,
    String courseType, {
    String? semId,
    bool force = false,
  }) async {
    final id = semId ?? _activeSemId;
    if (id == null) return;
    final cacheKey = "${courseId}_$courseType";
    if (!force && _fullAttendanceCache.containsKey(cacheKey)) return;
    _setLoading(true);
    try {
      final data = await _apiService.getFullAttendance(
        id,
        courseId,
        courseType,
      );
      if (data != null) {
        _fullAttendanceCache[cacheKey] = data;
      } else {
        _error = 'Failed to fetch full attendance';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchTimetable({String? semId, bool force = false}) async {
    final id = semId ?? _activeSemId;
    if (id == null) return;

    final cacheKey = 'TimetableData_$id';
    if (!force && _timetableData != null) {
      if (await _shouldFetch(cacheKey, false)) {
        _apiService.getTimetable(id).then((data) {
          if (data != null) {
            _timetableData = data;
            _saveToCache(cacheKey, data);
            notifyListeners();
          }
        });
      }
      return;
    }

    _setLoading(true);
    try {
      final data = await _apiService.getTimetable(id);
      if (data != null) {
        _timetableData = data;
        _saveToCache(cacheKey, data);
      } else if (_timetableData == null) {
        _error = 'Failed to fetch timetable';
      }
    } catch (e) {
      if (_timetableData == null) _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchMarks({String? semId, bool force = false}) async {
    final id = semId ?? _activeSemId;
    if (id == null) return;

    final cacheKey = 'MarksData_$id';
    if (!force && _marksData != null) {
      if (await _shouldFetch(cacheKey, false)) {
        _apiService.getMarks(id).then((data) {
          if (data != null) {
            _marksData = data;
            _saveToCache(cacheKey, data);
            notifyListeners();
          }
        });
      }
      return;
    }

    _setLoading(true);
    try {
      final data = await _apiService.getMarks(id);
      if (data != null) {
        _marksData = data;
        _saveToCache(cacheKey, data);
      } else if (_marksData == null) {
        _error = 'Failed to fetch marks';
      }
    } catch (e) {
      if (_marksData == null) _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchGradeView({String? semId, bool force = false}) async {
    final id = semId ?? _activeSemId;
    if (id == null) return;

    final cacheKey = 'GradeViewData_$id';
    if (!force && _gradeViewData != null) {
      if (await _shouldFetch(cacheKey, false)) {
        _apiService.getGradeView(id).then((data) {
          if (data != null) {
            _gradeViewData = data;
            _saveToCache(cacheKey, data);
            notifyListeners();
          }
        });
      }
      return;
    }

    _setLoading(true);
    try {
      final data = await _apiService.getGradeView(id);
      if (data != null) {
        _gradeViewData = data;
        _saveToCache(cacheKey, data);
      } else if (_gradeViewData == null) {
        _error = 'Failed to fetch grade view';
      }
    } catch (e) {
      if (_gradeViewData == null) _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchGradeDetails(
    String courseId, {
    String? semId,
    bool force = false,
  }) async {
    final id = semId ?? _activeSemId;
    if (id == null) return;

    final cacheKey = 'GradeDetailsData_${id}_$courseId';
    if (!force && _gradeDetailsCache.containsKey(courseId)) {
      if (await _shouldFetch(cacheKey, false)) {
        _apiService.getGradeDetails(id, courseId).then((data) {
          if (data != null) {
            _gradeDetailsCache[courseId] = data;
            _saveToCache(cacheKey, data);
            notifyListeners();
          }
        });
      }
      return;
    }

    _setLoading(true);
    try {
      final data = await _apiService.getGradeDetails(id, courseId);
      if (data != null) {
        _gradeDetailsCache[courseId] = data;
        _saveToCache(cacheKey, data);
      } else if (!_gradeDetailsCache.containsKey(courseId)) {
        _error = 'Failed to fetch grade details';
      }
    } catch (e) {
      if (!_gradeDetailsCache.containsKey(courseId)) _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchGradeHistory({bool force = false}) async {
    const cacheKey = 'GradeHistoryData';
    if (!force && _gradeHistoryData != null) {
      if (await _shouldFetch(cacheKey, false)) {
        _apiService.getGradeHistoryData().then((data) {
          if (data != null) {
            _gradeHistoryData = data;
            _saveToCache(cacheKey, data);
            notifyListeners();
          }
        });
      }
      return;
    }

    _setLoading(true);
    try {
      final data = await _apiService.getGradeHistoryData();
      if (data != null) {
        _gradeHistoryData = data;
        _saveToCache(cacheKey, data);
      } else if (_gradeHistoryData == null) {
        _error = 'Failed to fetch grade history';
      }
    } catch (e) {
      if (_gradeHistoryData == null) _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchExamSchedule({String? semId, bool force = false}) async {
    final id = semId ?? _activeSemId;
    if (id == null) return;

    final cacheKey = 'ExamScheduleData_$id';
    if (!force && _examScheduleData != null) {
      if (await _shouldFetch(cacheKey, false)) {
        _apiService.getExamSchedule(id).then((data) {
          if (data != null) {
            _examScheduleData = data;
            _saveToCache(cacheKey, data);
            notifyListeners();
          }
        });
      }
      return;
    }

    _setLoading(true);
    try {
      final data = await _apiService.getExamSchedule(id);
      if (data != null) {
        _examScheduleData = data;
        _saveToCache(cacheKey, data);
      } else if (_examScheduleData == null) {
        _error = 'Failed to fetch exam schedule';
      }
    } catch (e) {
      if (_examScheduleData == null) _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool val) {
    if (val) {
      _loadingCount++;
      _error = null;
    } else {
      if (_loadingCount > 0) _loadingCount--;
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearAllData() {
    _semesterData = null;
    _attendanceData = null;
    _timetableData = null;
    _marksData = null;
    _gradeViewData = null;
    _fullAttendanceCache.clear();
    _gradeDetailsCache.clear();
    _gradeHistoryData = null;
    _examScheduleData = null;
    _error = null;
    _selectedSemesterId = null;
    notifyListeners();
  }

  Future<void> resetState() async {
    final regNo = _currentRegNo;
    _userName = null;
    _userHostel = null;
    await PreferencesService.clearAll();
    clearAllData();
    if (regNo != null) {
      await CacheService.clearCache(regNo);
    }
  }

  String? _findBestSemester(SemesterData data) {
    if (data.semesters.isEmpty) return null;

    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    // Logic:
    // Jan-June: Winter Semester (e.g., "Winter 2024-25")
    // July-Dec: Fall Semester (e.g., "Fall 2024-25")
    final String targetPrefix = (month >= 1 && month <= 6) ? 'Winter' : 'Fall';
    final String targetYearRange = (month >= 7)
        ? '$year-${(year + 1).toString().substring(2)}'
        : '${year - 1}-${year.toString().substring(2)}';

    final searchTag = '$targetPrefix $targetYearRange';

    for (var sem in data.semesters) {
      if (sem.id.contains(searchTag) || sem.name.contains(searchTag)) {
        return sem.id;
      }
    }

    // Fallback search prefix only
    for (var sem in data.semesters) {
      if (sem.name.startsWith(targetPrefix)) {
        return sem.id;
      }
    }

    return data.semesters.first.id;
  }
}
