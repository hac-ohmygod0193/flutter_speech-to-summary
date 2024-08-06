import 'package:flutter/material.dart';
class LanguageSelector extends StatefulWidget {
  final Function(String?) onLanguageSelected;

  LanguageSelector({required this.onLanguageSelected});

  @override
  _LanguageSelectorState createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  String? _selectedLanguage;
  final List<String> _languages = ['English', 'Traditional Chinese', 'Czech',  'Spanish', 'French', 'German', 'Simplified Chinese'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferred Language for Generation',
            style: TextStyle(fontSize: 16),
          ),
          DropdownButton<String>(
            value: _selectedLanguage,
            hint: Text('Select a language'),
            onChanged: (String? newValue) {
              setState(() {
                _selectedLanguage = newValue;
                widget.onLanguageSelected(newValue);
              });
            },
            items: _languages.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}