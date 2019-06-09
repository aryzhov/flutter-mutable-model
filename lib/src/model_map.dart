part of mutable_model;

class ModelMapEntry<K, V> extends OrderedMapEntry<K, V> {

  ModelMap<K, V> map;

  ModelMapEntry(this.map, K key, V value, int idx): super(key, value, idx) {
    (value as Listenable).addListener(_onValueChange);
  }

  _onValueChange() {
    map.valueChanged(key);
  }

  @override
  dispose() {
    (value as Listenable).removeListener(_onValueChange);
  }

}

/// Ordered map loaded or not loaded
class ModelMapLoaded<K, V> extends OrderedMapEvent<K, V> {
  bool loaded;
  ModelMapLoaded(OrderedMap<K, V> map, this.loaded): super(map);
}

class ModelMap<K, V> extends OrderedMap<K, V> with ChangeNotifier {

  final bool notifyListenersOnValueChange;
  bool _loaded;

  get loaded => _loaded;

  set loaded(bool value) {
    if(_loaded != value) {
      _loaded = value;
      notifyListeners();
    }
  }

  ModelMap({this.notifyListenersOnValueChange = false, loaded = true}): _loaded = loaded {
    stream.listen((change) {
      if(change is ModelMapLoaded) {
        loaded = change.loaded;
      } else if(loaded) {
        if(!(change is OrderedMapValueChange) || notifyListenersOnValueChange) {
          notifyListeners();
        }
      }
    });
  }

  @override
  OrderedMapEntry<K, V> createMapEntry(K key, V value, int idx) {
    if(value is Listenable)
      return ModelMapEntry<K, V>(this, key, value, idx);
    else
      return super.createMapEntry(key, value, idx);
  }

  @override
  StreamSubscription<OrderedMapEvent<K, V>> filter(OrderedMap<K, V> source, Filter<K, V> filter) {
    loaded = false;
    try {
      return super.filter(source, filter);
    } finally {
      if(source is ModelMap<K, V>) {
        loaded = source.loaded;
      } else {
        loaded = true;
      }
    }
  }


}
