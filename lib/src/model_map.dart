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

// Changed the order of extends/with as a workaround for https://github.com/flutter/flutter/issues/32644
class ModelMap<K, V> extends OrderedMap<K, V> with ChangeNotifier {

  final bool notifyListenersOnValueChange;

  ModelMap({this.notifyListenersOnValueChange = false, loaded = true}): super(loaded: loaded) {
    stream.listen((change) {
      if(this.loaded) {
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
