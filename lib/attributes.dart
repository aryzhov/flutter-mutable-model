import 'package:collection/equality.dart';

import 'mutable.dart';
import 'utils.dart';

abstract class Attr<T> extends Mutable {
  dynamic _data;
  @override
  bool _changed = false;
  @override
  bool get changed => _changed;
  set changed(c) {
    _changed = c;
  }
  get data => _data;
  set data(newData) {
    if(!equals(newData)) {
      _data = newData;
      _changed = true;
    }
  }
  T get value;
  set value(T t);
  bool equals(dynamic newData);
}

class SimpleAttr<T> extends Attr<T> {
  get value => data as T;

  SimpleAttr([T initialValue]) {
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

class BoolAttr extends SimpleAttr<bool>{

  BoolAttr([bool initialValue=false]): super(initialValue);

  get value => super.value ?? false;

  set value(bool b) {
    data = b ?? false;
  }

}

class IntAttr extends SimpleAttr<int>{

  IntAttr([int initialValue]): super(initialValue);

  get value {
    return data is double ? data.toInt(): data as int;
  }

  bool equals(newData) {
    return value == (newData is double ? newData.toInt() : newData as int);
  }

}

class DoubleAttr extends SimpleAttr<double>{

  DoubleAttr([double initialValue]): super(initialValue);

  get value {
    return data is int ? (data as int).toDouble(): data as double;
  }

  bool equals(newData) {
    return value == (newData is int ? newData.toDouble() : newData as double);
  }

}


class EnumAttr<E> extends Attr<E> {

  List<E> enumValues;

  get value => parseEnum(enumValues, data as String);

  EnumAttr(this.enumValues, [E initialValue]) {
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

class IntStrAttr extends Attr<int> {



  get value => data == null ? null : int.parse(data as String);

  set value(i) {
    data = i == null ? null : "$i";
  }

  @override
  bool equals(dynamic newData) {
    return data == newData;
  }

  IntStrAttr([int initialValue]) {
    if(initialValue != null)
      value = initialValue;
  }

}

class BoolStrAttr extends Attr<bool> {

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

  BoolStrAttr([bool initialValue]) {
    if(initialValue != null)
      value = initialValue;
  }

}



abstract class MapAttr<T> extends Attr<T> {

  static const equality = MapEquality();

  bool equals(newData) {
    if(data != null && newData != null)
        return equality.equals(data, newData);
    else
      return value == newData;
  }

}


abstract class StoredAttr extends Mutable {

  get name;

  void readFrom(Map<dynamic, dynamic> data);

  void writeTo(Map<dynamic, dynamic> data);

}

class SingleAttr<T> extends StoredAttr {

  final String _name;
  final Attr<T> attr;

  SingleAttr(this._name, this.attr);

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
