import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shared_extra/src/profile/profile_editor.dart';
import 'package:provider/provider.dart';
import 'package:flutter_shared/flutter_shared.dart';
import 'package:flutter_shared_extra/flutter_shared_extra.dart';

class ProfileWidget extends StatelessWidget {
  Widget _userImageWidget(
      BuildContext context, FirebaseUserProvider userProvider) {
    Widget image;
    Color backColor = Colors.white;

    if (userProvider.photoUrl.isNotEmpty) {
      image = SuperImage(SuperImageSource(url: userProvider.photoUrl));
      backColor = Colors.transparent;
    } else {
      image = const Icon(Icons.person, size: 90, color: Colors.black54);
    }

    return AvatarGlow(
      endRadius: 80.0, //required
      glowColor: Colors.blue,

      child: Material(
        clipBehavior: Clip.antiAlias,
        elevation: 8.0,
        shape: const CircleBorder(),
        child: CircleAvatar(
          backgroundColor: backColor,
          radius: 60.0,
          child: image,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<FirebaseUserProvider>(context);
    String userName = 'Profile';

    if (userProvider.hasUser) {
      userName = userProvider.identity;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Center(
        child: Column(
          children: [
            _userImageWidget(context, userProvider),
            Text(userName, style: Theme.of(context).textTheme.headline5),
            Text(userProvider.email,
                style: Theme.of(context).textTheme.subtitle1),
            Text(userProvider.phoneNumber,
                style: Theme.of(context).textTheme.subtitle1),
            Text('id: ${userProvider.userId}',
                style: Theme.of(context).textTheme.subtitle1),
            Text('admin: ${userProvider.isAdmin}',
                style: Theme.of(context).textTheme.subtitle1),
            const SizedBox(height: 30),
            ThemeButton(
              title: 'Edit',
              onPressed: () async {
                final ProfileData data =
                    await showEmailEditProfileDialog(context);

                if (data != null) {
                  try {
                    if (data.name != null && data.name.isNotEmpty) {
                      await userProvider.updateProfile(
                          data.name, data.photoUrl);
                    }

                    if (data.email != null && data.email.isNotEmpty) {
                      await userProvider.updateEmail(data.email);
                    }
                  } catch (error) {
                    print('Error saving user name/email: $error');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
