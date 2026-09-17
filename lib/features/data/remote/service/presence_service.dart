import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class PresenceService {
final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
  app: Firebase.app(),
  databaseURL: 'https://chatapp-4a9e1-default-rtdb.firebaseio.com/',
);  
final FirebaseAuth _auth = FirebaseAuth.instance;

  // إعداد وتحديث حالة اتصال المستخدم الحالي تلقائياً
  void configureUserPresence() {
    final user = _auth.currentUser;
    if (user == null) return;

    // المرجع الخاص بحالة المستخدم داخل Realtime Database
    final DatabaseReference userPresenceRef =
        _db.ref().child("status").child(user.uid);

    // مرجع خاص بالتحقق من الاتصال بسيرفرات Realtime Database
    final DatabaseReference connectedRef = _db.ref(".info/connected");

    connectedRef.onValue.listen((event) {
      final isConnected = event.snapshot.value as bool? ?? false;

      if (isConnected) {
        // 1. إعداد السيرفر ليعلم عند قطع الاتصال (إغلاق التطبيق / انقطاع الإنترنت)
        userPresenceRef.onDisconnect().set({
          'isOnline': false,
          'lastSeen': ServerValue.timestamp,
        });

        // 2. تحديث الحالة فوراً إلى متصل أونلاين
        userPresenceRef.set({
          'isOnline': true,
          'lastSeen': ServerValue.timestamp,
        });
      }
    });
  }

  // الاستماع لحالة مستخدم آخر لطباعتها في الواجهة (مثل اسم الشخص أونلاين أو آخر ظهور)
  Stream<DatabaseEvent> getUserPresenceStream(String targetUid) {
    return _db.ref().child("status").child(targetUid).onValue;
  }

  // تحديث الحالة يدوياً عند تسجيل الخروج
  Future<void> setOffline() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _db.ref().child("status").child(user.uid).set({
        'isOnline': false,
        'lastSeen': ServerValue.timestamp,
      });
    }
  }
}