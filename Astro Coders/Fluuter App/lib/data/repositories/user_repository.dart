// lib/data/repositories/user_repository.dart
class UserRepository {
  // In-memory for now. We'll swap to SharedPreferences or DB later if you want persistence.
  List<String> _selectedHobbies = [];

  Future<List<String>> loadHobbies() async {
    // simulate small delay (like reading from disk)
    await Future.delayed(const Duration(milliseconds: 150));
    return _selectedHobbies;
  }

  Future<void> saveHobbies(List<String> hobbies) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _selectedHobbies = List.from(hobbies);
  }
}
