part of mutable_model;

/// A property contains a value that can be changed.
abstract class Mutable<T> {
  T value;
  bool changed;
}

/// A model contains mutable properties and fires a change event when [flushChanges] is called.
abstract class MutableModel<P extends Mutable> extends ChangeNotifier {

  List<P> get properties;
  bool _flushing = false;
  bool _repeatFlush = false;

  /// Fires a change event and clears the change flag on all properties. Returns true if there were changes.
  bool flushChanges() {
    if(_flushing) {
      _repeatFlush = true;
      return false;
    }
    final changed = Set.from(properties.where((p) => p.changed));
    if(changed.isEmpty)
      return false;
    try {
      _flushing = true;
      notifyListeners();
    } finally {
      _flushing = false;
      for(var p in changed)
        p.changed = false;
      if(_repeatFlush) {
        _repeatFlush = false;
        flushChanges();
      }
    }
    return true;
  }

  /// Returns true if any of the properties has changed.
  get changed {
    return properties.map((p) => p.changed).reduce((a, b) => a || b) ;
  }

}
