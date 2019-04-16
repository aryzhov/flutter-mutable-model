part of mutable_model;

abstract class MetaModel {

  Map<Property, int> _indexes;
  Iterable<Property> get properties;

  int indexOf(Property p, {bool nullIfAbsent = false}) {
    if(_indexes == null) {
      _indexes = Map<Property, int>();
      int idx = 0;
      for(var p in properties)
        _indexes[p] = idx++;
    }
    final result = _indexes[p];
    assert(result != null && !nullIfAbsent, "Property not found");
    return result;
  }
}

abstract class Model<MM extends MetaModel> extends ChangeNotifier {

  bool _flushing = false;

  MM get meta;

  List<dynamic> _data;
  Map<Property, dynamic> _changes;

  List<dynamic> get data {
    if(_data == null)
      _data = List.unmodifiable(meta.properties.map((p) => p.store(p.initial)));
    return _data;
  }

  bool get changed {
    return _changes?.isNotEmpty ?? false;
  }

  Map<Property, dynamic> get changes {
    return _changes;
  }

  T operator[]<T>(Property<T> prop) {
    return prop.load(_getData(prop));
  }

  dynamic _getData(Property prop) {
    if(changed && _changes.containsKey(prop))
      return _changes[prop];
    return data[meta.indexOf(prop)];
  }

  void operator []=<T>(Property prop, T value) {
    _setData(prop, prop.store(value));
  }

  void _setData(Property prop, dynamic d) {
    if(prop.dataEquals(d, data[meta.indexOf(prop)])) {
      if(_changes != null) {
        _changes.remove(prop);
        if(_changes.isEmpty)
          _changes = null;
      }
    } else {
      if(_changes == null)
        _changes = Map<Property, dynamic>();
      _changes[prop] = d;
    }
  }

  bool isChanged(Property prop) {
    return _changes != null && _changes.containsKey(prop);
  }

  /// Fires a change event and clears the change flag on all properties. Returns true if there were changes.
  bool flushChanges() {
    if(_flushing) {
      return false;
    }
    onFlushChanges();
    if(!changed)
      return false;
    final ch = Map.from(_changes);
    try {
      _flushing = true;
      notifyListeners();
    } finally {
      _flushing = false;
      
      var data2 = List.from(_data);
      for(var me in ch.entries) {
        final prop = me.key;
        final newData = me.value;
        data2[meta.indexOf(prop)] = newData;
        if(_changes.containsKey(prop) && prop.dataEquals(_changes[prop], newData))
          _changes.remove(prop);
      }
      _data = List.unmodifiable(data2);
      if(_changes.isNotEmpty)
        flushChanges();
      else
        _changes = null;
    }
    return true;
  }

  /// A hook to perform calculations before firing [notifyListeners].
  @protected
  void onFlushChanges() {
  }

  void copyFrom(Model other, {bool clearChanges = true}) {
    assert(this.meta == other.meta, "Can only copy models with the same meta class");
    if(clearChanges) {
      this._data = other._data;
      this._changes = other._changes != null ? Map.from(other._changes): null;
    }
    else {
      for(var p in meta.properties) {
        this._setData(p, other._getData(p));
      }
    }
  }

}
