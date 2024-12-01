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
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            SizedBox(
              height: 250,
              width: double.infinity,
              child: LineChart(
                swapAnimationCurve: Curves.linear,
                LineChartData(
                  backgroundColor: Colors.lightBlue.withOpacity(0.1),
                  lineBarsData: [
                    LineChartBarData(
                      spots: weatherData
                          .map((data) => FlSpot(
                              data.date.millisecondsSinceEpoch.toDouble(),
                              data.temp))
                          .toList(),
                      isCurved: true,
                      colors: [
                        Colors.blue, // Start of the gradient
                        Colors.blueAccent // End of the gradient
                      ],
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        colors: [
                          Color(0xff296e48).withOpacity(0.3),
                          Color(0xff8cd790).withOpacity(0.1),
                        ],
                        gradientFrom: Offset(0, 0),
                        gradientTo: Offset(0, 1),
                      ),
                      dotData: FlDotData(show: true),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: SideTitles(
                      reservedSize: 40,
                      margin: 8,
                      showTitles: true,
                      getTextStyles: (context, _) => const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 12,
                      ),
                    ),
                    rightTitles: SideTitles(showTitles: false),
                    bottomTitles: SideTitles(
                      showTitles: true,
                      getTitles: (value) {
                        return DateFormat('E').format(
                            DateTime.fromMillisecondsSinceEpoch(value.toInt()));
                      },
                      reservedSize: 32,
                    ),
                    topTitles: SideTitles(showTitles: false),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
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
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back,
            color: Constants.primaryColor,
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
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xff296e48), Color(0xffa8d5ba)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  offset: const Offset(0, 4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 20),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.pin_drop,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _locationName.isEmpty
                                          ? 'Fetching Location...'
                                          : _locationName,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Temperature Over Time',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _buildWeatherChart(weatherData),
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true, // Allows ListView to fit in Column
                          itemCount: weatherData.length,
                          itemBuilder: (context, index) {
                            WeatherData data = weatherData[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.blueGrey.withOpacity(0.1),
                                    ),
                                  ),
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: Colors.lightBlue
                                                  .withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          Image.network(
                                            'https://openweathermap.org/img/wn/${data.icon}.png',
                                            width: 50,
                                            height: 50,
                                          ),
                                        ],
                                      ),
                                    ),
                                    title: Text(
                                      '${DateFormat('E, MMM d').format(data.date)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      '🌡️ Min: ${data.minTemp}°C, Max: ${data.maxTemp}°C\n💧 Humidity: ${data.humidity}%',
                                      style: const TextStyle(height: 1.5),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
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
