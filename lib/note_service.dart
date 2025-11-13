
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/note.dart';

class NoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference<Note> _notesRef;

  NoteService() {
    _notesRef = _firestore.collection('notes').withConverter<Note>(
      fromFirestore: Note.fromFirestore,
      toFirestore: (Note note, _) => note.toFirestore(),
    );
  }

  // リアルタイムにノートリストを取得するストリーム
  Stream<QuerySnapshot<Note>> getNotesStream() {
    return _notesRef.orderBy('createdAt', descending: true).snapshots();
  }

  // 新しいノートを追加する
  Future<void> addNote(Note note) {
    return _notesRef.add(note);
  }

  // (参考) 将来的に必要になるかもしれない機能
  // Future<void> updateNote(Note note) {
  //   return _notesRef.doc(note.id).update(note.toFirestore());
  // }

  // Future<void> deleteNote(String noteId) {
  //   return _notesRef.doc(noteId).delete();
  // }
}
