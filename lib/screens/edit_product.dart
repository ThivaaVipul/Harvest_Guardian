import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:harvest_guardian/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lottie/lottie.dart';

class EditProductPage extends StatefulWidget {
  final DocumentSnapshot product;

  const EditProductPage({Key? key, required this.product}) : super(key: key);

  @override
  _EditProductPageState createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  String? _name, _quantity, _price, _contact, _location;
  String? _imageUrl;
  File? _imageFile;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _name = widget.product['name'];
    _quantity = widget.product['quantity'];
    _price = widget.product['price'];
    _contact = widget.product['contact'];
    _location = widget.product['location'];
    _imageUrl = widget.product['imageUrl'];
    print(_imageUrl);
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

  Future<void> updateProduct() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      try {
        String? imageUrl;
        if (_imageFile != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('product_images/${DateTime.now().millisecondsSinceEpoch}');
          final uploadTask = storageRef.putFile(_imageFile!);
          final taskSnapshot = await uploadTask.whenComplete(() => null);
          imageUrl = await taskSnapshot.ref.getDownloadURL();
          String? existingImageUrl = widget.product['imageUrl'];
          if (existingImageUrl != null) {
            final existingImageRef =
                FirebaseStorage.instance.refFromURL(existingImageUrl);
            await existingImageRef.delete();
          }
        } else {
          imageUrl = _imageUrl;
        }

        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.product.id)
            .update({
          'name': _name!,
          'quantity': _quantity!,
          'price': _price!,
          'contact': _contact!,
          'location': _location!,
          'imageUrl': imageUrl!,
          'timestamp': FieldValue.serverTimestamp(),
        });

        Fluttertoast.showToast(msg: 'Product updated successfully');
        Navigator.pop(context);
      } catch (error) {
        print('Error updating product: $error');
        Fluttertoast.showToast(msg: 'Error updating product');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Edit Product'),
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
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
                        : _imageUrl != null
                            ? GestureDetector(
                                onTap: pickImage,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Image.network(
                                      _imageUrl!,
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
                                              style: TextStyle(
                                                  color: Colors.white),
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
                      initialValue: _name,
                      decoration: InputDecoration(labelText: 'Product Name'),
                      onSaved: (value) => _name = value,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a name' : null,
                    ),
                    TextFormField(
                      initialValue: _quantity,
                      decoration: InputDecoration(labelText: 'Quantity'),
                      onSaved: (value) => _quantity = value,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a quantity' : null,
                    ),
                    TextFormField(
                      initialValue: _price,
                      decoration: InputDecoration(labelText: 'Price'),
                      onSaved: (value) => _price = value,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a price' : null,
                      keyboardType: TextInputType.number,
                    ),
                    TextFormField(
                      initialValue: _contact,
                      decoration: InputDecoration(labelText: 'Contact'),
                      onSaved: (value) => _contact = value,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a contact' : null,
                      keyboardType: TextInputType.phone,
                    ),
                    TextFormField(
                      initialValue: _location,
                      decoration: InputDecoration(labelText: 'Location'),
                      onSaved: (value) => _location = value,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a location' : null,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => updateProduct(),
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
                        'Update Product',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                      "Updating Product...",
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
}
