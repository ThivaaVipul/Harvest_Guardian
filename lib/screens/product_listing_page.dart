import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:harvest_guardian/constants.dart';
import 'package:harvest_guardian/screens/add_product_page.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductListingPage extends StatelessWidget {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final String defaultImageUrl =
      "https://firebasestorage.googleapis.com/v0/b/harvest-guardian-462ea.appspot.com/o/product_images%2Fproducts.jpg?alt=media&token=53515524-e646-47b0-a04b-c4549223b0be";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vegetable Market'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No products available'));
          }

          var products = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return !data['sold'] || data['userId'] == currentUserId;
          }).toList();

          if (products.isEmpty) {
            return Center(child: Text('No products available'));
          }

          return ListView.builder(
            padding: EdgeInsets.only(
                bottom: 80.0), // Added white space at the bottom
            itemCount: products.length,
            itemBuilder: (context, index) {
              var product = products[index];
              bool isSold = product['sold'];

              // Check if the fields exist before accessing them
              String name = product['name'] ?? 'Unknown';
              String quantity = product['quantity'] ?? 'Unknown';
              String price = product['price'] ?? 'Unknown';
              String contact_in_db = product['contact'] ?? 'Unknown';
              String contact = contact_in_db.startsWith('0')
                  ? '+94${contact_in_db.substring(1)}'
                  : contact_in_db;
              String imageUrl = product['imageUrl'] ?? defaultImageUrl;

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
                          builder: (context) =>
                              FullScreenImageView(imageUrl: imageUrl),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(15)),
                        child: Image.network(
                          imageUrl,
                          height: 200,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          SizedBox(height: 5),
                          Text('Quantity: $quantity',
                              style: TextStyle(fontSize: 16)),
                          Text('Price: Rs. $price',
                              style: TextStyle(fontSize: 16)),
                          Text('Contact: $contact',
                              style: TextStyle(fontSize: 16)),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(Icons.call, color: Colors.green),
                                onPressed: () => _makePhoneCall('tel:$contact'),
                                tooltip: "Call",
                              ),
                              IconButton(
                                icon: Icon(Icons.chat, color: Colors.green),
                                onPressed: () => _openWhatsApp(contact,
                                    'Hi, I\'m interested in your product $name. Is it still available?'),
                                tooltip: "Chat Via WhatsApp",
                              ),
                              if (product['userId'] == currentUserId) ...[
                                IconButton(
                                  icon: Icon(
                                      isSold
                                          ? Icons.remove_circle
                                          : Icons.check_circle,
                                      color:
                                          isSold ? Colors.red : Colors.green),
                                  onPressed: () =>
                                      toggleSoldStatus(product.id, !isSold),
                                  tooltip: isSold
                                      ? "Mark as Sold"
                                      : "Mark as UnSold",
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () =>
                                      deleteProduct(product.id, imageUrl),
                                  tooltip: "Delete the product",
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProductPage()),
          );
        },
        label: Text('Add Product'),
        icon: Icon(Icons.add),
      ),
    );
  }

  void toggleSoldStatus(String productId, bool newStatus) {
    FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .update({'sold': newStatus});
  }

  void deleteProduct(String productId, String imageUrl) {
    if (imageUrl != defaultImageUrl) {
      FirebaseStorage.instance.refFromURL(imageUrl).delete();
    }
    FirebaseFirestore.instance.collection('products').doc(productId).delete();
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
        ),
      ),
    );
  }
}
