// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:harvest_guardian/constants.dart';
import 'package:image_picker/image_picker.dart';

class AddBlogPost extends StatefulWidget {
  const AddBlogPost({super.key});

  @override
  State<AddBlogPost> createState() => _AddBlogPostState();
}

class _AddBlogPostState extends State<AddBlogPost> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = false;

  File? _image;

  final picker = ImagePicker();

  Future _getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        Fluttertoast.showToast(msg: 'No image selected.');
      }
    });
  }

  Future<void> _uploadBlogPost() async {
    FocusScope.of(context).unfocus();
    if (_image == null) {
      Fluttertoast.showToast(msg: "Select Image First");
      return;
    } else if (_titleController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Add Title");
      return;
    } else if (_descriptionController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Add Description");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Reference storageReference = FirebaseStorage.instance
          .ref()
          .child("BlogImages")
          .child(
              '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}.jpg');
      UploadTask uploadTask = storageReference.putFile(_image!);
      await uploadTask;

      String downloadUrl = await storageReference.getDownloadURL();

      int timestamp = DateTime.now().millisecondsSinceEpoch;
      String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;

      Map<String, dynamic> data = {
        'image': downloadUrl,
        'desc': _descriptionController.text.toString(),
        'title': _titleController.text.toString(),
        'likes': [],
        'timestamp': timestamp,
        'userEmail': currentUserEmail,
      };

      String blogId = FirebaseDatabase.instance.ref("Blogs").push().key!;
      await FirebaseDatabase.instance.ref("Blogs").child(blogId).set(data);

      Fluttertoast.showToast(msg: "Post Added Successfully");

      setState(() {
        _isLoading = false;
      });
      Navigator.pop(context);
    } catch (error) {
      Fluttertoast.showToast(msg: "Error uploading post: $error");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.3,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(
            Icons.arrow_back,
            size: 30,
            color: Constants.primaryColor,
          ),
        ),
        title: Text(
          'Add New Post',
          style: TextStyle(
            color: Constants.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          margin: const EdgeInsets.all(15),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              Container(
                decoration: BoxDecoration(
                    border:
                        Border.all(color: Constants.primaryColor, width: 0.5)),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: _image != null
                          ? Image(
                              width: MediaQuery.of(context).size.width,
                              height: 250.0,
                              image: FileImage(_image!),
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                            )
                          : InkWell(
                              onTap: _getImage,
                              splashColor:
                                  Constants.primaryColor.withOpacity(0.2),
                              child: SizedBox(
                                height: 250,
                                child: Center(
                                  child: Icon(
                                    Icons.add_photo_alternate_rounded,
                                    size: 100,
                                    color: Constants.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              SizedBox(
                height: 45,
                child: TextFormField(
                  controller: _titleController,
                  style: TextStyle(
                    color: Constants.primaryColor,
                    fontSize: 16,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelStyle: TextStyle(
                      color: Constants.primaryColor,
                      fontSize: 16,
                    ),
                    labelText: 'Title',
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(
                        color: Constants.primaryColor,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(
                        color: Constants.primaryColor,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              SizedBox(
                height: 45,
                child: TextFormField(
                  controller: _descriptionController,
                  style: TextStyle(
                    color: Constants.primaryColor,
                    fontSize: 16,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelStyle: TextStyle(
                      color: Constants.primaryColor,
                      fontSize: 16,
                    ),
                    labelText: 'Description',
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(
                        color: Constants.primaryColor,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(
                        color: Constants.primaryColor,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: _uploadBlogPost,
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
                  'Add Post',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              _isLoading
                  ? Column(
                      children: [
                        Container(
                          width: 200,
                          margin: const EdgeInsets.symmetric(horizontal: 60),
                          child: LinearProgressIndicator(
                            color: Constants.primaryColor,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const Center(
                          child: Text("Posting"),
                        ),
                      ],
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
