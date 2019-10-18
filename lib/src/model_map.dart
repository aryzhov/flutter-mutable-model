part of mutable_model;

class ModelMapEntry<K, V> extends OrderedMapEntry<K, V> {

  ModelMap<K, V> map;

  ModelMapEntry(this.map, K key, V value): super(key, value) {
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

// Changed the order of extends/with as a workaround for https://github.com/flutter/flutter/issues/32644
class ModelMap<K, V> extends OrderedMap<K, V> with ChangeNotifier {

  final bool notifyListenersOnValueChange;

  ModelMap({this.notifyListenersOnValueChange = false, loaded = true}) {
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
  OrderedMapEntry<K, V> createMapEntry(K key, V value) {
    if(value is Listenable)
      return ModelMapEntry<K, V>(this, key, value);
    else
      return super.createMapEntry(key, value);
  }

}
