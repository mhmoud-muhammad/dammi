import 'package:flutter/material.dart';

import '../../core/blood_types.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/app_user.dart';
import '../../models/hospital.dart';
import '../../services/firestore_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/blood_type_selector.dart';
import '../../widgets/common.dart';
import 'request_details_screen.dart';

/// شاشة ٣: إنشاء نداء طلب دم.
class CreateRequestScreen extends StatefulWidget {
  final AppUser user;
  const CreateRequestScreen({super.key, required this.user});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patient = TextEditingController();
  late final TextEditingController _phone = TextEditingController(text: widget.user.phone);
  late final Stream<List<Hospital>> _hospitals =
      FirestoreService.instance.hospitalsStream(widget.user.city);

  Hospital? _hospital;
  String? _bloodType;
  SearchScope _scope = SearchScope.compatible;
  int _units = 1;
  bool _submitting = false;

  @override
  void dispose() {
    _patient.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_hospital == null) {
      showSnack(context, 'اختر المستشفى.');
      return;
    }
    if (_bloodType == null) {
      showSnack(context, 'اختر فصيلة الدم المطلوبة.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final id = await FirestoreService.instance.createRequest(
        requester: widget.user,
        patientName: _patient.text.trim(),
        hospital: _hospital!,
        bloodType: _bloodType!,
        scope: _scope,
        units: _units,
        contactPhone: normalizePhone(_phone.text),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => RequestDetailsScreen(requestId: id, currentUser: widget.user),
      ));
    } catch (e) {
      if (mounted) showSnack(context, 'تعذر نشر الطلب: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('طلب دم طارئ')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const FieldLabel('اسم المريض'),
            TextFormField(
              controller: _patient,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().length < 3) ? 'أدخل اسم المريض الصريح' : null,
            ),
            const SizedBox(height: 18),
            const FieldLabel('المستشفى / المركز الطبي'),
            _HospitalDropdown(
              stream: _hospitals,
              value: _hospital,
              onChanged: (h) => setState(() => _hospital = h),
            ),
            const HelperText('القائمة يديرها مدير النظام.'),
            const SizedBox(height: 18),
            const FieldLabel('فصيلة الدم المطلوبة'),
            BloodTypeSelector(
              value: _bloodType,
              onChanged: (t) => setState(() => _bloodType = t),
            ),
            const SizedBox(height: 18),
            const FieldLabel('نطاق البحث'),
            _ScopeOption(
              title: 'الفصيلة المطلوبة فقط',
              subtitle: 'يصل النداء لأصحاب نفس الفصيلة فقط.',
              selected: _scope == SearchScope.exact,
              onTap: () => setState(() => _scope = SearchScope.exact),
            ),
            const SizedBox(height: 8),
            _ScopeOption(
              title: 'جلب الفصائل المتوافقة تلقائياً',
              subtitle: 'يوسّع النظام الطلب لكل من يمكنه التبرع طبياً — أسرع للإنقاذ.',
              selected: _scope == SearchScope.compatible,
              onTap: () => setState(() => _scope = SearchScope.compatible),
            ),
            if (_bloodType != null) ...[
              const SizedBox(height: 8),
              _AcceptedPreview(types: acceptedTypesFor(_bloodType!, _scope)),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text('عدد الزجاجات المطلوبة',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                _Stepper(
                  value: _units,
                  onChanged: (v) => setState(() => _units = v),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const FieldLabel('رقم التواصل'),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                validator: (v) => isValidLocalPhone(v ?? '') ? null : 'رقم غير صحيح',
              ),
            ),
            const HelperText('مُعبأ تلقائياً من حسابك — يمكنك تعديله.'),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('نشر النداء'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HospitalDropdown extends StatelessWidget {
  final Stream<List<Hospital>> stream;
  final Hospital? value;
  final ValueChanged<Hospital?> onChanged;

  const _HospitalDropdown({required this.stream, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Hospital>>(
      stream: stream,
      builder: (context, snap) {
        final hospitals = snap.data ?? const <Hospital>[];
        // Hospital يقارن بالمعرّف، فيبقى الاختيار صالحاً عند تحديث القائمة.
        return DropdownButtonFormField<Hospital>(
          initialValue: value,
          isExpanded: true,
          hint: Text(snap.hasData
              ? (hospitals.isEmpty ? 'لا توجد مستشفيات مضافة بعد' : 'اختر المستشفى')
              : 'جارٍ التحميل…'),
          items: [
            for (final h in hospitals) DropdownMenuItem(value: h, child: Text(h.name)),
          ],
          onChanged: onChanged,
          validator: (h) => h == null ? 'اختر المستشفى' : null,
        );
      },
    );
  }
}

class _ScopeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ScopeOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? const Color(0xFFFFF7F6) : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.fieldBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: selected ? AppColors.primary : AppColors.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AcceptedPreview extends StatelessWidget {
  final List<String> types;
  const _AcceptedPreview({required this.types});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('سيصل النداء إلى أصحاب الفصائل:',
              style: TextStyle(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in types)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(t,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _Stepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.fieldBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filledTonal(
            tooltip: 'زيادة',
            onPressed: value < kMaxUnits ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add),
          ),
          SizedBox(
            width: 40,
            child: Text(arabicDigits(value),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          IconButton.filledTonal(
            tooltip: 'إنقاص',
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
