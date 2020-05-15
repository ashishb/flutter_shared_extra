import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_shared/flutter_shared.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:flutter_shared_extras/flutter_shared_extra.dart';

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
  Document({this.path}) {
    ref = _store.document(path);
  }

  final Firestore _store = AuthService().store;
  final String path;
  DocumentReference ref;

  String get documentId => ref.documentID;

  Future<T> getData() {
    return ref
        .get()
        .then((v) => FirestoreRefs.convert(T, v.data, documentId) as T);
  }

  Stream<T> streamData() {
    return ref
        .snapshots()
        .map((v) => FirestoreRefs.convert(T, v.data, documentId) as T);
  }

  Future<void> upsert(Map<String, dynamic> data) {
    return ref.setData(data, merge: true);
  }

  Future<void> delete() {
    return ref.delete();
  }

  @override
  String toString() {
    return 'path: $path';
  }
}

class Collection<T> {
  Collection({this.path}) {
    ref = _store.collection(path);
  }

  final Firestore _store = AuthService().store;
  final String path;
  CollectionReference ref;

  Future<List<T>> getData() async {
    final snapshots = await ref.getDocuments();
    return snapshots.documents
        .map((doc) => FirestoreRefs.convert(T, doc.data, doc.documentID) as T)
        .toList();
  }

  Stream<List<T>> streamData() {
    return ref.snapshots().map((v) => v.documents
        .map((doc) => FirestoreRefs.convert(T, doc.data, doc.documentID) as T)
        .toList());
  }

  // must use add to add the timestamp automatically
  Stream<List<T>> orderedStreamData({List<WhereQuery> where}) {
    final Query query = ref.orderBy('timestamp');

    if (Utils.isNotEmpty(where)) {
      final List<Stream<List<T>>> streams = [];

      for (final w in where) {
        final Query tmpQuery = w.where(query);

        streams.add(tmpQuery.snapshots().map((v) => v.documents.map((doc) {
              return FirestoreRefs.convert(T, doc.data, doc.documentID) as T;
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
      return query.snapshots().map((v) => v.documents
          .map((doc) => FirestoreRefs.convert(T, doc.data, doc.documentID) as T)
          .toList());
    }
  }

  // use orderedStreamData above to sort by timestamp
  Future<DocumentReference> addOrdered(Map<String, dynamic> data) {
    data['timestamp'] = FieldValue.serverTimestamp();

    return ref.add(Map<String, dynamic>.from(data));
  }

  Future<bool> delete() async {
    final QuerySnapshot snap = await ref.getDocuments();

    try {
      final List<DocumentSnapshot> docs = snap.documents;

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
  final AuthService auth = AuthService();

  Stream<T> get documentStream {
    return auth.userStream.switchMap((user) {
      if (user != null) {
        final Document<T> doc = Document<T>(path: '$collection/${user.uid}');
        return doc.streamData();
      } else {
        return Stream<T>.value(null);
      }
    });
  }

  Future<T> getDocument() async {
    final FirebaseUser user = await auth.currentUser;

    if (user != null && user.uid.isNotEmpty) {
      final Document<T> doc = Document<T>(path: '$collection/${user.uid}');
      return doc.getData();
    } else {
      return null;
    }
  }

  Future<void> upsert(Map<String, dynamic> data) async {
    final FirebaseUser user = await auth.currentUser;

    if (user != null && user.uid.isNotEmpty) {
      final Document<T> ref = Document(path: '$collection/${user.uid}');
      return ref.upsert(data);
    }
  }
}
