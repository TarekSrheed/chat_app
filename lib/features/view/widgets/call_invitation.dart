// import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
// import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';


// import '../static.dart';

// // class CallInvitationPage extends StatelessWidget {
// //   const CallInvitationPage(
// //       {Key? key, required this.userName, required this.child})
// //       : super(key: key);
// //   final String userName;
// //   final Widget child;
// //   @override
// //   Widget build(BuildContext context) {
// //     return ZegoUIKitPrebuiltCallWithInvitation(
// //       appID: Statics.appID,
// //       appSign: Statics.appSign,
// //       userID: userName,
// //       userName: userName,
// //       plugins: [ZegoUIKitSignalingPlugin()],
// //       child: child,
// //     );
// //   }
// // }
//  onUserLogin(String userName) {
//   /// 1.2.1. initialized ZegoUIKitPrebuiltCallInvitationService
//   /// when app's user is logged in or re-logged in
//   /// We recommend calling this method as soon as the user logs in to your app.
//   ZegoUIKitPrebuiltCallInvitationService().init(
//     appID: Statics.appID /*input your AppID*/,
//     appSign: Statics.appSign /*input your AppSign*/,
//     userID: userName,
//     userName: userName,
//     plugins: [ZegoUIKitSignalingPlugin()],
//   );
// }

// /// on App's user logout
// void onUserLogout() {
//   /// 1.2.2. de-initialization ZegoUIKitPrebuiltCallInvitationService
//   /// when app's user is logged out
//   ZegoUIKitPrebuiltCallInvitationService().uninit();
// }


