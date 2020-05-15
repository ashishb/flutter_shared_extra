import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shared_extras/flutter_shared_extra.dart';

class FirebaseUserProvider extends ChangeNotifier {
  FirebaseUserProvider() {
    _setup();
  }

  FirebaseUser _user;
  final AuthService _auth = AuthService();
  bool _initalized = false;
  bool _isAdmin = false;

  bool get isAdmin => _isAdmin;
  bool get hasUser => _user != null;
  String get userId => hasUser ? _user.uid : '';

  bool get initalized => _initalized;

  // work around for reload
  Future<void> reload() async {
    await _user.reload();
    _user = await _auth.currentUser;

    notifyListeners();
  }

  String get identity {
    String result = displayName;

    if (result.isEmpty) {
      result = phoneNumber;
    }

    if (result.isEmpty) {
      result = email;
    }

    if (result.isEmpty) {
      result = 'Guest';
    }

    return result;
  }

  String get displayName {
    String result;

    if (_user != null) {
      result = _user.displayName;
    }

    return result ?? '';
  }

  String get phoneNumber {
    String result;

    if (_user != null) {
      result = _user.phoneNumber;
    }

    return result ?? '';
  }

  String get email {
    String result;

    if (_user != null) {
      result = _user.email;
    }

    return result ?? '';
  }

  String get photoUrl {
    String result;

    if (_user != null) {
      result = _user.photoUrl;
    }

    return result ?? '';
  }

  Future<void> updateProfile(UserUpdateInfo userInfo) async {
    await _user.updateProfile(userInfo);
    await reload();
  }

  Future<void> updateEmail(String email) async {
    await _user.updateEmail(email);
    await reload();
  }

  Future<void> _setup() async {
    final Stream<FirebaseUser> stream = _auth.userStream;

    await stream.forEach((FirebaseUser user) async {
      _user = user;

      // this checks for user == null
      _isAdmin = await _auth.isAdmin();

      // want to avoid flashing the login screen until we get the
      // first response
      _initalized = true;

      notifyListeners();
    });
  }
}
