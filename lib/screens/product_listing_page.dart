import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:harvest_guardian/constants.dart';
import 'package:harvest_guardian/screens/add_product_page.dart';
import 'package:harvest_guardian/screens/edit_product.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductListingPage extends StatefulWidget {
  @override
  _ProductListingPageState createState() => _ProductListingPageState();
}

class _ProductListingPageState extends State<ProductListingPage> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final String defaultImageUrl = Constants.defaultProductImgUrl;
  String searchQuery = "";
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  Timer? _debounce;

  Future<void> _refreshProducts() async {
    await Future.delayed(Duration(seconds: 2));
    Fluttertoast.showToast(msg: "Products refreshed successfully");
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        searchQuery = value.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    searchFocusNode.unfocus();
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'Market Place',
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
          body: RefreshIndicator(
            onRefresh: _refreshProducts,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildNoProductsWidget(searchQuery);
                }

                var products = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  var name = data['name']?.toString().toLowerCase() ?? '';
                  var location =
                      data['location']?.toString().toLowerCase() ?? '';
                  return (!data['sold'] || data['userId'] == currentUserId) &&
                      (name.contains(searchQuery) ||
                          location.contains(searchQuery));
                }).toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        child: TextField(
                          focusNode: searchFocusNode,
                          controller: searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 15.0),
                            hintText: "Search by product name or location...",
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            prefixIcon: Icon(Icons.search,
                                color: Constants.primaryColor),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    if (products.isEmpty)
                      SizedBox(
                        height: 150,
                      ),
                    if (products.isEmpty) _buildNoProductsWidget(searchQuery),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.only(bottom: 80.0),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          var product = products[index];
                          bool isSold = product['sold'];
                          String currentuser = FirebaseAuth
                              .instance.currentUser!.email
                              .toString();

                          String name = product['name'] ?? 'Unknown';
                          String quantity = product['quantity'] ?? 'Unknown';
                          String price = product['price'] ?? 'Unknown';
                          String location = product['location'] ?? 'Unknown';
                          String contact_in_db =
                              product['contact'] ?? 'Unknown';
                          String contact = contact_in_db.startsWith('0')
                              ? '+94${contact_in_db.substring(1)}'
                              : contact_in_db;
                          String imageUrl =
                              product['imageUrl'] ?? defaultImageUrl;

                          DateTime postDateTime =
                              product['timestamp']?.toDate() ?? DateTime.now();
                          String formattedDateTime =
                              DateFormat('dd/MM/yyyy h:mm a')
                                  .format(postDateTime);

                          String mail = product['email'] ?? "Unknown";

                          return Card(
                            elevation: 8,
                            margin: EdgeInsets.all(10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FullScreenImageView(
                                          imageUrl: imageUrl),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(15)),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      width: MediaQuery.of(context).size.width,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        height: 200,
                                        width:
                                            MediaQuery.of(context).size.width,
                                        child: Center(
                                          child: Lottie.asset(
                                            'assets/loading_animation_txt.json',
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.fill,
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(name,
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold)),
                                      SizedBox(height: 5),
                                      Text('Quantity: $quantity',
                                          style: TextStyle(fontSize: 16)),
                                      Text('Price: Rs. $price',
                                          style: TextStyle(fontSize: 16)),
                                      Text('Location: $location',
                                          style: TextStyle(fontSize: 16)),
                                      if (currentuser != mail)
                                        Text('Contact: $contact',
                                            style: TextStyle(fontSize: 16)),
                                      Text('Posted on: $formattedDateTime',
                                          style: TextStyle(fontSize: 16)),
                                      currentuser != mail
                                          ? Text('By: $mail',
                                              style: TextStyle(fontSize: 16))
                                          : Text('By: You',
                                              style: TextStyle(fontSize: 16)),
                                      SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          if (product['userId'] !=
                                              currentUserId) ...[
                                            Column(
                                              children: [
                                                IconButton(
                                                  icon: FaIcon(Icons.phone,
                                                      color: Colors.green),
                                                  onPressed: () =>
                                                      _makePhoneCall(
                                                          'tel:$contact'),
                                                  tooltip: "Call",
                                                ),
                                                Text('Call',
                                                    style: TextStyle(
                                                        fontSize: 12)),
                                              ],
                                            ),
                                            SizedBox(width: 10),
                                            Column(
                                              children: [
                                                IconButton(
                                                  icon: FaIcon(
                                                      FontAwesomeIcons.whatsapp,
                                                      color: Colors.green),
                                                  onPressed: () => _openWhatsApp(
                                                      contact,
                                                      'Hi, I\'m interested in your product $name. Is it still available?'),
                                                  tooltip: "Chat Via WhatsApp",
                                                ),
                                                Text('WhatsApp',
                                                    style: TextStyle(
                                                        fontSize: 12)),
                                              ],
                                            ),
                                          ],
                                          if (product['userId'] ==
                                              currentUserId) ...[
                                            Column(
                                              children: [
                                                IconButton(
                                                  icon: FaIcon(
                                                      FontAwesomeIcons
                                                          .penToSquare,
                                                      color: Colors.green),
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            EditProductPage(
                                                                product:
                                                                    product),
                                                      ),
                                                    );
                                                  },
                                                  tooltip: "Edit Product",
                                                ),
                                                Text('Edit',
                                                    style: TextStyle(
                                                        fontSize: 12)),
                                              ],
                                            ),
                                            SizedBox(width: 10),
                                            Column(
                                              children: [
                                                IconButton(
                                                  icon: FaIcon(
                                                      isSold
                                                          ? FontAwesomeIcons
                                                              .circleXmark
                                                          : FontAwesomeIcons
                                                              .circleCheck,
                                                      color: isSold
                                                          ? Colors.red
                                                          : Colors.green),
                                                  onPressed: () =>
                                                      toggleSoldStatus(
                                                          product.id, !isSold),
                                                  tooltip: isSold
                                                      ? "Mark as UnSold"
                                                      : "Mark as Sold",
                                                ),
                                                Text(isSold ? 'UnSold' : 'Sold',
                                                    style: TextStyle(
                                                        fontSize: 12)),
                                              ],
                                            ),
                                            SizedBox(width: 10),
                                            Column(
                                              children: [
                                                IconButton(
                                                  icon: FaIcon(
                                                      FontAwesomeIcons.trashCan,
                                                      color: Colors.red),
                                                  onPressed: () =>
                                                      deleteProductWithConfirmation(
                                                          context,
                                                          product.id,
                                                          imageUrl),
                                                  tooltip: "Delete the product",
                                                ),
                                                Text('Delete',
                                                    style: TextStyle(
                                                        fontSize: 12)),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: Constants.primaryColor,
            icon: const Icon(
              Icons.add,
              color: Colors.white,
            ),
            label: const Text(
              'Add Product',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddProductPage()),
              );
            },
          )),
    );
  }

  void toggleSoldStatus(String productId, bool newStatus) {
    Map<String, dynamic> updateData = {
      'sold': newStatus,
    };

    if (!newStatus) {
      updateData['timestamp'] = DateTime.now();
    }

    FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .update(updateData)
        .then((_) {
      if (newStatus) {
        Fluttertoast.showToast(msg: 'Product marked as sold');
      } else {
        Fluttertoast.showToast(msg: 'Product marked as unsold');
      }
    }).catchError((error) {
      Fluttertoast.showToast(msg: 'Failed to update product: $error');
    });
  }

  void deleteProductWithConfirmation(
      BuildContext context, String productId, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this product?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                deleteProduct(productId, imageUrl);
              },
            ),
          ],
        );
      },
    );
  }

  void deleteProduct(String productId, String imageUrl) {
    if (imageUrl != defaultImageUrl) {
      FirebaseStorage.instance.refFromURL(imageUrl).delete();
    }
    FirebaseFirestore.instance.collection('products').doc(productId).delete();
    Fluttertoast.showToast(msg: 'Product deleted successfully');
  }

  void _makePhoneCall(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _openWhatsApp(String phone, String message) async {
    final whatsappUrl = "https://wa.me/$phone?text=${Uri.encodeFull(message)}";
    if (await canLaunch(whatsappUrl)) {
      await launch(whatsappUrl);
    } else {
      throw 'Could not launch WhatsApp';
    }
  }
}

Widget _buildNoProductsWidget(String searchQuery) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shopping_cart_outlined,
            size: 100, color: Constants.primaryColor),
        SizedBox(height: 20),
        Text(
          searchQuery.isEmpty
              ? 'No products available'
              : 'No products found for "$searchQuery"',
          style: TextStyle(fontSize: 20, color: Constants.primaryColor),
        ),
      ],
    ),
  );
}

class FullScreenImageView extends StatelessWidget {
  final String imageUrl;

  FullScreenImageView({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Constants.primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
          backgroundDecoration: BoxDecoration(color: Colors.black),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          loadingBuilder: (context, url) => Container(
            alignment: Alignment.center,
            child: Center(
              child: Lottie.asset(
                'assets/loading_animation_txt.json',
                width: 100,
                height: 100,
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
