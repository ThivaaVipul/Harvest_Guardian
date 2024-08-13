import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:lottie/lottie.dart';

class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  String? _name, _quantity, _price, _contact;
  String? _imageUrl;
  File? _imageFile;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Product'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
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
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Price (Rs)'),
                    onSaved: (value) => _price = value,
                    validator: (value) => value!.isEmpty ? 'Enter price' : null,
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Contact Number'),
                    onSaved: (value) => _contact = value,
                    validator: (value) =>
                        value!.isEmpty ? 'Enter contact number' : null,
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 16.0),
                  _imageFile != null
                      ? Image.file(_imageFile!)
                      : ElevatedButton(
                          onPressed: () => pickImage(),
                          child: Text('Upload Image'),
                        ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () => submitProduct(),
                    child: Text('Add Product'),
                  ),
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
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                )
              ],
            ),
        ],
      ),
    );
  }

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> submitProduct() async {
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
          _imageUrl =
              "https://firebasestorage.googleapis.com/v0/b/harvest-guardian-462ea.appspot.com/o/product_images%2Fproducts.jpg?alt=media&token=166cbd44-073d-4d42-b1f1-f1b864b9fe42";
        }

        String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;

        await FirebaseFirestore.instance.collection('products').add({
          'name': _name,
          'quantity': _quantity,
          'price': _price,
          'contact': _contact,
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
