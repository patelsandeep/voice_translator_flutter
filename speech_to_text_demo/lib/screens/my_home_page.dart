import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:text_to_speech/text_to_speech.dart';
import 'package:translator/translator.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  String _convertedWords = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    setState(() => _convertedWords = '');
    await _speechToText.listen(
      onResult: _onSpeechResult,
      onDevice: true,
      listenFor: const Duration(seconds: 30),
    );
    setState(() {});
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on thef
  /// listen method.
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() => _lastWords = result.recognizedWords);
    if (result.finalResult) {
      translateText(_lastWords);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Recognized words:',
                style: TextStyle(fontSize: 20.0),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  // If listening is active show the recognized words
                  _speechToText.isListening
                      ? _lastWords
                      // If listening isn't active but could be tell the user
                      // how to start it, otherwise indicate that speech
                      // recognition is not yet ready or not supported on
                      // the target device
                      : _speechEnabled
                          ? 'Long press & hold the microphone to start listening...'
                          : 'Speech not available',
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                    // If listening is active show the recognized words
                    _convertedWords),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: GestureDetector(
        onLongPressDown: (details) {
          _startListening();
        },
        onLongPressUp: () {
          _stopListening();
        },
        onTap: _speechToText.isNotListening ? _startListening : _stopListening,
        child: Container(
          height: 70,
          width: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: kElevationToShadow[2],
            color: Theme.of(context).primaryColor,
          ),
          child: Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic,
              color: Colors.white),
        ),
      ),
    );
  }

  Future<void> translateText(String recognizedWords) async {
    final translator = GoogleTranslator();
    final input = recognizedWords;

    translator.translate(input, from: 'en', to: 'hi').then((result) {
      if (kDebugMode) print("RESULT :: $result");
      setState(() => _convertedWords = result.toString());
      if (kDebugMode) print("CONVERTED WORDS :: $_convertedWords");
      TextToSpeech tts = TextToSpeech();
      tts.setVolume(1);
      tts.setRate(1);
      tts.setPitch(1);
      tts.setLanguage('hi');
      tts.speak(_convertedWords);
    });

    // // Passing the translation to a variable
    // var translation = await translator
    //     .translate("I would buy a car, if I had money.", from: 'en', to: 'it');

    // // You can also call the extension method directly on the input
    // print('Translated: ${await input.translate(to: 'en')}');

    // // For countries that default base URL doesn't work
    // translator.baseUrl = "translate.google.cn";
    // translator.translateAndPrint("This means 'testing' in chinese",
    //     to: 'zh-cn');
    // //prints 这意味着用中文'测试'

    // print("translation: $translation");
  }
}
