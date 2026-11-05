import 'package:cloud_firestore/cloud_firestore.dart';

/// مستشفى معتمد تديره لوحة الإدارة.
class Hospital {
  final String id;
  final String name;
  final String city;
  final int order;

  const Hospital({required this.id, required this.name, required this.city, this.order = 0});

  // المقارنة بالمعرّف: كل تحديث من Firestore ينشئ كائنات جديدة لنفس المستشفى.
  @override
  bool operator ==(Object other) => other is Hospital && other.id == id;

  @override
  int get hashCode => id.hashCode;

  factory Hospital.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Hospital(
      id: doc.id,
      name: d['name'] as String? ?? '',
      city: d['city'] as String? ?? '',
      order: (d['order'] as num?)?.toInt() ?? 0,
    );
  }
}
