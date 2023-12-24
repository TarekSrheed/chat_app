import 'package:chat_app/screens/auth/login_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../helper/helper_function.dart';
import '../../service/auth_service.dart';
import '../../shared/constants.dart';
import '../../widgets/widgets.dart';
import '../hobby_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  String email = "";
  String password = "";
  bool _isLoading = false;
  String fullName = "";
  String age = "";
  AuthService authService = AuthService();
  final formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding, vertical: kDefaultPadding + 5),
                child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        const Text(
                          "Groupie",
                          style: TextStyle(
                              fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: kDefaultPadding / 2),
                        const Text(
                          "Create your account now to chat and explore",
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w400),
                        ),
                        Image.asset(
                          Constants.registerImage,
                          height: 300,
                        ),
                        TextFormField(
                          keyboardType: TextInputType.emailAddress,
                          decoration: textInputDecoration.copyWith(
                              labelText: "Full Name",
                              prefixIcon: Icon(
                                Icons.person,
                                color: Theme.of(context).primaryColor,
                              )),
                          onChanged: (val) {
                            setState(() {
                              fullName = val;
                            });
                          },
                          validator: (val) {
                            if (val!.isNotEmpty) {
                              return null;
                            } else {
                              return "Name cannot be empty";
                            }
                          },
                        ),
                        const SizedBox(
                          height: kDefaultPadding / 2,
                        ),
                        TextFormField(
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: textInputDecoration.copyWith(
                              labelText: "Age",
                              prefixIcon: Icon(
                                Icons.accessibility_outlined,
                                color: Theme.of(context).primaryColor,
                              )),
                          onChanged: (val) {
                            setState(() {
                              age = val;
                            });
                          },
                          validator: (val) {
                            if (val!.isNotEmpty) {
                              return null;
                            } else {
                              return "Age cannot be empty";
                            }
                          },
                        ),
                        const SizedBox(
                          height: kDefaultPadding / 2,
                        ),
                        TextFormField(
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
                                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                    .hasMatch(val!)
                                ? null
                                : "Please enter a valid email";
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
                              )),
                          validator: (val) {
                            if (val!.length < 6) {
                              return "Password must be at least 6 characters";
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
                                primary: Theme.of(context).primaryColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30))),
                            child: const Text(
                              "Next",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            onPressed: () {
                              register();
                            },
                          ),
                        ),
                        const SizedBox(
                          height: kDefaultPadding / 3,
                        ),
                        Text.rich(TextSpan(
                          text: "Already have an account? ",
                          style: const TextStyle(
                              color: Colors.black, fontSize: 14),
                          children: <TextSpan>[
                            TextSpan(
                                text: "Login now",
                                style: const TextStyle(
                                    color: Colors.black,
                                    decoration: TextDecoration.underline),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    nextScreen(context, const LoginScreen());
                                  }),
                          ],
                        )),
                      ],
                    )),
              ),
            ),
    );
  }

  register() {
    if (formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      nextScreen(
        context,
        hobbyScreen(
          email: email,
          password: password,
          fullName: fullName,
          age: age,
        ),
      );
    }
    // } else {
    //   showSnackbar(context, Colors.red, );
    //   setState(() {
    //     _isLoading = false;
    //   });
    // }
  }
  // register() async {
  //   if (formKey.currentState!.validate()) {
  //     setState(() {
  //       _isLoading = true;
  //     });
  //     await authService
  //         .registerUserWithEmailandPassword(fullName, email, password, age)
  //         .then((value) async {
  //       if (value == true) {
  //         // saving the shared preference state
  //         await HelperFunctions.saveUserLoggedInStatus(true);
  //         await HelperFunctions.saveUserEmailSF(email);
  //         await HelperFunctions.saveUserNameSF(fullName);
  //         await HelperFunctions.saveUserAgeSF(age);
  //         nextScreen(context, hobbyScreen());
  //       } else {
  //         showSnackbar(context, Colors.red, value);
  //         setState(() {
  //           _isLoading = false;
  //         });
  //       }
  //     });
  //   }
  // }
}
