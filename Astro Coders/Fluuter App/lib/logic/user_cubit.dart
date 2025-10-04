// lib/logic/user_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/user_repository.dart';
import 'user_state.dart';

class UserCubit extends Cubit<UserState> {
  final UserRepository repository;

  UserCubit(this.repository) : super(UserInitial());
  // في UserCubit.dart - أضف هذه الدالة

Future<List<String>> getHobbies() async {
  if (state is UserLoaded) {
    return (state as UserLoaded).hobbies;
  } else {
    // إذا مفيش هوايات محملة، جيبها من الـ Repository
    final hobbies = await repository.loadHobbies();
    return hobbies;
  }
}
  Future<void> loadHobbies() async {
    try {
      emit(UserLoading());
      final hobbies = await repository.loadHobbies();
      if (hobbies.isEmpty) {
        emit(UserEmpty());
      } else {
        emit(UserLoaded(hobbies));
      }
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> saveHobbies(List<String> hobbies) async {
    try {
      emit(UserLoading());
      await repository.saveHobbies(hobbies);
      emit(UserLoaded(hobbies));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }
}
