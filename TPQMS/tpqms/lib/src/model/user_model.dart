import 'package:tpqms/src/constants.dart';

class UserModel {
  String uid;
  String name;
  String phoneNumber;

  UserModel({
    required this.uid,
    required this.name,
    required this.phoneNumber,
  });

//from map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map[Constants.uid] ?? '',
      name: map[Constants.name] ?? '',
      phoneNumber: map[Constants.phoneNumber] ?? '',
    );
  }

//to map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phoneNumber': phoneNumber,
    };
  }
}
