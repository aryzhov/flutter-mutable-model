part of mutable_model;

// The subclass must define a getter for [properties] that includes [loaded], [saving], and [attrs]
abstract class StoredMetaModel extends MetaModel {

  List<StoredProperty> get attrs;
  static final saving = BoolProp();
  static final loaded = BoolProp();

  static final storedModelProperties = <Property>[saving, loaded];

  get properties => storedModelProperties + List.castFrom<StoredProperty, Property>(attrs);

  List<StoredProperty> _cachedAttrs;

  get cachedAttrs {
    if(_cachedAttrs == null) {
       _cachedAttrs = checkAttrs(attrs);
       assert(_cachedAttrs != null);
    }
    return _cachedAttrs;
  }

  static List<StoredProperty> checkAttrs(final List<StoredProperty> attrs) {
    List<String> getDuplicates() {
      return attrs.map((a) => a.name).toSet().where((n) {
        return 1 < attrs.map((a) => a.name == n ? 1: 0).reduce((x, y) => x + y);
      }).toList();
    }
    
    assert(() {
      return attrs == null || getDuplicates().length == 0;
    }(), "Attributes contain a duplicate name: ${getDuplicates()}");
    return attrs;
  }

}

abstract class StoredModel extends Model {

  Map<String, dynamic> data;
  bool get loaded => get(StoredMetaModel.loaded);
  bool get saving => get(StoredMetaModel.saving);
  set loaded(bool value) => set(StoredMetaModel.loaded, value);
  set saving(bool value) => set(StoredMetaModel.saving, value);

  StoredModel(StoredMetaModel meta): super(meta);

  @override
  StoredMetaModel get meta => super.meta as StoredMetaModel;

  readFrom(Map<String, dynamic> data, [List<StoredProperty> attrs]) {
    if(data == null)
      return;
    final attrs2 = StoredMetaModel.checkAttrs(attrs) ?? this.meta.cachedAttrs;
    for(var attr in attrs2)
      setData(attr, attr.readFrom(data));
    this.data = createData(attrs2);
    loaded = true;
  }

  void writeTo(Map<String, dynamic> data, [List<StoredProperty> attrs]) {
    for(var attr in StoredMetaModel.checkAttrs(attrs) ?? this.meta.cachedAttrs)
      attr.writeTo(getData(attr), data);
  }

  Map<String, dynamic> createData([List<StoredProperty> attrs]) {
    final data = Map<String, dynamic>();
    writeTo(data, attrs);
    return data;
  }

  Map<String, dynamic> getChanges([List<StoredProperty> attrs]) {
    if(data == null)
      return createData(attrs);
    else {
      final changes = Map<String, dynamic>();
      for(var attr in StoredMetaModel.checkAttrs(attrs) ?? this.meta.cachedAttrs)
        attr.calcChanges(getData(attr), data, changes);
      return changes;
    }
  }

  void copyAttributesFrom(StoredModel other, [List<StoredProperty> attrs]) {
    copyFrom(other, StoredMetaModel.checkAttrs(attrs) ?? meta.cachedAttrs);
  }

}
