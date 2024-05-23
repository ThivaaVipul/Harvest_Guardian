class WeatherData {
  final double temp;
  final double minTemp;
  final double maxTemp;
  final double humidity;
  final String description;
  final String icon;
  final DateTime date;

  WeatherData({
    required this.temp,
    required this.minTemp,
    required this.maxTemp,
    required this.humidity,
    required this.description,
    required this.icon,
    required this.date,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temp: json['temp']['day'].toDouble(),
      minTemp: json['temp']['min'].toDouble(),
      maxTemp: json['temp']['max'].toDouble(),
      humidity: json['humidity'].toDouble(),
      description: json['weather'][0]['description'],
      icon: json['weather'][0]['icon'],
      date: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
    );
  }
}
