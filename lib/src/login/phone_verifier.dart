import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_shared_extras/flutter_shared_extra.dart';

class PhoneVerifyier extends ChangeNotifier {
  String _verificationId;
  String _errorMessage;

  final FirebaseAuth _auth = AuthService().auth;

  bool get hasVerificationId =>
      _verificationId != null && _verificationId.isNotEmpty;
  String get verificationId => _verificationId;
  String get errorMessage => _errorMessage;

  // PhoneVerificationCompleted
  Future<void> _verificationCompleted(
      AuthCredential phoneAuthCredential) async {
    try {
      await _auth.signInWithCredential(phoneAuthCredential);
    } on PlatformException catch (error) {
      _errorMessage = error.message;

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

    notifyListeners();
  }

  // PhoneVerificationFailed
  void _verificationFailed(AuthException authException) {
    _errorMessage =
        'Phone number verification failed. Code: ${authException.code}. Message: ${authException.message}';

    notifyListeners();
  }

  // PhoneCodeSent
  void _codeSent(String verificationId, [int forceResendingToken]) {
    _verificationId = verificationId;

    notifyListeners();
  }

  // PhoneCodeAutoRetrievalTimeout
  void _codeAutoRetrievalTimeout(String verificationId) {
    _verificationId = verificationId;

    notifyListeners();
  }

  Future<void> verifyPhoneNumber(String phoneNumber) async {
    await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 10),
        verificationCompleted: _verificationCompleted,
        verificationFailed: _verificationFailed,
        codeSent: _codeSent,
        codeAutoRetrievalTimeout: _codeAutoRetrievalTimeout);
  }
}
