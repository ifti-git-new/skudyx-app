import 'package:flutter/foundation.dart';

enum IdType { nid, passport, driving }

class IdentityVerificationController extends ChangeNotifier {
  IdType? selected;
  bool captured = false;

  void select(IdType type) {
    selected = type;
    notifyListeners();
  }

  void setCaptured(bool v) {
    captured = v;
    notifyListeners();
  }

  void reset() {
    selected = null;
    captured = false;
    notifyListeners();
  }
}
