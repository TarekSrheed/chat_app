import 'package:flutter/material.dart';

const textInputDecoration = InputDecoration(
  contentPadding: EdgeInsets.symmetric(vertical: 5),
  labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.w300),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Color(0xFFee7b64), width: 2),
    borderRadius: BorderRadius.all(
      Radius.circular(10),
    ),
  ),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Color(0xFFee7b64), width: 2),
    borderRadius: BorderRadius.all(
      Radius.circular(10),
    ),
  ),
  errorBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Color(0xFFee7b64), width: 2),
  ),
);

void nextScreen( BuildContext context, Widget page) {
  Navigator.push(context, MaterialPageRoute(builder: (context) => page));
}

void nextScreenReplace( BuildContext context, Widget page) {
  Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (context) => page));
}

void showSnackbar(BuildContext context, Color color, String message) {
  ScaffoldMessenger.of(context).clearSnackBars();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontSize: 14),
      ),
      backgroundColor: color,
      // 2. تحديد مدة العرض
      duration: const Duration(seconds: 1), 
      // 3. طريقة ظهور واختفاء سلسة
      behavior: SnackBarBehavior.floating, 
      
    ),
  );
}

void showSnackbarProfile(BuildContext context, Color color, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontSize: 14),
      ),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
      action: SnackBarAction(
        label: "OK",
        onPressed: () {},
        textColor: Colors.white,
      ),
    ),
  );
}
