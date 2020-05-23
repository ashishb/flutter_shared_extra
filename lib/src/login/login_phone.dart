import 'package:flutter/material.dart';
import 'package:flutter_shared/flutter_shared.dart';
import 'package:flutter_shared_extra/flutter_shared_extra.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:provider/provider.dart';

class LoginPhoneDialog extends StatefulWidget {
  @override
  _LoginPhoneDialogState createState() => _LoginPhoneDialogState();
}

class _LoginPhoneDialogState extends State<LoginPhoneDialog> {
  bool phoneValid = false;
  String _initialValue;
  final PhoneVerifyier _phoneVerifier = PhoneVerifyier();
  PhoneNumber phoneNumber;
  final TextEditingController _smsCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // _initialValue = Preferences().getLoginPhone();
    if (_initialValue != null && _initialValue.isNotEmpty) {
      // the phone control doesn't currently validate the initalValue, so just set it to true if we restored from prefs
      phoneValid = true;
      phoneNumber = PhoneNumber(phoneNumber: _initialValue);
    }
  }

  @override
  void dispose() {
    _smsCodeController.dispose();
    super.dispose();
  }

  void _onInputChanged(PhoneNumber phoneNumber) {
    setState(() {
      this.phoneNumber = phoneNumber;
    });
  }

  void _onInputValidated(bool value) {
    setState(() {
      phoneValid = value;
    });
  }

  List<Widget> _children(BuildContext context) {
    final PhoneVerifyier phoneVerifier = Provider.of<PhoneVerifyier>(context);

    if (!phoneVerifier.hasVerificationId) {
      return <Widget>[
        InternationalPhoneNumberInput(
          onInputChanged: _onInputChanged,
          onInputValidated: _onInputValidated,
          textFieldController: TextEditingController()..text = _initialValue,
          hintText: '(415) 555 1234',
        ),
      ];
    }

    return <Widget>[
      Text('A 6-digit code was sent to $phoneNumber'),
      TextField(
        keyboardType: TextInputType.number,
        controller: _smsCodeController,
        decoration: const InputDecoration(
          labelText: 'Verification code',
          helperText: 'Enter the 6-digit code',
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(
        'Login with Phone',
        style: Theme.of(context).textTheme.headline5,
      ),
      contentPadding:
          const EdgeInsets.only(top: 12, bottom: 16, left: 16, right: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      children: [
        ChangeNotifierProvider.value(
          value: _phoneVerifier,
          child: Builder(
            builder: (BuildContext context) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: _children(context),
              );
            },
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        ColoredButton(
          color: Colors.green,
          title: 'Login',
          icon: const Icon(Icons.lock_open, size: 16),
          disabled: !phoneValid,
          onPressed: () async {
            if (!_phoneVerifier.hasVerificationId) {
              await _phoneVerifier.verifyPhoneNumber(phoneNumber.phoneNumber);
            } else {
              final SignInResult result = await AuthService().phoneSignIn(
                  _phoneVerifier.verificationId,
                  _smsCodeController.text.trim());

              Navigator.of(context).pop(result);
            }
          },
        ),
      ],
    );
  }
}

Future<SignInResult> showLoginPhoneDialog(BuildContext context) async {
  return showGeneralDialog<SignInResult>(
    barrierColor: Colors.black.withOpacity(0.5),
    transitionBuilder: (context, a1, a2, widget) {
      return Transform.scale(
        scale: a1.value,
        child: Opacity(
          opacity: a1.value,
          child: LoginPhoneDialog(),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 200),
    barrierDismissible: true,
    barrierLabel: '',
    context: context,
    pageBuilder: (context, animation1, animation2) {
      // never gets called, but is required
      return null;
    },
  );
}
