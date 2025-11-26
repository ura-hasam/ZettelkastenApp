
import 'package:firebase_ai/firebase_ai.dart';
import 'package:myapp/note.dart';

class AiService {
  // モデルを初期化します。safetySettingsを削除し、デフォルト設定を使用します。
  final _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-1.5-flash',
  );

  // ノートのリストをカテゴリに分類するメソッド
  Future<String> classifyNotes(List<Note> notes) async {
    // AIへの指示（プロンプト）を作成します。
    final prompt = '''
    You are an expert at organizing information. 
    Please classify the following notes into appropriate categories. 
    Each note has a title and content.
    
    Provide the output in a clean JSON format like this: 
    [{"id": "note_id_1", "category": "Category Name A"}, {"id": "note_id_2", "category": "Category Name B"}]

    Here are the notes:
    ${notes.map((n) => '{"id": "${n.id}", "title": "${n.title}", "content": "${n.content}"}').toList()}
    ''';

    try {
      // AIにプロンプトを送信し、応答を待ちます。
      final response = await _model.generateContent([Content.text(prompt)]);

      // AIからの応答テキストを返します。
      // JSONの整形処理を追加
      final text = response.text;
      if (text != null) {
        final startIndex = text.indexOf('[');
        final endIndex = text.lastIndexOf(']');
        if (startIndex != -1 && endIndex != -1) {
          return text.substring(startIndex, endIndex + 1);
        }
      }
      return '';

    } catch (e) {
      print('Error classifying notes: $e');
      return ''; // エラーの場合は空の文字列を返す
    }
  }
}
