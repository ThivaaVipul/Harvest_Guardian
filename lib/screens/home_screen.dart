import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:harvest_guardian/constants.dart';
import 'package:harvest_guardian/screens/authentication/signin_screen.dart';
import 'package:harvest_guardian/screens/community_screen.dart';
import 'package:harvest_guardian/screens/plant_disease_detection_screen.dart';
import 'package:harvest_guardian/widgets/weather_forecast.dart';
import 'package:page_transition/page_transition.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const WeatherWidget(),
            const SizedBox(
              height: 20,
            ),
            Text(
              "Hello ${FirebaseAuth.instance.currentUser!.displayName.toString()} 🤠",
              style: TextStyle(
                  fontSize: 28,
                  color: Constants.primaryColor,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  PageTransition(
                    child: const SignIn(),
                    type: PageTransitionType.bottomToTop,
                  ),
                );
              },
              child: const Text(
                "Logout",
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
                    child: const CommunityPage(),
                    type: PageTransitionType.bottomToTop,
                  ),
                );
              },
              child: const Text(
                "Go To Community",
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
                    child: const PlantDiseaseDetectionPage(),
                    type: PageTransitionType.bottomToTop,
                  ),
                );
              },
              child: const Text(
                "Predict Disease",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
