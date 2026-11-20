import 'dart:async';

import 'package:chat_app/features/data/remote/models/category_model.dart';
import 'package:chat_app/features/data/remote/models/user_model.dart';
import 'package:chat_app/features/data/remote/service/notification_service.dart';
import 'package:chat_app/features/view/widgets/group_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get userCollection =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get publicUserCollection =>
      _firestore.collection('users_public');
  CollectionReference<Map<String, dynamic>> get groupCollection =>
      _firestore.collection('groups');
  CollectionReference<Map<String, dynamic>> get groupDirectoryCollection =>
      _firestore.collection('groupDirectory');
  CollectionReference<Map<String, dynamic>> get categoryCollection =>
      _firestore.collection('categary');

  String get _authenticatedUid {
    final currentUid = uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid.isEmpty) {
      throw StateError('A signed-in user is required for this operation.');
    }
    return currentUid;
  }

  Future<void> savingUserData(UserModel user) async {
    final userId = _authenticatedUid;
    if (user.uid != userId) {
      throw StateError('User profile UID does not match the signed-in user.');
    }

    final batch = _firestore.batch();
    batch.set(userCollection.doc(userId), user.toMap());
    batch.set(publicUserCollection.doc(userId), {
      'uid': userId,
      'fullName': user.fullName,
      'profilePic': user.profilePic,
    });
    await batch.commit();
  }

  Future<UserModel?> gettingUserData(String email) async {
    final userId = _authenticatedUid;
    final snapshot = await userCollection.doc(userId).get();
    final userData = snapshot.data();
    if (userData == null || userData['email'] != email) return null;
    return UserModel.fromMap(userData);
  }

  Future<void> migrateLegacyUserData() async {
    final userId = _authenticatedUid;
    final userSnapshot = await userCollection.doc(userId).get();
    final userData = userSnapshot.data();
    if (userData == null) return;

    final profileReference = publicUserCollection.doc(userId);
    final profileSnapshot = await profileReference.get();
    if (!profileSnapshot.exists) {
      await profileReference.set({
        'uid': userId,
        'fullName': userData['fullName'] ?? '',
        'profilePic': userData['profilePic'] ?? '',
      });
    }

    final memberGroups =
        await groupCollection.where('members', arrayContains: userId).get();
    for (final group in memberGroups.docs) {
      await _ensureGroupMembershipAndDirectory(group);
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    final snapshot = await categoryCollection.get();
    return snapshot.docs
        .map((doc) => CategoryModel.fromMap(doc.data()))
        .toList();
  }

  Future<void> updateUserData(String newName) async {
    final userId = _authenticatedUid;
    final name = newName.trim();
    if (name.isEmpty) {
      throw ArgumentError.value(newName, 'newName', 'Name cannot be empty.');
    }
    final userReference = userCollection.doc(userId);
    final profileReference = publicUserCollection.doc(userId);
    final userSnapshot = await userReference.get();
    final privateUser = userSnapshot.data();
    if (privateUser == null) {
      throw StateError('The signed-in user profile is unavailable.');
    }
    final existingProfile = await profileReference.get();
    final profilePic = existingProfile.data()?['profilePic'] ??
        privateUser['profilePic'] ??
        '';

    final batch = _firestore.batch();
    batch.update(userReference, {'fullName': name});
    batch.set(profileReference, {
      'uid': userId,
      'fullName': name,
      'profilePic': profilePic,
    });
    await batch.commit();

    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser != null && authUser.uid == userId) {
      await authUser.updateDisplayName(name);
      await authUser.reload();
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserGroups() {
    final userId = _authenticatedUid;
    return groupCollection
        .where('members', arrayContains: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      for (final group in snapshot.docs) {
        await _ensureGroupMembershipAndDirectory(group);
      }
      return snapshot;
    });
  }

  Future<void> _ensureGroupMembershipAndDirectory(
    QueryDocumentSnapshot<Map<String, dynamic>> group,
  ) async {
    final userId = _authenticatedUid;
    final membershipReference =
        group.reference.collection('members').doc(userId);
    final directoryReference = groupDirectoryCollection.doc(group.id);
    final snapshots = await Future.wait([
      membershipReference.get(),
      directoryReference.get(),
    ]);

    final batch = _firestore.batch();
    var hasWrites = false;
    if (!snapshots[0].exists) {
      batch.set(membershipReference, {
        'uid': userId,
        'groupId': group.id,
        'createdAt': FieldValue.serverTimestamp(),
      });
      hasWrites = true;
    }

    if (!snapshots[1].exists) {
      final data = group.data();
      batch.set(directoryReference, {
        'groupId': group.id,
        'groupName': data['groupName'] ?? '',
        'category': data['category'] ?? '',
        'groupIcon': data['groupIcon'] ?? '',
        'adminName': data['adminName'] ?? '',
        'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
      });
      hasWrites = true;
    }

    if (hasWrites) await batch.commit();
  }

  Future<void> createGroup(
    String userName,
    String id,
    String groupName,
    String category,
  ) async {
    final userId = _authenticatedUid;
    final profile = await _getCurrentPublicProfile(userId);
    final groupReference = groupCollection.doc();
    final createdAt = FieldValue.serverTimestamp();
    final data = <String, dynamic>{
      'groupName': groupName.trim(),
      'category': category,
      'groupIcon': '',
      'admin': userId,
      'adminName': profile['fullName'],
      'members': [userId],
      'groupId': groupReference.id,
      'recentMessage': '',
      'recentMessageSender': '',
      'recentMessageTime': createdAt,
      'recentMessageId': '',
      'createdAt': createdAt,
    };

    final directoryReference = groupDirectoryCollection.doc(groupReference.id);
    final batch = _firestore.batch();
    batch.set(groupReference, data);
    batch.set(directoryReference, {
      'groupId': groupReference.id,
      'groupName': data['groupName'],
      'category': data['category'],
      'groupIcon': data['groupIcon'],
      'adminName': data['adminName'],
      'createdAt': createdAt,
    });
    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getChats(String groupId) {
    return groupCollection
        .doc(groupId)
        .collection('messages')
        .orderBy('time', descending: false)
        .snapshots();
  }

  Future<String> getGroupAdmin(String groupId) async {
    final doc = await groupCollection.doc(groupId).get();
    return doc.data()?['adminName'] as String? ?? '';
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getGroupMembers(
    String groupId,
  ) {
    return groupCollection.doc(groupId).snapshots();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> searchByName(
    String groupName,
  ) async {
    final query = groupName.trim().toLowerCase();
    if (query.isEmpty) return [];

    final snapshot = await groupDirectoryCollection.get();
    return snapshot.docs.where((doc) {
      final name = doc.data()['groupName'];
      return name is String && name.toLowerCase().contains(query);
    }).toList();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> searchBycategory(
    String category,
  ) {
    return groupDirectoryCollection
        .where('category', isEqualTo: category)
        .get();
  }

  Future<bool> isUserJoined(String groupId) async {
    if (uid == null && FirebaseAuth.instance.currentUser == null) return false;
    final userId = _authenticatedUid;
    final membership = await groupCollection
        .doc(groupId)
        .collection('members')
        .doc(userId)
        .get();
    return membership.exists;
  }

  Future<void> toggleGroupJoin(
    String groupId,
    String userName,
    String groupName,
  ) async {
    final userId = _authenticatedUid;
    final groupReference = groupCollection.doc(groupId);
    final membershipReference =
        groupReference.collection('members').doc(userId);
    final joined = await isUserJoined(groupId);
    final batch = _firestore.batch();

    if (joined) {
      final groupSnapshot = await groupReference.get();
      final groupData = groupSnapshot.data();
      if (groupData == null) {
        throw StateError('The group no longer exists.');
      }

      final members = (groupData['members'] as List<dynamic>? ?? [])
          .where((member) => GroupUtils.getId(member.toString()) != userId)
          .toList();
      batch.update(groupReference, {'members': members});
      batch.delete(membershipReference);
    } else {
      batch.update(groupReference, {
        'members': FieldValue.arrayUnion([userId]),
      });
      batch.set(membershipReference, {
        'uid': userId,
        'groupId': groupId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> sendMessage(
    String groupId,
    Map<String, dynamic> chatMessageData,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('A signed-in user is required to send a message.');
    }
    if (uid != null && uid != user.uid) {
      throw StateError('The message sender does not match the signed-in user.');
    }
    final senderId = user.uid;
    final message =
        (chatMessageData['message'] ?? chatMessageData['text'] ?? '')
            .toString()
            .trim();
    if (message.isEmpty || message.length > 4000) {
      throw ArgumentError.value(message.length, 'message.length');
    }

    await _getCurrentPublicProfile(senderId);
    final senderSnapshot = await userCollection.doc(senderId).get();
    final senderName = senderSnapshot.data()?['fullName'];
    if (senderName is! String || senderName.trim().isEmpty) {
      throw StateError('The signed-in user profile has no display name.');
    }
    final messageReference =
        groupCollection.doc(groupId).collection('messages').doc();
    final messageTime = FieldValue.serverTimestamp();
    final messageData = <String, dynamic>{
      'groupId': groupId,
      'message': message,
      'sender': senderName.trim(),
      'senderId': senderId,
      'time': messageTime,
    };

    final batch = _firestore.batch();
    batch.set(messageReference, messageData);
    batch.update(groupCollection.doc(groupId), {
      'recentMessage': message,
      'recentMessageSender': senderName.trim(),
      'recentMessageTime': messageTime,
      'recentMessageId': messageReference.id,
    });
    await batch.commit();

    unawaited(NotificationService.instance.sendMessageNotification(
      groupId: groupId,
      messageId: messageReference.id,
    ));
  }

  Future<Map<String, dynamic>> _getCurrentPublicProfile(String userId) async {
    final profileReference = publicUserCollection.doc(userId);
    var profileSnapshot = await profileReference.get();
    if (!profileSnapshot.exists) {
      final privateSnapshot = await userCollection.doc(userId).get();
      final privateUser = privateSnapshot.data();
      if (privateUser == null) {
        throw StateError('The signed-in user profile is unavailable.');
      }
      await profileReference.set({
        'uid': userId,
        'fullName': privateUser['fullName'] ?? '',
        'profilePic': privateUser['profilePic'] ?? '',
      });
      profileSnapshot = await profileReference.get();
    }

    final profile = profileSnapshot.data();
    final name = profile?['fullName'];
    if (name is! String || name.trim().isEmpty) {
      throw StateError('The signed-in user profile has no display name.');
    }
    return profile!;
  }
}
