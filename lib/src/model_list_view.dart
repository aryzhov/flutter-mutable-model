part of mutable_model;

typedef OrderedMapItemBuilder<T>(BuildContext context, String key, int index, T item);

class ModelListView<E extends Listenable> extends StatelessWidget {
  final ModelMap<String, E> modelMap;
  final WidgetBuilder emptyListBuilder;
  final OrderedMapItemBuilder<E> itemBuilder;
  final IndexedWidgetBuilder separatorBuilder;
  final bool itemBuilderUsesIndex;

  ModelListView({
    @required
    this.modelMap,
    @required
    this.itemBuilder,
    this.emptyListBuilder,
    this.separatorBuilder,
    this.itemBuilderUsesIndex = false,
  });

  @override
  Widget build(BuildContext context) {
    listItemBuilder(context, idx) {
      if(idx >= modelMap.length)
        return emptyListBuilder(context);
      final entry = modelMap._list[idx];
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

    final listItemCount = modelMap.length == 0 && emptyListBuilder != null && modelMap.loaded ? 1 : modelMap.length;

    if(separatorBuilder != null)
      return ListView.separated(itemBuilder: listItemBuilder, separatorBuilder: separatorBuilder, itemCount: listItemCount);
    else
      return ListView.builder(itemBuilder: listItemBuilder, itemCount: listItemCount);
  }

}
