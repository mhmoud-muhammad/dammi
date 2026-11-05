import 'package:flutter/material.dart';

import '../../core/blood_types.dart';
import '../../core/theme.dart';
import '../../models/app_user.dart';
import '../../models/blood_request.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common.dart';
import '../../widgets/request_card.dart';
import '../request/create_request_screen.dart';
import '../request/request_details_screen.dart';

/// شاشة ٢: لوحة التحكم الشخصية.
class HomeScreen extends StatefulWidget {
  final AppUser user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0; // 0 = تناسب فصيلتي، 1 = طلباتي
  late Stream<List<BloodRequest>> _matching;
  late Stream<List<BloodRequest>> _mine;

  @override
  void initState() {
    super.initState();
    _buildStreams();
  }

  @override
  void didUpdateWidget(HomeScreen old) {
    super.didUpdateWidget(old);
    final u = widget.user;
    if (u.uid != old.user.uid || u.bloodType != old.user.bloodType || u.city != old.user.city) {
      _buildStreams();
    }
  }

  void _buildStreams() {
    _matching = FirestoreService.instance.matchingRequests(widget.user);
    _mine = FirestoreService.instance.myRequests(widget.user.uid);
  }

  void _openDetails(BloodRequest r) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RequestDetailsScreen(requestId: r.id, currentUser: widget.user),
    ));
  }

  void _openCreate() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CreateRequestScreen(user: widget.user),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(user: user, tab: _tab, onTab: (i) => setState(() => _tab = i)),
            Expanded(
              child: _tab == 0
                  ? _MatchingList(user: user, stream: _matching, onOpen: _openDetails)
                  : _RequestList(
                      stream: _mine,
                      onOpen: _openDetails,
                      emptyTitle: 'لم تنشئ أي طلب بعد',
                      emptySubtitle: 'عند الحاجة اضغط «طلب دم طارئ».',
                    ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 58,
          child: FloatingActionButton.extended(
            onPressed: _openCreate,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            icon: const Icon(Icons.add),
            label: const Text('طلب دم طارئ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AppUser user;
  final int tab;
  final ValueChanged<int> onTab;

  const _Header({required this.user, required this.tab, required this.onTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('مرحباً،', style: TextStyle(fontSize: 14, color: AppColors.muted)),
                    Text(user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text('فصيلتك',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark)),
                    Text(user.bloodType,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'المزيد',
                onSelected: (v) {
                  if (v == 'logout') AuthService.instance.signOut();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'logout', child: Text('تسجيل الخروج')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _AvailabilityTile(user: user),
          const SizedBox(height: 14),
          SegmentedButton<int>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              selectedBackgroundColor: AppColors.primarySoft,
              selectedForegroundColor: AppColors.primaryDark,
            ),
            segments: const [
              ButtonSegment(value: 0, label: Text('تناسب فصيلتي')),
              ButtonSegment(value: 1, label: Text('طلباتي')),
            ],
            selected: {tab},
            onSelectionChanged: (s) => onTab(s.first),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityTile extends StatelessWidget {
  final AppUser user;
  const _AvailabilityTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final on = user.isAvailable;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: on ? AppColors.successSoft : AppColors.subtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(on ? 'متاح للتبرع' : 'غير متاح حالياً',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: on ? AppColors.successDark : AppColors.ink)),
                Text(
                  on ? 'تصلك نداءات ${user.city} المتوافقة' : 'لن تظهر لك نداءات جديدة',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Switch(
            value: on,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.success,
            onChanged: (v) => FirestoreService.instance.setAvailability(user.uid, v),
          ),
        ],
      ),
    );
  }
}

class _MatchingList extends StatelessWidget {
  final AppUser user;
  final Stream<List<BloodRequest>> stream;
  final ValueChanged<BloodRequest> onOpen;

  const _MatchingList({required this.user, required this.stream, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (!user.isAvailable) {
      return const MessageView(
        icon: Icons.pause_circle_outline,
        title: 'أوقفت استقبال النداءات',
        subtitle: 'فعّل «متاح للتبرع» لرؤية الطلبات التي تناسب فصيلتك.',
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('يمكنك التبرع لـ:',
                  style: TextStyle(fontSize: 13, color: AppColors.muted)),
              for (final t in recipientsFor(user.bloodType))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(t,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
        Expanded(
          child: _RequestList(
            stream: stream,
            onOpen: onOpen,
            emptyTitle: 'لا توجد نداءات تناسب فصيلتك الآن',
            emptySubtitle: 'سنعرض هنا أي طلب جديد في ${user.city} يمكنك التبرع له.',
          ),
        ),
      ],
    );
  }
}

class _RequestList extends StatelessWidget {
  final Stream<List<BloodRequest>> stream;
  final ValueChanged<BloodRequest> onOpen;
  final String emptyTitle;
  final String emptySubtitle;

  const _RequestList({
    required this.stream,
    required this.onOpen,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BloodRequest>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return MessageView(
            icon: Icons.cloud_off,
            title: 'تعذر تحميل الطلبات',
            subtitle: '${snap.error}',
          );
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final items = snap.data!;
        if (items.isEmpty) {
          return MessageView(
            icon: Icons.volunteer_activism_outlined,
            title: emptyTitle,
            subtitle: emptySubtitle,
          );
        }
        return ListView.separated(
          // مساحة سفلية حتى لا يغطي الزر العائم آخر بطاقة.
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => RequestCard(request: items[i], onTap: () => onOpen(items[i])),
        );
      },
    );
  }
}
