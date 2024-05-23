import 'dart:convert';
import 'package:harvest_guardian/data/services/keys.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  static final String _apiKey = APIConstants.openWeatherMapAPI;
  static const String _baseUrl =
      'https://api.openweathermap.org/data/3.0/onecall';

  Future<Map<String, dynamic>> fetchWeatherData(double lat, double lon) async {
    final response = await http.get(Uri.parse(
        '$_baseUrl?lat=$lat&lon=$lon&exclude=hourly,minutely&units=metric&appid=$_apiKey'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load weather data');
    }
  }
}
