import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User?> signInWithGoogle() async {
  try {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      final result = await _auth.signInWithPopup(provider);
      return result.user;
    } else {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      return result.user;
    }
  } on Exception catch (e, stack) {
    debugPrint("Error en Google Sign-In (rethrow): $e\n$stack");
    rethrow;
  }
}

  Future<void> signOutAll() async {
    try {
      try {
        await _googleSignIn.disconnect();
      } catch (e) {
        try {
          await _googleSignIn.signOut();
        } catch (e2) {
          debugPrint("Error en GoogleSignIn.signOut tras fallo disconnect: $e2");
        }
      }
    } catch (e) {
      debugPrint("Error en GoogleSignIn.disconnect/signOut: $e");
    }

    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint("Error en FirebaseAuth.signOut: $e");
    }
  }
}
