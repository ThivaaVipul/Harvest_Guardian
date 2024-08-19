import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:harvest_guardian/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:lottie/lottie.dart';

class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  String? _name, _quantity, _price, _contact, _location;
  String? _imageUrl;
  File? _imageFile;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Add Product',
            style: TextStyle(
                color: Constants.primaryColor,
                fontSize: 25,
                fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Constants.primaryColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _imageFile != null
                        ? GestureDetector(
                            onTap: pickImage,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.file(
                                  _imageFile!,
                                  color: Colors.black.withOpacity(0.5),
                                  colorBlendMode: BlendMode.color,
                                ),
                                Container(
                                  child: Column(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit),
                                        color: Colors.white,
                                        onPressed: pickImage,
                                        padding: EdgeInsets.all(8.0),
                                        iconSize: 24.0,
                                        splashColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                      ),
                                      Center(
                                        child: Text(
                                          'Change Image',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : InkWell(
                            onTap: () => pickImage(),
                            child: Container(
                              height: 150.0,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Constants.primaryColor,
                                ),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: _imageFile != null
                                  ? Image.file(
                                      _imageFile!,
                                      fit: BoxFit.cover,
                                    )
                                  : Center(
                                      child: Text(
                                        'Product Image',
                                        style: TextStyle(
                                            color: Constants.primaryColor),
                                      ),
                                    ),
                            ),
                          ),
                    SizedBox(height: 16.0),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Product Name'),
                      onSaved: (value) => _name = value,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter product name' : null,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Quantity'),
                      onSaved: (value) => _quantity = value,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter quantity' : null,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Price (Rs)'),
                      onSaved: (value) => _price = value,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter price' : null,
                      keyboardType: TextInputType.number,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Contact Number'),
                      onSaved: (value) => _contact = value,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter contact number' : null,
                      keyboardType: TextInputType.phone,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Location'),
                      onSaved: (value) => _location = value,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter location' : null,
                    ),
                    SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () => submitProduct(),
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
                        'Add Product',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Lottie.asset(
                      'assets/loading_animation.json',
                      width: 250,
                      height: 250,
                      fit: BoxFit.fill,
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Center(
                    child: Text(
                      "Adding Product...",
                      style: TextStyle(color: Colors.black, fontSize: 18),
                    ),
                  )
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.photo_camera),
              title: Text('Camera'),
              onTap: () async {
                final pickedFile =
                    await _picker.pickImage(source: ImageSource.camera);
                if (pickedFile != null) {
                  setState(() {
                    _imageFile = File(pickedFile.path);
                  });
                }
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Gallery'),
              onTap: () async {
                final pickedFile =
                    await _picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  setState(() {
                    _imageFile = File(pickedFile.path);
                  });
                }
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
    FocusScope.of(context).unfocus();
  }

  Future<void> submitProduct() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      try {
        if (_imageFile != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('product_images/${DateTime.now().millisecondsSinceEpoch}');
          final uploadTask = storageRef.putFile(_imageFile!);
          final taskSnapshot = await uploadTask.whenComplete(() => null);
          _imageUrl = await taskSnapshot.ref.getDownloadURL();
        } else {
          _imageUrl = Constants.defaultProductImgUrl;
        }

        String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;

        await FirebaseFirestore.instance.collection('products').add({
          'name': _name,
          'quantity': _quantity,
          'price': _price,
          'contact': _contact,
          'location': _location,
          'imageUrl': _imageUrl,
          'userId': FirebaseAuth.instance.currentUser!.uid,
          'sold': false,
          'timestamp': FieldValue.serverTimestamp(),
          'email': currentUserEmail,
        });

        Fluttertoast.showToast(msg: 'Product added successfully');

        Navigator.pop(context);
      } catch (error) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $error')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
