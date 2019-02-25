import 'package:collection/equality.dart';

import 'mutable.dart';
import 'utils.dart';

abstract class Attribute<T> extends Property {
  dynamic _data;
  bool changed = false;
  get data => _data;
  set data(newData) {
    if(!equals(newData)) {
      _data = newData;
      changed = true;
    }
  }
  T get value;
  set value(T t);
  bool equals(dynamic newData);
}

class SimpleAttribute<T> extends Attribute<T> {
  get value => data as T;

  SimpleAttribute([T initialValue]) {
    if(initialValue != null)
      value = initialValue;
  }

  set value(t) {
    data = t;
  }

  bool equals(newData) {
    return data == newData;
  }

}

class BoolAttribute extends SimpleAttribute<bool>{

  BoolAttribute([bool initialValue=false]): super(initialValue);

  get value => super.value ?? false;

  set value(bool b) {
    data = b ?? false;
  }

}

class IntAttribute extends SimpleAttribute<int>{

  IntAttribute([int initialValue]): super(initialValue);

  get value {
    return data is double ? data.toInt(): data as int;
  }

  bool equals(newData) {
    return value == (newData is double ? newData.toInt() : newData as int);
  }

}

class DoubleAttribute extends SimpleAttribute<double>{

  DoubleAttribute([double initialValue]): super(initialValue);

  get value {
    return data is int ? (data as int).toDouble(): data as double;
  }

  bool equals(newData) {
    return value == (newData is int ? newData.toDouble() : newData as double);
  }

}


class EnumAttribute<E> extends Attribute<E> {

  List<E> enumValues;

  get value => parseEnum(enumValues, data as String);

  EnumAttribute(this.enumValues, [E initialValue]) {
    if(initialValue != null)
      value = initialValue;
  }

  set value(e) {
    data = enumStr(e);
  }

  bool equals(newData) {
    return data == newData;
  }

}

class IntStrAttribute extends Attribute<int> {

  get value => data == null ? null : int.parse(data as String);

  set value(i) {
    data = i == null ? null : "$i";
  }

  @override
  bool equals(dynamic newData) {
    return data == newData;
  }

  IntStrAttribute([int initialValue]) {
    if(initialValue != null)
      value = initialValue;
  }

}

class BoolStrAttribute extends Attribute<bool> {

  static final falseStr = "false";
  static final trueStr = "true";

  get value => data == null ? null : (data as String).toLowerCase() == trueStr;

  set value(b) {
    data = b == null ? null : b ? trueStr : falseStr;
  }

  @override
  bool equals(dynamic newData) {
    return data == newData;
  }

  BoolStrAttribute([bool initialValue]) {
    if(initialValue != null)
      value = initialValue;
  }

}



abstract class MapAttribute<T> extends Attribute<T> {

  static const equality = MapEquality();

  bool equals(newData) {
    if(data != null && newData != null)
        return equality.equals(data, newData);
    else
      return value == newData;
  }

}


abstract class StoredAttribute extends Property {

  get name;

  void readFrom(Map<dynamic, dynamic> data);

  void writeTo(Map<dynamic, dynamic> data);

}

class NamedAttribute<T> extends StoredAttribute {

  final String _name;
  final Attribute<T> attr;

  NamedAttribute(this._name, this.attr);

  get name => _name;
  bool get changed => attr.changed;
  set changed(bool c) {
    attr.changed = c;
  }

  @override
  void readFrom(Map<dynamic, dynamic> data) {
    if(!data.containsKey(_name)) {
      attr.data = null;
    } else {
      var attrData = data[_name];
      attr.data = attrData;
    }
  }

  T get value => attr.value;

  set value(v) {
    attr.value = v;
  }

  bool get isNull => attr.data == null;

  @override
  void writeTo(Map<dynamic, dynamic> data) {
    data[_name] = attr.data;
  }

}
