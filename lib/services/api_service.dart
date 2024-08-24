import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
class ApiService {
  static const String _geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String _groqBaseUrl = 'https://api.groq.com/openai/v1';
  static Future<Map<String, dynamic>> uploadToGemini(String apiKey, File file, {String mimeType = "audio/mpeg"}) async {
    // Get file size
    int fileSize = await file.length();
    print(fileSize);

    // Read file as bytes
    List<int> fileBytes = await file.readAsBytes();

    // Prepare the upload request
    var uri = Uri.parse("https://generativelanguage.googleapis.com/upload/v1beta/files?key=$apiKey");
    var request = http.MultipartRequest('POST', uri);

    // Add headers
    request.headers.addAll({
      "X-Goog-Upload-Command": "start, upload, finalize",
      "X-Goog-Upload-Header-Content-Length": fileSize.toString(),
      "X-Goog-Upload-Header-Content-Type": mimeType,
      "Content-Type": mimeType,
    });

    // Add file to the request
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: file.path.split('/').last,
      contentType: MediaType.parse(mimeType),
    ));

    // Send the request
    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    try {
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(responseBody);
        String fileUri = jsonResponse['file']['uri'];
        print("Uploaded file '${file.path}' as: $fileUri");
        return {'success': true, 'data': fileUri};
      } else {
        return {'success': false, 'error': 'File upload failed: ${responseBody}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> geminiCheckConnection(String apiKey) async {
    final uri = Uri.parse('$_geminiBaseUrl/models/gemini-1.5-pro-latest:generateContent?key=$apiKey');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': 'hello'}
              ]
            },
          ],
          'safetySettings': [
            {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'},
          ]
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return {'success': true, 'data': jsonResponse['candidates'][0]['content']['parts'][0]['text']};
      } else {
        return {'success': false, 'error': 'Your API key is not working: ${response.body}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }

  }
  static Future<Map<String, dynamic>> geminiGenerateContent(String apiKey, String fileUri, String prompt) async {
    final uri = Uri.parse('$_geminiBaseUrl/models/gemini-1.5-pro-latest:generateContent?key=$apiKey');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt}
              ]
            },
            {
              'role': 'user',
              'parts': [
                {
                  'fileData': {
                    'fileUri': fileUri,
                    'mimeType': 'audio/mpeg'
                  }
                }
              ]
            },

          ],
          'safetySettings': [
            {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'},
          ]
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return {'success': true, 'data': jsonResponse['candidates'][0]['content']['parts'][0]['text']};
      } else {
        return {'success': false, 'error': 'Generate content failed: ${response.body}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> geminiGenerateAnswer(String apiKey, String transcription, String question) async {
    final uri = Uri.parse('$_geminiBaseUrl/models/gemini-1.5-pro-latest:generateContent?key=$apiKey');
    try {
      String prompt="""I will now provide you with the full transcription. Please process and analyze this information, organizing the key concepts, main topics, and important details in your memory.

                              [TRANSCRIPTION]
                              $transcription
                      
                              Once you have processed the entire transcription, respond with: 'Transcription received and processed. Ready for questions'.
                      
                              For all subsequent questions I ask, please follow these guidelines:
                              1. Answer based solely on the course transcription provided above.
                              2. Treat each question as if it were the first, ensuring consistent quality and accuracy.
                              3. Provide concise responses using only information from the course material.
                              4. If a question cannot be answered based on the transcription, state that the information is not available.
                              5. Always respond in the same language as the question.
                      
                              You don't need to repeat these instructions; just answer the questions directly.""";
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': json.encode(prompt)}
              ]
            },
            {
              'role': 'user',
              'parts': [
                {'text': 'Transcription received and processed. Ready for questions'}
              ]
            },
            {
              'role': 'user',
              'parts': [
                {'text': json.encode(question)}
              ]
            },
          ],
          'safetySettings': [
            {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'},
          ]
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return {'success': true, 'data': jsonResponse['candidates'][0]['content']['parts'][0]['text']};
      } else {
        return {'success': false, 'error': 'Generate content failed: ${response.body}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> transcribeAudio(File file, String apiKey) async {
    final uri = Uri.parse('$_groqBaseUrl/audio/transcriptions');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..files.add(await http.MultipartFile.fromPath('file', file.path))
      ..fields['model'] = 'whisper-large-v3'
      ..fields['response_format'] = 'verbose_json';

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseBody);
        return {'success': true, 'data': jsonResponse['text']};
      } else {
        return {'success': false, 'error': 'Transcription failed: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }
  static Future<Map<String, dynamic>> groqCheckConnection(String apiKey) async {
    final uri = Uri.parse('$_groqBaseUrl/chat/completions');
    try {

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $apiKey',
        },
        body: utf8.encode(json.encode({
          'messages': [
            {'role': 'user', 'content': 'hi'}
          ],
          'model': 'llama-3.1-70b-versatile',
          'temperature': 0,
        })),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        return {'success': true, 'data': jsonResponse['choices'][0]['message']['content']};
      } else {
        return {'success': false, 'error': 'Request failed: ${response.body}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }
  static Future<Map<String, dynamic>> groqGenerateContent(String prompt, String apiKey) async {
    final uri = Uri.parse('$_groqBaseUrl/chat/completions');
    try {

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $apiKey',
        },
        body: utf8.encode(json.encode({
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'model': 'llama-3.1-70b-versatile',
          'temperature': 0,
        })),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        return {'success': true, 'data': jsonResponse['choices'][0]['message']['content']};
      } else {
        return {'success': false, 'error': 'Request failed: ${response.body}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }
  static Future<Map<String, dynamic>> groqGenerateAnswer(String apiKey, String transcription, String question) async {
    final uri = Uri.parse('$_groqBaseUrl/chat/completions');
    try {
      String prompt="""I will now provide you with the full transcription. Please process and analyze this information, organizing the key concepts, main topics, and important details in your memory.

                              Once you have processed the entire transcription, respond with: 'Transcription received and processed. Ready for questions.'
                      
                              For all subsequent questions I ask, please follow these guidelines:
                              1. Answer based solely on the course transcription provided above.
                              2. Treat each question as if it were the first, ensuring consistent quality and accuracy.
                              3. Provide concise responses using only information from the course material.
                              4. If a question cannot be answered based on the transcription, state that the information is not available.
                              5. Always respond in the same language as the question.
                      
                              You don't need to repeat these instructions; just answer the questions directly.""";
      String TRANSCRIPTION="""Here is Transcripton:
                              $transcription""";

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $apiKey',
        },
        body: utf8.encode(json.encode({
          'messages': [
            {'role': 'system', 'content': json.encode(prompt)},
            {'role': 'user', 'content': json.encode(TRANSCRIPTION)},
            {'role': 'assistant', 'content': 'Transcription received and processed. Ready for questions.'},
            {'role': 'user', 'content': json.encode(question)}
          ],
          'model': 'llama-3.1-70b-versatile',
          'temperature': 0,
        })),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        return {'success': true, 'data': jsonResponse['choices'][0]['message']['content']};
      } else {
        return {'success': false, 'error': 'Request failed: ${response.body}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }
}