part of mutable_model;

/// A property that converts its value to an easily serializable form for storing
abstract class DataProperty<T> implements Property<T> {
  dynamic _data;
  dynamic _oldData;
  bool _changed = false;

  DataProperty([T initialValue]) {
    this.value = initialValue;
    changed = false;
  }

  @override
  T get value => dataToValue(data);

  @override
  set value(T v) {
    data = valueToData(v);
  }

  @override
  T get oldValue => _changed ? dataToValue(_oldData): value;

  @override
  bool get changed => _changed;

  @override
  set changed(ch) {
    _changed = ch;
    if(!ch) {
      _oldData = null;
    }
  }

  @override
  bool equals(Property<T> other) {
    return other is DataProperty<T> && dataEquals(other.data);
  }

  void copyFrom(Property<T> other) {
    if(other is DataProperty<T>)
      data = other.data;
    else
      value = other.value;
  }

  /// Returns the serialized representation of the data
  dynamic get data => _data;

  /// Sets the value using the serialized representation
  set data (dynamic d) {
    if(!dataEquals(d)) {
      _data = d;
      if(_changed) {
        if(dataEquals(_oldData)) {
          _changed = false;
          _oldData = null;
        }
      } else {
        _oldData = _data;
        _changed = true;
      }
    }
  }

  /// Override this method for custom conversion from data to value
  T dataToValue(dynamic data) {
    return data as T;
  }

  /// Override this method for custom conversion value to data
  dynamic valueToData(T value) {
    return value;
  }

  /// Override this method for custom equality behavior
  bool dataEquals(dynamic newData) {
    return data == newData;
  }

}

/// A property that stores its data without conversion
class SimpleProperty<T> implements Property<T> {

  @override
  T value;

  @override
  T oldValue;

  @override
  bool get changed => !valueEquals(oldValue);

  @override
  set changed(ch) {
    if(!ch)
      oldValue = value;
  }

  SimpleProperty([T initialValue]) {
    value = initialValue;
    changed = false;
  }

  @override
  bool equals(Property<T> other) {
    return other is SimpleProperty<T> && valueEquals(other.value);
  }

  /// Override this method for custom comparison
  bool valueEquals(T otherValue) {
    return this.value == otherValue;
  }

  void copyFrom(Property<T> other) {
    value = other.value;
  }

}

class StringProp extends DataProperty<String>{

  StringProp([String initialValue]): super(initialValue);

}

class BoolProp extends DataProperty<bool>{

  BoolProp([bool initialValue=false]): super(initialValue);

  get value => super.value ?? false;

}

class IntProp extends DataProperty<int>{

  IntProp([int initialValue]): super(initialValue);

  @override
  int valueToData(v) {
    return v is double ? v.toInt(): v;
  }

  @override
  bool dataEquals(other) {
    return data == (other is double ? other.toInt() : other);
  }

}

class DoubleProp extends DataProperty<double>{

  DoubleProp([double initialValue]): super(initialValue);

  @override
  double valueToData(v) {
    return v is int ? v.toDouble(): v;
  }

  @override
  bool dataEquals(other) {
    return data == (other is int ? other.toDouble() : other);
  }

}

class EnumProp<E> extends DataProperty<E> {

  List<E> enumValues;

  @override
  dataToValue(data) => parseEnum(enumValues, data as String);

  @override
  valueToData(value) => enumStr(value);

  EnumProp(this.enumValues, [E initialValue]): super(initialValue);

}

/// Stores an int value as a string
class IntStrProp extends DataProperty<int> {


  @override
  valueToData(i) => i == null ? null : "$i";

  @override
  dataToValue(data) => data == null ? null : int.parse(data as String);

  @override
  bool dataEquals(dynamic newData) {
    return data == newData;
  }

  IntStrProp([int initialValue]) {
    if(initialValue != null)
      value = initialValue;
  }

}

class BoolStrProp extends DataProperty<bool> {

  static final falseStr = "false";
  static final trueStr = "true";

  @override
  dataToValue(data) => data == null ? null : (data as String).toLowerCase() == trueStr;

  @override
  valueToData(b) => b == null ? null : b ? trueStr : falseStr;

  @override
  bool dataEquals(dynamic newData) {
    return data == newData;
  }

  BoolStrProp([bool initialValue]): super(initialValue);

}

class DateTimeProp extends DataProperty<DateTime> {

  DateTimeProp([DateTime initialValue]): super(initialValue);

  @override
  bool dataEquals(dynamic newData) {
    return data == newData || ((data is DateTime) && (newData is DateTime) && (data as DateTime).compareTo(newData) == 0);
  }
}


class DateTimeProperty extends SimpleProperty<DateTime> {

  DateTimeProperty([DateTime initialValue]): super(initialValue);

  @override
  bool valueEquals(DateTime other) {
    return value == other || (value != null && other != null && value.compareTo(other) == 0);
  }
}


abstract class MapProp<T> extends DataProperty<T> {

  static const equality = MapEquality();

  bool dataEquals(newData) {
    if(data != null && newData != null)
        return equality.equals(data, newData);
    else
      return value == newData;
  }

}
