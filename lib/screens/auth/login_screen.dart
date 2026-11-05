import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';

/// شاشة ١: تسجيل الدخول / إنشاء حساب بالبريد وكلمة المرور، أو بحساب Google.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _isRegister = false;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      // AppGate ينتقل تلقائياً بعد نجاح الدخول.
    } on FirebaseAuthException catch (e) {
      if (mounted) showSnack(context, AuthService.messageFor(e));
    } catch (e) {
      if (mounted) showSnack(context, 'حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _run(() => _isRegister
        ? AuthService.instance.registerWithEmail(email: _email.text, password: _password.text)
        : AuthService.instance.signInWithEmail(email: _email.text, password: _password.text));
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      showSnack(context, 'اكتب بريدك الإلكتروني أولاً ثم اضغط «نسيت كلمة المرور».');
      return;
    }
    await _run(() async {
      await AuthService.instance.sendPasswordReset(email);
      if (mounted) showSnack(context, 'أرسلنا رابط استعادة كلمة المرور إلى $email');
    });
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
              Text(_isRegister ? 'إنشاء حساب' : 'تسجيل الدخول',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text(
                'حساب واحد: متبرع جاهز في الأوقات العادية، وطالب دم عند الحاجة.',
                style: TextStyle(fontSize: 15, color: AppColors.muted, height: 1.6),
              ),
              const SizedBox(height: 28),
              _GoogleButton(
                onPressed: _busy ? null : () => _run(AuthService.instance.signInWithGoogle),
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('أو بالبريد الإلكتروني',
                        style: TextStyle(fontSize: 13, color: AppColors.muted)),
                  ),
                  Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: 20),
              const FieldLabel('البريد الإلكتروني'),
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final value = (v ?? '').trim();
                    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)
                        ? null
                        : 'أدخل بريداً صحيحاً';
                  },
                ),
              ),
              const SizedBox(height: 16),
              const FieldLabel('كلمة المرور'),
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  autofillHints: [
                    _isRegister ? AutofillHints.newPassword : AutofillHints.password,
                  ],
                  textInputAction: _isRegister ? TextInputAction.next : TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!_isRegister) _submit();
                  },
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور',
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) =>
                      (v ?? '').length < 6 ? 'كلمة المرور ٦ أحرف على الأقل' : null,
                ),
              ),
              if (_isRegister) ...[
                const SizedBox(height: 16),
                const FieldLabel('تأكيد كلمة المرور'),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextFormField(
                    controller: _confirm,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) => v != _password.text ? 'كلمتا المرور غير متطابقتين' : null,
                  ),
                ),
              ] else
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: _busy ? null : _resetPassword,
                    child: const Text('نسيت كلمة المرور؟'),
                  ),
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(_isRegister ? 'إنشاء الحساب' : 'دخول'),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_isRegister ? 'لديك حساب؟' : 'ليس لديك حساب؟',
                      style: const TextStyle(color: AppColors.muted)),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _isRegister = !_isRegister;
                              _confirm.clear();
                            }),
                    child: Text(_isRegister ? 'تسجيل الدخول' : 'إنشاء حساب'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _GoogleButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        side: const BorderSide(color: AppColors.fieldBorder),
        foregroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // حرف G بلون Google بدون حزمة أيقونات خارجية.
          Text('G',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF4285F4))),
          SizedBox(width: 10),
          Text('المتابعة بحساب Google'),
        ],
      ),
    );
  }
}
