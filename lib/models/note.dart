class Note {
  final int id;
  final String title;
  final String fileName;
  final String noteContent;
  final String summary;
  final String transcript;
  final String source;
  final String executeTime;
  final String timestamp;

  Note({
    required this.id,
    required this.title,
    required this.fileName,
    required this.noteContent,
    required this.summary,
    required this.transcript,
    required this.source,
    required this.executeTime,
    required this.timestamp,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    final result = Map<String, dynamic>.from(map['result']);
    return Note(
      id: map['id'],
      title: map['title'],
      fileName: map['file_name'],
      noteContent: result['note'],
      summary: result['summary'],
      transcript: result['text'],
      source: result['source'],
      executeTime: result['execute_time'],
      timestamp: map['timestamp'],
    );
  }
}