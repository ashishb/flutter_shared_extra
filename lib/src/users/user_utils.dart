import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_shared/flutter_shared.dart';

class UserUtils {
  static Future<List<Map>> users({String nextPageToken}) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'users',
      );

      final params = <dynamic, dynamic>{
        'nextPageToken': nextPageToken,
      };

      return callable.call<Map>(params).then((HttpsCallableResult resp) {
        if (resp != null && resp.data != null) {
          final Map m = resp.data as Map;

          if (m.listVal<Map>('list') != null) {
            return m.listVal<Map>('list');
          }
        }
        return null;
      });
    } catch (error) {
      print('error $error');
    }

    return null;
  }

  static Future<List<String>> getSubCollections(String docPath) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'users',
      );

      final params = <dynamic, dynamic>{
        'docPath': docPath,
      };

      return callable.call<Map>(params).then((HttpsCallableResult resp) {
        if (resp != null && resp.data != null) {
          final List<String> m = resp.data.collections as List<String>;

          return m;
        }
        return null;
      });
    } catch (error) {
      print('error $error');
    }

    return null;
  }
}
