class GroupUtils {
  //  static String getName(String r) {
  //   if (r.contains("_")) {
  //     return r.substring(r.indexOf("_") + 1);
  //   }
  //   return r;
  // }

//  static String getId(String res) {
//     if (res.contains("_")) {
//       return res.substring(0, res.indexOf("_"));
//     }
//     return res;
//   }
  static bool isUserJoined(
      List<dynamic> members, String userId, String userName) {
    return members.contains(userId) || members.contains("${userId}_$userName");
  }
}
