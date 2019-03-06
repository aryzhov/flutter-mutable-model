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

class ModelMap<K, V> extends OrderedMap<K, V> with ChangeNotifier {

  final bool notifyListenersOnValueChange;

  ModelMap({this.notifyListenersOnValueChange = false}) {
    stream.listen((change) {
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
