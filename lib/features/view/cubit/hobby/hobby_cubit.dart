import 'package:chat_app/features/data/remote/models/user_model.dart';
import 'package:chat_app/features/data/remote/service/database_service.dart';
import 'package:chat_app/features/view/cubit/hobby/hobby_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/helper/helper_function.dart';
import '../../../data/remote/service/auth_service.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;

  List<String> selectedHobbies = ["Art", "Animal care", "Fashion"];

  AuthCubit({AuthService? authService})
      : _authService = authService ?? AuthService(),
        super(AuthInitial());

  /// تحديث قيمة هواية حسب المؤشر (Index)
  void updateHobby(int index, String value) {
    if (index >= 0 && index < selectedHobbies.length) {
      selectedHobbies[index] = value;
      emit(HobbySelectionUpdated(List.from(selectedHobbies)));
    }
  }

  /// تنفيذ عملية التسجيل وتخزين التفضيلات المحلية
  Future<void> registerUser({
    required String fullName,
    required String email,
    required String password,
    required String age,
  }) async {
    emit(AuthLoading());

    try {
      final result = await _authService.registerUserWithEmailandPassword(
        fullName: fullName,
        email: email,
        password: password,
        age: age,
        hobbies: selectedHobbies,
      );

      if (result == true) {
        // حفظ بيانات الجلسة محلية
        await HelperFunctions.saveUserLoggedInStatus(true);
        await HelperFunctions.saveUserEmailSF(email);
        await HelperFunctions.saveUserNameSF(fullName);
        await HelperFunctions.saveUserAgeSF(age);
        await HelperFunctions.saveUserHobbiesSF(selectedHobbies);

        emit(AuthSuccess());
      } else {
        emit(AuthFailure(result.toString()));
      }
    } catch (e) {
      emit(AuthFailure('An unexpected error occurred during registration.'));
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      final result =
          await _authService.loginWithUserNameandPassword(email, password);

      if (result == true) {
        UserModel? user =
            await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
                .gettingUserData(email);

        // saving the values to our shared preferences
        await HelperFunctions.saveUserLoggedInStatus(true);
        await HelperFunctions.saveUserEmailSF(email);
        await HelperFunctions.saveUserNameSF(user!.fullName);
        emit(AuthSuccess());
      } else {
        emit(AuthFailure(result.toString()));
      }
    } catch (e) {
      emit(AuthFailure('An unexpected error occurred during login.'));
    }
  }
}
