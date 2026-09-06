import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  AuthRepository._();

  static final AuthRepository instance = AuthRepository._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> watchUser() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password, String displayName) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(displayName);
  }

  Future<void> signOut() => _auth.signOut();

  String getErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'weak-password':
          return 'كلمة المرور ضعيفة (يجب ألا تقل عن 6 أحرف).';
        case 'email-already-in-use':
          return 'البريد الإلكتروني مستخدم بالفعل.';
        case 'invalid-email':
          return 'البريد الإلكتروني غير صالح.';
        case 'user-not-found':
          return 'لا يوجد حساب بهذا البريد الإلكتروني.';
        case 'wrong-password':
          return 'كلمة المرور غير صحيحة.';
        case 'too-many-requests':
          return 'محاولات كثيرة، حاول لاحقًا.';
        case 'network-request-failed':
          return 'مشكلة في الاتصال بالشبكة.';
        default:
          return error.message ?? 'حدث خطأ غير متوقع.';
      }
    }
    return 'حدث خطأ غير متوقع.';
  }
}