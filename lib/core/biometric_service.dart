import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Parmak izi ve Face ID ile biyometrik kimlik doğrulama servisi
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Cihazda biyometrik donanım ve kayıtlı biyometri var mı?
  static Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isDeviceSupported) return false;

      final biometrics = await _auth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Mevcut biyometri türünü döndürür (face / fingerprint / none)
  static Future<BiometricType?> getPreferredBiometric() async {
    try {
      final biometrics = await _auth.getAvailableBiometrics();
      if (biometrics.contains(BiometricType.face)) return BiometricType.face;
      if (biometrics.contains(BiometricType.fingerprint)) {
        return BiometricType.fingerprint;
      }
      if (biometrics.contains(BiometricType.strong)) {
        return BiometricType.strong;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Kullanıcıyı biyometrik olarak doğrula.
  /// [reason] — ekranda gösterilecek açıklama metni
  static Future<bool> authenticate({
    String reason = 'RoaTech uygulamasına giriş yapmak için doğrulayın',
  }) async {
    if (kIsWeb) return false;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // PIN'e geri dönüşe izin ver
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// Son oturum açılmış token'ı SharedPreferences'tan al
  static Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Token kaydet (login başarılı olduktan sonra çağrılır)
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  /// Biyometrik giriş aktif mi? (token kaydedilmiş mi?)
  static Future<bool> hasSavedSession() async {
    final token = await getSavedToken();
    return token != null && token.isNotEmpty;
  }
}
