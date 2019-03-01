part of mutable_model;

/// [Property] is a [Mutable] implementation that can convert its value before storing. Its [data] field contains the stored value.
/// Subclasses are expected to implement the getter and setter for [value] that in turn call [data], and [dataEquals] method.
abstract class Property<T> extends Mutable<T> {
  dynamic _data;
  bool changed = false;
  get data => _data;
  set data(newData) {
    if(!dataEquals(newData)) {
      _data = newData;
      changed = true;
    }
  }
  T get value;
  set value(T t);
  bool dataEquals(dynamic newData) {
    return data == newData;
  }
}

class SimpleProperty<T> extends Property<T> {
  get value => data as T;

  SimpleProperty([T initialValue]) {
    if(initialValue != null)
      value = initialValue;
  }

  set value(t) {
    data = t;
  }

  bool dataEquals(newData) {
    return data == newData;
  }

}

/// A property that can have a null value or can have a default non-null value
class DefaultValue<T> extends Property<T> {

  final Property<T> prop;
  final T defaultValue;

  DefaultValue(this.prop, this.defaultValue) {
    if(prop.value == null)
      prop.value = defaultValue;
  }

  get value => prop.value ?? defaultValue;

  set value(T newValue) {
    prop.value = newValue ?? defaultValue;
  }

}

class StringProp extends SimpleProperty<String>{

  StringProp([String initialValue]): super(initialValue);

}

class BoolProp extends SimpleProperty<bool>{

  BoolProp([bool initialValue=false]): super(initialValue);

  get value => super.value ?? false;

  set value(bool b) {
    data = b ?? false;
  }

}

class IntProp extends SimpleProperty<int>{

  IntProp([int initialValue]): super(initialValue);

  get value {
    return data is double ? data.toInt(): data as int;
  }

  bool dataEquals(newData) {
    return value == (newData is double ? newData.toInt() : newData as int);
  }

}

class DoubleProp extends SimpleProperty<double>{

  DoubleProp([double initialValue]): super(initialValue);

  get value {
    return data is int ? (data as int).toDouble(): data as double;
  }

  bool dataEquals(newData) {
    return value == (newData is int ? newData.toDouble() : newData as double);
  }

}


class EnumProp<E> extends Property<E> {

  List<E> enumValues;

  get value => parseEnum(enumValues, data as String);

  EnumProp(this.enumValues, [E initialValue]) {
    if(initialValue != null)
      value = initialValue;
  }

  set value(e) {
    data = enumStr(e);
  }

  bool dataEquals(newData) {
    return data == newData;
  }

}

class IntStrProp extends Property<int> {

  get value => data == null ? null : int.parse(data as String);

  set value(i) {
    data = i == null ? null : "$i";
  }

  @override
  bool dataEquals(dynamic newData) {
    return data == newData;
  }

  IntStrProp([int initialValue]) {
    if(initialValue != null)
      value = initialValue;
  }

}

class BoolStrProp extends Property<bool> {

  static final falseStr = "false";
  static final trueStr = "true";

  get value => data == null ? null : (data as String).toLowerCase() == trueStr;

  set value(b) {
    data = b == null ? null : b ? trueStr : falseStr;
  }

  @override
  bool dataEquals(dynamic newData) {
    return data == newData;
  }

  BoolStrProp([bool initialValue]) {
    if(initialValue != null)
      value = initialValue;
  }

}

abstract class MapProp<T> extends Property<T> {

  static const equality = MapEquality();

  bool dataEquals(newData) {
    if(data != null && newData != null)
        return equality.equals(data, newData);
    else
      return value == newData;
  }

}
