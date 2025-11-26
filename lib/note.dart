
import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String? id;
  final String title;
  final String content;
  final DateTime createdAt;
  final String? category; // カテゴリフィールドを追加

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.category,
  });

  // FirestoreのドキュメントからNoteオブジェクトを生成するファクトリコンストラクタ
  factory Note.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return Note(
      id: snapshot.id,
      title: data['title'],
      content: data['content'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      category: data['category'] as String?,
    );
  }

  // NoteオブジェクトをFirestoreに保存するためのMapに変換するメソッド
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'createdAt': createdAt,
      if (category != null) 'category': category,
    };
  }

  // オブジェクトのコピーを作成するためのメソッド
  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    String? category,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
    );
  }
}
