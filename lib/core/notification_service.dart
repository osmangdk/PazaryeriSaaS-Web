import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Firebase imports - yalnızca Firebase yapılandırıldığında aktif olacak
// ignore: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Firebase push bildirimleri + lokal bildirim servisi
/// google-services.json yoksa Firebase başlatma sessizce atlanır.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static bool _firebaseReady = false;

  /// Uygulamanın açılışında bir kez çağrılır.
  static Future<void> initialize() async {
    await _initLocalNotifications();
    await _initFirebase();
  }

  // ─── Lokal Bildirimler ────────────────────────────────────────────────────

  static Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotif.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Android 8+ Bildirim Kanalı
    if (!kIsWeb && Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'pazaryeri_notifications',
        'Pazaryeri Bildirimleri',
        description: 'Sipariş ve stok uyarıları',
        importance: Importance.high,
        playSound: true,
      );
      await _localNotif
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Bildirime tıklanınca yapılacak işlemler buraya eklenebilir
  }

  /// Herhangi bir yerde lokal bildirim göster
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'pazaryeri_notifications',
      'Pazaryeri Bildirimleri',
      channelDescription: 'Sipariş ve stok uyarıları',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _localNotif.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // ─── Firebase Cloud Messaging ─────────────────────────────────────────────

  static Future<void> _initFirebase() async {
    if (kIsWeb) return;
    try {
      // Firebase zaten başlatılmışsa tekrar başlatma
      if (Firebase.apps.isEmpty) return;
      _firebaseReady = true;

      final messaging = FirebaseMessaging.instance;

      // iOS izin iste
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // FCM Token al ve kaydet
      final token = await messaging.getToken();
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
      }

      // Foreground mesaj handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          showNotification(
            title: notification.title ?? 'Pazaryeri SaaS',
            body: notification.body ?? '',
            payload: message.data['route'],
          );
        }
      });

      // Token yenilendiğinde güncelle
      messaging.onTokenRefresh.listen((newToken) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', newToken);
      });
    } catch (e) {
      // google-services.json yoksa veya Firebase yapılandırılmamışsa sessizce atla
      _firebaseReady = false;
    }
  }

  static bool get isFirebaseReady => _firebaseReady;

  /// Sipariş bildirimi (Firebase olmadan da çalışır)
  static Future<void> notifyNewOrder({
    required String orderNumber,
    required String marketplace,
    required double amount,
  }) async {
    await showNotification(
      title: "Yeni Siparis — " + marketplace,
      body: "#" + orderNumber + " • TL" + amount.toStringAsFixed(2),
      payload: '/dashboard/orders',
    );
  }

  /// Stok uyarısı bildirimi
  static Future<void> notifyLowStock({
    required String productName,
    required int remaining,
  }) async {
    await showNotification(
      title: "Dusuk Stok Uyarisi",
      body: productName + " — " + remaining.toString() + " adet kaldi",
      payload: '/dashboard/products',
    );
  }
}
