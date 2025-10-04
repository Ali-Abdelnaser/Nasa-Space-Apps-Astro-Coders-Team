class WeatherModel {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final int pressure;
  final double windSpeed;
  final String mainCondition;
  final String description;

  WeatherModel({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.mainCondition,
    required this.description,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    try {
      print('🔄 تحويل JSON إلى WeatherModel...');

      // للـ API الجديد (weather)
      if (json.containsKey('main') && json.containsKey('weather')) {
        final main = json['main'];
        final weather = json['weather'][0];
        final wind = json['wind'] ?? {};

        return WeatherModel(
          temperature: (main['temp'] ?? 0).toDouble(),
          feelsLike: (main['feels_like'] ?? 0).toDouble(),
          humidity: (main['humidity'] ?? 0),
          pressure: (main['pressure'] ?? 0),
          windSpeed: (wind['speed'] ?? 0).toDouble(),
          mainCondition: weather['main'] ?? 'Unknown',
          description: weather['description'] ?? 'No description',
        );
      } else {
        throw Exception('بيانات API غير متوقعة: $json');
      }
    } catch (e) {
      print('❌ خطأ في fromJson: $e');
      rethrow;
    }
  }

  @override
  String toString() {
    return 'WeatherModel(temperature: $temperature, condition: $mainCondition)';
  }
}
