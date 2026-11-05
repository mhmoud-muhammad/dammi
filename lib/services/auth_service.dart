import 'package:firebase_auth/firebase_auth.dart';

/// التحقق برقم الهاتف عبر Firebase Auth (OTP).
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> authChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> sendCode({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String message) onError,
    required void Function() onAutoVerified,
    int? resendToken,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        // أندرويد قد يقرأ الرمز تلقائياً.
        try {
          await _auth.signInWithCredential(credential);
          onAutoVerified();
        } on FirebaseAuthException catch (e) {
          onError(messageFor(e));
        }
      },
      verificationFailed: (e) => onError(messageFor(e)),
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> verifyCode({required String verificationId, required String smsCode}) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() => _auth.signOut();

  static String messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'رقم الهاتف غير صحيح.';
      case 'invalid-verification-code':
        return 'رمز التحقق غير صحيح.';
      case 'session-expired':
        return 'انتهت صلاحية الرمز، اطلب رمزاً جديداً.';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول لاحقاً.';
      case 'network-request-failed':
        return 'تحقق من اتصال الإنترنت.';
      default:
        return e.message ?? 'حدث خطأ غير متوقع.';
    }
  }
}
