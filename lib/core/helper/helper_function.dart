import 'package:shared_preferences/shared_preferences.dart';

class HelperFunctions {
  //keys
  static String userLoggedInKey = "LOGGEDINKEY";
  static String userNameKey = "USERNAMEKEY";
  static String userEmailKey = "USEREMAILKEY";
  static String userHobbyKey = "USERHOBBYKEY";
  static String userAgeKey = "USERAGKEY";
  static String userHobbiesKey = "USERHOPPIESKEY";

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
  static Future<bool> saveUserHobbiesSF(List<String> hoppies) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setStringList(userHobbiesKey, hoppies);
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

  static Future<List<String>> getUserHobbiesSF() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getStringList(userHobbiesKey) ?? ["", "", ""];
  }
}
