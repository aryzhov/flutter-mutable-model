import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

abstract class Mutable {
  bool get changed;
  set changed(bool changed);
}


abstract class MutableObject extends ChangeNotifier {

  List<Mutable> get mutables;

  bool flushChanges() {
    if(!changed)
      return false;
    notifyListeners();
    clearChanged();
    return true;
  }

  get changed {
    return mutables.map((attr) => attr.changed).reduce((a, b) => a || b) ;
  }

  clearChanged() {
    for(var attr in mutables)
      attr.changed = false;
  }

}

