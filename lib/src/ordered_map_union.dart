part of mutable_model;

class UnionMapEntry<K, V> extends OrderedMapEntry<K, V> {
  
  final int srcIdx;

  UnionMapEntry(K key, V value, this.srcIdx): super(key, value);
  
}

class OrderedMapUnion<K, V> with Disposable {

  final subs = List<StreamSubscription<OrderedMapEvent<K, V>>>();

  OrderedMapUnion(OrderedMap<K, V> target, List<OrderedMap<K, V>> sources) {

    int srcIndex(K key) {
      for(var i = 0; i < sources.length; i++) {
        if(sources[i].containsKey(key))
          return i;
      }
      return null;
    }

    updateLoaded() {
      target.loaded = sources.map((s) => s.loaded).reduce((a, b) => a && b);
    }

    for(var entry in target.entries.toList()) {
      if(entry is UnionMapEntry<K, V>) {
        if(entry.srcIdx >= sources.length || sources[entry.srcIdx][entry.key] != entry.value)
          target.remove(entry.key);
      } else {
        target.remove(entry.key);
      }
    }

    for(var srcIdx = 0; srcIdx < sources.length; srcIdx++) {
      final s = sources[srcIdx];
      for(var entry in s.entries) {
        if(!target.containsKey(entry.key))
          target.putEntry(UnionMapEntry<K, V>(entry.key, entry.value, srcIdx));
      }
      
      subs.add(s.stream.listen((event) {
        if(event is OrderedMapChange) {
          final entry = event.entry;
          final oldEntry = target.getEntry(entry.key) as UnionMapEntry<K, V>;
          if (event is OrderedMapAdd) {
            if(oldEntry == null || oldEntry.srcIdx > srcIdx) {
              target.putEntry(UnionMapEntry<K, V>(entry.key, entry.value, srcIdx));
            }
          } else if (event is OrderedMapRemove) {
            if(oldEntry != null && oldEntry.srcIdx == srcIdx) {
              final newSrcIdx = srcIndex(entry.key);
              if(newSrcIdx == null) {
                target.remove(entry.key);
              } else {
                target.putEntry(UnionMapEntry<K, V>(entry.key, sources[newSrcIdx][entry.key], newSrcIdx));
              }
            }
          } else if (event is OrderedMapReplace) {
            if(oldEntry != null && oldEntry.srcIdx == srcIdx) {
              target.putEntry(UnionMapEntry<K, V>(entry.key, entry.value, srcIdx));
            }
          } else if (event is OrderedMapValueChange) {
            if(oldEntry != null && oldEntry.srcIdx == srcIdx) {
              target.valueChanged(entry.key, event.data);
            }
          }
        } else if(event is OrderedMapLoaded) {
          updateLoaded();
        }
      }));

    }

    updateLoaded();
  }

  @override
  void dispose() {
    for(var s in subs) {
      s.cancel();
    }
  }

}