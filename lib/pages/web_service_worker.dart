// lib/pages/web_service_worker.dart
// ignore_for_file: avoid_web_libraries_in_flutter, avoid_print

// ignore: deprecated_member_use
import 'dart:html' as html;

void registerServiceWorker() {
  html.window.navigator.serviceWorker
      ?.register('firebase-messaging-sw.js')
      .then((registration) {
    print("✅ Service Worker registered: ${registration.scope}");
  }).catchError((e) {
    print("❌ Service Worker registration failed: $e");
  });
}
