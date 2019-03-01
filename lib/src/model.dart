part of mutable_model;

/// A property contains a value that can be changed.
abstract class Mutable<T> {
  T value;
  bool changed;
}

/// A model contains mutable properties and fires a change event when [flushChanges] is called.
abstract class MutableModel<P extends Mutable> extends ChangeNotifier {

  List<P> get properties;

  /// Fires a change event and clears the change flag on all properties. Returns true if there were changes.
  bool flushChanges() {
    if(!changed)
      return false;
    notifyListeners();
    for(var p in properties)
      p.changed = false;
    return true;
  }

  /// Returns true if any of the properties has changed.
  get changed {
    return properties.map((p) => p.changed).reduce((a, b) => a || b) ;
  }

}
