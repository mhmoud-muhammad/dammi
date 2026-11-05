import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// أزرار التواصل الفوري (اتصال / رسالة / واتساب) عبر url_launcher.
class ContactLauncher {
  ContactLauncher._();

  static String _digits(String phone) => phone.replaceAll(RegExp(r'[^0-9+]'), '');

  static Future<void> call(BuildContext context, String phone) =>
      _open(context, Uri(scheme: 'tel', path: _digits(phone)));

  static Future<void> sms(BuildContext context, String phone) =>
      _open(context, Uri(scheme: 'sms', path: _digits(phone)));

  static Future<void> whatsapp(BuildContext context, String phone, {String? message}) {
    final number = _digits(phone).replaceFirst('+', '');
    return _open(
      context,
      Uri.https('wa.me', '/$number', message == null ? null : {'text': message}),
      external: true,
    );
  }

  static Future<void> _open(BuildContext context, Uri uri, {bool external = false}) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchUrl(
      uri,
      mode: external ? LaunchMode.externalApplication : LaunchMode.platformDefault,
    );
    if (!ok) {
      messenger.showSnackBar(const SnackBar(content: Text('تعذر فتح التطبيق المطلوب.')));
    }
  }
}
