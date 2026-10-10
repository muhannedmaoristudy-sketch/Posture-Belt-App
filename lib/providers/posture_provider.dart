import 'package:flutter/foundation.dart';
import '../models/alert_model.dart';
import '../services/database_service.dart';
import '../services/ble_service.dart';

class PostureProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final BleService _bleService = BleService();

  List<PostureAlert> _todayAlerts = [];
  List<PostureAlert> _weekAlerts = [];
  bool _isInitialized = false;

  List<PostureAlert> get todayAlerts => _todayAlerts;
  List<PostureAlert> get weekAlerts => _weekAlerts;
  bool get isInitialized => _isInitialized;

  PostureProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _bleService.receivedData.addListener(_onBleDataReceived);
    await loadTodayAlerts();
    await loadWeekAlerts();
    _isInitialized = true;
    notifyListeners();
  }

  void _onBleDataReceived() {
    final data = _bleService.receivedData.value;
    if (data != null && data.isNotEmpty) {
      // If ESP32 sends "1" as a byte (49 in ASCII) or integer 1
      if (data[0] == 1 || data[0] == 49) {
        addAlert();
      }
    }
  }

  Future<void> addAlert() async {
    final alert = PostureAlert(timestamp: DateTime.now());
    await _databaseService.insertAlert(alert);
    await loadTodayAlerts();
    await loadWeekAlerts();
    notifyListeners();
  }

  Future<void> loadTodayAlerts() async {
    _todayAlerts = await _databaseService.getAlertsForDay(DateTime.now());
    notifyListeners();
  }

  Future<void> loadWeekAlerts() async {
    _weekAlerts = await _databaseService.getAlertsForWeek(DateTime.now());
    notifyListeners();
  }

  int getTodayAlertCount() => _todayAlerts.length;

  Map<int, int> getAlertsPerDay() {
    final Map<int, int> alertsPerDay = {};

    for (int i = 0; i < 7; i++) {
      alertsPerDay[i] = 0;
    }

    for (var alert in _weekAlerts) {
      final dayOfWeek = alert.timestamp.weekday - 1;
      alertsPerDay[dayOfWeek] = (alertsPerDay[dayOfWeek] ?? 0) + 1;
    }

    return alertsPerDay;
  }

  String getPeakHour() {
    if (_todayAlerts.isEmpty) {
      return 'No data';
    }

    Map<int, int> hourlyAlerts = {};

    for (var alert in _todayAlerts) {
      final hour = alert.timestamp.hour;
      hourlyAlerts[hour] = (hourlyAlerts[hour] ?? 0) + 1;
    }

    int peakHour = hourlyAlerts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final endHour = (peakHour + 1) % 24;

    return '${peakHour.toString().padLeft(2, '0')}:00 - ${endHour.toString().padLeft(2, '0')}:00';
  }

  BleService get bleService => _bleService;

  @override
  void dispose() {
    _bleService.disconnect();
    super.dispose();
  }
}
