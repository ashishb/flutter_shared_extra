import 'package:flutter/material.dart';
import 'package:flutter_shared/flutter_shared.dart';
import 'package:flutter_shared_extra/src/users/user_details_screen.dart';
import 'package:flutter_shared_extra/src/users/user_utils.dart';

class UsersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: StreamBuilder<List<Map>>(
        stream: UserUtils.users().asStream(),
        builder: (context, snap) {
          bool hasData = false;

          if (snap.hasError) {
            print('snap.hasError');
            print(snap);
          }

          if (snap.hasData && !snap.hasError) {
            hasData = true;
          }

          if (hasData) {
            final List<Map> list = snap.data;

            return ListView.separated(
              itemBuilder: (context, index) {
                final item = list[index];

                final String displayName = item.strVal('displayName');
                final String email = item.strVal('email');
                final String uid = item.strVal('uid');
                final String photoUrl = item.strVal('photoURL');
                final customClaims =
                    item.mapVal<String, dynamic>('customClaims');

                String title = '';
                title += displayName.isNotEmpty ? displayName : '';
                if (title.isNotEmpty) {
                  title += email.isNotEmpty ? ' : $email' : '';
                } else {
                  title += email.isNotEmpty ? email : '';

                  // impossible for uid to be empty
                  title += title.isEmpty ? uid : '';
                }

                final subtitle = Padding(
                    padding: const EdgeInsets.only(top: 4, left: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            "Last Login: ${item['metadata']['lastSignInTime']}"),
                        if (customClaims != null) Text(customClaims.toString()),
                      ],
                    ));

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: Utils.isNotEmpty(photoUrl)
                        ? Image.network(photoUrl).image
                        : null,
                    child: Utils.isEmpty(photoUrl)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(title),
                  subtitle: subtitle,
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (context) => UserDetailsScreen(
                          map: Map<String, dynamic>.from(item),
                        ),
                      ),
                    );
                  },
                );
              },
              separatorBuilder: (context, index) => const Divider(),
              itemCount: list.length,
            );
          } else {
            return LoadingWidget();
          }
        },
      ),
    );
  }
}
