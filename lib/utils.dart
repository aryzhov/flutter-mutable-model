enumStr(dynamic enumValue) {
  return enumValue?.toString()?.split('.')?.last;
}

parseEnum(List<dynamic> values, String value) {
  return value == null ? null : values.firstWhere((v) => enumStr(v) == value);
}
