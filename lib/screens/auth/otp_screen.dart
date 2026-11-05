import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';

/// شاشة ١ (الجزء الثاني): إدخال رمز التحقق.
class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final int? resendToken;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _code = TextEditingController();
  late String _verificationId = widget.verificationId;
  late int? _resendToken = widget.resendToken;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _done() {
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.length != 6) {
      showSnack(context, 'الرمز مكون من ٦ أرقام.');
      return;
    }
    setState(() => _busy = true);
    try {
      await AuthService.instance.verifyCode(verificationId: _verificationId, smsCode: code);
      _done();
    } on FirebaseAuthException catch (e) {
      if (mounted) showSnack(context, AuthService.messageFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _busy = true);
    await AuthService.instance.sendCode(
      phoneNumber: widget.phoneNumber,
      resendToken: _resendToken,
      onCodeSent: (id, token) {
        if (!mounted) return;
        setState(() {
          _verificationId = id;
          _resendToken = token;
          _busy = false;
        });
        showSnack(context, 'تم إرسال رمز جديد.');
      },
      onError: (message) {
        if (!mounted) return;
        setState(() => _busy = false);
        showSnack(context, message);
      },
      onAutoVerified: _done,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('رمز التحقق')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('أدخل الرمز المرسل إلى',
              style: TextStyle(fontSize: 15, color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(widget.phoneNumber,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, letterSpacing: 12, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(counterText: '', hintText: '------'),
              onSubmitted: (_) => _verify(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _verify,
            child: const Text('تأكيد'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : _resend,
            child: const Text('إعادة إرسال الرمز'),
          ),
        ],
      ),
    );
  }
}
