
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/ai_service.dart';
import 'package:myapp/note.dart';
import 'package:myapp/note_edit_screen.dart';
import 'package:myapp/note_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:grouped_list/grouped_list.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setSystemTheme() {
    _themeMode = ThemeMode.system;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primarySeedColor = Colors.teal;

    final TextTheme appTextTheme = TextTheme(
      displayLarge: GoogleFonts.oswald(fontSize: 57, fontWeight: FontWeight.bold),
      titleLarge: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.openSans(fontSize: 14),
    );

    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.light,
      ),
      textTheme: appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: primarySeedColor,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primarySeedColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );

    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.dark,
      ),
      textTheme: appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.teal.shade200,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Zettelkasten AI',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          home: const MyHomePage(),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final NoteService _noteService = NoteService();
  final AiService _aiService = AiService();
  bool _isClassifying = false;

  Future<void> _addNote() async {
    final newNoteData = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (context) => const NoteEditScreen()),
    );

    if (newNoteData != null && newNoteData['title']!.isNotEmpty) {
      final newNote = Note(
        title: newNoteData['title']!,
        content: newNoteData['content']!,
        createdAt: DateTime.now(),
        category: 'Uncategorized',
      );
      await _noteService.addNote(newNote);
    }
  }

  Future<void> _editNote(Note note) async {
    final updatedNoteData = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (context) => NoteEditScreen(note: note)),
    );

    if (updatedNoteData != null) {
      final updatedNote = note.copyWith(
        title: updatedNoteData['title']!,
        content: updatedNoteData['content']!,
      );
      await _noteService.updateNote(updatedNote);
    }
  }

  Future<void> _deleteNote(String noteId) async {
    try {
      await _noteService.deleteNote(noteId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted')),
        );
      }
    } catch (e, s) {
      developer.log(
        'Failed to delete note',
        name: 'com.example.myapp.MyHomePage',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting note: $e')),
        );
      }
    }
  }

  Future<void> _classifyNotes() async {
    if (_isClassifying) return;

    setState(() {
      _isClassifying = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI is classifying your notes...')),
    );

    try {
      final allNotesSnapshot = await _noteService.getNotesStream().first;
      final allNotes = allNotesSnapshot.docs.map((doc) => doc.data()).toList();

      if (allNotes.length < 2) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You need at least 2 notes to classify.')),
          );
        }
        return;
      }

      final jsonResponse = await _aiService.classifyNotes(allNotes);
      if (jsonResponse.isEmpty) {
        throw Exception('AI did not return a valid classification.');
      }

      final List<dynamic> classifications = jsonDecode(jsonResponse);

      final WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var classification in classifications) {
        final noteId = classification['id'];
        final category = classification['category'];

        if (noteId != null && category != null) {
          final noteRef = _noteService.notesCollection.doc(noteId);
          batch.update(noteRef, {'category': category});
        }
      }

      await batch.commit();

      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Classification complete!')),
        );
      }

    } catch (e, s) {
        developer.log(
        'Error during classification',
        name: 'com.example.myapp.MyHomePage',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during classification: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClassifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zettelkasten AI'),
        actions: [
          if (_isClassifying)
            const Padding(
              padding: EdgeInsets.only(right: 12.0),
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.auto_awesome_mosaic_outlined),
              onPressed: _classifyNotes,
              tooltip: 'Classify Notes',
            ),
          IconButton(
            icon: Icon(themeProvider.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.auto_mode),
            onPressed: () => themeProvider.setSystemTheme(),
            tooltip: 'Set System Theme',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Note>>(
        stream: _noteService.getNotesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
             developer.log(
              'Error in notes stream',
              name: 'com.example.myapp.MyHomePage.StreamBuilder',
              level: 1000,
              error: snapshot.error,
              stackTrace: snapshot.stackTrace,
            );
            return Center(child: Text('Something went wrong: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notes = snapshot.data?.docs.map((doc) => doc.data()).toList() ?? [];

          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('Welcome to Zettelkasten AI!', style: Theme.of(context).textTheme.displayLarge),
                  const SizedBox(height: 20),
                  Text('Create and link your notes with the power of AI.', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _addNote,
                    child: const Text('Create a New Note'),
                  ),
                ],
              ),
            );
          }

          return GroupedListView<Note, String>(
            elements: notes,
            groupBy: (note) => note.category ?? 'Uncategorized',
            groupSeparatorBuilder: (String groupByValue) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                groupByValue,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            itemBuilder: (context, Note note) {
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                child: Dismissible(
                  key: Key(note.id!),
                  onDismissed: (direction) {
                    _deleteNote(note.id!);
                  },
                  background: Container(
                    color: Colors.red.shade400,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      note.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _editNote(note),
                  ),
                ),
              );
            },
            order: GroupedListOrder.ASC,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        tooltip: 'New Note',
        child: const Icon(Icons.add),
      ),
    );
  }
}
