import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_shared/flutter_shared.dart';

class SignInResult {
  const SignInResult({this.user, this.errorString});

  final String errorString;
  final auth.User user;
}

class AuthService {
  factory AuthService() {
    return _instance ??= AuthService._();
  }
  AuthService._();
  static AuthService _instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _store = FirebaseFirestore.instance;

  auth.User get currentUser => _auth.currentUser;
  Stream<auth.User> get userStream => _auth.authStateChanges();
  FirebaseFirestore get store => _store;
  auth.FirebaseAuth get fbAuth => _auth;

  // returns a map {user: user, error: 'error message'}
  Future<SignInResult> emailSignIn(String email, String password) async {
    auth.User user;
    String errorString;

    // you must trim the inputs, flutter is appending a tab when tab over to the password
    final trimmedEmail = StrUtils.trim(email);
    final trimmedPassword = StrUtils.trim(password);

    try {
      final auth.UserCredential authResult =
          await _auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );

      user = authResult.user;
    } on auth.FirebaseAuthException catch (error) {
      errorString = error.message;

      switch (error.code) {
        case 'user-disabled':
          break;
        case 'wrong-password':
          break;
        case 'invalid-email':
          break;
        case 'user-not-found':
          // create user if doesn't have account
          final SignInResult createRes =
              await createUserWithEmail(email, password);
          user = createRes.user;
          errorString = createRes.errorString;
          break;
      }
    }

    return SignInResult(user: user, errorString: errorString);
  }

  // returns a map {user: user, error: 'error message'}
  Future<SignInResult> createUserWithEmail(
      String email, String password) async {
    auth.User user;
    String errorString;

    // you must trim the inputs, flutter is appending a tab when tab over to the password
    final trimmedEmail = StrUtils.trim(email);
    final trimmedPassword = StrUtils.trim(password);

    try {
      final auth.UserCredential result =
          await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );

      user = result.user;
    } on auth.FirebaseAuthException catch (error) {
      errorString = error.message;

      switch (error.code) {
        case 'email-already-in-use':
          break;
        case 'invalid-email':
          break;
        case 'operation-not-allowed':
          break;
        case 'weak-password':
          break;
      }
    }

    return SignInResult(user: user, errorString: errorString);
  }

  // returns a map {user: user, error: 'error message'}
  Future<SignInResult> googleSignIn() async {
    auth.User user;
    String errorString;

    try {
      final GoogleSignInAccount googleSignInAccount =
          await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleSignInAccount.authentication;

      final auth.AuthCredential credential = auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final auth.UserCredential authResult =
          await _auth.signInWithCredential(credential);
      user = authResult.user;
    } on auth.FirebaseAuthException catch (error) {
      errorString = error.message;

      switch (error.code) {
        case 'account-exists-with-different-credential':
          break;
        case 'invalid-credential':
          break;
        case 'operation-not-allowed':
          break;
        case 'user-disabled':
          break;
        case 'user-not-found':
          break;
        case 'wrong-password':
          break;
        case 'invalid-verification-code':
          break;
        case 'ERROR_OPERATION_NOT_ALLOWED':
          break;
        case 'invalid-verification-id':
          break;
      }
    }

    return SignInResult(user: user, errorString: errorString);
  }

  // returns a map {user: user, error: 'error message'}
  Future<SignInResult> anonLogin() async {
    auth.User user;
    String errorString;

    try {
      final auth.UserCredential authResult = await _auth.signInAnonymously();

      user = authResult.user;
    } on auth.FirebaseAuthException catch (error) {
      errorString = error.message;

      switch (error.code) {
        case 'operation-not-allowed':
          break;
      }
    }

    return SignInResult(user: user, errorString: errorString);
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  bool isAnonymous() {
    final auth.User user = currentUser;

    if (user != null && user.uid.isNotEmpty) {
      return user.isAnonymous;
    }

    return false;
  }

  Future<Map> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);

      return <String, dynamic>{'result': true, 'errorString': ''};
    } on auth.FirebaseAuthException catch (error) {
      final String errorString = error.message;

      switch (error.code) {
        case 'invalid-email':
          break;
        case 'user-not-found':
          break;
      }
      return <String, dynamic>{'result': false, 'errorString': errorString};
    }
  }

  // returns a map {user: user, error: 'error message'}
  Future<SignInResult> phoneSignIn(
      String verificationId, String smsCode) async {
    auth.User user;
    String errorString;

    // you must trim the inputs, flutter is appending a tab when tab over to the password
    final trimmedSmsCode = StrUtils.trim(smsCode);

    try {
      final auth.AuthCredential credential = auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: trimmedSmsCode,
      );

      final auth.UserCredential authResult =
          await _auth.signInWithCredential(credential);
      user = authResult.user;
    } on auth.FirebaseAuthException catch (error) {
      errorString = error.message;

      switch (error.code) {
        case 'account-exists-with-different-credential':
          break;
        case 'invalid-credential':
          break;
        case 'operation-not-allowed':
          break;
        case 'user-disabled':
          break;
        case 'user-not-found':
          break;
        case 'wrong-password':
          break;
        case 'invalid-verification-code':
          break;
        case 'invalid-verification-id':
          break;
      }
    }

    return SignInResult(user: user, errorString: errorString);
  }

  Future<bool> addClaimToEmail(String email, String claim) async {
    return _modifyClaims(
      email: email,
      uid: null,
      claims: <String, bool>{claim: true},
    );
  }

  Future<bool> removeClaimForEmail(String email, String claim) async {
    return _modifyClaims(
      email: email,
      uid: null,
      claims: <String, bool>{claim: false},
    );
  }

  Future<bool> addClaimToUid(String uid, String claim) async {
    return _modifyClaims(
      email: null,
      uid: uid,
      claims: <String, bool>{claim: true},
    );
  }

  Future<bool> removeClaimForUid(String uid, String claim) async {
    return _modifyClaims(
      email: null,
      uid: uid,
      claims: <String, bool>{claim: false},
    );
  }

  Future<bool> _modifyClaims({
    @required String email,
    @required String uid,
    @required Map<String, bool> claims,
  }) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'addUserClaims',
      );
      final HttpsCallableResult resp =
          await callable.call<Map>(<String, dynamic>{
        'email': email,
        'uid': uid,
        'claims': claims,
      });

      if (resp != null && resp.data != null) {
        if (resp.data['error'] != null) {
          print(resp.data);
          return false;
        }

        return true;
      }
    } catch (error) {
      print('erroor $error');
    }

    return false;
  }

  Future<bool> isAdmin() async {
    final userClaims = await claims();

    return userClaims.contains('admin');
  }

  Future<List<String>> claims() async {
    final List<String> result = [];

    final auth.User user = currentUser;
    if (user != null) {
      try {
        final x = await user.getIdTokenResult();

        x.claims.keys.forEach((key) {
          if (x.claims[key] == true) {
            result.add(key);
          }
        });
      } catch (error) {
        print(error);
      }
    }

    return result;
  }
}
