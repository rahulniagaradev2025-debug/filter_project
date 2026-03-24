import 'package:shared_preferences/shared_preferences.dart';

class AuthPreferences {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyMobileNumber = 'user_mobile';
  static const String _keyPassword = 'user_password';

  static final AuthPreferences instance = AuthPreferences._();
  AuthPreferences._();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool isLoggedIn() {
    return _prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<void> setLoggedIn(bool value) async {
    await _prefs.setBool(_keyIsLoggedIn, value);
  }

  Future<void> saveCredentials(String mobile, String password) async {
    await _prefs.setString(_keyMobileNumber, mobile);
    await _prefs.setString(_keyPassword, password);
  }

  String? getSavedMobile() => _prefs.getString(_keyMobileNumber);
  String? getSavedPassword() => _prefs.getString(_keyPassword);
}
