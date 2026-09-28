import 'package:chat_app/features/view/cubit/hobby/hobby_cubit.dart';
import 'package:chat_app/features/view/cubit/hobby/hobby_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/shared/constants.dart';
import '../../../data/local/hobbies.dart';
import '../home_screen.dart';
import '../../widgets/widgets.dart';

class SelectedHobbyScreen extends StatelessWidget {
  final String email;
  final String password;
  final String fullName;
  final String age;

  const SelectedHobbyScreen({
    super.key,
    required this.password,
    required this.email,
    required this.age,
    required this.fullName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthCubit(),
      child: _HobbyScreenBody(
        email: email,
        password: password,
        fullName: fullName,
        age: age,
      ),
    );
  }
}

class _HobbyScreenBody extends StatefulWidget {
  final String email;
  final String password;
  final String fullName;
  final String age;

  const _HobbyScreenBody({
    required this.email,
    required this.password,
    required this.fullName,
    required this.age,
  });

  @override
  State<_HobbyScreenBody> createState() => _HobbyScreenBodyState();
}

class _HobbyScreenBodyState extends State<_HobbyScreenBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AuthCubit>();
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: primaryColor,
          onPressed: () {
            Navigator.pop(context);
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            nextScreenReplace(context, const HomeScreen());
          } else if (state is AuthFailure) {
            showSnackbar(context, Colors.red, state.errorMessage);
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding,
                vertical: kDefaultPadding + 5,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(height: kDefaultPadding * 3),
                    const Text(
                      "Groupie",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: kDefaultPadding * 2),
                    const Text(
                      "Add your favorite interests to share with friends",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: kDefaultPadding * 2),

                    // إتاحة القوائم المنسدلة من خلال دالة إعادة استخدام مفردة
                    ...List.generate(
                      cubit.selectedHobbies.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: kDefaultPadding),
                        child: _buildHobbyDropdown(
                          context: context,
                          initialValue: cubit.selectedHobbies[index],
                          onChanged: (val) {
                            if (val != null) {
                              cubit.updateHobby(index, val);
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: kDefaultPadding * 0.5),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "Register",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            cubit.registerUser(
                              fullName: widget.fullName,
                              email: widget.email,
                              password: widget.password,
                              age: widget.age,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHobbyDropdown({
    required BuildContext context,
    required String initialValue,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String>(
        initialValue: initialValue,
        decoration: textInputDecoration,
        items: hobbies
            .map(
              (hobby) => DropdownMenuItem<String>(
                value: hobby,
                child: Text(
                  hobby,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
