part of mutable_model;

/// Converts an enumeration value to its string representation without the type name
enumStr(dynamic enumValue) {
  return enumValue?.toString()?.split('.')?.last;
}

/// Converts a string to an enum value. Works as the inverse of [enumStr()].
parseEnum(List<dynamic> values, String value) {
  return value == null ? null : values.firstWhere((v) => enumStr(v) == value);
}
