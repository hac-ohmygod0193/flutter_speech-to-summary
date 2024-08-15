import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

Future<Map<String, dynamic>> createFileInDownloads(String fileName) async {
  // Get the downloads directory
  final dir = await getDownloadsDirectory();

  if (dir == null) {
    throw Exception('Downloads directory not found');
  }

  // Build the file path
  final filePath = path.join(dir.path, fileName);

  // Create the file
  final file = File(filePath);

  // Open the file to write (this creates the file if it doesn't exist)
  await file.create(recursive: true);

  // Return both the File object and the filePath
  return {
    'file': file,
    'filePath': filePath,
  };
}