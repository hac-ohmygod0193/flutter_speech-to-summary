import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../services/notes_db.dart';
import '../services/api_keys_db.dart';
import '../utilities/alert_utils.dart';
import '../utilities/download_progress_bar.dart';
import '../widgets/language_selector.dart';
import '../widgets/section_widget.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:flutter_speech_to_summary/utilities/get_directory.dart';
import 'dart:convert';

class CreateYTNotePage extends StatefulWidget {
  @override
  _CreateYTNotePageState createState() => _CreateYTNotePageState();
}

class _CreateYTNotePageState extends State<CreateYTNotePage> {
  final _titleController = TextEditingController();
  final _linkController = TextEditingController();
  String? _filePath;
  String? _fileName;
  Map<String, dynamic>? _result;
  bool _isGenerating = false;
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = '';
  String language="English";
  String? _selectedLanguage;
  double _downloadprogress=0.0;

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
                        deleteFile(_filePath);
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
        padding: EdgeInsets.all(16),
        children: [
          if (_result == null) ...[
            Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Create your note title',
                        hintText: 'Default is YT Title',
                        border: OutlineInputBorder(),
                        helperText: 'Enter a descriptive title for your note',
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Insert the URL',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _linkController,
                      decoration: InputDecoration(
                        hintText: 'Enter the YouTube URL',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            if (!_isDownloading) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueAccent,
                ),
                icon: Icon(Icons.link),
                label: Text(_filePath == null ? 'Select Video' : 'Reselect Video'),
                onPressed: _selectYoutubeFile,
              ),
            ] else ...[
              LinearProgressIndicator(
                value: _downloadprogress / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              SizedBox(height: 10),
              Text(
                'Processing... ${_downloadprogress.toStringAsFixed(2)}%',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
            if (_filePath != null) ...[
              SizedBox(height: 16),
              Text(
                'Selected YT Video: $_fileName',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Language',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      LanguageSelector(onLanguageSelected: _handleLanguageSelected),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              if (_selectedLanguage == null)
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Please select a language before generating a note',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                ),
                icon: Icon(Icons.note_add),
                label: Text('Generate Note'),
                onPressed: (_isGenerating || _selectedLanguage == null) ? null : _generateNote,
              ),
            ],
            if (_isGenerating) ...[
              SizedBox(height: 32),
              _buildProgressBar(),
            ],
          ] else ...[
            Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionWidget(
                      title: 'File Information',
                      content: 'File: $_fileName\n'
                          'Execute time: ${_result!['execute_time']}',
                    ),
                    SectionWidget(title: 'Generated by', content: _result!['source']),
                    SectionWidget(title: 'Note', content: _result!['note'], copyable: true),
                    SectionWidget(title: 'Summary', content: _result!['summary'], copyable: true),
                    SectionWidget(
                        title: 'Transcript', content: _result!['text'], copyable: true, scrollable: true),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.greenAccent,
              ),
              child: Text('Save'),
              onPressed: _saveNote,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> deleteFile(String? filePath) async {
    if(filePath==null) return;

    final file = File(filePath);

    if (await file.exists()) {
      await file.delete(); // Asynchronously deletes the file
      // print('File deleted successfully');
    }
  }
  Future<void> _selectYoutubeFile() async {
    try {
      setState(() {
        _isDownloading = true;
        _downloadprogress = 0.0;
      });
      // Here you should validate the given input or else an error
      // will be thrown.
      final yt = YoutubeExplode();
      final id = VideoId(_linkController.text.trim());
      final video = await yt.videos.get(id);

      // Display info about this video.
      // print('Title: ${video.title}, Duration: ${video.duration}');

      // Request permission to write in an external directory.
      // (In this case downloads)

      // Get the streams manifest and the audio track.
      final manifest = await yt.videos.streamsClient.getManifest(id);
      final audio = manifest.audioOnly.last;

      int bytes = audio.size.totalBytes;

      if (bytes != 0) {
        // Check file size (25MB = 25 * 1024 * 1024 bytes)
        if (bytes > 25 * 1024 * 1024) {
          // File is larger than 25MB, show error dialog
          AlertUtils.showErrorDialog(
              context,
              'File Too Large',
              'The selected audio file exceeds the 25MB limit. Please choose a shorter video.'
          );
        } else {
          final audioStream = yt.videos.streamsClient.get(audio);
          // File size is acceptable, Build the directory.
          final fileName = '${video.title}.${audio.container.name}'
              .replaceAll(r'\', '')
              .replaceAll('/', '')
              .replaceAll('*', '')
              .replaceAll('?', '')
              .replaceAll('"', '')
              .replaceAll('<', '')
              .replaceAll('>', '')
              .replaceAll('|', '');
          final result = await createFileInDownloads(fileName);
          File file = result['file'];
          String filePath = result['filePath'];

          // Track the file download status.
          final len = audio.size.totalBytes;
          var count = 0;

          final fileStream = file.openWrite();
          // Listen for data received.
          await for (final data in audioStream) {
            // Keep track of the current downloaded data.
            count += data.length;

            // Calculate the current progress.
            final progress = ((count / len) * 100);
            setState(() {
              _downloadprogress = progress;
            });
            // print(_downloadprogress);
            // Write to file.
            fileStream.add(data);

          }
          await fileStream.close();


          // Show that the file was downloaded.
          // print('Download completed and saved to: $filePath');

          // update state
          setState(() {
            _filePath = filePath;
            _fileName = video.title;
          });
        }
      }
    } catch (e) {
      print('Error picking video: $e');
      AlertUtils.showErrorDialog(
          context,
          'YT video Selection Error',
          'An error occurred while selecting the video: $e'
      );
    }finally {
      setState(() {
        _isDownloading = false;
      });
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
          Below is the video transcript to the audio file. Provide a concise summary of the speaker's message in $language.
          -----------------------
          video transcript:
          `$transcription`
          -----------------------
          Go beyond just facts and identify any intentions, or attitudes conveyed through tone, word choice,
          ''';
          final groq_note_prompt = '''
          Welcome, Video Summarizer! Your task is to distill the essence of a given video transcript into a concise summary in $language. 
          Your summary should capture the key points and essential information, presented in bullet points, within a 250-word limit. 
          Let's dive into the provided transcript and extract the vital details for our audience.
          ----------------------- 
          video transcript:
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
          'text': _ensureUtf8(transcription),
          'summary': _ensureUtf8(summary),
          'note': _ensureUtf8(note),
          'source': source,
          'execute_time': DateTime.now().toString(),
        };
        _isGenerating = false;
      });
    } catch (e) {
      AlertUtils.showErrorDialog(context, 'Error', 'An unexpected error occurred: ${e.toString()}');
      return;
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }
  String _ensureUtf8(String text) {
    try {
      // First, try to decode as UTF-8
      utf8.decode(utf8.encode(text));
      return text; // If successful, it's already UTF-8
    } catch (_) {
      // If UTF-8 decoding fails, assume it's ISO-8859-1 and convert
      return utf8.decode(latin1.encode(text));
    }
  }
  Future<void> _saveNote() async {
    if (_result == null) return;
    deleteFile(_filePath);
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
