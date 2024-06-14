import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:harvest_guardian/constants.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:fluttertoast/fluttertoast.dart';

class DiseaseDetailCard extends StatelessWidget {
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

  void shareDiseaseDetails() async {
    try {
      await FlutterShare.share(
        title: name,
        text: "*$name*\n\n$description\n\nCure:\n$cure",
        linkUrl: imageUrl,
        chooserTitle: 'Share via',
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error sharing: $e');
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
                    builder: (_) =>
                        FullScreenImagePage(imageUrl: imageUrl, title: name),
                  ),
                );
              },
              child: CachedNetworkImage(
                imageUrl: imageUrl,
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
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(description),
            const SizedBox(height: 10),
            const Text(
              'Cure:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(cure),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: shareDiseaseDetails,
                  child: const Icon(
                    Icons.share,
                    size: 25,
                    color: Colors.blue,
                  ),
                ),
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

  const FullScreenImagePage(
      {required this.imageUrl, required this.title, super.key});

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
            errorWidget: (context, url, error) =>
                const Icon(Icons.error, color: Colors.white),
            imageBuilder: (context, imageProvider) => GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
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
      ),
    );
  }
}
