part of mutable_model;

/// A property contains a value that can be changed.
abstract class Property<T> {
  int index;
  dynamic store(T value) => value;
  T load(dynamic value) => value as T;
  bool dataEquals(dynamic a, dynamic b) => a == b;
  T get initial => null;
}

class Prop<T> extends Property<T> {
  final T initial;

  Prop([this.initial]);
}

class StringProp extends Prop<String> {
  StringProp([String initial]) : super(initial);
}

class BoolProp extends Prop<bool> {
  BoolProp([bool initial]) : super(initial);

  bool load(dynamic value) => value as bool ?? false;
}

class IntProp extends Prop<int> {
  IntProp([int initial]) : super(initial);

  @override
  int load(dynamic data) {
    return data is double ? data.toInt() : data;
  }

  @override
  dynamic store(v) {
    return v;
  }
}

class DoubleProp extends Prop<double> {
  DoubleProp([double initial]) : super(initial);

  @override
  double load(dynamic data) {
    return data is int ? data.toDouble() : data;
  }
}

class EnumProp<E> extends Prop<E> {
  final List<E> enumValues;

  EnumProp(this.enumValues, [E initial]) : super(initial);

  @override
  load(data) => parseEnum(enumValues, data as String);

  @override
  store(value) => enumStr(value);
}

/// Stores an int value as a string
class IntStrProp extends Prop<int> {
  IntStrProp([int initial]) : super(initial);

  @override
  store(i) => i == null ? null : "$i";

  @override
  load(data) => data == null ? null : int.parse(data as String);
}

class BoolStrProp extends Prop<bool> {
  static final falseStr = "false";
  static final trueStr = "true";

  BoolStrProp([bool initial]) : super(initial);

  @override
  load(data) => data == null ? null : (data as String).toLowerCase() == trueStr;

  @override
  store(b) => b == null ? null : b ? trueStr : falseStr;
}

class DateTimeProp extends Prop<DateTime> {
  DateTimeProp([DateTime initial]) : super(initial);
}

/// A base class for properties that store their data as a Map
/// Provides an equality function that compares the serialized versions of the object
abstract class MapProp<T> extends Prop<T> {
  static const equality = MapEquality();

  MapProp([T initial]) : super(initial);

  bool dataEquals(a, b) {
    if (a is Map && b is Map)
      return equality.equals(a, b);
    else
      return a == b;
  }
}

/// A property that stores its data as a list.
class ListProp<T> extends Prop<List<T>> {

  final Property<T> element;

  ListProp(this.element, [List<T> initial]) : super(initial);

  bool dataEquals(a, b) {
    if (a is List && b is List) {
      if(a.length != b.length)
        return false;
      for(int i = 0; i < a.length; i++)
        if(!element.dataEquals(a, b))
          return false;
      return true;
    } else {
      return a == b;
    }
  }

  dynamic store(List<T> value) {
    return value?.map((v) => element.store(v))?.toList();
  }

  List<T> load(dynamic value) {
    if(value is List)
      return value?.map((d) => element.load(d))?.toList();
    else
      return null;
  }

}

abstract class StoredProperty<T> implements Property<T> {
  final Property<T> prop;
  int index;
  final String name;

  StoredProperty(this.name, this.prop);

  dynamic store(T value) => prop.store(value);
  T load(dynamic value) => prop.load(value);
  bool dataEquals(dynamic a, dynamic b) => prop.dataEquals(a, b);
  T get initial => prop.initial;

  dynamic readFrom(Map<dynamic, dynamic> data);

  void writeTo(dynamic modelData, Map<dynamic, dynamic> data);

  void calcChanges(dynamic modelData, Map<dynamic, dynamic> data, Map<dynamic, dynamic> changes);

}
