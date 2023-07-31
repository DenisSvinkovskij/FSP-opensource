import 'package:find_safe_places/models/user.dart';
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;

  get user => _user;

  void setUser(UserModel? user) {
    _user = user;
    notifyListeners();
  }
}
