import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:harvest_guardian/constants.dart';
import 'package:harvest_guardian/data/services/weather.dart';
import 'package:harvest_guardian/utils/weather_data.dart';
import 'package:intl/intl.dart';

class WeatherDashboard extends StatefulWidget {
  const WeatherDashboard({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _WeatherDashboardState createState() => _WeatherDashboardState();
}

class _WeatherDashboardState extends State<WeatherDashboard> {
  late Future<Map<String, dynamic>> _weatherData;
  late Future<Position> _currentPosition;
  String _locationName = '';

  @override
  void initState() {
    super.initState();
    _currentPosition = _determinePosition();
    _currentPosition.then((position) {
      setState(() {
        _weatherData = WeatherService()
            .fetchWeatherData(position.latitude, position.longitude);
        _getLocationName(position.latitude, position.longitude);
      });
    }).catchError((error) {
      Fluttertoast.showToast(msg: 'Error getting location');
    });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _getLocationName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        setState(() {
          _locationName = '${placemark.locality}, ${placemark.country}';
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error getting location name');
    }
  }

  List<WeatherData> _parseWeatherData(Map<String, dynamic> data) {
    List<WeatherData> weatherList = [];
    for (var day in data['daily']) {
      weatherList.add(WeatherData.fromJson(day));
    }
    return weatherList;
  }

  Widget _buildWeatherChart(List<WeatherData> weatherData) {
    return Column(
      children: [
        Text(
          _locationName,
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Constants.primaryColor),
        ),
        const SizedBox(
          height: 20,
        ),
        SizedBox(
          height: 250,
          width: MediaQuery.of(context).size.width - 50,
          child: LineChart(
            swapAnimationCurve: Curves.linear,
            LineChartData(
              backgroundColor: Colors.green.withAlpha(40),
              lineBarsData: [
                LineChartBarData(
                  spots: weatherData
                      .map((data) => FlSpot(
                          data.date.millisecondsSinceEpoch.toDouble(),
                          data.temp))
                      .toList(),
                  isCurved: true,
                  colors: [Colors.green, Colors.black],
                  barWidth: 4,
                  dotData: FlDotData(show: true),
                ),
              ],
              titlesData: FlTitlesData(
                leftTitles: SideTitles(
                  reservedSize: 40,
                  margin: 10,
                  showTitles: true,
                  getTextStyles: (context, _) => TextStyle(
                    color: Constants.primaryColor,
                    fontSize: 18,
                  ),
                ),
                rightTitles: SideTitles(showTitles: false),
                bottomTitles: SideTitles(
                  showTitles: true,
                  getTitles: (value) {
                    return DateFormat('E').format(
                        DateTime.fromMillisecondsSinceEpoch(value.toInt()));
                  },
                  margin: 10,
                  getTextStyles: (context, _) =>
                      TextStyle(color: Constants.primaryColor, fontSize: 18),
                ),
                topTitles: SideTitles(showTitles: false),
              ),
              borderData: FlBorderData(
                show: false,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Weather Dashboard',
          style: TextStyle(
            color: Constants.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
      ),
      body: FutureBuilder<Position>(
        future: _currentPosition,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return FutureBuilder<Map<String, dynamic>>(
              future: _weatherData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  List<WeatherData> weatherData =
                      _parseWeatherData(snapshot.data!);
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildWeatherChart(weatherData),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: weatherData.length,
                          itemBuilder: (context, index) {
                            WeatherData data = weatherData[index];
                            return ListTile(
                              leading: Image.network(
                                  'https://openweathermap.org/img/wn/${data.icon}.png'),
                              title: Text(
                                  '${DateFormat('E, MMM d').format(data.date)}: ${data.description.capitalize()}'),
                              subtitle: Text(
                                  'Min: ${data.minTemp}°C, Max: ${data.maxTemp}°C, Humidity: ${data.humidity}%'),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }
              },
            );
          }
        },
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
