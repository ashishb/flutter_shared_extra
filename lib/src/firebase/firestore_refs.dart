import 'package:flutter_shared_extra/flutter_shared_extra.dart';

typedef FirestoreRefConverter = dynamic Function(
    Type t, Map<String, dynamic> data, String id);

class FirestoreRefs {
  static FirestoreRefConverter converter;

  static dynamic convert(Type t, Map<String, dynamic> data, String id) {
    // data is null if you try to get a specific object and it doesn't exist.
    if (data == null) {
      return null;
    }

    // always adding id so we can delete by id if needed
    data['id'] = id;

    if (t == ChatMessage) {
      return ChatMessage.fromMap(data);
    } else {
      if (converter != null) {
        return converter(t, data, id);
      }
    }
  }
}
