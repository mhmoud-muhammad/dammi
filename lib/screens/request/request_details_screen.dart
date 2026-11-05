import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/app_user.dart';
import '../../models/blood_request.dart';
import '../../models/responder.dart';
import '../../services/firestore_service.dart';
import '../../utils/contact_launcher.dart';
import '../../utils/formatters.dart';
import '../../widgets/blood_type_badge.dart';
import '../../widgets/common.dart';

/// شاشة ٤: تفاصيل الطلب.
/// - صاحب الطلب يرى قائمة المستجيبين وأزرار التواصل وزر الإغلاق (٤ب).
/// - المتبرع يرى التفاصيل وزر «أنا قادم» (٤أ).
class RequestDetailsScreen extends StatefulWidget {
  final String requestId;
  final AppUser currentUser;

  const RequestDetailsScreen({super.key, required this.requestId, required this.currentUser});

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  late final Stream<BloodRequest?> _request =
      FirestoreService.instance.requestStream(widget.requestId);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BloodRequest?>(
      stream: _request,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: MessageView(icon: Icons.cloud_off, title: 'تعذر التحميل', subtitle: '${snap.error}'),
          );
        }
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const LoadingView();
        }
        final request = snap.data;
        if (request == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const MessageView(icon: Icons.delete_outline, title: 'هذا الطلب لم يعد موجوداً'),
          );
        }
        final isOwner = request.requesterId == widget.currentUser.uid;
        return isOwner
            ? _RequesterView(request: request)
            : _DonorView(request: request, donor: widget.currentUser);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// ٤أ — المتبرع
// ---------------------------------------------------------------------------

class _DonorView extends StatefulWidget {
  final BloodRequest request;
  final AppUser donor;

  const _DonorView({required this.request, required this.donor});

  @override
  State<_DonorView> createState() => _DonorViewState();
}

class _DonorViewState extends State<_DonorView> {
  late final Stream<bool> _responded =
      FirestoreService.instance.hasRespondedStream(widget.request.id, widget.donor.uid);
  bool _busy = false;

  Future<void> _confirmAndRespond() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد القدوم'),
        content: Text(
          'سيظهر اسمك وفصيلتك ومنطقتك ورقم هاتفك لطالب الدم، '
          'وعليك التوجه إلى ${widget.request.hospitalName}.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم، أنا قادم'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await FirestoreService.instance.respond(requestId: widget.request.id, donor: widget.donor);
      if (mounted) showSnack(context, 'شكراً لك! تم إبلاغ طالب الدم.');
    } on AlreadyRespondedException {
      if (mounted) showSnack(context, 'سبق أن قبلت هذا الطلب.');
    } on RequestClosedException {
      if (mounted) showSnack(context, 'تم إغلاق هذا الطلب.');
    } catch (e) {
      if (mounted) showSnack(context, 'تعذر التسجيل: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final compatible = r.accepts(widget.donor.bloodType);

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل النداء')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Hero(request: r),
          const SizedBox(height: 14),
          _InfoCard(request: r),
          const SizedBox(height: 14),
          _Banner(
            ok: compatible,
            text: compatible
                ? 'فصيلتك ${widget.donor.bloodType} متوافقة مع هذا الطلب.'
                : 'فصيلتك ${widget.donor.bloodType} لا تتوافق مع هذا الطلب.',
          ),
          const SizedBox(height: 14),
          _PhoneRow(label: 'طالب الدم', phone: r.contactPhone),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        child: StreamBuilder<bool>(
          stream: _responded,
          builder: (context, snap) {
            final responded = snap.data ?? false;
            if (responded) {
              return const _Banner(ok: true, text: 'سجّلت قدومك — تواصل مع طالب الدم للتنسيق.');
            }
            if (!r.isActive) {
              return const _Banner(ok: false, text: 'تم إغلاق هذا الطلب.');
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'عند القبول سيظهر اسمك وفصيلتك ومنطقتك ورقمك لطالب الدم.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: (!compatible || _busy) ? null : _confirmAndRespond,
                  child: const Text('قبول الطلب · أنا قادم'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ٤ب — طالب الدم
// ---------------------------------------------------------------------------

class _RequesterView extends StatefulWidget {
  final BloodRequest request;
  const _RequesterView({required this.request});

  @override
  State<_RequesterView> createState() => _RequesterViewState();
}

class _RequesterViewState extends State<_RequesterView> {
  late final Stream<List<Responder>> _responders =
      FirestoreService.instance.respondersStream(widget.request.id);

  Future<void> _close() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إغلاق الطلب؟'),
        content: const Text('سيختفي الطلب من قوائم المتبرعين ولن يستقبل استجابات جديدة.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(100, 44),
              backgroundColor: AppColors.success,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تم الاكتفاء'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await FirestoreService.instance.closeRequest(widget.request.id);
    } catch (e) {
      if (mounted) showSnack(context, 'تعذر الإغلاق: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبي'),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: Center(child: _StatusPill(status: r.status)),
          ),
        ],
      ),
      body: StreamBuilder<List<Responder>>(
        stream: _responders,
        builder: (context, snap) {
          final responders = snap.data ?? const <Responder>[];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(request: r),
              const SizedBox(height: 18),
              Text('المتبرعون القادمون (${arabicDigits(responders.length)})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              if (snap.hasError)
                MessageView(icon: Icons.cloud_off, title: 'تعذر التحميل', subtitle: '${snap.error}')
              else if (!snap.hasData)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (responders.isEmpty)
                const MessageView(
                  icon: Icons.hourglass_empty,
                  title: 'لم يستجب أحد بعد',
                  subtitle: 'وصل النداء إلى المتبرعين المتوافقين، وستظهر بياناتهم هنا فور القبول.',
                )
              else
                for (final p in responders) ...[
                  _ResponderCard(responder: p, request: r),
                  const SizedBox(height: 10),
                ],
            ],
          );
        },
      ),
      bottomNavigationBar: r.isActive
          ? _BottomBar(
              child: OutlinedButton(
                onPressed: _close,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  side: const BorderSide(color: AppColors.success, width: 2),
                  foregroundColor: AppColors.successDark,
                  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                child: const Text('تم الاكتفاء · إغلاق الطلب'),
              ),
            )
          : null,
    );
  }
}

class _ResponderCard extends StatelessWidget {
  final Responder responder;
  final BloodRequest request;

  const _ResponderCard({required this.responder, required this.request});

  @override
  Widget build(BuildContext context) {
    final msg = 'السلام عليكم، بخصوص طلب الدم للمريض ${request.patientName} في ${request.hospitalName}.';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(responder.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(responder.area,
                        style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                    Text(responder.phone,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  BloodTypeChip(type: responder.bloodType),
                  const SizedBox(height: 6),
                  Text(timeAgo(responder.respondedAt),
                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                  onPressed: () => ContactLauncher.call(context, responder.phone),
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('اتصال', style: TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ContactLauncher.whatsapp(context, responder.phone, message: msg),
                  child: const Text('واتساب'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ContactLauncher.sms(context, responder.phone),
                  child: const Text('رسالة'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// مكونات مشتركة
// ---------------------------------------------------------------------------

class _Hero extends StatelessWidget {
  final BloodRequest request;
  const _Hero({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الفصيلة المطلوبة',
                    style: TextStyle(fontSize: 13, color: Color(0xFFFFD9D4))),
                Text(request.bloodType,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                        fontSize: 44, height: 1.1, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('المطلوب', style: TextStyle(fontSize: 13, color: Color(0xFFFFD9D4))),
              Text(unitsLabel(request.units),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
              Text(
                'بقي ${arabicDigits(request.remaining)} · استجاب ${arabicDigits(request.respondersCount)}',
                style: const TextStyle(fontSize: 13, color: Color(0xFFFFE9E6)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final BloodRequest request;
  const _InfoCard({required this.request});

  @override
  Widget build(BuildContext context) {
    Widget row(String label, Widget value, {bool last = false}) => Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: last ? null : const Border(bottom: BorderSide(color: AppColors.subtle)),
          ),
          child: Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
              const SizedBox(width: 12),
              Expanded(
                child: Align(alignment: AlignmentDirectional.centerEnd, child: value),
              ),
            ],
          ),
        );
    const valueStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w700);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          row('اسم المريض', Text(request.patientName, style: valueStyle)),
          row('المستشفى', Text(request.hospitalName, style: valueStyle, textAlign: TextAlign.end)),
          row('يقبل الفصائل',
              Text(request.acceptedTypes.join(' · '),
                  textDirection: TextDirection.ltr, style: valueStyle)),
          row('نُشر', Text(timeAgo(request.createdAt), style: valueStyle), last: true),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final BloodRequest request;
  const _SummaryCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          BloodTypeBadge(type: request.bloodType, size: 60),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.patientName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text(request.hospitalName,
                    style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${arabicDigits(request.respondersCount.clamp(0, request.units))} من ${unitsLabel(request.units)}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark),
                      ),
                    ),
                    Text(request.scope.label,
                        style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: request.progress,
                    minHeight: 6,
                    backgroundColor: AppColors.subtle,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneRow extends StatelessWidget {
  final String label;
  final String phone;
  const _PhoneRow({required this.label, required this.phone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                Text(phone,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'اتصال',
            onPressed: () => ContactLauncher.call(context, phone),
            icon: const Icon(Icons.call),
          ),
          const SizedBox(width: 6),
          IconButton.filledTonal(
            tooltip: 'واتساب',
            onPressed: () => ContactLauncher.whatsapp(context, phone),
            icon: const Icon(Icons.chat_outlined),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final bool ok;
  final String text;
  const _Banner({required this.ok, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ok ? AppColors.successSoft : AppColors.subtle,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(ok ? Icons.check : Icons.info_outline,
              color: ok ? AppColors.success : AppColors.muted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 14, color: ok ? AppColors.successDark : AppColors.ink)),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final RequestStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final active = status == RequestStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.successSoft : AppColors.subtle,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(status.label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? AppColors.successDark : AppColors.ink)),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final Widget child;
  const _BottomBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 14), child: child),
      ),
    );
  }
}
