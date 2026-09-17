import 'package:chat_app/features/data/remote/models/category_model.dart';
import 'package:chat_app/features/data/remote/models/user_model.dart';
import 'package:chat_app/features/data/remote/service/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  // المراجع الخاصة بالمجموعات (Collections)
  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection("users");
  final CollectionReference groupCollection =
      FirebaseFirestore.instance.collection("groups");
  final CollectionReference categoryCollection =
      FirebaseFirestore.instance.collection("categary");

  // حفظ بيانات المستخدم عند التسجيل
  Future<void> savingUserData(UserModel user) async {
    return userCollection.doc(uid).set(user.toMap());
  }

  // جلب بيانات المستخدم عبر البريد الإلكتروني
  Future<UserModel?> gettingUserData(String email) async {
    final QuerySnapshot snapshot =
        await userCollection.where("email", isEqualTo: email).get();
    if (snapshot.docs.isNotEmpty) {
      final userData = snapshot.docs.first.data() as Map<String, dynamic>;
      return UserModel.fromMap(userData);
    } else {
      return null;
    }
  }

  // جلب جميع التصنيفات
  Future<List<CategoryModel>> getCategories() async {
    final QuerySnapshot snapshot = await categoryCollection.get();
    return snapshot.docs.map((doc) {
      return CategoryModel.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();
  }
  

  // تحديث الاسم الشخصي للمستخدم
  Future<void> updateUserData(String newName) async {
    await userCollection.doc(uid).update({'fullName': newName});
  }

  // جلب المجموعات التي ينتمي إليها المستخدم حالياً (بدون الحاجة لمصفوفة groups في users)
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserGroups() {
    return groupCollection
        .where("members", arrayContains: uid)
        .snapshots()
        .cast<QuerySnapshot<Map<String, dynamic>>>();
  }

  // إنشاء مجموعة جديدة
  Future<void> createGroup(
    String userName,
    String id,
    String groupName,
    String category,
  ) async {
    final DocumentReference groupDocumentReference = await groupCollection.add({
      "groupName": groupName,
      "category": category,
      "groupIcon": "",
      "admin": uid,
      "adminName": userName,
      "members": [uid], // إضافة UID الصافي فقط
      "groupId": "",
      "recentMessage": "",
      "recentMessageSender": "",
      "recentMessageTime": FieldValue.serverTimestamp(),
      "createdAt": FieldValue.serverTimestamp(),
    });

    // تحديث groupId بداخل المستند برقم المستند المنشأ
    await groupDocumentReference.update({
      "groupId": groupDocumentReference.id,
    });
  }

  // جلب الرسائل الفرعية للمجموعة مرتبة حسب الوقت
  Stream<QuerySnapshot<Map<String, dynamic>>> getChats(String groupId) {
    return groupCollection
        .doc(groupId)
        .collection('messages')
        .orderBy('time', descending: false)
        .snapshots()
        .cast<QuerySnapshot<Map<String, dynamic>>>();
  }

  // جلب UID أدمن المجموعة
  Future<String> getGroupAdmin(String groupId) async {
    final DocumentSnapshot doc = await groupCollection.doc(groupId).get();
    return doc['adminName'] as String;
  }

  // جلب بيانات المجموعة وأعضائها
  Stream<DocumentSnapshot<Map<String, dynamic>>> getGroupMembers(
    String groupId,
  ) {
    return groupCollection
        .doc(groupId)
        .snapshots()
        .cast<DocumentSnapshot<Map<String, dynamic>>>();
  }

  // البحث عن مجموعة بالاسم
  Future<QuerySnapshot> searchByName(String groupName) {
    return groupCollection.where("groupName", isEqualTo: groupName).get();
  }

  // البحث عن المجموعات بتصنيف معني
  Future<QuerySnapshot> searchBycategory(String category) {
    return groupCollection.where("category", isEqualTo: category).get();
  }

  // التحقق من انضمام المستخدم عبر فحص مصفوفة members في مستند المجموعة المباشرة
  Future<bool> isUserJoined(String groupId) async {
    if (uid == null) return false;
    final DocumentSnapshot groupDoc = await groupCollection.doc(groupId).get();
    if (groupDoc.exists && groupDoc.data() != null) {
      List<dynamic> members = (groupDoc.data() as Map<String, dynamic>)['members'] ?? [];
      return members.contains(uid);
    }
    return false;
  }

  // الانضمام للمجموعة أو المغادرة منه
  Future<void> toggleGroupJoin(
      String groupId, String userName, String groupName) async {
    DocumentReference groupDocumentReference = groupCollection.doc(groupId);

    bool joined = await isUserJoined(groupId);

    if (joined) {
      // إزالة UID المستخدم من مصفوفة الأعضاء
      await groupDocumentReference.update({
        "members": FieldValue.arrayRemove([uid])
      });
    } else {
      // إضافة UID المستخدم إلى مصفوفة الأعضاء
      await groupDocumentReference.update({
        "members": FieldValue.arrayUnion([uid])
      });
    }
  }

  // إرسال رسالة وتحديث بيانات أحدث رسالة بالوقت نفسه
  Future<void> sendMessage(
      String groupId, Map<String, dynamic> chatMessageData) async {
    // 1. إضافة الرسالة للمجموعة الفرعية messages
    await groupCollection
        .doc(groupId)
        .collection("messages")
        .add(chatMessageData);

    // 2. تحديث بيانات أحدث رسالة في مستند المجموعة الرئيسي (Inbox Preview)
    await groupCollection.doc(groupId).update({
      "recentMessage": chatMessageData['message'] ?? chatMessageData['text'] ?? "",
      "recentMessageSender": chatMessageData['sender'] ?? "",
      "recentMessageTime": chatMessageData['time'] ?? FieldValue.serverTimestamp(),
    });
    // 3. إرسال الإشعار لأعضاء المجموعة (باستثناء المُرْسِل نفسه)
    final groupDoc = await groupCollection.doc(groupId).get();
    if (groupDoc.exists) {
      List<dynamic> members = groupDoc['members'] ?? [];
      String groupName = groupDoc['groupName'] ?? "مجموعة جديدة";

      for (String memberUid in members) {
        if (memberUid != uid) { // عدم إرسال الإشعار للمستخدِم الذي أرسل الرسالة
          final userDoc = await userCollection.doc(memberUid).get();
          if (userDoc.exists && userDoc.data() != null) {
            String? fcmToken = (userDoc.data() as Map<String, dynamic>)['fcmToken'];
            if (fcmToken != null && fcmToken.isNotEmpty) {
              await NotificationService.sendPushNotification(
                targetToken: fcmToken,
                title: groupName,
                body: "${chatMessageData['sender']}: ${chatMessageData['message']}",
                data: {
                  "groupId": groupId,
                  "groupName": groupName,
                },
              );
            }
          }
        }
      }
    }
  }
}