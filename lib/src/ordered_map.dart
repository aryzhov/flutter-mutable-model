part of mutable_model;

class OrderedMapChange<K, V> {
  final OrderedMap<K, V> map;
  final OrderedMapEntry<K, V> entry;
  OrderedMapChange(this.map, this.entry);
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

class OrderedMapEntry<K, V> {
  final K key;
  final V value;
  int _idx;

  OrderedMapEntry(this.key, this.value, this._idx);

  get idx => _idx;

  dispose() {}
}

typedef int Comparator<T>(T a, T b);
typedef bool Filter<K, V>(OrderedMapEntry<K, V> entry);

class OrderedMap<K, V> {
  final list = List<OrderedMapEntry<K, V>>();
  final map = LinkedHashMap<K, OrderedMapEntry<K, V>>();
  final _streamController = StreamController<OrderedMapChange<K, V>>();

  Comparator<OrderedMapEntry<K, V>> _compareFunc;

  Stream<OrderedMapChange> get stream {
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
      if(list.isNotEmpty) {
        final list2 = List.of(list);
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
    final oldEntry = map[key];
    if(oldEntry != null && oldEntry.value == value)
      return oldEntry._idx;
    final entry = createMapEntry(key, value, null);
    if(oldEntry == null) {
      final idx = _compareFunc == null ? length : lowerBound(list, entry, compare: _compareFunc);
      entry._idx = idx;
      map[key] = entry;
      list.insert(idx, entry);
      for(var i = idx + 1; i < list.length; i++)
        list[i]._idx = i;
      _streamController.add(OrderedMapAdd(this, oldEntry));
    } else {
      entry._idx = oldEntry._idx;
      map[key] = entry;
      list[oldEntry._idx] = entry;
      _streamController.add(OrderedMapReplace(this, entry, oldEntry));
      oldEntry.dispose();
      _checkEntryPosition(entry);
    }
    return entry._idx;
  }

  valueChanged(K key, [dynamic valueChangeEventData]) {
    final entry = map[key];
    if(entry != null) {
      _streamController.add(OrderedMapValueChange(this, entry, valueChangeEventData));
      _checkEntryPosition(entry);
    }
  }

  _checkEntryPosition(OrderedMapEntry<K, V> entry) {
    if(_compareFunc == null)
      return;
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
    _streamController.add(OrderedMapRemove(this, entry));
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
    _streamController.add(OrderedMapMove(this, entry, fromIdx));
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

  // Makes this map contain a subset of items of another map
  // The order of the elements is determined by this map's orderBy() setting.
  StreamSubscription<OrderedMapChange<K, V>> filter(OrderedMap<K, V> source, Filter<K, V> filter) {
    for(var i = list.length; i >= 0; i--) {
      final entry = list[i];
      if(!filter(entry))
        remove(entry.key);
    }
    for(var entry in source.list) {
      if(filter(entry))
        put(entry.key, entry.value);
    }
    return source.stream.listen((change) {
      final entry = change.entry;
      if (change is OrderedMapAdd) {
        if (filter(entry))
          put(entry.key, entry.value);
      } else if (change is OrderedMapRemove) {
        remove(entry.key);
      } else if (change is OrderedMapReplace || change is OrderedMapValueChange) {
        if (filter(change.entry))
          put(entry.key, entry.value);
        else
          remove(entry.key);
      }
    });
  }

}
