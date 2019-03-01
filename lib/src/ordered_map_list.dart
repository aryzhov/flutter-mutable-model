part of mutable_model;

typedef OrderedMapItemBuilder<T>(BuildContext context, String key, int index, T item);

class OrderedMapList<E extends ChangeNotifier> extends StatelessWidget {
  final OrderedMap<String, E> orderedMap;
  final WidgetBuilder emptyListBuilder;
  final OrderedMapItemBuilder<E> itemBuilder;
  final IndexedWidgetBuilder separatorBuilder;
  final bool itemBuilderUsesIndex;

  OrderedMapList({
    @required
    this.orderedMap,
    @required
    this.itemBuilder,
    this.emptyListBuilder,
    this.separatorBuilder,
    this.itemBuilderUsesIndex = false,
  });

  @override
  Widget build(BuildContext context) {
    listItemBuilder(context, idx) {
      if(idx >= orderedMap.length)
        return emptyListBuilder(context);
      final entry = orderedMap.list[idx];
      final item = ModelProvider<E>(
        model: entry.value,
        child: Builder(
          builder: (context) {
            var model = ModelProvider.of<E>(context, rebuildOnChange: true);
            return itemBuilder(context, entry.key, idx, model);
          },
        ),
      );
      return itemBuilderUsesIndex ? item : Container(key: Key(entry.key), child: item,);
    }

    final listItemCount = orderedMap.length == 0 && emptyListBuilder != null ? 1 : orderedMap.length;

    if(separatorBuilder != null)
      return ListView.separated(itemBuilder: listItemBuilder, separatorBuilder: separatorBuilder, itemCount: listItemCount);
    else
      return ListView.builder(itemBuilder: listItemBuilder, itemCount: listItemCount);
  }

}
