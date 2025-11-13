
import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String? id;
  final String title;
  final String content;
  final DateTime createdAt;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  // FirestoreのドキュメントからNoteオブジェクトを生成するファクトリコンストラクタ
  factory Note.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return Note(
      id: snapshot.id,
      title: data?['title'] ?? '',
      content: data?['content'] ?? '',
      createdAt: (data?['createdAt'] as Timestamp).toDate(),
    );
  }

  // NoteオブジェクトをFirestoreに保存するためのMapに変換するメソッド
  Map<String, dynamic> toFirestore() {
    return {
      "title": title,
      "content": content,
      "createdAt": Timestamp.fromDate(createdAt),
    };
  }
}
