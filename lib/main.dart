import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'screens/note_page.dart';
import 'screens/create_note_page.dart';
import 'screens/settings_page.dart';
import 'services/notes_db.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotesDb.initDatabase();
  NotesDb.initStream();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Notes App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'SF Pro Display',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/create_note': (context) => CreateNotePage(),
        '/settings': (context) => SettingsPage(),
        '/note': (context) => NotePage(
              noteId: ModalRoute.of(context)!.settings.arguments as int,
            ),
      },
      debugShowCheckedModeBanner: false,

    );
  }
}
