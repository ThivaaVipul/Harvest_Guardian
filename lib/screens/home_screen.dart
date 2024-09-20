import 'package:flutter/material.dart';
import 'package:harvest_guardian/constants.dart';
import 'package:harvest_guardian/screens/plant_disease_detection_screen.dart';
import 'package:harvest_guardian/screens/product_listing_page.dart';
import 'package:harvest_guardian/screens/weather_forecast_screen.dart';
import 'package:harvest_guardian/screens/disease_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:harvest_guardian/widgets/weather_forecast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
              const SizedBox(height: 20),
              const WeatherWidget(),
              const SizedBox(height: 20),

              // 2x2 Grid of Buttons Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.8,
                  children: [
                    _buildGridCard(
                      context,
                      title: "Predict Disease",
                      icon: Icons.qr_code_scanner_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          PageTransition(
                            child: const PlantDiseaseDetectionPage(),
                            type: PageTransitionType.bottomToTop,
                          ),
                        );
                      },
                    ),
                    _buildGridCard(
                      context,
                      title: "Weather Dashboard",
                      icon: Icons.cloudy_snowing,
                      onTap: () {
                        Navigator.push(
                          context,
                          PageTransition(
                            child: const WeatherDashboard(),
                            type: PageTransitionType.bottomToTop,
                          ),
                        );
                      },
                    ),
                    _buildGridCard(
                      context,
                      title: "Disease Details",
                      icon: Icons.list_alt,
                      onTap: () {
                        Navigator.push(
                          context,
                          PageTransition(
                            child: const DiseaseDetailsPage(),
                            type: PageTransitionType.bottomToTop,
                          ),
                        );
                      },
                    ),
                    _buildGridCard(
                      context,
                      title: "Market",
                      icon: Icons.storefront,
                      onTap: () {
                        Navigator.push(
                          context,
                          PageTransition(
                            child: ProductListingPage(),
                            type: PageTransitionType.bottomToTop,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context,
      {required String title,
      required IconData icon,
      required Function onTap}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 6,
      shadowColor: Colors.black54,
      child: InkWell(
        onTap: () => onTap(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Constants.primaryColor, Colors.green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(icon, color: Colors.white, size: 35),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
