import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:harvest_guardian/constants.dart';
import 'package:harvest_guardian/screens/add_blog_post_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
import '../widgets/disease_detail.dart';

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
  List<Disease> _diseases = [];

  @override
  void initState() {
    super.initState();
    _loadModel();
    _loadLabels();
    _loadDiseaseData();
  }

  Future<void> _loadModel() async {
    await Tflite.loadModel(
      model: 'assets/plant_disease_model.tflite',
      labels: 'assets/plant_disease_labels.txt',
    );
  }

  Future<void> _loadLabels() async {
    final String labels = await DefaultAssetBundle.of(context)
        .loadString('assets/plant_disease_labels.txt');
    setState(() {
      _labels = labels.split('\n').where((label) => label.isNotEmpty).toList();
      // _labels.add("Other");
    });
  }

  Future<void> _loadDiseaseData() async {
    final String response =
        await rootBundle.loadString('assets/disease_data.json');
    final List<dynamic> data = json.decode(response);
    setState(() {
      _diseases = data.map((d) => Disease.fromJson(d)).toList();
    });
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

  Future<void> _predictImage(String imagePath) async {
    final List<dynamic>? predictions = await Tflite.runModelOnImage(
      path: imagePath,
      numResults: 1,
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
        Fluttertoast.showToast(
          msg: 'Thanks for the feedback!',
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
    Fluttertoast.showToast(
      msg: 'Image uploaded! Thanks For Your Feedback.',
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
                  Fluttertoast.showToast(
                    msg: 'Please enter a label.',
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
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back,
            size: 30,
            color: Constants.primaryColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_predictions == null)
                SizedBox(
                  height: 200,
                ),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5), // Light grey background
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Experimental Feature\nNot Perfect',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87, // Darker text for better contrast
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
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
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => _pickImage(ImageSource.gallery),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Constants.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(
                  'Select Image',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _pickImage(ImageSource.camera),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Constants.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(
                  'Take Picture',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // In the PlantDiseaseDetectionPage
              if (_predictions != null)
                Column(
                  children: [
                    ..._predictions!.map((prediction) {
                      final disease = _diseases.firstWhere(
                        (d) =>
                            d.name.trim().toLowerCase() ==
                            prediction['label'].trim().toLowerCase(),
                        orElse: () => Disease(
                          name: 'Unknown',
                          description: 'No description available.',
                          cure: 'No cure available.',
                          img:
                              'https://cdn.britannica.com/26/152026-050-41D137DE/Sunshine-leaves-beech-tree.jpg',
                        ),
                      );

                      return DiseaseDetailCard(
                        name: disease.name,
                        description: disease.description,
                        cure: disease.cure,
                        imageUrl: disease.img,
                      );
                    }),
                    const SizedBox(height: 20),

                    // New Label and Button for suggesting users to post in the community
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFF5F5F5), // Light grey background
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'The prediction might not be accurate. If you feel unsure, please share your issue with the community!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () {
                        // Navigate to AddPostPage with the image preloaded
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                AddBlogPost(imagePath: _imageFile!.path),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Constants.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                        padding:
                            EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: Text(
                        'Share with Community',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFF5F5F5), // Light grey background
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Does this diagnosis match your observation?\nIf not, please share the image and disease name if you know.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

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
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor:
                                Constants.primaryColor.withOpacity(0.9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 5,
                            padding: EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                          ),
                          child: Text(
                            'Correct',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor:
                                Constants.primaryColor.withOpacity(0.9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 5,
                            padding: EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                          ),
                          child: Text(
                            'Incorrect',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
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

class Disease {
  final String name;
  final String description;
  final String cure;
  final String img;

  Disease({
    required this.name,
    required this.description,
    required this.cure,
    required this.img,
  });

  factory Disease.fromJson(Map<String, dynamic> json) {
    return Disease(
      name: json['name'],
      description: json['description'],
      cure: json['cure'],
      img: json['img'],
    );
  }
}
