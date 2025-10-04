import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/logic/weather_state.dart';

class WeatherRepository {
  Future<Weather> fetchWeather(LatLng position) async {
    await Future.delayed(const Duration(seconds: 2)); // محاكاة API delay

    /// هنا ممكن تحط API حقيقية زي OpenWeatherMap
    return Weather(
      temperature: 25.5,
      condition: "Sunny",
    );
  }
}
