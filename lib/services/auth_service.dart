import 'package:firebase_auth/firebase_auth.dart';

/// تسجيل الدخول بالبريد وكلمة المرور، أو بحساب Google.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> authChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signInWithEmail({required String email, required String password}) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (displayName != null && displayName.trim().isNotEmpty) {
      await cred.user?.updateDisplayName(displayName.trim());
    }
  }

  /// يفتح صفحة اختيار حساب Google (يتطلب بصمة SHA-1 مسجلة على أندرويد).
  Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'});
    await _auth.signInWithProvider(provider);
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() => _auth.signOut();

  static String messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح.';
      case 'user-disabled':
        return 'تم إيقاف هذا الحساب.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'البريد أو كلمة المرور غير صحيحة.';
      case 'email-already-in-use':
        return 'هذا البريد مسجل مسبقاً، سجّل الدخول بدلاً من ذلك.';
      case 'weak-password':
        return 'كلمة المرور ضعيفة، استخدم ٦ أحرف على الأقل.';
      case 'account-exists-with-different-credential':
        return 'هذا البريد مسجل بطريقة دخول أخرى. سجّل الدخول بالبريد وكلمة المرور.';
      case 'web-context-canceled':
      case 'canceled':
        return 'تم إلغاء تسجيل الدخول.';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول لاحقاً.';
      case 'network-request-failed':
        return 'تحقق من اتصال الإنترنت.';
      case 'operation-not-allowed':
        return 'طريقة الدخول هذه غير مفعّلة في Firebase.';
      default:
        return e.message ?? 'حدث خطأ غير متوقع.';
    }
  }
}
