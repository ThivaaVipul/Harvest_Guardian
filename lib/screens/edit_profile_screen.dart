import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:harvest_guardian/constants.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  String? _displayName;
  String? _userPhotoURL;
  File? _pickedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
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
          elevation: 0,
          title: Text(
            "Edit Profile",
            style: TextStyle(
              color: Constants.primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 90),
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: _pickedImage != null
                              ? DecorationImage(
                                  image: FileImage(_pickedImage!),
                                  fit: BoxFit.cover,
                                )
                              : _userPhotoURL != null
                                  ? DecorationImage(
                                      image: NetworkImage(_userPhotoURL!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                        ),
                        child: _pickedImage == null && _userPhotoURL == null
                            ? Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: NetworkImage(FirebaseAuth
                                            .instance.currentUser!.photoURL ??
                                        'https://st4.depositphotos.com/1496387/40483/v/450/depositphotos_404831150-stock-illustration-happy-farmer-logo-agriculture-natural.jpg'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      if (_pickedImage == null && _userPhotoURL == null)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.5),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.edit,
                                color: Colors.white70,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 45,
                  child: TextFormField(
                    onChanged: (value) {
                      setState(() {
                        _displayName = value;
                      });
                    },
                    style: TextStyle(
                      color: Constants.primaryColor,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      labelStyle: TextStyle(
                        color: Constants.primaryColor,
                        fontSize: 16,
                      ),
                      labelText: 'Display Name',
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
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      FocusScope.of(context).unfocus();
                      setState(() {
                        _isLoading = true;
                      });
                      try {
                        if (_displayName != null) {
                          await FirebaseAuth.instance.currentUser!
                              .updateDisplayName(_displayName!);
                          final userUid =
                              FirebaseAuth.instance.currentUser!.uid;
                          await FirebaseDatabase.instance
                              .ref()
                              .child('Users')
                              .child(userUid)
                              .update({
                            'displayName': _displayName,
                          });
                        }
                        if (_pickedImage != null) {
                          final storageRef = FirebaseStorage.instance
                              .ref()
                              .child('profile_images')
                              .child(
                                  '${FirebaseAuth.instance.currentUser!.uid}.jpg');
                          await storageRef.putFile(_pickedImage!);
                          final String downloadURL =
                              await storageRef.getDownloadURL();
                          setState(() {
                            _userPhotoURL = downloadURL;
                          });
                          await FirebaseAuth.instance.currentUser!
                              .updatePhotoURL(_userPhotoURL!);
                          final userUid =
                              FirebaseAuth.instance.currentUser!.uid;
                          await FirebaseDatabase.instance
                              .ref()
                              .child('Users')
                              .child(userUid)
                              .update({
                            'photoUrl': _userPhotoURL,
                          });
                        }
                        Fluttertoast.showToast(
                          msg: 'Profile updated successfully!',
                        );
                        // ignore: use_build_context_synchronously
                        Navigator.popUntil(context, ModalRoute.withName('/'));
                      } catch (error) {
                        Fluttertoast.showToast(
                          msg: 'Failed to update profile: $error',
                          gravity: ToastGravity.BOTTOM,
                        );
                      } finally {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    },
                    child: const Text('Save'),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                _isLoading
                    ? Container(
                        width: 200,
                        margin: const EdgeInsets.symmetric(horizontal: 60),
                        child: Column(
                          children: [
                            LinearProgressIndicator(
                              color: Constants.primaryColor,
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            const Center(
                              child: Text("Saving"),
                            )
                          ],
                        ),
                      )
                    : Container(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
