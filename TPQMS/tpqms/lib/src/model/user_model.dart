import 'package:tpqms/common/constants.dart';

class UserModel {
  final String uid;
  final String name;
  final String phoneNumber;
  final String age;
  final String height;

  UserModel({
    required this.uid,
    required this.name,
    required this.phoneNumber,
    required this.age,
    required this.height,
  });

//from map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map[Constants.uid] ?? '',
      name: map[Constants.name] ?? '',
      phoneNumber: map[Constants.phoneNumber] ?? '',
      age: map[Constants.age] ?? '',
      height: map[Constants.height] ?? '',
    );
  }

//to map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phoneNumber': phoneNumber,
      'age': age,
      'height': height,
    };
  }
}
