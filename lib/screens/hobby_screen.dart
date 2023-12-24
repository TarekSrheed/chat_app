import 'package:chat_app/screens/home_screen.dart';

import 'package:flutter/material.dart';

import '../helper/helper_function.dart';
import '../service/auth_service.dart';
import '../shared/constants.dart';
import '../widgets/widgets.dart';

class hobbyScreen extends StatefulWidget {
  String email;
  String password;
  String fullName;
  String age;
  hobbyScreen(
      {Key? key,
      required this.password,
      required this.email,
      required this.age,
      required this.fullName})
      : super(key: key);

  @override
  State<hobbyScreen> createState() => _hobbyScreenState();
}

class _hobbyScreenState extends State<hobbyScreen> {
  bool _isLoading = false;
  String currentHobby = "Art";
  String currentHobby1 = "Animal care";
  String currentHobby2 = "Fashion";
  final List<String> hobbys = [
    'Art',
    'Animal care',
    'Cars',
    'Education',
    'Fashion',
    'Games',
    'History',
    'Music',
    'Social',
    'Sport'
  ];

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
                            value: currentHobby,
                            decoration: textInputDecoration,
                            items: hobbys
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
                                setState(() => currentHobby = val!),
                          ),
                        ),
                        const SizedBox(
                          height: kDefaultPadding,
                        ),
                        SizedBox(
                          width: 200,
                          child: DropdownButtonFormField<String>(
                            value: currentHobby2,
                            decoration: textInputDecoration,
                            items: hobbys
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
                                setState(() => currentHobby2 = val!),
                          ),
                        ),
                        const SizedBox(
                          height: kDefaultPadding,
                        ),
                        SizedBox(
                          width: 200,
                          child: DropdownButtonFormField<String>(
                            value: currentHobby1,
                            decoration: textInputDecoration,
                            items: hobbys
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
                                setState(() => currentHobby1 = val!),
                          ),
                        ),
                        const SizedBox(
                          height: kDefaultPadding * 1.5,
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
register (){
  nextScreen(context, HomeScreen());
}
  // register() async {
  //   if (formKey.currentState!.validate()) {
  //     setState(() {
  //       _isLoading = true;
  //     });
  //     await authService
  //         .registerUserWithEmailandPassword(
  //             widget.fullName,
  //             widget.email,
  //             widget.password,
  //             widget.age,
  //             currentHobby,
  //             currentHobby1,
  //             currentHobby2)
  //         .then((value) async {
  //       if (value == true) {
  //         // saving the shared preference state
  //         await HelperFunctions.saveUserLoggedInStatus(true);
  //         await HelperFunctions.saveUserEmailSF(widget.email);
  //         await HelperFunctions.saveUserNameSF(widget.fullName);
  //         await HelperFunctions.saveUserAgeSF(widget.age);
  //         await HelperFunctions.saveUserHoppySF(currentHobby);
  //         await HelperFunctions.saveUserHoppy1SF(currentHobby1);
  //         await HelperFunctions.saveUserHoppy2SF(currentHobby2);
  //         nextScreen(context, HomeScreen());
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
