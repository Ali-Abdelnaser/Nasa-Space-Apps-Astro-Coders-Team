import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/data/repositories/weather_repository.dart';
import 'weather_state.dart';

class WeatherCubit extends Cubit<WeatherState> {
  final WeatherRepository weatherRepository;

  WeatherCubit(this.weatherRepository) : super(WeatherInitial());

  Future<void> getWeatherForCurrentLocation() async {
    try {
      emit(WeatherLoading());

      /// هنا هنجيب المكان الحالي (مؤقتًا نخليه مكان افتراضي)
      LatLng currentPosition = const LatLng(30.0444, 31.2357); // القاهرة

      /// استدعاء الـ Repository
      final weather = await weatherRepository.fetchWeather(currentPosition);

      emit(WeatherLoaded(position: currentPosition, weather: weather));
    } catch (e) {
      emit(WeatherError(e.toString()));
    }
  }
}
