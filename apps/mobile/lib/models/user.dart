import 'package:flutter/cupertino.dart';

class User with ChangeNotifier {
  // ChangeNotifier allows widgets using this model to be updated when data changes
  String name;
  String surname;
  String phoneNumber;

  User({
    required this.name,
    required this.surname,
    required this.phoneNumber,
  });

  // Methods to update user data
  void set({
    String? name,
    String? surname,
    String? phoneNumber,
  }) {
    if (name != null) this.name = name;
    if (surname != null) this.surname = surname;
    if (phoneNumber != null) this.phoneNumber = phoneNumber;

    // Notifies listeners that the data was updated
    notifyListeners();
  }
}
