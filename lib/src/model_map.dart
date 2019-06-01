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

// Changed the order of extends/with as a workaround for https://github.com/flutter/flutter/issues/32644
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
      if(!_loaded)
        return;
      if(change is OrderedMapValueChange && !notifyListenersOnValueChange)
        return;
      notifyListeners();
    });
  }

  @override
  OrderedMapEntry<K, V> createMapEntry(K key, V value, int idx) {
    if(value is Listenable)
      return ModelMapEntry<K, V>(this, key, value, idx);
    else
      return super.createMapEntry(key, value, idx);
  }

}
