import 'package:expert_ai/services/auth/auth_exceptions.dart';
import 'package:expert_ai/services/auth/auth_provider.dart';
import 'package:expert_ai/services/auth/auth_user.dart';
import 'package:expert_ai/services/auth/firebase_auth_provider.dart';

class AuthService implements AuthProvider {
  final AuthProvider provider;
  const AuthService(this.provider);

  factory AuthService.firebase() => AuthService(FirebaseAuthProvider());

  @override
  Future<void> logout() => provider.logout();

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) => provider.createUser(email: email, password: password);
  @override
Future<AuthUser> signInWithFacebook() => provider.signInWithFacebook();

  @override
  AuthUser? get currentUser => provider.currentUser;

  @override
  Future<AuthUser> signInWithGoogle() => provider.signInWithGoogle();

  @override
  Future<AuthUser> logIn({
    required String email, 
    required String password,
  }) => provider.logIn(email: email, password: password);

  @override
  Future<void> sendEmailVerification() => provider.sendEmailVerification();
  
  @override
  Future<void> initialize() => provider.initialize();

  @override
  Future<AuthUser> getupdateduser() => provider.getupdateduser();

  // --- ADDED MISSING METHODS BELOW ---

  @override
  Future<void> sendphoneverificationCode({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(AuthException exception) onVerificationFailed, 
    Function(AuthUser user)? onVerificationCompleted,
    // Note: make sure 'AuthException' matches exactly what is in your auth_provider.dart interface!
  }) => provider.sendphoneverificationCode(
      phoneNumber: phoneNumber, 
      onCodeSent: onCodeSent, 
      onVerificationFailed: onVerificationFailed,
      onVerificationCompleted: onVerificationCompleted,
    );

  @override
  Future<AuthUser> verifyCodeAndSignIn({
    required String verificationId,
    required String smsCode,
  }) => provider.verifyCodeAndSignIn(
      verificationId: verificationId, 
      smsCode: smsCode,
    );

  @override
  Future<void> sendPasswordReset({required String toEmail}) => provider.sendPasswordReset(toEmail: toEmail);
}