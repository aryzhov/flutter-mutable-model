library mutable_model;

import 'dart:js_util';

import 'package:collection/collection.dart';
import 'package:collection/equality.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';
import 'dart:collection';

part 'package:mutable_model/src/binding.dart';
part 'package:mutable_model/src/master_detail.dart';
part 'package:mutable_model/src/model.dart';
part 'package:mutable_model/src/model_provider.dart';
part 'package:mutable_model/src/model_map.dart';
part 'package:mutable_model/src/model_list_view.dart';
part 'package:mutable_model/src/ordered_map.dart';
part 'package:mutable_model/src/properties.dart';
part 'package:mutable_model/src/stored_model.dart';
part 'package:mutable_model/src/utils.dart';
part 'package:mutable_model/src/ordered_map_filter.dart';
part 'package:mutable_model/src/ordered_map_union.dart';

abstract class Disposable {

  void dispose();
}
