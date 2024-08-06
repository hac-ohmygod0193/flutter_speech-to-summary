import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class SectionWidget extends StatelessWidget {
  final String title;
  final String content;
  final bool copyable;
  final bool scrollable;

  const SectionWidget({
    Key? key,
    required this.title,
    required this.content,
    this.copyable = false,
    this.scrollable = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (copyable)
                IconButton(
                  icon: Icon(Icons.copy, size: 20),
                  onPressed: () => _copyToClipboard(context),
                ),
            ],
          ),
          SizedBox(height: 8),
          if (scrollable)
            Container(
              height: 200,
              child: SingleChildScrollView(
                child: MarkdownBody(data: content, styleSheet: MarkdownStyleSheet(
                p: TextStyle(fontFamily: 'NotoSansSC'), // Example of a Chinese-supporting font
                // Add other text styles as needed
              ),),
              ),
            )
          else
            MarkdownBody(data: content, styleSheet: MarkdownStyleSheet(
              p: TextStyle(fontFamily: 'NotoSansSC'), // Example of a Chinese-supporting font
              // Add other text styles as needed
            ),),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied to clipboard')),
    );
  }
}