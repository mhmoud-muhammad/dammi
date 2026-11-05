import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import 'otp_screen.dart';

/// شاشة ١ (الجزء الأول): إدخال رقم الهاتف وإرسال رمز التحقق.
class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final phoneNumber = normalizePhone(_phone.text);
    setState(() => _sending = true);

    await AuthService.instance.sendCode(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() => _sending = false);
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => OtpScreen(
            phoneNumber: phoneNumber,
            verificationId: verificationId,
            resendToken: resendToken,
          ),
        ));
      },
      onError: (message) {
        if (!mounted) return;
        setState(() => _sending = false);
        showSnack(context, message);
      },
      onAutoVerified: () {
        if (!mounted) return;
        Navigator.of(context).popUntil((r) => r.isFirst);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.water_drop, color: AppColors.primary, size: 28),
                ),
              ),
              const SizedBox(height: 14),
              Text('أهلاً بك',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text(
                'حساب واحد: متبرع جاهز في الأوقات العادية، وطالب دم عند الحاجة.',
                style: TextStyle(fontSize: 15, color: AppColors.muted, height: 1.6),
              ),
              const SizedBox(height: 32),
              const FieldLabel('رقم الهاتف'),
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    prefixText: '$kCountryCode  ',
                    hintText: '9X XXX XXXX',
                  ),
                  validator: (v) =>
                      isValidLocalPhone(v ?? '') ? null : 'أدخل رقماً صحيحاً من ٩ أرقام',
                ),
              ),
              const HelperText('سيصلك رمز تحقق، ويُستخدم الرقم لتواصل المتبرعين معك.'),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _sending ? null : _send,
                child: _sending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('إرسال رمز التحقق'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
