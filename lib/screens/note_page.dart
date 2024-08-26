import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/note.dart';
import '../services/api_keys_db.dart';
import '../services/api_service.dart';
import '../services/notes_db.dart';
import '../widgets/section_widget.dart';

class NotePage extends StatefulWidget {
  final int noteId;

  NotePage({required this.noteId});

  @override
  _NotePageState createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  String answer = "";
  String title="";
  String transcript="";
  final _questionController = TextEditingController();
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Note Details'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Row(
              children: [
                Text('Chat with Note'),
                SizedBox(width: 5),// Adds some space between the icon and the text
                Icon(Icons.smart_toy),// Add the caption here
              ],
            ), // Add the bot icon here
            onPressed: () {
              _showBotModal(context); // Show the floating page
            },
          ),
        ],
      ),
      body: FutureBuilder<Note?>(
        future: NotesDb.getNoteContent(widget.noteId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('Note not found'));
          }

          Note note = snapshot.data!;
          title = note.title;
          transcript = note.transcript;
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
                      'File: ${note.fileName} \nGenerate Time: ${note.timestamp} \nProcess Time: ${note.executeTime}',
                      style: TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                  ],
                ),
              ),
              SectionWidget(
                  title: 'Note', content: note.noteContent, copyable: true),
              SectionWidget(
                  title: 'Summary', content: note.summary, copyable: true),
              SectionWidget(
                  title: 'Transcript',
                  content: note.transcript,
                  copyable: true,
                  scrollable: true),
              SectionWidget(title: 'Contributed by', content: note.source),
            ],
          );
        },
      ),
    );
  }
  Future<String> _generateNote(String question) async {
    setState(() {
      _isGenerating = true;
      answer = "Generating...";
    });

    final (geminiApiKey, groqApiKey) = await ApiKeysDb.loadApiKeys();
    if (geminiApiKey == null || groqApiKey == null) {
      return "API keys not found";
    }

    try {
      final noteResult = await ApiService.geminiGenerateAnswer(geminiApiKey, transcript, question);
      if (!noteResult['success']) {
        throw Exception('Note Generation Error: ${noteResult['error']}');
      }
      return noteResult['data'];
    } catch (e) {
      try {
        final noteResult = await ApiService.groqGenerateAnswer(groqApiKey, transcript, question);
        if (!noteResult['success']) {
          throw Exception('Note Generation Error: ${noteResult['error']}');
        }
        return noteResult['data'];
      } catch (e) {
        return "Error: $e";
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _showBotModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7, // Start at 50% of screen height
              minChildSize: 0.5, // Minimum height (30% of screen height)
              maxChildSize: 0.9, // Maximum height (90% of screen height)
              expand: false,
              builder: (_, controller) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: SingleChildScrollView(
                    controller: controller,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Chat with Note",
                            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          TextField(
                            controller: _questionController,
                            decoration: InputDecoration(
                              labelText: "Enter your question",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _isGenerating
                                ? null
                                : () async {
                              if (_questionController.text.isNotEmpty) {
                                setModalState(() {
                                  _isGenerating = true;
                                });
                                final generatedAnswer = await _generateNote(_questionController.text);
                                setModalState(() {
                                  _isGenerating = false;
                                  answer = generatedAnswer;
                                });
                                setState(() {
                                  answer = generatedAnswer;
                                });
                              }
                            },
                            child: _isGenerating
                                ? CircularProgressIndicator()
                                : Text("Send"),
                          ),
                          SizedBox(height: 10),
                          SectionWidget(
                            title: 'Answer',
                            content: answer,
                            copyable: true,

                          ),
                          SizedBox(height: 20),
                          Divider(), // Adds a line to separate the close button

                          Container(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the modal
                              },
                              child: Text(
                                'Close chat',
                                style: TextStyle(fontSize: 16,color: Colors.white),

                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red, // Optional: set the button color to red
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

}
