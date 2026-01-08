import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class StorageService {
  static late SharedPreferences _prefs;
  static late Box<dynamic> _hiveBox;

  static Future<void> initialize() async {
    // Initialize SharedPreferences
    _prefs = await SharedPreferences.getInstance();

    // Initialize Hive
    await Hive.initFlutter();
    _hiveBox = await Hive.openBox('mobiletrade_data');
  }

  // ===================== AUTH TOKEN =====================

  static Future<void> setAuthToken(String token) async {
    await _prefs.setString('auth_token', token);
  }

  static String? getAuthToken() {
    return _prefs.getString('auth_token');
  }

  static Future<void> clearAuthToken() async {
    await _prefs.remove('auth_token');
  }

  // ===================== USER DATA =====================

  static Future<void> setUserId(int userId) async {
    await _prefs.setInt('user_id', userId);
  }

  static int? getUserId() {
    return _prefs.getInt('user_id');
  }

  static Future<void> setUserData(Map<String, dynamic> userData) async {
    await _prefs.setString('user_data', jsonEncode(userData));
  }

  static Map<String, dynamic>? getUserData() {
    final data = _prefs.getString('user_data');
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  // ===================== APP SETTINGS =====================

  static Future<void> setThemeMode(String mode) async {
    await _prefs.setString('theme_mode', mode);
  }

  static String getThemeMode() {
    return _prefs.getString('theme_mode') ?? 'light';
  }

  static Future<void> setLanguage(String language) async {
    await _prefs.setString('language', language);
  }

  static String getLanguage() {
    return _prefs.getString('language') ?? 'ar';
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool('notifications_enabled', enabled);
  }

  static bool isNotificationsEnabled() {
    return _prefs.getBool('notifications_enabled') ?? true;
  }

  static Future<void> setOfflineModeEnabled(bool enabled) async {
    await _prefs.setBool('offline_mode_enabled', enabled);
  }

  static bool isOfflineModeEnabled() {
    return _prefs.getBool('offline_mode_enabled') ?? true;
  }

  // ===================== DEVICE SETTINGS =====================

  static Future<void> setDeviceId(String deviceId) async {
    await _prefs.setString('device_id', deviceId);
  }

  static String? getDeviceId() {
    return _prefs.getString('device_id');
  }

  static Future<void> setDeviceName(String name) async {
    await _prefs.setString('device_name', name);
  }

  static String? getDeviceName() {
    return _prefs.getString('device_name');
  }

  // ===================== PRINTER SETTINGS =====================

  static Future<void> setDefaultPrinter(String printerName) async {
    await _prefs.setString('default_printer', printerName);
  }

  static String? getDefaultPrinter() {
    return _prefs.getString('default_printer');
  }

  static Future<void> setPrinterWidth(int width) async {
    await _prefs.setInt('printer_width', width);
  }

  static int getPrinterWidth() {
    return _prefs.getInt('printer_width') ?? 80;
  }

  static Future<void> setPrintFooter(String footer) async {
    await _prefs.setString('print_footer', footer);
  }

  static String? getPrintFooter() {
    return _prefs.getString('print_footer');
  }

  // ===================== TAX & CURRENCY =====================

  static Future<void> setDefaultTaxRate(double rate) async {
    await _prefs.setDouble('default_tax_rate', rate);
  }

  static double getDefaultTaxRate() {
    return _prefs.getDouble('default_tax_rate') ?? 19.0;
  }

  static Future<void> setCurrency(String currency) async {
    await _prefs.setString('currency', currency);
  }

  static String getCurrency() {
    return _prefs.getString('currency') ?? 'DZD';
  }

  // ===================== SYNC SETTINGS =====================

  static Future<void> setAutoSyncEnabled(bool enabled) async {
    await _prefs.setBool('auto_sync_enabled', enabled);
  }

  static bool isAutoSyncEnabled() {
    return _prefs.getBool('auto_sync_enabled') ?? true;
  }

  static Future<void> setSyncInterval(int minutes) async {
    await _prefs.setInt('sync_interval', minutes);
  }

  static int getSyncInterval() {
    return _prefs.getInt('sync_interval') ?? 5;
  }

  static Future<void> setLastSyncTime(DateTime time) async {
    await _prefs.setString('last_sync_time', time.toIso8601String());
  }

  static DateTime? getLastSyncTime() {
    final time = _prefs.getString('last_sync_time');
    if (time != null) {
      return DateTime.tryParse(time);
    }
    return null;
  }

  // ===================== HIVE STORAGE (Complex Objects) =====================

  static Future<void> saveInvoicesDraft(Map<String, dynamic> draft) async {
    await _hiveBox.put('invoices_draft', draft);
  }

  static Map<String, dynamic>? getInvoicesDraft() {
    return _hiveBox.get('invoices_draft');
  }

  static Future<void> clearInvoicesDraft() async {
    await _hiveBox.delete('invoices_draft');
  }

  static Future<void> saveCacheData(String key, dynamic data) async {
    await _hiveBox.put(key, data);
  }

  static dynamic getCacheData(String key) {
    return _hiveBox.get(key);
  }

  static Future<void> clearCache() async {
    await _hiveBox.clear();
  }

  // ===================== FAVORITES & RECENT =====================

  static Future<void> addToRecent(String type, int id, String name) async {
    final recent = getRecent(type) ?? [];
    
    // Remove duplicate if exists
    recent.removeWhere((item) => item['id'] == id);
    
    // Add to beginning
    recent.insert(0, {'id': id, 'name': name, 'timestamp': DateTime.now().toIso8601String()});
    
    // Keep only last 10
    if (recent.length > 10) {
      recent.removeRange(10, recent.length);
    }

    await _prefs.setStringList(
      'recent_$type',
      recent.map((item) => jsonEncode(item)).toList(),
    );
  }

  static List<Map<String, dynamic>>? getRecent(String type) {
    final data = _prefs.getStringList('recent_$type');
    if (data != null) {
      return data.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
    }
    return null;
  }

  // ===================== LOGOUT =====================

  static Future<void> logout() async {
    await clearAuthToken();
    await _prefs.remove('user_id');
    await _prefs.remove('user_data');
    await _hiveBox.clear();
  }

  // ===================== CLEAR ALL =====================

  static Future<void> clearAll() async {
    await _prefs.clear();
    await _hiveBox.clear();
  }
}
