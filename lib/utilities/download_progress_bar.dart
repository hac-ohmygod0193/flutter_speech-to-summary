import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class DownloadProgressBar extends StatefulWidget {
  final Stream<List<int>> audioStream;
  final int totalLength;

  DownloadProgressBar({required this.audioStream, required this.totalLength});

  @override
  _DownloadProgressBarState createState() => _DownloadProgressBarState();
}

class _DownloadProgressBarState extends State<DownloadProgressBar> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _startListeningToProgress();
  }

  void _startListeningToProgress() async {
    int count = 0;
    await for (final data in widget.audioStream) {
      count += data.length;
      final progress = (count / widget.totalLength) * 100;
      setState(() {
        _progress = progress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: _progress / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        SizedBox(height: 10),
        Text(
          '${_progress.toStringAsFixed(2)}%',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}