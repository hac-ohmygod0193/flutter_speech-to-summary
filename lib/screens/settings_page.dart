import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_keys_db.dart';
import '../services/api_service.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _geminiApiKeyController = TextEditingController();
  final _groqApiKeyController = TextEditingController();
  String? _geminiApiKeyStatus;
  String? _groqApiKeyStatus;
  bool _isSaveButtonEnabled = false;
  bool _isGeminiValidating = false;
  bool _isGroqValidating = false;

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
      _updateSaveButtonState();
    });
  }

  Future<void> _validateApiKey(String apiKey, String serviceName) async {
    setState(() {
      if (serviceName == 'Gemini') {
        _isGeminiValidating = true;
      } else if (serviceName == 'Groq') {
        _isGroqValidating = true;
      }
    });

    bool isValid = await _checkApiKeyValidity(apiKey, serviceName);

    setState(() {
      if (serviceName == 'Gemini') {
        _isGeminiValidating = false;
        _geminiApiKeyStatus = isValid ? 'Valid API Key' : 'Invalid API Key, Please Try Again';
      } else if (serviceName == 'Groq') {
        _isGroqValidating = false;
        _groqApiKeyStatus = isValid ? 'Valid API Key' : 'Invalid API Key, Please Try Again';
      }
      _updateSaveButtonState();
    });
  }

  Future<bool> _checkApiKeyValidity(String apiKey, String serviceName) async {
    if (serviceName == 'Gemini') {
      final result = await ApiService.geminiCheckConnection(apiKey);
      return result['success'] ?? false;
    } else if (serviceName == 'Groq') {
      final result = await ApiService.groqCheckConnection(apiKey);
      return result['success'] ?? false;
    }
    return false;
  }

  void _updateSaveButtonState() {
    setState(() {
      _isSaveButtonEnabled = _geminiApiKeyStatus == 'Valid API Key' && _groqApiKeyStatus == 'Valid API Key';
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
          SizedBox(height: 8),
          _buildValidateButton('Gemini'),
          if (_geminiApiKeyStatus != null)
            Text(
              _geminiApiKeyStatus!,
              style: TextStyle(
                color: _geminiApiKeyStatus == 'Valid API Key' ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
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
          SizedBox(height: 8),
          _buildValidateButton('Groq'),
          if (_groqApiKeyStatus != null)
            Text(
              _groqApiKeyStatus!,
              style: TextStyle(
                color: _groqApiKeyStatus == 'Valid API Key' ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
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
            child: Text(
                'Save API Keys',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            onPressed: _isSaveButtonEnabled ? _saveApiKeys : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSaveButtonEnabled ? Colors.blue : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidateButton(String serviceName) {
    bool isValidating = serviceName == 'Gemini' ? _isGeminiValidating : _isGroqValidating;

    return ElevatedButton(
      onPressed: isValidating
          ? null
          : () => _validateApiKey(
        serviceName == 'Gemini' ? _geminiApiKeyController.text : _groqApiKeyController.text,
        serviceName,
      ),
      child: isValidating
          ? SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      )
          : Text('Validate $serviceName API Key'),
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
