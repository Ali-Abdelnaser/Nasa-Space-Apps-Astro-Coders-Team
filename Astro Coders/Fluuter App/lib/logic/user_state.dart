// lib/logic/user_state.dart
abstract class UserState {}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final List<String> hobbies;
  UserLoaded(this.hobbies);
}

class UserEmpty extends UserState {}

class UserError extends UserState {
  final String message;
  UserError(this.message);
}
