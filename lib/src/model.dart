part of mutable_model;

/// A property contains a value that can be changed.
abstract class Mutable<T> {
  T value;
  T oldValue;
  bool changed;
}

class MutableModelChange<M extends MutableModel> extends o.ChangeRecord {
  final M model;
  final Map<Mutable, dynamic> oldValues;
  MutableModelChange(this.model, this.oldValues);
}

/// A model contains mutable properties and fires a change event when [flushChanges] is called.
abstract class MutableModel<P extends Mutable> extends o.ChangeNotifier<MutableModelChange> with ChangeNotifier {

  List<P> get properties;

  /// Fires a change event and clears the change flag on all properties. Returns true if there were changes.
  bool flushChanges() {
    if(!changed)
      return false;
    if(hasObservers) {
      final Map<P, dynamic> oldValues = Map.fromEntries(properties.where(
              (p) => p.changed).map((p) =>
          MapEntry<P, dynamic>(p, p.oldValue)));
      notifyChange(MutableModelChange(this, oldValues));
    }
    if(hasListeners)
      notifyListeners();
    for(var p in properties)
      p.changed = false;
    return true;
  }

//  @override
//  bool deliverChanges() {
//    try {
//      return super.deliverChanges();
//    } finally {
//      for(var p in properties)
//        p.changed = false;
//    }
//  }
//
  /// Returns true if any of the properties has changed.
  get changed {
    for(var p in properties)
      if(p.changed)
        return true;
    return false;
  }

}
