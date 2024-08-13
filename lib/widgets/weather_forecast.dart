import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:harvest_guardian/constants.dart';
import 'package:harvest_guardian/data/services/keys.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _WeatherWidgetState createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  String openWeatherMapAPI = APIConstants.openWeatherMapAPI;
  String _apiUrl = '';
  Map<String, dynamic> _weatherData = {};
  String _city = '';
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _getLocationAndWeather();
    _timer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _getLocationAndWeather();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _checkLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      if (await Permission.location.request().isGranted) {
        _getLocationAndWeather();
      } else {
        Fluttertoast.showToast(msg: 'Location permission is required');
      }
    }
  }

  Future<void> _getLocationAndWeather() async {
    if (FirebaseAuth.instance.currentUser != null) {
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10));
        List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        setState(() {
          _city = placemarks[0].locality ?? 'Unknown Location';
          _apiUrl =
              'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$openWeatherMapAPI';
        });
        _fetchWeatherData();
      } catch (e) {
        Fluttertoast.showToast(msg: 'Error getting location');
      }
    }
  }

  Future<void> _fetchWeatherData() async {
    try {
      var response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          _weatherData = jsonDecode(response.body);
          double kelvinTemperature = _weatherData['main']['temp'];
          double celsiusTemperature = kelvinTemperature - 273.15;
          _weatherData['main']['temp'] = celsiusTemperature.toStringAsFixed(2);
        });
      } else {
        Fluttertoast.showToast(msg: 'Failed to load weather data');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error fetching weather data');
    }
  }

  String getCamelCase(String text) {
    List<String> words = text.split(' ');
    for (int i = 0; i < words.length; i++) {
      words[i] =
          words[i][0].toUpperCase() + words[i].substring(1).toLowerCase();
    }
    return words.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      width: double.infinity,
      height: MediaQuery.of(context).size.height / 3,
      margin: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Constants.primaryColor,
            Colors.black87,
          ],
        ),
      ),
      duration: const Duration(milliseconds: 5000),
      child: _weatherData.isNotEmpty
          ? SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$_city Weather',
                      style: const TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Image.network(
                      'https://openweathermap.org/img/wn/${_weatherData['weather'][0]['icon']}@2x.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                    Text(
                      'Temperature: ${_weatherData['main']['temp']}°C',
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      getCamelCase(_weatherData['weather'][0]['description']),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      DateFormat('EEEE, d MMMM | hh:mm a')
                          .format(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Constants.primaryColor.withOpacity(0.2),
                        Colors.black38.withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey.withOpacity(0.3),
                    highlightColor: Colors.grey.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 200,
                            height: 28,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: 100,
                            height: 100,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: 150,
                            height: 22,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            width: 120,
                            height: 18,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            width: 200,
                            height: 18,
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
