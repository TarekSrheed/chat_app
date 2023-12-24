import 'package:shared_preferences/shared_preferences.dart';

class HelperFunctions {
  //keys
  static String userLoggedInKey = "LOGGEDINKEY";
  static String userNameKey = "USERNAMEKEY";
  static String userEmailKey = "USEREMAILKEY";
  static String userHobbyKey = "USERHOBBYKEY";
  static String userAgeKey = "USERAGKEY";
  static String userHoppyKey = "USEHOPPYKEY";
  static String userHoppy1Key = "USEHOPPY1KEY";
  static String userHoppy2Key = "USEHOPPY2KEY";

  static Future<bool> saveUserLoggedInStatus(bool isUserLoggedIn) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setBool(userLoggedInKey, isUserLoggedIn);
  }

  static Future<bool> saveUserNameSF(String userName) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setString(userNameKey, userName);
  }

  static Future<bool> saveUserAgeSF(String age) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setString(userAgeKey, age);
  }

// save User Hoppy to SF
  static Future<bool> saveUserHoppySF(String hoppy) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setString(userHoppyKey, hoppy);
  }

  static Future<bool> saveUserHoppy1SF(String hoppy1) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setString(userHoppy1Key, hoppy1);
  }

  static Future<bool> saveUserHoppy2SF(String hoppy2) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setString(userHoppy2Key, hoppy2);
  }

  static Future<bool> saveUserEmailSF(String userEmail) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setString(userEmailKey, userEmail);
  }

  // saving the data to SF

  static Future<bool?> getUserLoggedInStatus() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getBool(userLoggedInKey);
  }

  static Future<String?> getUserEmailFromSF() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getString(userEmailKey);
  }

  static Future<String?> getUserNameFromSF() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getString(userNameKey);
  }

  static Future<String?> getUserAgeFromSF() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getString(userAgeKey);
  }

  static Future<String?> getUserHoppyFromSF() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getString(userHoppyKey);
  }

  static Future<String?> getUserHoppy1FromSF() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getString(userHoppy1Key);
  }

  static Future<String?> getUserHoppy2FromSF() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getString(userHoppy2Key);
  }
}
