import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../services/notes_db.dart';
import '../services/api_keys_db.dart';
import '../utilities/alert_utils.dart';
import '../widgets/language_selector.dart';
import '../widgets/section_widget.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:flutter_speech_to_summary/utilities/get_directory.dart';
class CreateAudioNotePage extends StatefulWidget {
  @override
  _CreateAudioNotePageState createState() => _CreateAudioNotePageState();
}

class _CreateAudioNotePageState extends State<CreateAudioNotePage> {
  final _titleController = TextEditingController();
  String? _filePath;
  String? _fileName;
  Map<String, dynamic>? _result;
  bool _isGenerating = false;
  double _progress = 0.0;
  String _statusText = '';
  String language="English";
  String? _selectedLanguage;
  String _executionTime = '';

  void _handleLanguageSelected(String? language) {
    setState(() {
      _selectedLanguage = language;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Note'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Warning'),
                  content: Text('The note won\'t be saved if you go back directly. Do you want to go back?'),
                  actions: <Widget>[
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                    ),
                    TextButton(
                      child: Text('Go Back'),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                        Navigator.pop(context); // Go back to the previous screen
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          if (_result == null) ...[
            Card(
              margin: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Create your note title',
                    hintText: 'Default is your file name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    helperText: 'Enter a descriptive title for your note',
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 18),
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(Icons.file_upload, size: 24,color: Colors.white,),
              label: Text(
                _filePath == null ? 'Select file' : 'Reselect file',
                style: TextStyle(fontSize: 16,color: Colors.white),

              ),
              onPressed: _selectAudioFile,
            ),
            if (_filePath != null) ...[
              SizedBox(height: 24),
              Text(
                'Selected Audio File: $_fileName',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 24),
              Card(
                margin: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LanguageSelector(onLanguageSelected: _handleLanguageSelected),
                ),
              ),
              SizedBox(height: 24),
              if (_selectedLanguage == null)
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Please select a language before generating a note',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(Icons.note_add, size: 24, color: Colors.white),
                label: Text(
                  'Generate Note',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                onPressed: (_isGenerating || _selectedLanguage == null) ? null : _generateNote,
              ),
            ],
            if (_isGenerating) ...[
              SizedBox(height: 32),
              _buildProgressBar(),
            ],
          ] else ...[
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
                    _fileName ?? '', // Assuming note.title contains the title of the note
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8), // Adds space between the title and the message
                  Text(
                    'Create time: ${_result!['execute_time']} \nProcessing Time: $_executionTime',
                    style: TextStyle(
                      fontSize: 16.0,
                    ),
                  ),
                ],
              ),
            ),
            SectionWidget(title: 'Generated by', content: _result!['source']),
            SectionWidget(title: 'Note', content: _result!['note'], copyable: true),
            SectionWidget(title: 'Summary', content: _result!['summary'], copyable: true),
            SectionWidget(title: 'Transcript', content: _result!['text'], copyable: true, scrollable: true),
            SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 18),
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Save',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              onPressed: _saveNote,
            ),
          ],
        ],
      ),

    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }


  Future<void> _selectAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null) {
        // Check file size (25MB = 25 * 1024 * 1024 bytes)
        if (result.files.single.size > 25 * 1024 * 1024) {
          // File is larger than 25MB, show error dialog
          AlertUtils.showErrorDialog(
              context,
              'File Too Large',
              'The selected audio file exceeds the 25MB limit. Please choose a smaller file.'
          );
        } else {
          // File size is acceptable, update state
          setState(() {
            _filePath = result.files.single.path;
            _fileName = result.files.single.name;
          });
        }
      }
    } catch (e) {
      print('Error picking file: $e');
      AlertUtils.showErrorDialog(
          context,
          'File Selection Error',
          'An error occurred while selecting the file: $e'
      );
    }
  }
  void _updateProgress(double progress, String status) {
    setState(() {
      _progress = progress;
      _statusText = status;
    });
  }
  Future<void> _generateNote() async {
    if (_filePath == null) return;

    setState(() {
      _isGenerating = true;
      _progress = 0.0;
      _statusText = 'Initializing...';
    });
    final stopwatch = Stopwatch()..start();
    String summary="Failed";
    String note="Failed";
    String source="AI-generated";
    language = _selectedLanguage! ;
    try {
      _updateProgress(0.1, 'Loading API keys...');
      final (geminiApiKey, groqApiKey) = await ApiKeysDb.loadApiKeys();
      if (geminiApiKey == null || groqApiKey == null) {
        AlertUtils.showErrorDialog(
            context,
            'API Keys Missing',
            'Please set up your API keys in the settings page.'
        );
        return;
      }

      _updateProgress(0.2, 'Transcribing audio...');
      final transcriptionResult = await ApiService.transcribeAudio(File(_filePath!), groqApiKey);
      if (!transcriptionResult['success']) {
        AlertUtils.showErrorDialog(context, 'Transcription Error', transcriptionResult['error']);
        return;
      }
      final transcription = transcriptionResult['data'];

      _updateProgress(0.4, 'Generating summary...');
      try {
        // Try Gemini first
        _updateProgress(0.5, 'Uploading to Gemini...');
        final uriResult = await ApiService.uploadToGemini(geminiApiKey, File(_filePath!));
        if (!uriResult['success']) {
          throw Exception(uriResult['error']);
        }
        final file_uri = uriResult['data'];

        final gemini_summary_prompt = '''
        Listen intently to the audio file. Provide a concise summary of the speaker's message in $language.
        Go beyond just facts and identify any underlying intentions, or attitudes conveyed through tone, word choice, 
        Include timestamps for significant shifts or particularly impactful moments.
        Try to identify who the speaker is.
        ''';
        final gemini_note_prompt = '''
        Listen intently to the audio file. Distill the essence points into a concise note in $language. 
        Your note should capture the key points and essential information, presented in bullet points, within a 250-word limit. 
        ''';

        _updateProgress(0.6, 'Generating summary with Gemini...');
        final summaryResult = await ApiService.geminiGenerateContent(
            geminiApiKey, file_uri, gemini_summary_prompt);
        if (!summaryResult['success']) {
          throw Exception('Summary Generation Error: ${summaryResult['error']}');
        }
        summary = summaryResult['data'];
        await Future.delayed(Duration(milliseconds: 100));
        _updateProgress(0.8, 'Generating note with Gemini...');
        final noteResult = await ApiService.geminiGenerateContent(
            geminiApiKey, file_uri, gemini_note_prompt);
        if (!noteResult['success']) {
          throw Exception('Note Generation Error: ${noteResult['error']}');
        }
        note = noteResult['data'];
        source = "Gemini-Generated";
      } catch (e) {
        print('Gemini failed: ${e.toString()}');
        _updateProgress(0.5, 'Gemini failed, trying Groq...');

        // If Gemini fails, try Groq
        try {

          final groq_summary_prompt = '''
          Please provide a concise summary of the key points from the following transcript in $language. 
          Focus on the main ideas, important facts, and overall message. Limit your summary to 3-5 sentences. 
          Ensure your response is entirely in $language.
          ----------------------- 
          transcript:
          `$transcription`
          ----------------------- 
          ''';
          final groq_note_prompt = '''
          Based on the transcript provided, generate a set of useful notes in $language. 
          Include key concepts, important details, and any actionable items mentioned. 
          Organize the notes in a clear, easy-to-read format using bullet points or numbered lists where appropriate. 
          Your entire response should be in $language.
          ----------------------- 
          transcript:
          `$transcription`
          ----------------------- 
          ''';

          _updateProgress(0.6, 'Generating summary with Groq...');
          final summaryResult = await ApiService.groqGenerateContent(groq_summary_prompt, groqApiKey);
          if (!summaryResult['success']) {
            throw Exception('Summary Generation Error: ${summaryResult['error']}');
          }
          summary = summaryResult['data'];
          await Future.delayed(Duration(milliseconds: 100));
          final noteResult = await ApiService.groqGenerateContent(groq_note_prompt, groqApiKey);
          if (!noteResult['success']) {
            throw Exception('Note Generation Error: ${noteResult['error']}');
          }
          _updateProgress(0.8, 'Generating note with Groq...');
          note = noteResult['data'];
          source = "Llama-Generated";
        } catch (e) {
          // If both Gemini and Groq fail, show error dialog
          AlertUtils.showErrorDialog(context, 'Generation Error', 'Both Gemini and Groq failed: ${e.toString()}');
          return;
        }
      }
      _updateProgress(1.0, 'Finalizing...');
      setState(() {
        _result = {
          'text': transcription,
          'summary': summary,
          'note': note,
          'source': source,
          'execute_time': DateTime.now().toString(),
        };
        _isGenerating = false;
        _executionTime = _formatDuration(stopwatch.elapsed);
      });
    } catch (e) {
      AlertUtils.showErrorDialog(context, 'Error', 'An unexpected error occurred: ${e.toString()}');
      return;
    } finally {
      stopwatch.stop();
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _saveNote() async {
    if (_result == null) return;

    final title = _titleController.text.isNotEmpty
        ? _titleController.text
        : 'Note from $_fileName';

    await NotesDb.createNote(title, _fileName!, _result!);
    Navigator.pop(context);
  }
  Widget _buildProgressBar() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: _progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        SizedBox(height: 8),
        Text(_statusText, style: TextStyle(fontStyle: FontStyle.italic)),
      ],
    );
  }
}