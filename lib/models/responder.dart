import 'package:cloud_firestore/cloud_firestore.dart';

/// متبرع ضغط «أنا قادم» على طلب.
class Responder {
  final String uid;
  final String name;
  final String bloodType;
  final String area;
  final String phone;
  final DateTime respondedAt;

  const Responder({
    required this.uid,
    required this.name,
    required this.bloodType,
    required this.area,
    required this.phone,
    required this.respondedAt,
  });

  factory Responder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final ts = d['respondedAt'];
    return Responder(
      uid: doc.id,
      name: d['name'] as String? ?? '',
      bloodType: d['bloodType'] as String? ?? '',
      area: d['area'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      respondedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
