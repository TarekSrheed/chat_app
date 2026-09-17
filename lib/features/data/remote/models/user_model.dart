// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class UserModel {
  String? uid;
  String fullName;
  String email;
  String profilePic;
  String age;
  List<String> hobbies;
  List<String> groups;

  UserModel({
    this.uid,
    required this.fullName,
    required this.email,
    required this.profilePic,
    required this.age,
    required this.hobbies,
    required this.groups,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'profilePic': profilePic,
      'age': age,
      'hobbies': hobbies,
      'groups': groups,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      age: map['age'] ?? '',
      profilePic: map['profilePic'] ?? '',
      // التأكد من تحويل القوائم بشكل آمن حتى لا يحدث خطأ Type Cast
      groups: List<String>.from(map['groups'] ?? []),
      hobbies: List<String>.from(map['hobbies'] ?? []),
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);
}


class UserDataModel{
  String userName;
  String email;
  UserDataModel({
    required this.userName,
    required this.email,
  });
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userName': userName,
      'email': email,
    };
  }
  factory UserDataModel.fromMap(Map<String, dynamic> map) {
    return UserDataModel(
      userName: map['userName'] ?? '',
      email: map['email'] ?? '',
    );
  }
}