part of mutable_model;

class OrderedMapEvent<K, V> {
  final OrderedMap<K, V> map;
  OrderedMapEvent(this.map);
}

class OrderedMapChange<K, V> extends OrderedMapEvent<K, V>{
  final OrderedMapEntry<K, V> entry;
  OrderedMapChange(OrderedMap<K, V> map, this.entry): super(map);
}

class OrderedMapAdd<K, V> extends OrderedMapChange<K, V> {
  OrderedMapAdd(OrderedMap<K, V> map, OrderedMapEntry<K, V> entry): super(map, entry);
}

class OrderedMapRemove<K, V> extends OrderedMapChange<K, V> {
  OrderedMapRemove(OrderedMap<K, V> map, OrderedMapEntry<K, V> entry): super(map, entry);
}

class OrderedMapReplace<K, V> extends OrderedMapChange<K, V> {
  final OrderedMapEntry<K, V> oldEntry;
  OrderedMapReplace(OrderedMap<K, V> map, OrderedMapEntry<K, V> entry, this.oldEntry): super(map, entry);
}

class OrderedMapMove<K, V> extends OrderedMapChange<K, V> {
  final int oldIdx;
  OrderedMapMove(OrderedMap<K, V> map, OrderedMapEntry<K, V> entry, this.oldIdx): super(map, entry);
}

class OrderedMapValueChange<K, V> extends OrderedMapChange<K, V> {
  final dynamic data;
  OrderedMapValueChange(OrderedMap<K, V> map, OrderedMapEntry<K, V> entry, this.data): super(map, entry);
}

class OrderedMapEntry<K, V> implements MapEntry<K, V> {
  final K key;
  final V value;
  int _idx;

  OrderedMapEntry(this.key, this.value, this._idx);

  get idx => _idx;

  dispose() {}
}

typedef int Comparator<T>(T a, T b);
typedef bool Filter<K, V>(OrderedMapEntry<K, V> entry);

class OrderedMap<K, V> implements Map<K, V> {
  final List<OrderedMapEntry<K, V>> _list = List<OrderedMapEntry<K, V>>();
  final Map<K, OrderedMapEntry<K, V>> _map = Map<K, OrderedMapEntry<K, V>>();
  final StreamController<OrderedMapEvent<K, V>> _streamController = StreamController<OrderedMapEvent<K, V>>.broadcast(sync: true);
  Comparator<OrderedMapEntry<K, V>> _compareFunc;

  // Removed as a workaround for issue https://github.com/flutter/flutter/issues/32644
  // OrderedMap({List<OrderedMapEntry<K, V>> list,
  //     Map<K, OrderedMapEntry<K, V>> map,
  //     StreamController<OrderedMapEvent<K, V>> streamController}):
  //   this._list = list ?? List<OrderedMapEntry<K, V>>(),
  //   this._map = map ?? Map<K, OrderedMapEntry<K, V>>(),
  //   this._streamController = streamController ?? StreamController<OrderedMapEvent<K, V>>();

  Stream<OrderedMapEvent> get stream {
    return _streamController.stream;
  }

  void orderBy(Comparator<V> comparator, {bool descending=false}) {
    if(comparator == null) {
      this._compareFunc = null;
    } else {
      this._compareFunc = (a, b) {
        int k = comparator(a.value, b.value);
        return descending ? -k: k;
      };
      if(_list.isNotEmpty) {
        final list2 = List.of(_list);
        list2.sort(this._compareFunc);
        for(var i = 0; i < list2.length; i++) {
          move(list2[i]._idx, i);
        }
      }
    }
  }

  OrderedMapEntry<K, V> createMapEntry(K key, V value, int idx) {
    return OrderedMapEntry<K, V>(key, value, null);
  }

  int put(K key, V value) {
    final oldEntry = _map[key];
    if(oldEntry != null && oldEntry.value == value)
      return oldEntry._idx;
    final entry = createMapEntry(key, value, null);
    if(oldEntry == null) {
      final idx = _compareFunc == null ? length : lowerBound(_list, entry, compare: _compareFunc);
      entry._idx = idx;
      _map[key] = entry;
      _list.insert(idx, entry);
      for(var i = idx + 1; i < _list.length; i++)
        _list[i]._idx = i;
      _streamController.add(OrderedMapAdd(this, entry));
    } else {
      entry._idx = oldEntry._idx;
      _map[key] = entry;
      _list[oldEntry._idx] = entry;
      _streamController.add(OrderedMapReplace(this, entry, oldEntry));
      oldEntry.dispose();
      _checkEntryPosition(entry);
    }
    return entry._idx;
  }

  valueChanged(K key, [dynamic valueChangeEventData]) {
    final entry = _map[key];
    if(entry != null) {
      _streamController.add(OrderedMapValueChange(this, entry, valueChangeEventData));
      _checkEntryPosition(entry);
    }
  }

  _checkEntryPosition(OrderedMapEntry<K, V> entry) {
    if(_compareFunc == null)
      return;
    final entry2 = OrderedMapEntry(entry.key, entry.value, null);
    final idx = lowerBound(_list, entry2, compare: _compareFunc);
    final shouldMove = (idx < entry._idx - 1 || idx > entry._idx + 1 ||
        (idx != entry._idx && _compareFunc(entry, entry2) != 0));
    if(shouldMove) {
      move(entry._idx, idx);
    }
  }

  V remove(key) {
    var entry = _map.remove(key);
    if(entry == null)
      return null;
    _list.removeAt(entry._idx);
    _streamController.add(OrderedMapRemove(this, entry));
    for(var i = entry._idx; i < _list.length; i++)
      _list[i]._idx = i;
    return entry.value;
  }

  int get length {
    return _list.length;
  }

  V at(idx) {
    return _list[idx].value;
  }

  void removeAll() {
    for(var i = _list.length-1; i >= 0; i--) {
      remove(_list[i].key);
    }
  }

  move(int fromIdx, int toIdx) {
    assert(fromIdx >= 0);
    assert(toIdx >= 0);
    assert(fromIdx < _list.length);
    assert(toIdx < _list.length);
    if(fromIdx == toIdx)
      return;
    var entry = _list[fromIdx];
    _list.removeAt(fromIdx);
    _list.insert(toIdx, entry);
    if(fromIdx < toIdx) {
      for(var i = fromIdx; i <= toIdx; i++)
        _list[i]._idx = i;
    } else {
      for(var i = toIdx; i <= fromIdx; i++)
        _list[i]._idx = i;
    }
    _streamController.add(OrderedMapMove(this, entry, fromIdx));
  }

  indexOf(key) {
    var entry = _map[key];
    return entry?._idx ?? -1;
  }

  V operator [] (Object key) {
    return _map[key]?.value;
  }

  void operator []= (K key, V value) {
    put(key, value);
  }

  Iterable<V> elements() {
    return _list.map((entry) => entry.value);
  }

//  Iterable<MapEntry<K, V>> entries() {
//    return list.map((entry) =>  MapEntry(entry.key, entry.value));
//  }
//
//  Iterable<K> keys() {
//    return list.map((entry) => entry.key);
//  }

  bool containsKey(Object key) {
    return _map.containsKey(key);
  }

  bool get isEmpty => _list.isEmpty;
  bool get isNotEmpty => _list.isNotEmpty;

  // Makes this map contain a subset of items of another map
  // The order of the elements is determined by this map's orderBy() setting.
  StreamSubscription<OrderedMapEvent<K, V>> filter(OrderedMap<K, V> source, Filter<K, V> filter) {
    for(var i = _list.length - 1; i >= 0; i--) {
      final entry = _list[i];
      if(!filter(entry))
        remove(entry.key);
    }
    for(var entry in source._list) {
      if(filter(entry)) {
        put(entry.key, entry.value);
      }
    }
    return source.stream.listen((event) {
      if(event is OrderedMapChange) {
        final entry = event.entry;
        if (event is OrderedMapAdd) {
          if (filter(entry)) {
            put(entry.key, entry.value);
          }
        } else if (event is OrderedMapRemove) {
          remove(entry.key);
        } else if (event is OrderedMapReplace || event is OrderedMapValueChange) {
          if (filter(event.entry))
            put(entry.key, entry.value);
          else
            remove(entry.key);
        }
      }
    });
  }

  @override
  Iterable<V> get values {
    return _list.map((e) => e.value);
  }

  @override
  Iterable<K> get keys {
    return _map.keys;
  }

  @override
  void forEach(void f(K key, V value)) {
    _list.forEach((e) => f(e.key, e.value));
  }

  @override
  void clear() {
    removeWhere((k, v) => true);
  }

  @override
  void addAll(Map<K, V> other) {
    other.entries.forEach((me) => put(me.key, me.value));
  }

  @override
  V putIfAbsent(K key, V ifAbsent()) {
    if(!containsKey(key)) {
      final value = ifAbsent();
      put(key, value);
      return value;
    } else {
      return this[key];
    }
  }

  @override
  void removeWhere(bool predicate(K key, V value)) {
    for(var i = _list.length-1; i >= 0; i--) {
      final item = _list[i];
      if (predicate(item.key, item.value))
        remove(_list[i].key);
    }
  }

  @override
  void updateAll(V update(K key, V value)) {
    _list.forEach((e) => update(e.key, e.value));
  }

  @override
  V update(K key, V update(V value), {V ifAbsent()}) {
    if(containsKey(key)) {
      final newValue = update(this[key]);
      put(key, newValue);
      return newValue;
    } else {
      return putIfAbsent(key, ifAbsent);
    }
  }

  @override
  void addEntries(Iterable<MapEntry<K, V>> newEntries) {
    for(var me in newEntries)
      put(me.key, me.value);
  }

  @override
  Iterable<MapEntry<K, V>> get entries {
    return _list;
  }

  @override
  bool containsValue(Object value) {
    for(var e in _list)
      if(e.value == value)
        return true;
    return false;
  }

  @override
  Map<RK, RV> cast<RK, RV>() {
    throw UnimplementedError();
  }

  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> f(K key, V value)) {
    return Map.fromEntries(_list.map((me) => f(me.key, me.value)));
  }


}
