import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maps/logic/weather_bloc.dart';
import 'package:maps/logic/weather_state.dart';


class WeatherPage extends StatelessWidget {
  final double lat;
  final double lon;

  const WeatherPage({super.key, required this.lat, required this.lon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Weather Info"),
        centerTitle: true,
      ),
      body: BlocBuilder<WeatherCubit, WeatherState>(
        builder: (context, state) {
          if (state is WeatherInitial) {
            return const Center(child: Text("Enter location to see weather"));
          } else if (state is WeatherLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is WeatherLoaded) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Temp: ${state.weather.temperature} °C",
                      style: const TextStyle(fontSize: 20)),
                  
                ],
              ),
            );
          } else if (state is WeatherError) {
            return Center(child: Text("Error: ${state.message}"));
          }
          return Container();
        },
      ),
    );
  }
}
