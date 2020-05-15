import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_shared/flutter_shared.dart';

class SignInResult {
  const SignInResult({this.user, this.errorString});

  final String errorString;
  final FirebaseUser user;
}

class AuthService {
  factory AuthService() {
    return _instance;
  }
  AuthService._privateConstructor();

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Firestore _store = Firestore.instance;

  // singleton
  static final AuthService _instance = AuthService._privateConstructor();

  Future<FirebaseUser> get currentUser => _auth.currentUser();
  Stream<FirebaseUser> get userStream => _auth.onAuthStateChanged;
  Firestore get store => _store;
  FirebaseAuth get auth => _auth;

  // returns a map {user: user, error: 'error message'}
  Future<SignInResult> emailSignIn(String email, String password) async {
    FirebaseUser user;
    String errorString;

    // you must trim the inputs, flutter is appending a tab when tab over to the password
    final trimmedEmail = StrUtils.trim(email);
    final trimmedPassword = StrUtils.trim(password);

    try {
      final AuthResult authResult = await _auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );

      user = authResult.user;
    } on PlatformException catch (error) {
      errorString = error.message;

      switch (error.code) {
        case 'ERROR_INVALID_EMAIL':
          break;
        case 'ERROR_WRONG_PASSWORD':
          break;
        case 'ERROR_USER_NOT_FOUND':
          // create user if doesn't have account
          final SignInResult createRes =
              await createUserWithEmail(email, password);
          user = createRes.user;
          errorString = createRes.errorString;
          break;
        case 'ERROR_USER_DISABLED':
          break;
        case 'ERROR_TOO_MANY_REQUESTS':
          break;
        case 'ERROR_OPERATION_NOT_ALLOWED':
          break;
      }
    }

    return SignInResult(user: user, errorString: errorString);
  }

  // returns a map {user: user, error: 'error message'}
  Future<SignInResult> createUserWithEmail(
      String email, String password) async {
    FirebaseUser user;
    String errorString;

    // you must trim the inputs, flutter is appending a tab when tab over to the password
    final trimmedEmail = StrUtils.trim(email);
    final trimmedPassword = StrUtils.trim(password);

    try {
      final AuthResult result = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );

      user = result.user;
    } on PlatformException catch (error) {
      errorString = error.message;

      switch (error.code) {
        case 'ERROR_WEAK_PASSWORD':
          break;
        case 'ERROR_INVALID_EMAIL':
          break;
        case 'ERROR_EMAIL_ALREADY_IN_USE':
          break;
      }
    }

    return SignInResult(user: user, errorString: errorString);
  }

  // returns a map {user: user, error: 'error message'}
  Future<SignInResult> googleSignIn() async {
    FirebaseUser user;
    String errorString;

    try {
      final GoogleSignInAccount googleSignInAccount =
          await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.getCredential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final AuthResult authResult =
          await _auth.signInWithCredential(credential);
      user = authResult.user;
    } on PlatformException catch (error) {
      errorString = error.message;
    }

    return SignInResult(user: user, errorString: errorString);
  }

  // returns a map {user: user, error: 'error message'}
  Future<SignInResult> anonLogin() async {
    FirebaseUser user;
    String errorString;

    try {
      final AuthResult authResult = await _auth.signInAnonymously();

      user = authResult.user;
    } on PlatformException catch (error) {
      errorString = error.message;

      switch (error.code) {
        case 'ERROR_OPERATION_NOT_ALLOWED':
          break;
      }
    }

    return SignInResult(user: user, errorString: errorString);
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  Future<bool> isAnonymous() async {
    final FirebaseUser user = await currentUser;

    if (user != null && user.uid.isNotEmpty) {
      return user.isAnonymous;
    }

    return false;
  }

  Future<Map> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);

      return <String, dynamic>{'result': true, 'errorString': ''};
    } on PlatformException catch (error) {
      final String errorString = error.message;

      switch (error.code) {
        case 'ERROR_INVALID_EMAIL':
          break;
        case 'ERROR_USER_NOT_FOUND':
          break;
      }
      return <String, dynamic>{'result': false, 'errorString': errorString};
    }
  }

  // returns a map {user: user, error: 'error message'}
  Future<SignInResult> phoneSignIn(
      String verificationId, String smsCode) async {
    FirebaseUser user;
    String errorString;

    // you must trim the inputs, flutter is appending a tab when tab over to the password
    final trimmedSmsCode = StrUtils.trim(smsCode);

    try {
      final AuthCredential credential = PhoneAuthProvider.getCredential(
        verificationId: verificationId,
        smsCode: trimmedSmsCode,
      );

      final AuthResult authResult =
          await _auth.signInWithCredential(credential);
      user = authResult.user;
    } on PlatformException catch (error) {
      // PlatformException has code, message and details
      errorString = error.message;

      switch (error.code) {
        case 'ERROR_INVALID_CREDENTIAL':
          break;
        case 'ERROR_USER_DISABLED':
          break;
        case 'ERROR_ACCOUNT_EXISTS_WITH_DIFFERENT_CREDENTIAL':
          break;
        case 'ERROR_INVALID_ACTION_CODE':
          break;
        case 'ERROR_OPERATION_NOT_ALLOWED':
          break;
      }
    }

    return SignInResult(user: user, errorString: errorString);
  }

  Future<bool> addAdminClaimToEmail(String email) async {
    return modifyClaimsForEmail(email, <String, dynamic>{'admin': true});
  }

  Future<bool> deleteClaimForEmail(String email) async {
    return modifyClaimsForEmail(email, null);
  }

  Future<bool> modifyClaimsForEmail(
      String email, Map<String, dynamic> claims) async {
    try {
      final HttpsCallable callable = CloudFunctions.instance.getHttpsCallable(
        functionName: 'addUserClaims',
      );
      final HttpsCallableResult resp = await callable.call(<String, dynamic>{
        'email': email,
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
    final FirebaseUser user = await currentUser;

    if (user != null) {
      try {
        // SNG - crashes in airplane mode.  Issue on Github
        return user.getIdToken().then((x) {
          return x.claims['admin'] == true;
        });
      } catch (error) {
        print(error);
        return false;
      }
    }

    return false;
  }
}
