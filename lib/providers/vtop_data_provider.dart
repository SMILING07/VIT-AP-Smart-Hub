import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../services/vtop_api_service.dart';
import '../src/rust/api/vtop/types.dart';

class VtopDataProvider extends ChangeNotifier {
  final VtopApiService _apiService;

  VtopDataProvider(this._apiService) {
    initializePreferences();
  }

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
    notifyListeners();
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

  SemesterData? _semesterData;
  SemesterData? get semesterData => _semesterData;

  AttendanceData? _attendanceData;
  AttendanceData? get attendanceData => _attendanceData;

  FullAttendanceData? _fullAttendanceData;
  FullAttendanceData? get fullAttendanceData => _fullAttendanceData;

  TimetableData? _timetableData;
  TimetableData? get timetableData => _timetableData;

  MarksData? _marksData;
  MarksData? get marksData => _marksData;

  GradeViewData? _gradeViewData;
  GradeViewData? get gradeViewData => _gradeViewData;

  GradeDetailsData? _gradeDetailsData;
  GradeDetailsData? get gradeDetailsData => _gradeDetailsData;

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
      _gradeDetailsData = null;
      _examScheduleData = null;
      notifyListeners();
    }
  }

  String? get _activeSemId =>
      _selectedSemesterId ?? _semesterData?.semesters.firstOrNull?.id;

  Future<void> fetchSemesters({bool force = false}) async {
    if (!force && _semesterData != null) return;
    _setLoading(true);
    try {
      final data = await _apiService.getSemesters();
      if (data != null) {
        _semesterData = data;
        _selectedSemesterId ??= _findBestSemester(data);
      } else {
        _error = 'Failed to fetch semesters';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchAttendance({String? semId, bool force = false}) async {
    final id = semId ?? _activeSemId;
    if (id == null) return;
    if (!force && _attendanceData != null) return;
    _setLoading(true);
    try {
      final data = await _apiService.getAttendance(id);
      if (data != null) {
        _attendanceData = data;
      } else {
        _error = 'Failed to fetch attendance';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchFullAttendance(String courseId, String courseType, {String? semId, bool force = false}) async {
    final id = semId ?? _activeSemId;
    if (id == null) return;
    if (!force && _fullAttendanceData != null) return;
    _setLoading(true);
    try {
      final data = await _apiService.getFullAttendance(id, courseId, courseType);
      if (data != null) {
        _fullAttendanceData = data;
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
    if (!force && _timetableData != null) return;
    _setLoading(true);
    try {
      final data = await _apiService.getTimetable(id);
      if (data != null) {
        _timetableData = data;
      } else {
        _error = 'Failed to fetch timetable';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchMarks({String? semId, bool force = false}) async {
    final id = semId ?? _activeSemId;
    if (id == null) return;
    if (!force && _marksData != null) return;
    _setLoading(true);
    try {
      final data = await _apiService.getMarks(id);
      if (data != null) {
        _marksData = data;
      } else {
        _error = 'Failed to fetch marks';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchGradeView({String? semId, bool force = false}) async {
    final id = semId ?? _activeSemId;
    if (id == null) return;
    if (!force && _gradeViewData != null) return;
    _setLoading(true);
    try {
      final data = await _apiService.getGradeView(id);
      if (data != null) {
        _gradeViewData = data;
      } else {
        _error = 'Failed to fetch grade view';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchGradeDetails(String courseId, {String? semId, bool force = false}) async {
    final id = semId ?? _activeSemId;
    if (id == null) return;
    if (!force && _gradeDetailsData != null) return;
    _setLoading(true);
    try {
      final data = await _apiService.getGradeDetails(id, courseId);
      if (data != null) {
        _gradeDetailsData = data;
      } else {
        _error = 'Failed to fetch grade details';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchGradeHistory({bool force = false}) async {
    if (!force && _gradeHistoryData != null) return;
    _setLoading(true);
    try {
      final data = await _apiService.getGradeHistoryData();
      if (data != null) {
        _gradeHistoryData = data;
      } else {
        _error = 'Failed to fetch grade history';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchExamSchedule({String? semId, bool force = false}) async {
    final id = semId ?? _activeSemId;
    if (id == null) return;
    if (!force && _examScheduleData != null) return;
    _setLoading(true);
    try {
      final data = await _apiService.getExamSchedule(id);
      if (data != null) {
        _examScheduleData = data;
      } else {
        _error = 'Failed to fetch exam schedule';
      }
    } catch (e) {
      _error = e.toString();
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
    _fullAttendanceData = null;
    _timetableData = null;
    _marksData = null;
    _gradeViewData = null;
    _gradeDetailsData = null;
    _gradeHistoryData = null;
    _examScheduleData = null;
    _error = null;
    _selectedSemesterId = null;
    notifyListeners();
  }

  Future<void> resetState() async {
    _userName = null;
    _userHostel = null;
    await PreferencesService.clearAll();
    clearAllData();
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
