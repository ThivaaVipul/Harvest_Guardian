import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:harvest_guardian/constants.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';

class DiseaseDetailCard extends StatefulWidget {
  final String name;
  final String description;
  final String cure;
  final String imageUrl;

  const DiseaseDetailCard({
    required this.name,
    required this.description,
    required this.cure,
    required this.imageUrl,
    super.key,
  });

  @override
  _DiseaseDetailCardState createState() => _DiseaseDetailCardState();
}

class _DiseaseDetailCardState extends State<DiseaseDetailCard> {
  late FlutterTts flutterTts;
  final translator = GoogleTranslator();

  String selectedLanguage = 'English';
  bool isLoading = false;
  bool isSpeaking = false;

  String translatedName = '';
  String translatedDescription = '';
  String translatedCure = '';
  String translatedCureLabel = 'Cure:';
  String ttsLanguageCode = 'en-US';

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    translatedName = widget.name;
    translatedDescription = widget.description;
    translatedCure = widget.cure;

    // Listener for TTS completion
    flutterTts.setCompletionHandler(() {
      setState(() {
        isSpeaking = false;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        isSpeaking = false;
      });
      Fluttertoast.showToast(msg: "TTS Error: $msg");
    });
  }

  @override
  void dispose() {
    // Stop TTS if it's speaking
    if (isSpeaking) {
      flutterTts.stop();
    }
    super.dispose();
  }

  // Translate the text based on the selected language
  Future<void> translateText(String language) async {
    String targetLanguage = '';
    String ttsLanguage = '';

    switch (language) {
      case 'English':
        targetLanguage = 'en';
        ttsLanguage = 'en-US'; // English TTS
        break;
      case 'Tamil':
        targetLanguage = 'ta';
        ttsLanguage = 'ta-LK'; // Tamil TTS
        break;
      case 'Sinhala':
        targetLanguage = 'si';
        ttsLanguage = 'si-LK'; // Sinhala TTS
        break;
      default:
        targetLanguage = 'en'; // Default to English
        ttsLanguage = 'en-US'; // Default to English TTS
    }

    setState(() {
      isLoading = true; // Show shimmer effect when translation starts
    });

    try {
      var translation =
          await translator.translate(widget.name, to: targetLanguage);
      translatedName = translation.text;

      translation =
          await translator.translate(widget.description, to: targetLanguage);
      translatedDescription = translation.text;

      translation = await translator.translate(widget.cure, to: targetLanguage);
      translatedCure = translation.text;

      // Translate "Cure:" label
      translation = await translator.translate('Cure:', to: targetLanguage);
      translatedCureLabel = translation.text;

      setState(() {
        isLoading = false; // Hide shimmer effect after translation is done
        ttsLanguageCode = ttsLanguage; // Update TTS language code
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error translating text: $e');
      setState(() {
        isLoading = false; // Hide shimmer effect if an error occurs
      });
    }
  }

  void shareDiseaseDetails() async {
    try {
      await FlutterShare.share(
        title: translatedName,
        text:
            "*$translatedName*\n\n$translatedDescription\n\n${translatedCureLabel}\n$translatedCure",
        linkUrl: widget.imageUrl,
        chooserTitle: 'Share via',
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error sharing: $e');
    }
  }

  void toggleAudio() async {
    if (isSpeaking) {
      // Stop the audio
      await flutterTts.stop();
      setState(() {
        isSpeaking = false;
      });
    } else {
      // Start the audio
      try {
        Fluttertoast.showToast(msg: 'Speaking..');
        await flutterTts.setLanguage(ttsLanguageCode); // Set TTS language
        await flutterTts.setPitch(1.0);
        await flutterTts.setSpeechRate(0.5);

        // Speak the translated text
        await flutterTts.speak(
            '$translatedName. $translatedDescription. ${translatedCureLabel} $translatedCure');
        setState(() {
          isSpeaking = true;
        });
      } catch (e) {
        Fluttertoast.showToast(msg: 'Error in TTS: $e');
        setState(() {
          isSpeaking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenImagePage(
                        imageUrl: widget.imageUrl, title: translatedName),
                  ),
                );
              },
              child: CachedNetworkImage(
                imageUrl: widget.imageUrl,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey.withOpacity(0.1),
                  highlightColor: Colors.grey.withOpacity(0.05),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey,
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
                imageBuilder: (context, imageProvider) => Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            isLoading
                ? Shimmer.fromColors(
                    baseColor: Colors.grey.withOpacity(0.1),
                    highlightColor: Colors.grey.withOpacity(0.05),
                    child: Container(
                      width: double.infinity,
                      height: 20,
                      color: Colors.grey,
                    ),
                  )
                : Text(
                    translatedName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            const SizedBox(height: 10),
            isLoading
                ? Shimmer.fromColors(
                    baseColor: Colors.grey.withOpacity(0.1),
                    highlightColor: Colors.grey.withOpacity(0.05),
                    child: Container(
                      width: double.infinity,
                      height: 20,
                      color: Colors.grey,
                    ),
                  )
                : Text(translatedDescription),
            const SizedBox(height: 10),
            Text(
              isLoading ? '...' : translatedCureLabel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            isLoading
                ? Shimmer.fromColors(
                    baseColor: Colors.grey.withOpacity(0.1),
                    highlightColor: Colors.grey.withOpacity(0.05),
                    child: Container(
                      width: double.infinity,
                      height: 20,
                      color: Colors.grey,
                    ),
                  )
                : Text(translatedCure),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Language Selection Button
                PopupMenuButton<String>(
                  onSelected: (String newValue) {
                    setState(() {
                      selectedLanguage = newValue;
                    });
                    translateText(selectedLanguage); // Trigger translation
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'English',
                      child: Row(
                        children: [
                          Icon(Icons.language, color: Colors.blue),
                          SizedBox(width: 10),
                          Text('English'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'Tamil',
                      child: Row(
                        children: [
                          Icon(Icons.language, color: Colors.green),
                          SizedBox(width: 10),
                          Text('Tamil'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'Sinhala',
                      child: Row(
                        children: [
                          Icon(Icons.language, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Sinhala'),
                        ],
                      ),
                    ),
                  ],
                  child: Row(
                    children: [
                      Icon(
                        Icons.language,
                        size: 30,
                        color: Constants.primaryColor,
                      ),
                      SizedBox(width: 5),
                      Text(
                        selectedLanguage,
                        style: TextStyle(
                          color: Constants.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10),

                // Toggle Audio Button
                GestureDetector(
                  onTap: toggleAudio,
                  child: Icon(
                    isSpeaking ? Icons.close : Icons.volume_up,
                    size: 30,
                    color: Constants.primaryColor,
                  ),
                ),
                SizedBox(width: 10),

                // Share Button
                GestureDetector(
                  onTap: shareDiseaseDetails,
                  child: const Icon(
                    Icons.share,
                    size: 30,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;
  final String title;

  const FullScreenImagePage({
    required this.imageUrl,
    required this.title,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Constants.primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: TextStyle(
              color: Constants.primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          Navigator.pop(context);
        },
        child: Center(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: Colors.grey.withOpacity(0.1),
              highlightColor: Colors.grey.withOpacity(0.05),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.grey,
              ),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            imageBuilder: (context, imageProvider) => Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
