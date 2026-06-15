import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticated = false;
  bool _lockEnabled = true;

  bool get isAuthenticated => _isAuthenticated;
  bool get lockEnabled => _lockEnabled;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _lockEnabled = prefs.getBool('lock_enabled') ?? false;
  }

  Future<void> setLockEnabled(bool value) async {
    _lockEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lock_enabled', value);
  }

  Future<bool> canAuthenticate() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    if (!_lockEnabled) {
      _isAuthenticated = true;
      return true;
    }
    try {
      final can = await canAuthenticate();
      if (!can) {
        _isAuthenticated = true;
        return true;
      }
      _isAuthenticated = await _auth.authenticate(
        localizedReason: 'Unlock REMS to access your properties',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      return _isAuthenticated;
    } catch (_) {
      _isAuthenticated = false;
      return false;
    }
  }

  void lock() {
    _isAuthenticated = false;
  }
}
