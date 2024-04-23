import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:harvest_guardian/constants.dart';
import 'package:harvest_guardian/data/services/keys.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

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

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _getLocationAndWeather();
    Timer.periodic(const Duration(minutes: 10), (timer) {
      _getLocationAndWeather();
    });
  }

  void _checkLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      await Permission.location.request();
    }
  }

  Future<void> _getLocationAndWeather() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10));
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      setState(() {
        _city = placemarks[0].locality!;
        _apiUrl =
            'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$openWeatherMapAPI';
      });
      _fetchWeatherData();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error getting location');
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
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error fetching weather data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height / 3,
      margin: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Constants.primaryColor.withOpacity(0.7),
            Colors.black38,
          ],
        ),
      ),
      child: _weatherData.isNotEmpty
          ? SingleChildScrollView(
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
                      'https://openweathermap.org/img/wn/${_weatherData['weather'][0]['icon']}.png',
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
                      'Weather: ${_weatherData['weather'][0]['description']}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Updated on: ${DateFormat('HH:mm').format(DateTime.now())}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                    child: Text(
                  "Fetching Weather Data",
                  style: TextStyle(fontSize: 24, color: Colors.white),
                )),
                Center(
                    child: Text(
                  "🌥️",
                  style: TextStyle(fontSize: 34, color: Colors.white),
                )),
                SizedBox(
                  height: 20,
                ),
                CircularProgressIndicator(
                  color: Colors.white,
                ),
              ],
            )),
    );
  }
}
