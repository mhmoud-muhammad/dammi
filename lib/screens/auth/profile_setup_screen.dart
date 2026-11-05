import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/blood_type_selector.dart';
import '../../widgets/common.dart';

/// إكمال الملف بعد أول تسجيل دخول — يُحفظ مرة واحدة في users/{uid}.
class ProfileSetupScreen extends StatefulWidget {
  final String uid;
  final String initialName;
  final String email;

  const ProfileSetupScreen({
    super.key,
    required this.uid,
    this.initialName = '',
    this.email = '',
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.initialName);
  final _phone = TextEditingController();
  final _area = TextEditingController();
  String? _bloodType;
  String _city = kCities.first;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _area.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_bloodType == null) {
      showSnack(context, 'اختر فصيلة دمك.');
      return;
    }
    setState(() => _saving = true);
    try {
      await FirestoreService.instance.createUser(AppUser(
        uid: widget.uid,
        name: _name.text.trim(),
        phone: normalizePhone(_phone.text),
        bloodType: _bloodType!,
        city: _city,
        area: _area.text.trim(),
      ));
      // AppGate ينتقل للرئيسية تلقائياً عند ظهور المستند.
    } catch (e) {
      if (mounted) showSnack(context, 'تعذر الحفظ: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('إكمال الملف'),
        actions: [
          TextButton(
            onPressed: () => AuthService.instance.signOut(),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (widget.email.isNotEmpty) ...[
                Text('مسجل باسم ${widget.email}',
                    style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                const SizedBox(height: 16),
              ],
              const FieldLabel('الاسم الكامل'),
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: (v) =>
                    (v == null || v.trim().length < 3) ? 'أدخل اسمك الكامل' : null,
              ),
              const SizedBox(height: 16),
              const FieldLabel('رقم الهاتف'),
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    prefixText: '$kCountryCode  ',
                    hintText: '9X XXX XXXX',
                  ),
                  validator: (v) =>
                      isValidLocalPhone(v ?? '') ? null : 'أدخل رقماً صحيحاً من ٩ أرقام',
                ),
              ),
              const HelperText('يظهر لطالب الدم عندما تقبل طلبه، وللمتبرعين عندما تنشئ طلباً.'),
              const SizedBox(height: 16),
              const FieldLabel('فصيلة الدم'),
              BloodTypeSelector(
                value: _bloodType,
                onChanged: (t) => setState(() => _bloodType = t),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FieldLabel('المدينة'),
                        DropdownButtonFormField<String>(
                          value: _city,
                          items: [
                            for (final c in kCities) DropdownMenuItem(value: c, child: Text(c)),
                          ],
                          onChanged: (v) => setState(() => _city = v ?? _city),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FieldLabel('الحي / المنطقة'),
                        TextFormField(
                          controller: _area,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: const Text('حفظ والمتابعة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
