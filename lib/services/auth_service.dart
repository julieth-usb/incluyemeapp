import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class NativeSignInAttempt {
  const NativeSignInAttempt._({
    this.email,
    required this.wasCancelled,
    this.error,
  });

  const NativeSignInAttempt.success(String email)
      : this._(email: email, wasCancelled: false);

  const NativeSignInAttempt.cancelled()
      : this._(wasCancelled: true);

  const NativeSignInAttempt.failed(String error)
      : this._(wasCancelled: false, error: error);

  final String? email;
  final bool wasCancelled;
  final String? error;
}

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static Future<String?> register({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  static Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  static Future<String?> signInWithProvider({
    required String provider,
    required String email,
  }) async {
    // Ya se completó la autenticación en tryNativeGoogleSignIn / tryNativeFacebookSignIn.
    return null;
  }

  static Future<String?> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      // Firebase requiere enviar un correo electrónico para restablecer la contraseña
      // de forma segura en lugar de actualizarla directamente desde el cliente sin sesión previa.
      await _auth.sendPasswordResetEmail(email: email);
      return null; // El frontend dirá que el correo fue enviado en lugar de actualizada
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  static Future<void> logout() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
      FacebookAuth.instance.logOut().catchError((_) {}),
    ]);
  }

  static Future<bool> hasActiveSession() async {
    // Validar si el currentUser ya está cargado por FirebaseAuth
    return _auth.currentUser != null;
  }

  static Future<NativeSignInAttempt> tryNativeGoogleSignIn() async {
    try {
      // Intentar forzar la cuenta en dispositivos que puedan tener varias
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const NativeSignInAttempt.cancelled();
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      return NativeSignInAttempt.success(googleUser.email);
    } on FirebaseAuthException catch (e) {
      return NativeSignInAttempt.failed(_handleFirebaseError(e));
    } catch (error) {
      return NativeSignInAttempt.failed('Google error no esperado: $error');
    }
  }

  static Future<NativeSignInAttempt> tryNativeFacebookSignIn() async {
    try {
      final result = await FacebookAuth.instance.login(
        permissions: const ['email', 'public_profile'],
        loginBehavior: LoginBehavior.nativeWithFallback,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Facebook login timed out'),
      );

      if (result.status == LoginStatus.cancelled) {
        return const NativeSignInAttempt.cancelled();
      }

      if (result.status != LoginStatus.success || result.accessToken == null) {
        return NativeSignInAttempt.failed(
          result.message ?? 'No se pudo abrir el selector nativo de Facebook.',
        );
      }

      final credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);
      final authResult = await _auth.signInWithCredential(credential);

      final email = authResult.user?.email ?? 'facebook_user';
      return NativeSignInAttempt.success(email);
    } on FirebaseAuthException catch (e) {
      return NativeSignInAttempt.failed(_handleFirebaseError(e));
    } catch (error) {
      return NativeSignInAttempt.failed('Facebook error no esperado: $error');
    }
  }

  static String _handleFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No encontramos una cuenta con ese correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta. Inténtalo de nuevo.';
      case 'email-already-in-use':
        return 'Este correo ya está registrado.';
      case 'invalid-email':
        return 'El formato del correo es inválido.';
      case 'weak-password':
        return 'La contraseña es muy débil.';
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con ese correo usando otro método.';
      case 'network-request-failed':
        return 'Sin conexión a internet.';
      default:
        return 'Error: ${e.message}';
    }
  }
}
