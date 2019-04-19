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
    assert(() {
      return attrs == null || attrs.length == Set.from(attrs.map((a) => a.name)).length;
    }(), "Attributes contain a duplicate name");
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

  void readFrom(Map<String, dynamic> data, [List<StoredProperty> attrs]) {
    if(data == null)
      return;
    for(var attr in StoredMetaModel.checkAttrs(attrs) ?? this.meta.cachedAttrs)
      setData(attr, attr.readFrom(data));
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
