part of mutable_model;

abstract class MetaModel {
  List<Property> get properties;
  List<Property> _properties;
  Unchanged _defaults;

  void init() {
    if(_properties != null)
      return;
    _properties = properties;
    for (var i = 0; i < _properties.length; i++) {
      final p = _properties[i];
      if (p.index == null)
        p.index = i;
      else
        assert(p.index == i, "Property $i is used in another model with a different index ${p.index}");
    }
    _defaults = Unchanged(this, _properties.map((p) => p.store(p.initial)));
  }

  Unchanged get defaults {
    init();
    return _defaults;
  }

  bool contains(Property p) {
    final idx = p.index;
    return idx != null && idx < _properties.length && _properties[idx] == p;
  }

  int indexOf(Property p) {
    final result = p.index;
    assert(result != null, "Property not registered");
    assert(_properties[result] == p, "Property belongs to another meta model");
    return result;
  }
}

abstract class Snapshot {
  final MetaModel meta;
  Snapshot(this.meta);
  dynamic operator [](Property prop);
  void operator []=(Property prop, dynamic data);
  bool get changed;
  bool get locked;
  Snapshot clone();
  Unchanged applyChanges();
  bool isChanged(Property prop);
  dynamic getBaseValue(Property prop);
}

class Unchanged extends Snapshot {
  final List<dynamic> _data;

  Unchanged(MetaModel meta, Iterable<dynamic> data)
      : _data = data.toList(growable: false),
        super(meta);

  dynamic operator [](Property prop) {
    return _data[meta.indexOf(prop)];
  }

  void operator []=(Property prop, dynamic data) {
    assert(false, "Can't modify immutable snapshot");
  }

  get changed => false;

  get locked => true;

  clone() => this;

  applyChanges() => this;

  isChanged(Property prop) => false;

  dynamic getBaseValue(Property prop) => this[prop];
}

class Changed extends Snapshot {
  final Map<Property, dynamic> _changes;
  final Snapshot _base;
  bool _locked = false;

  Changed(this._base)
      : _changes = Map<Property, dynamic>(),
        super(_base.meta);

  Snapshot get base => _base;

  dynamic operator [](Property prop) {
    if (_changes.containsKey(prop))
      return _changes[prop];
    else
      return base[prop];
  }

  void operator []=(Property prop, dynamic d) {
    assert(!_locked, "Cannot modify a locked snapshot");
    if (prop.dataEquals(d, base[prop])) {
      _changes.remove(prop);
    } else {
      _changes[prop] = d;
    }
  }

  get changed => _changes.isNotEmpty;

  get locked => _locked;

  bool isChanged(Property prop) {
    return _changes.containsKey(prop);
  }

  void lock() {
    this._locked = true;
  }

  clone() => Changed(this.base).._changes.addAll(this._changes);

  Unchanged applyChanges() {
    if (changed)
      return Unchanged(meta, meta._properties.map((p) => this[p]));
    else {
      return base.applyChanges();
    }
  }

  dynamic getBaseValue(Property prop) => _base[prop];
}

class Model extends ChangeNotifier {
  bool _flushing = false;
  Snapshot _snapshot;
  MetaModel get meta => _snapshot.meta;

  Model(MetaModel meta) : _snapshot = meta.defaults;

  Snapshot get snapshot => _snapshot;

  @protected
  T get<T>(Property<T> prop) {
    return prop.load(_snapshot[prop]);
  }

  @protected
  dynamic getData(Property prop) => _snapshot[prop];

  @protected
  void set<T>(Property prop, T value) {
    allowChanges();
    _snapshot[prop] = prop.store(value);
  }

  @protected
  void setData(Property prop, dynamic data) {
    allowChanges();
    _snapshot[prop] = data;
  }

  @protected
  void allowChanges() {
    if (_snapshot.locked) _snapshot = Changed(_snapshot);
  }

  bool isChanged(Property prop) => _snapshot.isChanged(prop);

  bool anyChanged(List<Property> props) {
    for(var p in props) {
      if(_snapshot.isChanged(p))
        return true;
    }
    return false;
  }

  T getOldValue<T>(Property<T> prop) => prop.load(_snapshot.getBaseValue(prop));

  /// Fires a change event and clears the change flag on all properties. Returns true if there were changes.
  bool flushChanges() {
    if (_flushing) {
      return !_snapshot.locked && _snapshot.changed;
    }
    _flushing = true;
    bool result = false;
    try {
      while (!_snapshot.locked && _snapshot.changed) {
        onFlushChanges();
        if (_snapshot.changed) {
          result = true;
          (_snapshot as Changed).lock();
          notifyListeners();
        }
      }
    } finally {
      _flushing = false;
      _snapshot = _snapshot.applyChanges();
    }
    return result;
  }

  @override
  void addListener(listener) {
    final hadListeners = hasListeners;
    super.addListener(listener);
    if(!hadListeners && hasListeners)
      onHasListeners();
  }

  @override
  void removeListener(listener) {
    final hadListeners = hasListeners;
    super.removeListener(listener);
    if(hadListeners && !hasListeners)
      onNoListeners();
  }

  /// A hook to perform calculations before firing [notifyListeners].
  @protected
  void onFlushChanges() {}

  @protected
  void onHasListeners() {}

  @protected
  void onNoListeners() {}

  void copyFrom(Model other, [List<Property> properties]) {
    for (var p in properties ?? meta._properties) {
      if (other.meta.contains(p)) this.setData(p, other.getData(p));
    }
  }
}
