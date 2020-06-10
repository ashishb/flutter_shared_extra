import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:flutter_shared/flutter_shared.dart';
import 'package:flutter_shared_extra/flutter_shared_extra.dart';
import 'package:provider/provider.dart';

class LoginPhoneDialog extends StatefulWidget {
  @override
  _LoginPhoneDialogState createState() => _LoginPhoneDialogState();
}

class _LoginPhoneDialogState extends State<LoginPhoneDialog> {
  final PhoneVerifyier _phoneVerifier = PhoneVerifyier();
  final TextEditingController _smsCodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _phoneController.dispose();

    _smsCodeController.dispose();
    super.dispose();
  }

  void _onCountrySelected(PhoneCountryData countryData) {
    setState(() {
      print(countryData?.country);
    });
  }

  List<Widget> _children(BuildContext context) {
    final PhoneVerifyier phoneVerifier = Provider.of<PhoneVerifyier>(context);

    if (!phoneVerifier.hasVerificationId) {
      return <Widget>[
        TextFormField(
          decoration: InputDecoration(
              border: const UnderlineInputBorder(),
              hintText: 'Type a phone to format',
              hintStyle: TextStyle(color: Colors.black.withOpacity(.3)),
              errorStyle: const TextStyle(color: Colors.red)),
          keyboardType: TextInputType.phone,
          controller: _phoneController,
          inputFormatters: [
            PhoneInputFormatter(onCountrySelected: _onCountrySelected)
          ],
          validator: (String value) {
            if (!isPhoneValid(value)) {
              return 'Phone is invalid';
            }
            return null;
          },
        ),
      ];
    }

    return <Widget>[
      Text('A 6-digit code was sent to ${_phoneController.text}'),
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
              return Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: _children(context),
                ),
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
          onPressed: () async {
            if (!_phoneVerifier.hasVerificationId) {
              if (_formKey.currentState.validate()) {
                print(formatAsPhoneNumber(_phoneController.text));

                await _phoneVerifier.verifyPhoneNumber(_phoneController.text);
              }
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
