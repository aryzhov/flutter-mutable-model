part of mutable_model;

typedef bool Filter<K, V>(OrderedMapEntry<K, V> entry);

class OrderedMapFilter<K, V> with Disposable {

  final OrderedMap<K, V> source;
  final OrderedMap<K, V> target;
  final Filter<K, V> filter;
  StreamSubscription<OrderedMapEvent<K, V>> sub;
  
  OrderedMapFilter(this.target, this.source, this.filter) {

    for(var entry in target.entries.toList()) {
      if(!filter(entry))
        target.remove(entry.key);
    }
    for(var entry in source.entries) {
      if(filter(entry)) {
        target.put(entry.key, entry.value);
      }
    }
    target.loaded = source.loaded;

    sub = source.stream.listen((event) {
      if(event is OrderedMapChange) {
        final entry = event.entry;
        if (event is OrderedMapAdd) {
          if (filter(entry)) {
            target.put(entry.key, entry.value);
          }
        } else if (event is OrderedMapRemove) {
          target.remove(entry.key);
        } else if (event is OrderedMapReplace || event is OrderedMapValueChange) {
          if (filter(event.entry))
            target.put(entry.key, entry.value);
          else
            target.remove(entry.key);
        }
      } else if(event is OrderedMapLoaded) {
        target.loaded = source.loaded;
      }
    });
  }

  @override
  void dispose() {
    sub.cancel();
  }

}