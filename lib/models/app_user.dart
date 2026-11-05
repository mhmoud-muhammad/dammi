import 'package:cloud_firestore/cloud_firestore.dart';

/// مستخدم التطبيق (حساب موحد: متبرع + طالب دم).
class AppUser {
  final String uid;
  final String name;
  final String phone;
  final String bloodType;
  final String city;
  final String area;
  final bool isAvailable;

  const AppUser({
    required this.uid,
    required this.name,
    required this.phone,
    required this.bloodType,
    required this.city,
    required this.area,
    this.isAvailable = true,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return AppUser(
      uid: doc.id,
      name: d['name'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      bloodType: d['bloodType'] as String? ?? '',
      city: d['city'] as String? ?? '',
      area: d['area'] as String? ?? '',
      isAvailable: d['isAvailable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toCreateMap() => {
        'name': name,
        'phone': phone,
        'bloodType': bloodType,
        'city': city,
        'area': area,
        'isAvailable': isAvailable,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
