import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_shared/flutter_shared.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:flutter_shared_extra/flutter_shared_extra.dart';

class WhereQuery {
  WhereQuery(this.fromUid, this.toUid);

  String fromUid;
  String toUid;

  Query where(Query query) {
    Query result = query;

    if (Utils.isNotEmpty(fromUid)) {
      result = result.where('user.uid', isEqualTo: fromUid);
    }

    if (Utils.isNotEmpty(toUid)) {
      result = result.where('toUid', isEqualTo: toUid);
    }

    return result;
  }
}

class Document<T> {
  Document(String path) {
    ref = _store.doc(path);
  }

  Document.withRef(this.ref);

  final FirebaseFirestore _store = AuthService().store;
  DocumentReference ref;

  String get documentId => ref.id;

  Future<T> getData() {
    return ref
        .get()
        .then((v) => FirestoreRefs.convert(T, v.data(), documentId) as T);
  }

  Stream<T> streamData() {
    return ref
        .snapshots()
        .map((v) => FirestoreRefs.convert(T, v.data(), documentId) as T);
  }

  Future<void> upsert(Map<String, dynamic> data) {
    return ref.set(data, SetOptions(merge: true));
  }

  Future<void> delete() {
    return ref.delete();
  }

  Collection<X> collection<X>(String path) {
    return Collection<X>.withRef(ref.collection(path));
  }
}

class Collection<T> {
  Collection(String path) {
    ref = _store.collection(path);
  }

  Collection.withRef(this.ref);

  final FirebaseFirestore _store = AuthService().store;
  CollectionReference ref;

  Document<T> document(String path) {
    return Document<T>.withRef(ref.doc(path));
  }

  Future<List<T>> getData() async {
    final snapshots = await ref.get();
    return snapshots.docs
        .map((doc) => FirestoreRefs.convert(T, doc.data(), doc.id) as T)
        .toList();
  }

  Stream<List<T>> streamData() {
    return ref.snapshots().map((v) => v.docs
        .map((doc) => FirestoreRefs.convert(T, doc.data(), doc.id) as T)
        .toList());
  }

  // must use add to add the timestamp automatically
  Stream<List<T>> orderedStreamData({List<WhereQuery> where}) {
    final Query query = ref.orderBy('timestamp');

    if (Utils.isNotEmpty(where)) {
      final List<Stream<List<T>>> streams = [];

      for (final w in where) {
        final Query tmpQuery = w.where(query);

        streams.add(tmpQuery.snapshots().map((v) => v.docs.map((doc) {
              return FirestoreRefs.convert(T, doc.data(), doc.id) as T;
            }).toList()));
      }

      Stream<List<T>> stream = streams.first;

      if (streams.length > 1) {
        stream = stream.combineLatest<List<T>, List<T>>(streams[1],
            (List<T> a, List<T> b) {
          final List<T> result = [];
          result.addAll(a);
          result.addAll(b);

          return result;
        });
      }

      return stream.asBroadcastStream();
    } else {
      return query.snapshots().map((v) => v.docs
          .map((doc) => FirestoreRefs.convert(T, doc.data(), doc.id) as T)
          .toList());
    }
  }

  // use orderedStreamData above to sort by timestamp
  Future<DocumentReference> addOrdered(Map<String, dynamic> data) {
    data['timestamp'] = FieldValue.serverTimestamp();

    return ref.add(Map<String, dynamic>.from(data));
  }

  Future<bool> delete() async {
    final QuerySnapshot snap = await ref.get();

    try {
      final List<DocumentSnapshot> docs = snap.docs;

      // can't use forEach with await
      await Future.forEach(docs, (DocumentSnapshot d) {
        return d.reference.delete();
      });

      return true;
    } catch (error) {
      print(error);

      return false;
    }
  }
}

class UserData<T> {
  UserData({this.collection});

  final String collection;
  final AuthService authService = AuthService();

  Stream<T> get documentStream {
    return authService.userStream.switchMap((user) {
      if (user != null) {
        final Document<T> doc = Document<T>('$collection/${user.uid}');
        return doc.streamData();
      } else {
        return Stream<T>.value(null);
      }
    });
  }

  Future<T> getDocument() async {
    final auth.User user = authService.currentUser;

    if (user != null && user.uid.isNotEmpty) {
      final Document<T> doc = Document<T>('$collection/${user.uid}');
      return doc.getData();
    } else {
      return null;
    }
  }

  Future<void> upsert(Map<String, dynamic> data) async {
    final auth.User user = authService.currentUser;

    if (user != null && user.uid.isNotEmpty) {
      final Document<T> ref = Document('$collection/${user.uid}');
      return ref.upsert(data);
    }
  }
}
