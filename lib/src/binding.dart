part of mutable_model;

class Binding<T> extends ChangeNotifier implements ValueListenable<T> {
  final Property<T> _property;
  final Model _model;
  final bool canChange;

  Binding(this._model, this._property, [this.canChange = true]) {
    _model.addListener(_changeListener);
  }

  @override
  void dispose() {
    super.dispose();
    _model.removeListener(_changeListener);
  }  

  _changeListener() {
    if(_model.isChanged(_property)) {
      notifyListeners();
    }
  }

  T get value => _model.get(_property);
  set value(T value) {
    assert(canChange, "Attempt to change read-only binding");
    if(canChange) {
      _model.set(_property, value);
      _model.flushChanges();
    }
  } 

  T get oldValue => _model.getOldValue(_property);
  bool get isChanged => _model.isChanged(_property);



}