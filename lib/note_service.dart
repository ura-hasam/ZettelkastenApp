
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/note.dart';

class NoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference<Note> notesCollection; // noteDocs -> notesCollection

  NoteService() {
    notesCollection = _firestore.collection('notes').withConverter<Note>(
      // 2つの引数(snapshot, _)を受け取り、snapshotだけをNote.fromFirestoreに渡す
      fromFirestore: (snapshot, _) => Note.fromFirestore(snapshot),
      toFirestore: (note, _) => note.toFirestore(),
    );
  }

  // リアルタイムにノートリストを取得するストリーム
  Stream<QuerySnapshot<Note>> getNotesStream() {
    return notesCollection.orderBy('createdAt', descending: true).snapshots();
  }

  // 新しいノートを追加する
  Future<void> addNote(Note note) {
    return notesCollection.add(note);
  }

  // ノートを更新する
  Future<void> updateNote(Note note) {
    return notesCollection.doc(note.id).update(note.toFirestore());
  }

  // ノートを削除する
  Future<void> deleteNote(String noteId) {
    return notesCollection.doc(noteId).delete();
  }

  // コレクションへの参照を公開
  CollectionReference<Note> get collection => notesCollection;
}

