import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:harvest_guardian/constants.dart';
import 'package:harvest_guardian/screens/plant_disease_detection_screen.dart';
import 'package:harvest_guardian/screens/weather_forecast_screen.dart';
import 'package:harvest_guardian/widgets/weather_forecast.dart';
import 'package:page_transition/page_transition.dart';

import 'disease_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              Text(
                "Hello ${FirebaseAuth.instance.currentUser!.displayName.toString()} 🤠",
                style: TextStyle(
                  fontSize: 28,
                  color: Constants.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              const WeatherWidget(),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageTransition(
                      child: const PlantDiseaseDetectionPage(),
                      type: PageTransitionType.bottomToTop,
                    ),
                  );
                },
                child: const Text(
                  "Predict Disease",
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageTransition(
                      child: const WeatherDashboard(),
                      type: PageTransitionType.bottomToTop,
                    ),
                  );
                },
                child: const Text(
                  "Weather Dashboard",
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageTransition(
                      child: const DiseaseDetailsPage(),
                      type: PageTransitionType.bottomToTop,
                    ),
                  );
                },
                child: const Text(
                  "Disease Details",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
