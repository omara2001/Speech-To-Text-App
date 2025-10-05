import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

enum TtsState { playing, stopped, paused }

class TextToSpeechScreen extends StatefulWidget {
  const TextToSpeechScreen({super.key});

  @override
  _TextToSpeechScreenState createState() => _TextToSpeechScreenState();
}

class _TextToSpeechScreenState extends State<TextToSpeechScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _speakerNameController = TextEditingController();
  String _selectedLanguage = 'en-US';
  double _volume = 1.0;
  double _pitch = 1.0;
  double _rate = 0.5;
  TtsState ttsState = TtsState.stopped;
  String _speakerName = '';
  String get _text => _textController.text;
  int _currentWordIndex = 0;

  List<String> _languages = [];
  final List<Map<String, String>> _languageList = [
    {'name': 'English (US)', 'code': 'en-US'},
    {'name': 'Spanish', 'code': 'es-ES'},
    {'name': 'French', 'code': 'fr-FR'},
    {'name': 'German', 'code': 'de-DE'},
    {'name': 'Italian', 'code': 'it-IT'},
    {'name': 'Japanese', 'code': 'ja-JP'},
    {'name': 'Korean', 'code': 'ko-KR'},
    {'name': 'Chinese (Mandarin)', 'code': 'zh-CN'},
    {'name': 'Russian', 'code': 'ru-RU'},
    {'name': 'Arabic', 'code': 'ar-SA'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  void _initializeTts() async {
    await flutterTts.setLanguage(_selectedLanguage);
    await flutterTts.setVolume(_volume);
    await flutterTts.setPitch(_pitch);
    await flutterTts.setSpeechRate(_rate);

    flutterTts.setProgressHandler((String text, int startOffset, int endOffset, String word) {
      setState(() {
        _currentWordIndex = _text.substring(0, startOffset).split(' ').length - 1;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        ttsState = TtsState.stopped;
        _currentWordIndex = 0;
      });
    });

    var languages = await flutterTts.getLanguages;
    setState(() {
      _languages = List<String>.from(languages);
    });
  }

  Future<void> _speak() async {
    if (_text.isNotEmpty) {
      if (ttsState == TtsState.paused) {
        await _resume();
      } else {
        await flutterTts.speak(_text);
        setState(() {
          ttsState = TtsState.playing;
        });
      }
    }
  }

  Future<void> _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) {
      setState(() {
        ttsState = TtsState.stopped;
        _currentWordIndex = 0;
      });
    }
  }

  Future<void> _pause() async {
    var result = await flutterTts.pause();
    if (result == 1) {
      setState(() {
        ttsState = TtsState.paused;
      });
    }
  }

  Future<void> _resume() async {
    String remainingText = _text.split(' ').sublist(_currentWordIndex).join(' ');
    await flutterTts.speak(remainingText);
    setState(() {
      ttsState = TtsState.playing;
    });
  }

  Future<void> _downloadAudio() async {
    if (_text.isNotEmpty) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = _speakerName.isNotEmpty ? '${_speakerName}_audio.wav' : 'tts_audio.wav';
      final file = File('${directory.path}/$fileName');
      await flutterTts.synthesizeToFile(_text, file.path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Audio saved as $fileName')),
      );
    }
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
            SizedBox(
              width: 50,
              child: Text(value.toStringAsFixed(2)),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Text to Speech'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _speakerNameController,
              decoration: InputDecoration(
                labelText: 'Speaker Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _speakerName = value;
                });
              },
            ),
            SizedBox(height: 20),
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Enter text to speak',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: InputDecoration(
                labelText: 'Select Language',
                border: OutlineInputBorder(),
              ),
              items: _languageList.map((lang) {
                return DropdownMenuItem(
                  value: lang['code'],
                  child: Text(lang['name']!),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedLanguage = newValue!;
                  flutterTts.setLanguage(_selectedLanguage);
                });
              },
            ),
            SizedBox(height: 20),
            _buildSlider(
              label: 'Volume',
              value: _volume,
              min: 0.0,
              max: 1.0,
              onChanged: (value) {
                setState(() {
                  _volume = value;
                  flutterTts.setVolume(_volume);
                });
              },
            ),
            _buildSlider(
              label: 'Pitch',
              value: _pitch,
              min: 0.5,
              max: 2.0,
              onChanged: (value) {
                setState(() {
                  _pitch = value;
                  flutterTts.setPitch(_pitch);
                });
              },
            ),
            _buildSlider(
              label: 'Rate',
              value: _rate,
              min: 0.0,
              max: 1.0,
              onChanged: (value) {
                setState(() {
                  _rate = value;
                  flutterTts.setSpeechRate(_rate);
                });
              },
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: (ttsState == TtsState.stopped || ttsState == TtsState.paused) ? _speak : _stop,
                  icon: Icon((ttsState == TtsState.stopped || ttsState == TtsState.paused) ? Icons.play_arrow : Icons.stop),
                  label: Text((ttsState == TtsState.stopped || ttsState == TtsState.paused) ? 'Speak' : 'Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (ttsState == TtsState.stopped || ttsState == TtsState.paused) ? Colors.green : Colors.red,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: ttsState == TtsState.playing ? _pause : (ttsState == TtsState.paused ? _resume : null),
                  icon: Icon(ttsState == TtsState.paused ? Icons.play_arrow : Icons.pause),
                  label: Text(ttsState == TtsState.paused ? 'Resume' : 'Pause'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ttsState == TtsState.paused ? Colors.green : Colors.orange,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _downloadAudio,
                  icon: Icon(Icons.download),
                  label: Text('Download'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}







