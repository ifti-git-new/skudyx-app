import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:skudyx/core/storage/app_prefs.dart';

class NotificationPrefsController extends ChangeNotifier {
  final AppPrefs prefs;
  NotificationPrefsController({required this.prefs});

  bool permissionGranted = false;

  bool setupReminders = true;
  bool deliveryUpdates = true;
  bool emergencyAlerts = true;
  bool systemAnnouncements = true;

  Future<void> init() async {
    await refreshPermission();
    _loadToggles();
  }

  Future<void> refreshPermission() async {
    final status = await Permission.notification.status;
    permissionGranted = status.isGranted;
    notifyListeners();
  }

  void _loadToggles() {
    setupReminders = prefs.notifSetupReminders;
    deliveryUpdates = prefs.notifDeliveryUpdates;
    emergencyAlerts = prefs.notifEmergencyAlerts;
    systemAnnouncements = prefs.notifSystemAnnouncements;
    notifyListeners();
  }

  Future<PermissionStatus> requestPermission() async {
    final status = await Permission.notification.request();
    permissionGranted = status.isGranted;
    notifyListeners();
    return status;
  }

  Future<void> setSetupReminders(bool v) async {
    setupReminders = v;
    notifyListeners();
    await prefs.setNotifSetupReminders(v);
  }

  Future<void> setDeliveryUpdates(bool v) async {
    deliveryUpdates = v;
    notifyListeners();
    await prefs.setNotifDeliveryUpdates(v);
  }

  Future<void> setEmergencyAlerts(bool v) async {
    emergencyAlerts = v;
    notifyListeners();
    await prefs.setNotifEmergencyAlerts(v);
  }

  Future<void> setSystemAnnouncements(bool v) async {
    systemAnnouncements = v;
    notifyListeners();
    await prefs.setNotifSystemAnnouncements(v);
  }
}
