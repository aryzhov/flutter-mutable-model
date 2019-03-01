part of mutable_model;

typedef void OrderedMapOnAdd<K, V>(K key, V value, int idx);
typedef void OrderedMapOnRemove<K, V>(K key, V value, int idx);
typedef void OrderedMapOnReplace<K, V>(K key, V oldValue, V value, int idx);
typedef void OrderedMapOnMove<K, V>(K key, V value, int fromIdx, int toIdx);

class OrderedMapEntry<K, V> {
  K key;
  V value;
  int idx;

  OrderedMapEntry(this.key, this.value, this.idx);
}

typedef int Comparator<T>(T a, T b);

class OrderedMap<K, V> extends ChangeNotifier {
  final list = List<OrderedMapEntry<K, V>>();
  final map = Map<K, OrderedMapEntry<K, V>>();
  OrderedMapOnAdd<K, V> onAdd;
  OrderedMapOnRemove<K, V> onRemove;
  OrderedMapOnReplace<K, V> onReplace;
  OrderedMapOnMove<K, V> onMove;
  Comparator<OrderedMapEntry<K, V>> _compareFunc;

  OrderedMap() {
    orderBy(null);
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
        move(list2[i].idx, i);
      }
    }
  }

  int put(K key, V value) {
    final entry = map[key];
    if(entry == null) {
      final newEntry = OrderedMapEntry(key, value, null);
      final idx = lowerBound(list, newEntry, compare: _compareFunc);
      newEntry.idx = idx;
      map[key] = newEntry;
      list.insert(idx, newEntry);
      for(var i = idx + 1; i < list.length; i++)
        list[i].idx = i;
      if(onAdd != null)
        onAdd(key, value, idx);
      notifyListeners();
      return idx;
    } else {
      final oldValue = entry.value;
      if(oldValue == value)
        return entry.idx;
      entry.value = value;
      final entry2 = OrderedMapEntry(key, value, null);
      final idx = lowerBound(list, entry2, compare: _compareFunc);
      if(onReplace != null)
        onReplace(key, oldValue, value, entry.idx);
      final shouldMove = (idx < entry.idx - 1 || idx > entry.idx + 1 ||
          (idx != entry.idx && _compareFunc(entry, entry2) != 0));
      if(shouldMove) {
        move(entry.idx, idx);
      }
      notifyListeners();
      return entry.idx;
    }
  }

  V remove(key) {
    var entry = map.remove(key);
    if(entry == null)
      return null;
    list.removeAt(entry.idx);
    if(onRemove != null)
      onRemove(key, entry.value, entry.idx);
    notifyListeners();
    for(var i = entry.idx; i < list.length; i++)
      list[i].idx = i;
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
        list[i].idx = i;
    } else {
      for(var i = toIdx; i <= fromIdx; i++)
        list[i].idx = i;
    }
    if(onMove != null)
      onMove(entry.key, entry.value, fromIdx, toIdx);
    notifyListeners();
  }

  indexOf(key) {
    var entry = map[key];
    return entry?.idx ?? -1;
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
