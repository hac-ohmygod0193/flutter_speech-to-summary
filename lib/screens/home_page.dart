import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/notes_db.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    NotesDb.initStream();
  }

  @override
  void dispose() {
    NotesDb.disposeStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Notes'),
        actions: [
          IconButton(
            icon: Row(
              children: [
                Text('Settings'),
                SizedBox(width: 5),// Adds some space between the icon and the text
                Icon(Icons.settings),// Add the caption here
              ],
            ),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),


        ],
      ),
      body: StreamBuilder<List<Note>>(
        stream: NotesDb.notesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                  'No notes yet!\nTap + to create a new note.\nGo to Settings to set the API keys first.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 23.0),
              ),
            );
          }

          final notes = snapshot.data!;
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return ListTile(
                title: Text(note.title),
                subtitle: Text(note.timestamp),
                onTap: () => Navigator.pushNamed(
                  context,
                  '/note',
                  arguments: note.id,
                ),
                onLongPress: () => _showDeleteDialog(context, note.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => Navigator.pushNamed(context, '/create_note'),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, int noteId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Note'),
          content: Text('Are you sure you want to delete this note?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                NotesDb.deleteNote(noteId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}