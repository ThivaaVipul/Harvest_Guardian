import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

import '../constants.dart';
import '../widgets/disease_detail.dart';

class DiseaseDetailsPage extends StatefulWidget {
  const DiseaseDetailsPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DiseaseDetailsPageState createState() => _DiseaseDetailsPageState();
}

class _DiseaseDetailsPageState extends State<DiseaseDetailsPage> {
  List<Disease> diseases = [];

  @override
  void initState() {
    super.initState();
    loadDiseaseData();
  }

  Future<void> loadDiseaseData() async {
    final String response =
        await rootBundle.loadString('assets/disease_data.json');
    final List<dynamic> data = json.decode(response);
    setState(() {
      diseases = data.map((d) => Disease.fromJson(d)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Disease Details',
          style: TextStyle(
              color: Constants.primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Constants.primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: diseases.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: diseases.length,
              itemBuilder: (context, index) {
                final disease = diseases[index];
                return DiseaseDetailCard(
                  name: disease.name,
                  description: disease.description,
                  cure: disease.cure,
                  imageUrl: disease.img,
                );
              },
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
      img: json['img'] ??
          'https://cdn.britannica.com/26/152026-050-41D137DE/Sunshine-leaves-beech-tree.jpg',
    );
  }
}
