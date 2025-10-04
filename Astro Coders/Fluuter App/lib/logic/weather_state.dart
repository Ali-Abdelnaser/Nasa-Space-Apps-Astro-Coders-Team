import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class WeatherState {}

class WeatherInitial extends WeatherState {}

class WeatherLoading extends WeatherState {}

class WeatherLoaded extends WeatherState {
  final LatLng position;
  final Weather weather;

  WeatherLoaded({required this.position, required this.weather});
}

class WeatherError extends WeatherState {
  final String message;

  WeatherError(this.message);
}

/// كلاس بسيط يمثل بيانات الطقس
class Weather {
  final double temperature;
  final String condition;

  Weather({required this.temperature, required this.condition});
}
