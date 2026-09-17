import 'package:chat_app/features/data/local/hobbies.dart';
import 'package:chat_app/features/view/screens/home_screen.dart';

import 'package:flutter/material.dart';

import '../../../core/helper/helper_function.dart';
import '../../data/remote/service/auth_service.dart';
import '../../../core/shared/constants.dart';
import '../widgets/widgets.dart';

class HobbyScreen extends StatefulWidget {
  final String email;
  final String password;
  final String fullName;
  final String age;
  const HobbyScreen({
    Key? key,
    required this.password,
    required this.email,
    required this.age,
    required this.fullName,
  }) : super(key: key);

  @override
  State<HobbyScreen> createState() => _HobbyScreenState();
}

class _HobbyScreenState extends State<HobbyScreen> {
  bool _isLoading = false;
  List<String> userHobbies = ["Art", "Animal care", "Fashion"];

  AuthService authService = AuthService();
  final formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
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
                        const SizedBox(
                          height: kDefaultPadding * 3,
                        ),
                        const Text(
                          "Groupie",
                          style: TextStyle(
                              fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          height: kDefaultPadding * 2,
                        ),
                        const Text(
                          "Add your favorite interests to share with friends",
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: kDefaultPadding),
                        SizedBox(
                          width: 200,
                          child: DropdownButtonFormField<String>(
                            initialValue: userHobbies[0],
                            decoration: textInputDecoration,
                            items: hobbies
                                .map((hobby) => DropdownMenuItem<String>(
                                      value: hobby,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: kDefaultPadding * 3.7),
                                        child: Text(
                                          hobby,
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .primaryColor),
                                        ),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => userHobbies[0] = val!),
                          ),
                        ),
                        const SizedBox(
                          height: kDefaultPadding,
                        ),
                        SizedBox(
                          width: 200,
                          child: DropdownButtonFormField<String>(
                            initialValue: userHobbies[1],
                            decoration: textInputDecoration,
                            items: hobbies
                                .map((hobby) => DropdownMenuItem<String>(
                                      value: hobby,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: kDefaultPadding * 3.7),
                                        child: Text(
                                          hobby,
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .primaryColor),
                                        ),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => userHobbies[1] = val!),
                          ),
                        ),
                        const SizedBox(
                          height: kDefaultPadding,
                        ),
                        SizedBox(
                          width: 200,
                          child: DropdownButtonFormField<String>(
                            initialValue: userHobbies[2],
                            decoration: textInputDecoration,
                            items: hobbies
                                .map((hobby) => DropdownMenuItem<String>(
                                      value: hobby,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: kDefaultPadding * 3.7),
                                        child: Text(
                                          hobby,
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .primaryColor),
                                        ),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => userHobbies[2] = val!),
                          ),
                        ),
                        const SizedBox(
                          height: kDefaultPadding * 1.5,
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
                              "Register",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            onPressed: () {
                              // nextScreenReplace(context, HomeScreen());
                              register();
                            },
                          ),
                        ),
                        const SizedBox(
                          height: kDefaultPadding / 3,
                        ),
                      ],
                    )),
              ),
            ),
    );
  }

// register (){
//   nextScreen(context, HomeScreen());
// }
  register() async {
    if (formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      await authService.registerUserWithEmailandPassword(
          fullName: widget.fullName,
          email: widget.email,
          password: widget.password,
          age: widget.age,
          hobbies: [
            userHobbies[0],
            userHobbies[1],
            userHobbies[2]
          ]).then((value) async {
        if (value == true) {
          // saving the shared preference state
          await HelperFunctions.saveUserLoggedInStatus(true);
          await HelperFunctions.saveUserEmailSF(widget.email);
          await HelperFunctions.saveUserNameSF(widget.fullName);
          await HelperFunctions.saveUserAgeSF(widget.age);
          await HelperFunctions.saveUserHobbiesSF(
              [userHobbies[0], userHobbies[1], userHobbies[2]]);

          nextScreen(context, const HomeScreen());
        } else {
          showSnackbar(context, Colors.red, value);
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }
}
