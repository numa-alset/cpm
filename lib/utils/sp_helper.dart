import 'package:shared_preferences/shared_preferences.dart';

class SpHelper {
  static const _keyCode = 'code';
  static const _keyAmountSyriatel = 'amount_syriatel';
  static const _keyAmountMtn = 'amount_mtn';

  /// Save code
  static Future<void> setCode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCode, value);
  }

  /// Get saved code (returns null if not set)
  static Future<String?> getCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCode);
  }

  /// Remove code
  static Future<void> clearCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCode);
  }

  /// Check if code exists
  static Future<bool> hasCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyCode);
  }

  // -------------------------------------------------------------
  // AMOUNTS (SYRIATEL + MTN)
  // -------------------------------------------------------------

  /// Set amount for Syriatel
  static Future<void> setAmountSyriatel(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyAmountSyriatel, value);
  }

  /// Get amount for Syriatel (defaults to 0.0)
  static Future<double> getAmountSyriatel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyAmountSyriatel) ?? 0.0;
  }

  /// Increase Syriatel amount
  static Future<void> increaseAmountSyriatel(double delta) async {
    final current = await getAmountSyriatel();
    await setAmountSyriatel(current + delta);
  }

  /// Decrease Syriatel amount (never below 0)
  static Future<void> decreaseAmountSyriatel(double delta) async {
    final current = await getAmountSyriatel();
    await setAmountSyriatel((current - delta).clamp(0, double.infinity));
  }

  /// Clear Syriatel amount
  static Future<void> clearAmountSyriatel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAmountSyriatel);
  }

  /// Check if Syriatel amount exists
  static Future<bool> hasAmountSyriatel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyAmountSyriatel);
  }

  // -------------------------------------------------------------
  // MTN
  // -------------------------------------------------------------

  /// Set amount for MTN
  static Future<void> setAmountMtn(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyAmountMtn, value);
  }

  /// Get amount for MTN (defaults to 0.0)
  static Future<double> getAmountMtn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyAmountMtn) ?? 0.0;
  }

  /// Increase MTN amount
  static Future<void> increaseAmountMtn(double delta) async {
    final current = await getAmountMtn();
    await setAmountMtn(current + delta);
  }

  /// Decrease MTN amount (never below 0)
  static Future<void> decreaseAmountMtn(double delta) async {
    final current = await getAmountMtn();
    await setAmountMtn((current - delta).clamp(0, double.infinity));
  }

  /// Clear MTN amount
  static Future<void> clearAmountMtn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAmountMtn);
  }

  /// Check if MTN amount exists
  static Future<bool> hasAmountMtn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyAmountMtn);
  }

  // -------------------------------------------------------------
  // GENERAL
  // -------------------------------------------------------------

  /// Clear everything (code + all amounts)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCode);
    await prefs.remove(_keyAmountSyriatel);
    await prefs.remove(_keyAmountMtn);
  }
}
