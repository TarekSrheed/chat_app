// ignore_for_file: use_build_context_synchronously
import 'package:chat_app/core/shared/app_string.dart';
import 'package:chat_app/features/view/cubit/hobby/hobby_cubit.dart';
import 'package:chat_app/features/view/cubit/hobby/hobby_state.dart';
import 'package:chat_app/features/view/screens/home_screen.dart';
import 'package:chat_app/features/data/remote/service/auth_service.dart';
import 'package:chat_app/core/shared/constants.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/widgets.dart';
import 'registration_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (context) => AuthCubit(),
      child: const LoginScreenBody(),
    );
  }
}

class LoginScreenBody extends StatefulWidget {
  const LoginScreenBody({super.key});

  @override
  State<LoginScreenBody> createState() => _LoginScreenBodyState();
}

class _LoginScreenBodyState extends State<LoginScreenBody> {
  final _formKey = GlobalKey<FormState>();
  AuthService authService = AuthService();
  String email = "";
  String password = "";
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AuthCubit>();
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
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
                  horizontal: kDefaultPadding, vertical: kDefaultPadding + 5),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      "Groupie",
                      style:
                          TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: kDefaultPadding / 2),
                    const Text(
                      AppString.loginNowToSeeWhatTheyAreTalking,
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
                    ),
                    Image.asset(
                      Constants.image,
                      height: 300,
                    ),
                    TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      decoration: textInputDecoration.copyWith(
                        labelText: Constants.yourEmail,
                        prefixIcon: Icon(
                          Icons.email,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          email = val;
                        });
                      },

                      // check tha validation
                      validator: (val) {
                        return RegExp(
                                    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^@`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                .hasMatch(val!)
                            ? null
                            : AppString.enterValidEmail;
                      },
                    ),
                    const SizedBox(height: kDefaultPadding / 2),
                    TextFormField(
                      obscureText: true,
                      decoration: textInputDecoration.copyWith(
                        labelText: Constants.yourPassword,
                        prefixIcon: Icon(
                          Icons.lock,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      validator: (val) {
                        if (val!.length < 6) {
                          return AppString.passwordTooShort;
                        } else {
                          return null;
                        }
                      },
                      onChanged: (val) {
                        setState(() {
                          password = val;
                        });
                      },
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 1.5,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30))),
                        child: const Text(
                          "Sign In",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            cubit.login(email: email, password: password);
                          }
                        },
                      ),
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 3,
                    ),
                    Text.rich(TextSpan(
                      text: AppString.dontHaveAccount,
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      children: <TextSpan>[
                        TextSpan(
                            text: "Register here",
                            style: const TextStyle(
                                color: Colors.black,
                                decoration: TextDecoration.underline),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                nextScreen(context, const RegistrationScreen());
                              }),
                      ],
                    )),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
