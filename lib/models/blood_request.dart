import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/blood_types.dart';

enum RequestStatus {
  active,
  completed;

  static RequestStatus fromName(String? name) =>
      name == 'completed' ? RequestStatus.completed : RequestStatus.active;

  String get label => this == active ? 'نشط' : 'مكتمل';
}

/// نداء طلب دم.
class BloodRequest {
  final String id;
  final String patientName;
  final String hospitalId;
  final String hospitalName;
  final String bloodType;
  final SearchScope scope;
  final List<String> acceptedTypes;
  final int units;
  final int respondersCount;
  final String contactPhone;
  final String requesterId;
  final String city;
  final RequestStatus status;
  final DateTime createdAt;

  const BloodRequest({
    required this.id,
    required this.patientName,
    required this.hospitalId,
    required this.hospitalName,
    required this.bloodType,
    required this.scope,
    required this.acceptedTypes,
    required this.units,
    required this.respondersCount,
    required this.contactPhone,
    required this.requesterId,
    required this.city,
    required this.status,
    required this.createdAt,
  });

  bool get isActive => status == RequestStatus.active;
  int get remaining => (units - respondersCount).clamp(0, units);
  double get progress => units == 0 ? 0 : (respondersCount / units).clamp(0, 1).toDouble();
  bool accepts(String donorType) => acceptedTypes.contains(donorType);

  factory BloodRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final ts = d['createdAt'];
    return BloodRequest(
      id: doc.id,
      patientName: d['patientName'] as String? ?? '',
      hospitalId: d['hospitalId'] as String? ?? '',
      hospitalName: d['hospitalName'] as String? ?? '',
      bloodType: d['bloodType'] as String? ?? '',
      scope: SearchScope.fromName(d['scope'] as String?),
      acceptedTypes: List<String>.from(d['acceptedTypes'] as List? ?? const []),
      units: (d['units'] as num?)?.toInt() ?? 1,
      respondersCount: (d['respondersCount'] as num?)?.toInt() ?? 0,
      contactPhone: d['contactPhone'] as String? ?? '',
      requesterId: d['requesterId'] as String? ?? '',
      city: d['city'] as String? ?? '',
      status: RequestStatus.fromName(d['status'] as String?),
      // serverTimestamp يكون null محلياً حتى يؤكده الخادم.
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
