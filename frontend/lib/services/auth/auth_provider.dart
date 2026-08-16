import 'package:forensiq/services/auth/auth_exceptions.dart';
import 'package:forensiq/services/auth/auth_user.dart';

abstract class AuthProvider {
  AuthUser? get currentUser;
  
  Future<AuthUser> logIn({
    required String email,
    required String password
  });
  Future<AuthUser> signInWithFacebook();
  
  Future<AuthUser> createUser({
    required String email,
    required String password
  });
  
  Future<void> initialize();
  Future<void> logout();
  Future<AuthUser> getupdateduser();
  
  Future<void> sendphoneverificationCode({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(AuthException exception) onVerificationFailed,
    Function(AuthUser user)? onVerificationCompleted,
  });
  
  Future<AuthUser> verifyCodeAndSignIn({
    required String verificationId,
    required String smsCode,
  });
  
  Future<void> sendEmailVerification();
  Future<AuthUser> signInWithGoogle();
  Future<void> sendPasswordReset({required String toEmail});
}