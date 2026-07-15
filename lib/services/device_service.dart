import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static final String deviceIdKey = 'device_id';
  String? _deviceId;

  Future<String> getDeviceId() async {
    _deviceId ??= await loadDeviceId();
    _deviceId ??= await generateDeviceId();
    return _deviceId!;
  }

  Future<void> saveDeviceId(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(deviceIdKey, deviceId);
    _deviceId = deviceId;
  }

  Future<String> generateDeviceId() async {
    final uuid = Uuid();
    final newDeviceId = uuid.v4();
    await saveDeviceId(newDeviceId);
    return newDeviceId;
  }

  Future<String?> loadDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(deviceIdKey);
  }
}
