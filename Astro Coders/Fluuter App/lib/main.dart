// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maps/logic/weather_bloc.dart';
import 'data/repositories/user_repository.dart';
import 'data/repositories/weather_repository.dart';
import 'logic/user_cubit.dart';
import 'presentation/onboarding/hobby_selection_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<UserCubit>(
          create: (context) => UserCubit(UserRepository()),
        ),
        BlocProvider<WeatherCubit>(
          create: (context) => WeatherCubit(WeatherRepository()),
        ),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HobbySelectionPage(),
      ),
    );
  }
}
