import 'package:flutter/foundation.dart';
import '../src/rust/api/vtop/vtop_client.dart';
import '../src/rust/api/vtop_get_client.dart';
import '../src/rust/api/vtop/types.dart';

class VtopApiService {
  VtopClient? _client;

  VtopClient? get client => _client;

  /// Initializes the VTOP client with credentials and optional cookies
  void initClient(String regNo, String password, {String? cookie}) {
    _client = getVtopClient(
      username: regNo,
      password: password,
      cookie: cookie,
    );
  }

  /// Attempts to login using the Rust-based VtopClient
  Future<bool> login(String regNo, String password) async {
    try {
      // Re-initialize client for new credentials to avoid session overlap
      initClient(regNo, password);
      await vtopClientLogin(client: _client!);
      return await fetchIsAuth(client: _client!);
    } catch (e) {
      debugPrint('Error during VTOP login: $e');
      return false;
    }
  }

  /// Fetches the list of available semesters
  Future<SemesterData?> getSemesters() async {
    if (_client == null) return null;
    try {
      return await fetchSemesters(client: _client!);
    } catch (e) {
      debugPrint('Error fetching semesters: $e');
      return null;
    }
  }

  /// Fetches attendance for a specific semester
  Future<AttendanceData?> getAttendance(String semesterId) async {
    if (_client == null) return null;
    try {
      return await fetchAttendance(client: _client!, semesterId: semesterId);
    } catch (e) {
      debugPrint('Error fetching attendance: $e');
      return null;
    }
  }

  /// Fetches full attendance details for a course
  Future<FullAttendanceData?> getFullAttendance(
    String semesterId,
    String courseId,
    String courseType,
  ) async {
    if (_client == null) return null;
    try {
      return await fetchFullAttendance(
        client: _client!,
        semesterId: semesterId,
        courseId: courseId,
        courseType: courseType,
      );
    } catch (e) {
      debugPrint('Error fetching full attendance: $e');
      return null;
    }
  }

  /// Fetches the timetable for a specific semester
  Future<TimetableData?> getTimetable(String semesterId) async {
    if (_client == null) return null;
    try {
      return await fetchTimetable(client: _client!, semesterId: semesterId);
    } catch (e) {
      debugPrint('Error fetching timetable: $e');
      return null;
    }
  }

  /// Fetches marks for a specific semester
  Future<MarksData?> getMarks(String semesterId) async {
    if (_client == null) return null;
    try {
      return await fetchMarks(client: _client!, semesterId: semesterId);
    } catch (e) {
      debugPrint('Error fetching marks: $e');
      return null;
    }
  }

  /// Fetches the exam schedule for a specific semester
  Future<ExamScheduleData?> getExamSchedule(String semesterId) async {
    if (_client == null) return null;
    try {
      return await fetchExamShedule(client: _client!, semesterId: semesterId);
    } catch (e) {
      debugPrint('Error fetching exam schedule: $e');
      return null;
    }
  }

  /// Fetches the grade view for a specific semester
  Future<GradeViewData?> getGradeView(String semesterId) async {
    if (_client == null) return null;
    try {
      return await fetchGradeView(client: _client!, semesterId: semesterId);
    } catch (e) {
      debugPrint('Error fetching grade view: $e');
      return null;
    }
  }

  /// Fetches detailed grades for a course
  Future<GradeDetailsData?> getGradeDetails(
    String semesterId,
    String courseId,
  ) async {
    if (_client == null) return null;
    try {
      return await fetchGradeViewDetails(
        client: _client!,
        semesterId: semesterId,
        courseId: courseId,
      );
    } catch (e) {
      debugPrint('Error fetching grade details: $e');
      return null;
    }
  }

  /// Fetches the entire grade history
  Future<GradeHistoryData?> getGradeHistoryData() async {
    if (_client == null) return null;
    try {
      return await fetchGradeHistory(client: _client!);
    } catch (e) {
      debugPrint('Error fetching grade history: $e');
      return null;
    }
  }

  /// Fetches the current session cookies from Rust
  Future<Uint8List?> getCookies() async {
    if (_client == null) return null;
    try {
      return await fetchCookies(client: _client!);
    } catch (e) {
      debugPrint('Error fetching cookies: $e');
      return null;
    }
  }

  /// WIFI login/logout using Rust
  Future<(bool, String)> wifiAction(
    String username,
    String password,
    int action,
  ) async {
    try {
      return await fetchWifi(username: username, password: password, i: action);
    } catch (e) {
      debugPrint('Error during WIFI action: $e');
      return (false, "Error: $e");
    }
  }
}
