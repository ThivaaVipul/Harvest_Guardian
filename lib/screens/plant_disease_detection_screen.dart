// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:math';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:harvest_guardian/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

class PlantDiseaseDetectionPage extends StatefulWidget {
  const PlantDiseaseDetectionPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PlantDiseaseDetectionPageState createState() =>
      _PlantDiseaseDetectionPageState();
}

class _PlantDiseaseDetectionPageState extends State<PlantDiseaseDetectionPage> {
  final picker = ImagePicker();
  List<dynamic>? _predictions;
  XFile? _imageFile;
  List<String> _labels = [];

  @override
  void initState() {
    super.initState();
    _loadModel();
    _loadLabels();
  }

  Future<void> _loadModel() async {
    await Tflite.loadModel(
      model: 'assets/plant_disease_model.tflite',
      labels: 'assets/plant_disease_labels.txt',
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
      _predictImage(pickedFile.path);
    }
  }

  Future<void> _loadLabels() async {
    final String labels = await DefaultAssetBundle.of(context)
        .loadString('assets/plant_disease_labels.txt');
    setState(() {
      _labels = labels.split('\n').where((label) => label.isNotEmpty).toList();
      _labels.add("Other");
    });
  }

  Future<void> _predictImage(String imagePath) async {
    final List<dynamic>? predictions = await Tflite.runModelOnImage(
      path: imagePath,
      numResults: 5,
      threshold: 0.1,
    );

    if (predictions != null) {
      setState(() {
        _predictions = predictions;
      });
    }
  }

  void _handleFeedback(bool isCorrect, String? selectedLabel) async {
    if (_imageFile != null && _predictions != null) {
      if (!isCorrect && selectedLabel != null) {
        if (selectedLabel == "Other") {
          _showCustomLabelDialog();
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Confirm"),
                content: Text("Is \"$selectedLabel\" the correct label?"),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _uploadImageToFirebase(selectedLabel);
                    },
                    child: const Text("Yes"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Select Label"),
                            content: SingleChildScrollView(
                              child: Column(
                                children: [
                                  ..._labels.map((innerLabel) {
                                    return ListTile(
                                      title: Text(innerLabel),
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        _handleFeedback(false, innerLabel);
                                      },
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: const Text("No"),
                  ),
                ],
              );
            },
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Thanks for the feedback!"),
          ),
        );
      }
    }
  }

  Future<void> _uploadImageToFirebase(String selectedLabel) async {
    final FirebaseStorage storage = FirebaseStorage.instance;
    final String imageName =
        "${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}.jpg";
    final Reference ref = storage
        .ref()
        .child("New_Training_Images")
        .child(selectedLabel)
        .child(imageName);
    final File file = File(_imageFile!.path);

    await ref.putFile(file);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Image uploaded! Thanks For Your Feedback."),
      ),
    );
  }

  Future<void> _showCustomLabelDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController customLabelController = TextEditingController();
        return AlertDialog(
          title: const Text("Enter Custom Label"),
          content: TextField(
            controller: customLabelController,
            decoration: const InputDecoration(hintText: "Custom Label"),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                String customLabel = customLabelController.text;
                if (customLabel.isNotEmpty) {
                  _uploadImageToFirebase(customLabel);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter a label."),
                    ),
                  );
                }
              },
              child: const Text("Submit"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Disease Detection',
          style: TextStyle(
            color: Constants.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.popUntil(context, ModalRoute.withName('/'));
          },
          icon: Icon(
            Icons.arrow_back,
            size: 30,
            color: Constants.primaryColor,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Experimental Feature\nNot Perfect',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            if (_imageFile != null)
              Image.file(
                File(_imageFile!.path),
                height: 200,
                width: 200,
                fit: BoxFit.cover,
              ),
            const SizedBox(
              height: 30,
            ),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery),
              child: const Text('Select Image'),
            ),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.camera),
              child: const Text('Take Picture'),
            ),
            const SizedBox(
              height: 30,
            ),
            if (_predictions != null)
              Column(
                children: [
                  ..._predictions!.map((prediction) {
                    return Text(
                      '${prediction['label']} (${(prediction['confidence'] * 100).toStringAsFixed(2)}%)',
                      style: TextStyle(
                          fontSize: 20,
                          color: Constants.primaryColor,
                          fontWeight: FontWeight.bold),
                    );
                  }),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Confirm"),
                                content:
                                    const Text("Is the prediction correct?"),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _handleFeedback(true, null);
                                    },
                                    child: const Text("Yes"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text("Select Label"),
                                            content: SingleChildScrollView(
                                              child: Column(
                                                children: [
                                                  ..._labels.map((label) {
                                                    return ListTile(
                                                      title: Text(label),
                                                      onTap: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                        _handleFeedback(
                                                            false, label);
                                                      },
                                                    );
                                                  }),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: const Text("No"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Text('Correct'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Select Label"),
                                content: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      ..._labels.map((label) {
                                        return ListTile(
                                          title: Text(label),
                                          onTap: () {
                                            Navigator.of(context).pop();
                                            _handleFeedback(false, label);
                                          },
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: const Text('Incorrect'),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
