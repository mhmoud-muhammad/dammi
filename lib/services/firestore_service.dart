import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/blood_types.dart';
import '../models/app_user.dart';
import '../models/blood_request.dart';
import '../models/hospital.dart';
import '../models/responder.dart';

class AlreadyRespondedException implements Exception {}

class RequestClosedException implements Exception {}

/// كل التعامل مع Cloud Firestore في مكان واحد.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _requests => _db.collection('requests');
  CollectionReference<Map<String, dynamic>> get _hospitals => _db.collection('hospitals');
  CollectionReference<Map<String, dynamic>> _responders(String requestId) =>
      _requests.doc(requestId).collection('responders');

  // ---------- المستخدمون ----------

  /// يعيد null إذا لم يُكمل المستخدم ملفه بعد.
  Stream<AppUser?> userStream(String uid) => _users
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromDoc(doc) : null);

  Future<void> createUser(AppUser user) => _users.doc(user.uid).set(user.toCreateMap());

  Future<void> setAvailability(String uid, bool isAvailable) =>
      _users.doc(uid).update({'isAvailable': isAvailable});

  // ---------- المستشفيات ----------

  Stream<List<Hospital>> hospitalsStream(String city) => _hospitals
      .where('city', isEqualTo: city)
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((s) {
        final list = s.docs.map(Hospital.fromDoc).toList()
          ..sort((a, b) {
            final byOrder = a.order.compareTo(b.order);
            return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
          });
        return list;
      });

  // ---------- الطلبات ----------

  /// الطلبات النشطة في مدينة المستخدم والتي تقبل فصيلته (التصفية الذكية).
  Stream<List<BloodRequest>> matchingRequests(AppUser user) => _requests
      .where('status', isEqualTo: RequestStatus.active.name)
      .where('city', isEqualTo: user.city)
      .where('acceptedTypes', arrayContains: user.bloodType)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs
          .map(BloodRequest.fromDoc)
          .where((r) => r.requesterId != user.uid)
          .toList());

  Stream<List<BloodRequest>> myRequests(String uid) => _requests
      .where('requesterId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map(BloodRequest.fromDoc).toList());

  Stream<BloodRequest?> requestStream(String id) => _requests
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? BloodRequest.fromDoc(doc) : null);

  Future<String> createRequest({
    required AppUser requester,
    required String patientName,
    required Hospital hospital,
    required String bloodType,
    required SearchScope scope,
    required int units,
    required String contactPhone,
  }) async {
    final ref = await _requests.add({
      'patientName': patientName,
      'hospitalId': hospital.id,
      'hospitalName': hospital.name,
      'bloodType': bloodType,
      'scope': scope.name,
      'acceptedTypes': acceptedTypesFor(bloodType, scope),
      'units': units,
      'respondersCount': 0,
      'contactPhone': contactPhone,
      'requesterId': requester.uid,
      'city': requester.city,
      'status': RequestStatus.active.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> closeRequest(String id) => _requests.doc(id).update({
        'status': RequestStatus.completed.name,
        'completedAt': FieldValue.serverTimestamp(),
      });

  // ---------- المستجيبون ----------

  Stream<List<Responder>> respondersStream(String requestId) => _responders(requestId)
      .orderBy('respondedAt')
      .snapshots()
      .map((s) => s.docs.map(Responder.fromDoc).toList());

  Stream<bool> hasRespondedStream(String requestId, String uid) =>
      _responders(requestId).doc(uid).snapshots().map((d) => d.exists);

  /// «أنا قادم»: يسجل المتبرع ويزيد العداد في معاملة واحدة.
  Future<void> respond({required String requestId, required AppUser donor}) {
    final requestRef = _requests.doc(requestId);
    final responderRef = _responders(requestId).doc(donor.uid);

    return _db.runTransaction((tx) async {
      final requestSnap = await tx.get(requestRef);
      if (!requestSnap.exists ||
          requestSnap.data()?['status'] != RequestStatus.active.name) {
        throw RequestClosedException();
      }
      final responderSnap = await tx.get(responderRef);
      if (responderSnap.exists) throw AlreadyRespondedException();

      tx.set(responderRef, {
        'name': donor.name,
        'bloodType': donor.bloodType,
        'area': donor.area,
        'phone': donor.phone,
        'respondedAt': FieldValue.serverTimestamp(),
      });
      tx.update(requestRef, {'respondersCount': FieldValue.increment(1)});
    });
  }
}
