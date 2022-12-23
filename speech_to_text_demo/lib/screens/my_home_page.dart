import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text_demo/utils/constants.dart';
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
  bool isListening = false;
  String _lastWords = '';
  String _convertedWords = '';

  Map lang = {};
  String from = 'en_US';
  String to = 'hi_IN';

  @override
  void initState() {
    super.initState();
    lang = languages;
    lang.removeWhere((key, value) => !key.contains('_'));
    _initSpeech();
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    setState(() {
      _lastWords = '';
      _convertedWords = '';
      isListening = true;
    });
    await _speechToText.listen(
      onResult: _onSpeechResult,
      onDevice: true,
      listenFor: const Duration(seconds: 30),
      localeId: from,
    );
    setState(() {});
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on thef
  /// listen method.
  void _stopListening() async {
    await _speechToText.stop();
    setState(() => isListening = false);
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() => _lastWords = result.recognizedWords);
    if (result.finalResult) {
      translateText(_lastWords);
    }
  }

  String getLanguageCode(String? locale) {
    return locale?.split('_').first ?? '';
  }

  showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void translateText(String recognizedWords) {
    final translator = GoogleTranslator();
    final input = recognizedWords;

    final fromCode = getLanguageCode(from);
    final toCode = getLanguageCode(to);

    translator
        .translate(input, from: fromCode, to: toCode)
        .then((result) async {
      if (kDebugMode) print("RESULT :: $result");
      setState(() => _convertedWords = result.toString());
      if (kDebugMode) print("CONVERTED WORDS :: $_convertedWords");

      TextToSpeech tts = TextToSpeech();

      tts.setVolume(1);
      tts.setRate(1);
      tts.setPitch(1);
      tts.setLanguage(toCode);
      tts.speak(_convertedWords);
    }).catchError(
      (e) {
        showMessage(e.toString());
      },
    );

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

  Widget getDropDown({bool isFrom = true}) {
    return DropdownButtonFormField<String>(
      borderRadius: BorderRadius.circular(8),
      focusColor: Colors.transparent,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: false,
        labelText: isFrom ? 'From' : 'To',
        labelStyle: const TextStyle(fontSize: 16, color: Colors.black),
        isDense: true,
      ),
      autofocus: false,
      value: isFrom ? from : to,
      items: lang.values
          .map((e) => DropdownMenuItem<String>(
                value: lang.keys
                    .singleWhere((key) => lang[key] == e, orElse: () => ''),
                child: Text(e),
              ))
          .toList(),
      onChanged: (String? selectedLanguage) {
        if (isFrom) {
          setState(() => from = selectedLanguage ?? '');
        } else {
          setState(() => to = selectedLanguage ?? '');
        }

        FocusScope.of(context).unfocus();
      },
    );
  }

  Widget languagesRow() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: getDropDown(),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: getDropDown(
              isFrom: false,
            ),
          ),
        ],
      ),
    );
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
            languagesRow(),
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
                child: Column(
                  children: [
                    Text(
                      // If listening is active show the recognized words
                      isListening
                          ? _lastWords
                          // If listening isn't active but could be tell the user
                          // how to start it, otherwise indicate that speech
                          // recognition is not yet ready or not supported on
                          // the target device
                          : _speechEnabled
                              ? 'Long press & hold the microphone to start listening...'
                              : 'Speech not available',
                    ),
                  ],
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
        onTap: !isListening ? _startListening : _stopListening,
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
}
