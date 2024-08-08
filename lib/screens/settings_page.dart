import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_keys_db.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _geminiApiKeyController = TextEditingController();
  final _groqApiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApiKeys();
  }

  Future<void> _loadApiKeys() async {
    final (geminiApiKey, groqApiKey) = await ApiKeysDb.loadApiKeys();
    setState(() {
      _geminiApiKeyController.text = geminiApiKey ?? '';
      _groqApiKeyController.text = groqApiKey ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('API Key Settings'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildInfoBox(
            'Gemini API Key Setup',
            'To get your Gemini API key, visit:',
            'https://ai.google.dev/gemini-api/docs/api-key',
          ),
          SizedBox(height: 16),
          TextField(
            controller: _geminiApiKeyController,
            decoration: InputDecoration(
              labelText: 'Gemini API Key',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 32),
          _buildInfoBox(
            'Groq API Key Setup',
            'To get your Groq API key, visit:',
            'https://console.groq.com/docs/',
          ),
          SizedBox(height: 16),
          TextField(
            controller: _groqApiKeyController,
            decoration: InputDecoration(
              labelText: 'Groq API Key',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'You must add both API keys to continue.',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton(
            child: Text('Save API Keys'),
            onPressed: _saveApiKeys,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String title, String description, String url) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(description),
          InkWell(
            child: Text(
              url,
              style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
            ),
            onTap: () => _launchURL(url),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  Future<void> _saveApiKeys() async {
    await ApiKeysDb.saveKeys(
      _geminiApiKeyController.text,
      _groqApiKeyController.text,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('API keys saved')),
    );
    Navigator.pop(context);
  }
}