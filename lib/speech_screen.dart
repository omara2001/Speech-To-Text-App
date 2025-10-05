import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  _SpeechScreenState createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts flutterTts = FlutterTts();
  bool _isListening = false;
  bool _isSpeaking = false;
  String _text = 'Press the button and start speaking';
  double _confidence = 1.0;
  String _selectedLanguage = 'en-US';

  final List<Map<String, String>> _languages = [
    {'name': 'English (US)', 'code': 'en-US'},
    {'name': 'Spanish', 'code': 'es-ES'},
    {'name': 'French', 'code': 'fr-FR'},
    {'name': 'German', 'code': 'de-DE'},
    {'name': 'Italian', 'code': 'it-IT'},
    {'name': 'Japanese', 'code': 'ja-JP'},
    {'name': 'Korean', 'code': 'ko-KR'},
    {'name': 'Chinese (Mandarin)', 'code': 'zh-CN'},
    {'name': 'Russian', 'code': 'ru-RU'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeSpeechRecognition();
    _initializeTextToSpeech();
  }

  void _initializeSpeechRecognition() async {
    await _speech.initialize(
      onStatus: (status) => print('Speech recognition status: $status'),
      onError: (errorNotification) => print('Speech recognition error: $errorNotification'),
    );
  }

  void _initializeTextToSpeech() async {
    await flutterTts.setLanguage(_selectedLanguage);
    flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) => print('Speech recognition status: $status'),
        onError: (errorNotification) => print('Speech recognition error: $errorNotification'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) => setState(() {
            _text = result.recognizedWords;
            if (result.hasConfidenceRating && result.confidence > 0) {
              _confidence = result.confidence;
            }
          }),
          localeId: _selectedLanguage,
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _speak() async {
    if (!_isSpeaking) {
      setState(() => _isSpeaking = true);
      await flutterTts.setLanguage(_selectedLanguage);
      await flutterTts.speak(_text);
    } else {
      setState(() => _isSpeaking = false);
      await flutterTts.stop();
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Text copied to clipboard')),
    );
  }

  Future<void> _downloadAudio() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/speech.wav');
    await flutterTts.synthesizeToFile(_text, file.path);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Audio saved to ${file.path}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Speech to Text'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 150.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  value: _selectedLanguage,
                  icon: const Icon(Icons.arrow_downward),
                  iconSize: 24,
                  elevation: 16,
                  style: const TextStyle(color: Colors.deepPurple),
                  underline: Container(
                    height: 2,
                    color: Colors.deepPurpleAccent,
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedLanguage = newValue!;
                    });
                  },
                  items: _languages.map<DropdownMenuItem<String>>((Map<String, String> value) {
                    return DropdownMenuItem<String>(
                      value: value['code'],
                      child: Text(value['name']!),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w200,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                _text,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    onPressed: _copyToClipboard,
                    tooltip: 'Copy to Clipboard',
                    child: Icon(Icons.content_copy),
                  ),
                  SizedBox(width: 20),
                  AvatarGlow(
                    animate: _isListening,
                    glowColor: Theme.of(context).primaryColor,
                    endRadius: 75.0,
                    duration: const Duration(milliseconds: 2000),
                    repeatPauseDuration: const Duration(milliseconds: 100),
                    repeat: true,
                    child: FloatingActionButton(
                      onPressed: _listen,
                      child: Icon(_isListening ? Icons.mic : Icons.mic_none),
                    ),
                  ),
                  SizedBox(width: 20),
                  FloatingActionButton(
                    onPressed: _speak,
                    tooltip: 'Speak',
                    child: Icon(_isSpeaking ? Icons.volume_off : Icons.volume_up),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    onPressed: _downloadAudio,
                    tooltip: 'Download Audio',
                    child: Icon(Icons.download),
                  ),
                  SizedBox(width: 20),
                  FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        _text = '';
                      });
                    },
                    tooltip: 'Clear Text',
                    child: Icon(Icons.clear),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

