abstract class AuthState {}

class AuthInitial extends AuthState {}

class HobbySelectionUpdated extends AuthState {
  final List<String> selectedHobbies;
  HobbySelectionUpdated(this.selectedHobbies);
}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {}

class AuthFailure extends AuthState {
  final String errorMessage;
  AuthFailure(this.errorMessage);
}
