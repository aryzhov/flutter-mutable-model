import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

abstract class Property {
  bool changed;
}

abstract class MutableModel<T extends Property> extends ChangeNotifier {

  List<T> get properties;

  bool flushChanges() {
    if(!changed)
      return false;
    notifyListeners();
    clearChanged();
    return true;
  }

  get changed {
    return properties.map((p) => p.changed).reduce((a, b) => a || b) ;
  }

  clearChanged() {
    for(var p in properties)
      p.changed = false;
  }

}
