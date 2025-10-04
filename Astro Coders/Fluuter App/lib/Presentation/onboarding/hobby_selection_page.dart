// lib/presentation/onboarding/hobby_selection_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maps/Presentation/home_page_wrapper.dart';
import '../../logic/user_cubit.dart';
import '../../logic/user_state.dart';

class HobbySelectionPage extends StatefulWidget {
  const HobbySelectionPage({super.key});

  @override
  State<HobbySelectionPage> createState() => _HobbySelectionPageState();
}

class _HobbySelectionPageState extends State<HobbySelectionPage> {
  final List<Map<String, dynamic>> options = [
    {'name': 'Running', 'icon': Icons.directions_run},
    {'name': 'Cycling', 'icon': Icons.pedal_bike},
    {'name': 'Hiking', 'icon': Icons.terrain},
    {'name': 'Reading', 'icon': Icons.book},
    {'name': 'Coffee', 'icon': Icons.coffee},
    {'name': 'Photography', 'icon': Icons.photo_camera},
    {'name': 'Swimming', 'icon': Icons.pool},
    {'name': 'Gardening', 'icon': Icons.grass},
    {'name': 'Cooking', 'icon': Icons.restaurant},
    {'name': 'Board games', 'icon': Icons.videogame_asset},
    {'name': 'Football', 'icon': Icons.sports_soccer},
    {'name': 'Yoga', 'icon': Icons.self_improvement},
  ];

  final Set<String> selected = {};

  @override
  void initState() {
    super.initState();
    context.read<UserCubit>().loadHobbies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<UserCubit, UserState>(
        listener: (context, state) {
          if (state is UserLoaded) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Select hobbies you like (we will suggest activities based on weather)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    itemCount: options.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // صفين جنب بعض
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.2,
                        ),
                    itemBuilder: (context, index) {
                      final hobby = options[index]['name'];
                      final icon = options[index]['icon'] as IconData;
                      final isSelected = selected.contains(hobby);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selected.remove(hobby);
                            } else {
                              selected.add(hobby);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.green.withOpacity(0.85)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.green
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      icon,
                                      size: 40,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[800],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      hobby,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () {
                          context.read<UserCubit>().saveHobbies(
                            selected.toList(),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 14,
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
