import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:forensiq/services/auth/auth_provider.dart';
import 'package:forensiq/services/auth/auth_exceptions.dart';
import 'package:forensiq/services/auth/auth_user.dart';
import 'package:forensiq/firebase_options.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart'
    show
        FirebaseAuth,
        FirebaseAuthException,
        GoogleAuthProvider,
        UserCredential,
        PhoneAuthCredential,
        PhoneAuthProvider,
        FacebookAuthProvider;

class FirebaseAuthProvider implements AuthProvider {
  final _auth = FirebaseAuth.instance;

  @override
  Future<void> sendphoneverificationCode({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(AuthException exception) onVerificationFailed,
    Function(AuthUser user)? onVerificationCompleted,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final userCredential = await _auth.signInWithCredential(credential);
            final user = userCredential.user;
            if (user != null && onVerificationCompleted != null) {
              onVerificationCompleted(AuthUser.fromFirebase(user));
            }
          } catch (e) {
            debugPrint("verificationCompleted sign-in error: $e");
            onVerificationFailed(GenericAuthExceptions());
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint("Firebase verifyPhoneNumber failed: [${e.code}] ${e.message}");
          if (e.code == 'invalid-phone-number') {
            onVerificationFailed(InvalidPhoneNumberException());
          } else {
            onVerificationFailed(GenericAuthExceptions());
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      debugPrint("sendphoneverificationCode error: $e");
      onVerificationFailed(GenericAuthExceptions());
    }
  }

  @override
  Future<AuthUser> verifyCodeAndSignIn({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        return AuthUser.fromFirebase(user);
      } else {
        throw GenericAuthException();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        throw InvalidVerificationCodeException();
      } else {
        throw GenericAuthException();
      }
    } catch (_) {
      throw GenericAuthException();
    }
  }

  @override
  Future<AuthUser> getupdateduser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await user.reload();
      } catch (e) {
        debugPrint("User reload error: $e");
      }
      final freshuser = FirebaseAuth.instance.currentUser;
      if (freshuser != null) {
        return AuthUser.fromFirebase(freshuser);
      }
    }
    throw UserNotLoggedinException();
  }

  @override
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint("Firebase signOut error: $e");
    }
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      debugPrint("Google sign out notice: $e");
    }
    try {
      await FacebookAuth.instance.logOut();
    } catch (e) {
      debugPrint("Facebook sign out notice: $e");
    }
  }

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = currentUser;
      if (user != null) {
        return user;
      } else {
        throw UserNotLoggedinException();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw WeakPassowrdExcetion();
      } else if (e.code == 'email-already-in-use') {
        throw EmailAlreadyInUseException();
      } else if (e.code == 'invalid-email') {
        throw InvalidEmailException();
      } else {
        throw GenericAuthException();
      }
    } catch (_) {
      throw GenericAuthException();
    }
  }

  @override
  AuthUser? get currentUser {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return AuthUser.fromFirebase(user);
    } else {
      return null;
    }
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = currentUser;
      if (user != null) {
        return user;
      } else {
        throw UserNotLoggedinException();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw UserNotFoundException();
      } else if (e.code == 'wrong-password') {
        throw WrongPassAuthException();
      } else {
        throw GenericAuthException();
      }
    } catch (e) {
      throw GenericAuthException();
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    } else {
      throw UserNotLoggedinException();
    }
  }

  @override
  Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        googleProvider.setCustomParameters({'prompt': 'select_account'});

        UserCredential userCredential;
        try {
          userCredential =
              await FirebaseAuth.instance.signInWithPopup(googleProvider);
        } catch (popupError) {
          final errStr = popupError.toString().toLowerCase();
          debugPrint("signInWithPopup error: $popupError");
          if (errStr.contains('popup-closed-by-user') ||
              errStr.contains('cancelled-popup-request') ||
              errStr.contains('user-cancelled') ||
              errStr.contains('popup_closed_by_user')) {
            throw GoogleSignInCancelledException();
          }
          if (errStr.contains('popup-blocked')) {
            await FirebaseAuth.instance.signInWithRedirect(googleProvider);
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) return AuthUser.fromFirebase(user);
            throw GoogleSignInCancelledException();
          }
          rethrow;
        }

        final user = userCredential.user ?? FirebaseAuth.instance.currentUser;
        if (user == null) throw GenericAuthException();

        return AuthUser.fromFirebase(user);
      } else {
        final GoogleSignInAccount? googleUser = await GoogleSignIn(
          scopes: ['email', 'profile'],
          serverClientId:
              '845900841870-u70fenbiiu6qrcom0f0os0lcfpv7m28s.apps.googleusercontent.com',
        ).signIn();

        if (googleUser == null) throw GoogleSignInCancelledException();

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw GenericAuthException();

        return AuthUser.fromFirebase(user);
      }
    } catch (e) {
      debugPrint("GOOGLE SIGN IN ERROR DETAILS: $e");
      if (e is GoogleSignInCancelledException) rethrow;
      rethrow;
    }
  }

  @override
  Future<AuthUser> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.cancelled) {
        throw FacebookSignInCancelledException();
      }

      if (result.status != LoginStatus.success) {
        throw GenericAuthException();
      }

      final accessToken = result.accessToken;
      if (accessToken == null) throw GenericAuthException();

      final credential = FacebookAuthProvider.credential(
        accessToken.tokenString,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw GenericAuthException();

      return AuthUser.fromFirebase(user);
    } catch (e) {
      debugPrint("FACEBOOK SIGN IN ERROR DETAILS: $e");
      if (e is FacebookSignInCancelledException) rethrow;
      throw GenericAuthException();
    }
  }

  @override
  Future<void> sendPasswordReset({required String toEmail}) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: toEmail);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        throw InvalidEmailException();
      } else if (e.code == 'user-not-found') {
        throw UserNotFoundException();
      } else {
        throw GenericAuthException();
      }
    } catch (_) {
      throw GenericAuthException();
    }
  }
}
