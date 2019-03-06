part of mutable_model;

class OrderedMapChange<K, V> {
  final OrderedMap<K, V> map;
  final K key;
  final V value;
  final int idx;
  OrderedMapChange({this.map, this.key, this.value, this.idx});
}

class OrderedMapAdd<K, V> extends OrderedMapChange<K, V> {
  OrderedMapAdd({OrderedMap<K, V> map, K key, V value, idx}): super(map: map, key: key, value: value, idx: idx);
}

class OrderedMapRemove<K, V> extends OrderedMapChange<K, V> {
  OrderedMapRemove({OrderedMap<K, V> map, K key, V value, int idx}): super(map: map, key: key, value: value, idx: idx);
}

class OrderedMapReplace<K, V> extends OrderedMapChange<K, V> {
  final V oldValue;
  OrderedMapReplace({OrderedMap<K, V> map, K key, V value, int idx, this.oldValue}): super(map: map, key: key, value: value, idx: idx);
}

class OrderedMapMove<K, V> extends OrderedMapChange<K, V> {
  final int toIdx;
  OrderedMapMove({OrderedMap<K, V> map, K key, V value, int fromIdx, this.toIdx}): super(map: map, key: key, value: value, idx: fromIdx);
}

class OrderedMapValueChange<K, V> extends OrderedMapChange<K, V> {
  final dynamic data;
  OrderedMapValueChange({OrderedMap<K, V> map, K key, V value, int idx, this.data}): super(map: map, key: key, value: value, idx: idx);
}

class OrderedMapEntry<K, V> {
  final K key;
  final V value;
  int _idx;

  OrderedMapEntry(this.key, this.value, this._idx);

  get idx => _idx;

  dispose() {}
}

class OrderedMapListenableEntry<K, V> extends OrderedMapEntry<K, V> {

  OrderedMap<K, V> map;

  OrderedMapListenableEntry(this.map, K key, V value, int idx): super(key, value, idx) {
    (value as Listenable).addListener(_onValueChange);
  }

  _onValueChange() {
    map.checkEntryPosition(this);
  }

  @override
  dispose() {
    (value as Listenable).removeListener(_onValueChange);
  }

}

typedef int Comparator<T>(T a, T b);

class OrderedMap<K, V> extends ChangeNotifier {
  final list = List<OrderedMapEntry<K, V>>();
  final map = Map<K, OrderedMapEntry<K, V>>();
  final _streamController = StreamController<OrderedMapChange<K, V>>();

  Comparator<OrderedMapEntry<K, V>> _compareFunc;

  OrderedMap() {
    orderBy(null);
  }

  Stream<OrderedMapChange> get stream {
    return _streamController.stream;
  }

  void orderBy(Comparator<V> comparator, {bool descending=false}) {
    this._compareFunc = (a, b) {
      int k = comparator == null ? -1: comparator(a.value, b.value);
      return descending ? -k: k;
    };
    if(list.isNotEmpty) {
      final list2 = List.of(list);
      list2.sort(this._compareFunc);
      for(var i = 0; i < list2.length; i++) {
        move(list2[i]._idx, i);
      }
    }
  }

  int put(K key, V value) {
    final entry = map[key];
    if(entry != null && entry.value == value)
      return entry._idx;
    final newEntry = (value is Listenable) ? OrderedMapListenableEntry<K, V>(this, key, value, null): OrderedMapEntry(key, value, null);
    if(entry == null) {
      final idx = lowerBound(list, newEntry, compare: _compareFunc);
      newEntry._idx = idx;
      map[key] = newEntry;
      list.insert(idx, newEntry);
      for(var i = idx + 1; i < list.length; i++)
        list[i]._idx = i;
      _streamController.add(OrderedMapAdd(map: this, key: key, value: value, idx: idx));
      notifyListeners();
    } else {
      newEntry._idx = entry._idx;
      map[key] = newEntry;
      list[entry._idx] = newEntry;
      _streamController.add(OrderedMapReplace(map: this, key: key, oldValue: entry.value, value: value, idx: entry._idx));
      notifyListeners();
      checkEntryPosition(newEntry);
      entry.dispose();
    }
    return newEntry._idx;
  }

  checkEntryPosition(OrderedMapEntry<K, V> entry) {
    final entry2 = OrderedMapEntry(entry.key, entry.value, null);
    final idx = lowerBound(list, entry2, compare: _compareFunc);
    final shouldMove = (idx < entry._idx - 1 || idx > entry._idx + 1 ||
        (idx != entry._idx && _compareFunc(entry, entry2) != 0));
    if(shouldMove) {
      move(entry._idx, idx);
    }
  }

  V remove(key) {
    var entry = map.remove(key);
    if(entry == null)
      return null;
    list.removeAt(entry._idx);
    _streamController.add(OrderedMapRemove(map: this, key: key, value: entry.value, idx: entry._idx));
    notifyListeners();
    for(var i = entry._idx; i < list.length; i++)
      list[i]._idx = i;
    return entry.value;
  }

  int get length {
    return list.length;
  }

  V at(idx) {
    return list[idx].value;
  }

  void removeAll() {
    for(var i = list.length-1; i >= 0; i--) {
      remove(list[i].key);
    }
  }

  move(int fromIdx, int toIdx) {
    assert(fromIdx >= 0);
    assert(toIdx >= 0);
    assert(fromIdx < list.length);
    assert(toIdx < list.length);
    if(fromIdx == toIdx)
      return;
    var entry = list[fromIdx];
    list.removeAt(fromIdx);
    list.insert(toIdx, entry);
    if(fromIdx < toIdx) {
      for(var i = fromIdx; i <= toIdx; i++)
        list[i]._idx = i;
    } else {
      for(var i = toIdx; i <= fromIdx; i++)
        list[i]._idx = i;
    }
    _streamController.add(OrderedMapMove(map: this, key: entry.key, value: entry.value, fromIdx: fromIdx, toIdx: toIdx));
    notifyListeners();
  }

  indexOf(key) {
    var entry = map[key];
    return entry?._idx ?? -1;
  }

  V operator [] (K key) {
    return map[key]?.value;
  }

  void operator []= (K key, V value) {
    put(key, value);
  }

  Iterable<V> elements() {
    return list.map((entry) => entry.value);
  }

  Iterable<MapEntry<K, V>> entries() {
    return list.map((entry) =>  MapEntry(entry.key, entry.value));
  }

  Iterable<K> keys() {
    return list.map((entry) => entry.key);
  }

  bool containsKey(K key) {
    return map.containsKey(key);
  }

  bool get isEmpty => list.isEmpty;
  bool get isNotEmpty => list.isNotEmpty;
}
