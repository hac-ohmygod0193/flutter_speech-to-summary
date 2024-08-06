import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/notes_db.dart';
import '../widgets/section_widget.dart';

class NotePage extends StatelessWidget {
  final int noteId;

  NotePage({required this.noteId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Note Details'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Note?>(
        future: NotesDb.getNoteContent(noteId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('Note not found'));
          }

          Note note = snapshot.data!;
          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 8),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              width: double.infinity, // Ensures the container takes up the full width
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                  note.title, // Assuming note.title contains the title of the note
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                  ),
                  SizedBox(height: 8), // Adds space between the title and the message
                  Text(
                    'File: ${note.fileName} \nGenerate Time: ${note.timestamp}',
                    style: TextStyle(
                      fontSize: 16.0,
                    ),
                  ),
                ],
                ),
              ),


              SectionWidget(title: 'Note', content: note.noteContent, copyable: true),
              SectionWidget(title: 'Summary', content: note.summary, copyable: true),
              SectionWidget(title: 'Transcript', content: note.transcript, copyable: true, scrollable: true),
              SectionWidget(title: 'Contributed by', content: note.source),
            ],
          );
        },
      ),
    );
  }
}