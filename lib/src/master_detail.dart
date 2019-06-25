part of mutable_model;

import 'package:flutter_web/material.dart';
import 'dart:async';
import 'package:mutable_model/mutable_model.dart';


class MasterDetail<M extends FirestoreModel, D extends FirestoreModel>extends ChangeNotifier {
  final M master;
  final ModelMap<String, D> details;

  MasterDetail(this.master, this.details);

  bool get isNotEmpty => details.isNotEmpty;

}

/// Returns the ID of the master
typedef String MasterLocator<D extends FirestoreModel>(D detail);
typedef ModelMap<String, D> ModelMapFactory<D extends FirestoreModel>();

ModelMap<String, D> defaultMapFactory<D extends FirestoreModel>() {
  return ModelMap<String, D>(loaded: false, notifyListenersOnValueChange: false);
}

class MasterDetailComposer<M extends FirestoreModel, D extends FirestoreModel> {
  
  final ModelMap<String, MasterDetail<M, D>> masterDetailMap;
  final ModelMap<String, M> masterMap;
  final ModelMap<String, D> detailsMap;
  final Map<String, MasterDetail<M, D>> _emptyMasters = Map<String, MasterDetail<M, D>>();
  final Map<String, D> _unassignedDetails = Map<String, D>();
  final MasterLocator<D> masterLocator;
  final ModelMapFactory<D> mapFactory;
  final bool excludeEmpty;

  StreamSubscription<OrderedMapEvent<String, M>> _masterSub;
  StreamSubscription<OrderedMapEvent<String, D>> _detailsSub;

  MasterDetailComposer({
      ModelMap<String, MasterDetail<M, D>> masterDetailMap,
      @required this.masterMap, 
      @required this.detailsMap, 
      @required this.masterLocator, 
      ModelMapFactory<D> mapFactory,
      this.excludeEmpty = false
    }): this.masterDetailMap = masterDetailMap ?? ModelMap<String, MasterDetail<M, D>>(notifyListenersOnValueChange: false, loaded: false),
        this.mapFactory = mapFactory ?? defaultMapFactory {

    masterMap.addListener(_calcLoaded);
    detailsMap.addListener(_calcLoaded);

    for(var me in masterMap.entries) {
      _addMaster(me.key, me.value);
    }

    for(var me in detailsMap.entries) {
      _addDetail(me.key, me.value);
    }

    _calcLoaded();

    _masterSub = masterMap.stream.listen((event) {
      if(event is OrderedMapAdd) {
        _addMaster(event.entry.key, event.entry.value);
      } else if(event is OrderedMapRemove) {
        _removeMaster(event.entry.key);
      } else if(event is OrderedMapReplace) {
        _addMaster(event.entry.key, event.entry.value);
      } else if(event is ModelMapLoaded) {
        _calcLoaded();
      }
    });

    _detailsSub = detailsMap.stream.listen((event) {
      if(event is OrderedMapAdd) {
        _addDetail(event.entry.key, event.entry.value);
      } else if(event is OrderedMapRemove) {
        _removeDetail(event.entry.key, event.entry.value);
      } else if(event is OrderedMapReplace) {
        _removeDetail(event.oldEntry.key, event.oldEntry.value);
        _addDetail(event.entry.key, event.entry.value);
      } else if(event is ModelMapLoaded) {
        _calcLoaded();
      }
    });

  }

  _calcLoaded() {
    final loaded = masterMap.loaded && detailsMap.loaded;
    if(masterDetailMap.loaded != loaded) {
      for(var md in masterDetailMap.values) {
        md.details.loaded = detailsMap.loaded;
      }
      masterDetailMap.loaded = loaded;
    }
  }

  MasterDetail<M, D> _createMasterDetail(M master) {
    return MasterDetail<M, D>(master, mapFactory());
  }

  _addMaster(String key, M value) {
    _removeMaster(key);
    final md = _createMasterDetail(value);
    if(excludeEmpty) {
      _emptyMasters[key] = md;
    } else {
      masterDetailMap[key] = md;
    }
    _checkUnassigned();
    md.details.loaded = detailsMap.loaded;
  }

  _removeMaster(String key) {
    final md = masterDetailMap.remove(key);
    if(md != null) {
      for(var me in md.details.entries) {
        _addDetail(me.key, me.value);
      }
      md.details.clear();
      md.dispose();
    }
    _emptyMasters.remove(key);
  }

  _checkUnassigned() {
    final un = Map<String, D>()..addAll(_unassignedDetails);
    for(var me in un.entries) {
      _addDetail(me.key, me.value);
    }
  }

  _addDetail(String key, D value) {
    final masterID = masterLocator(value);
    final md = masterID == null ? null : masterDetailMap[masterID] ?? _emptyMasters[masterID];
    if(md == null) {
      _unassignedDetails[key] = value;
    } else {
      _unassignedDetails.remove(key);
      md.details[key] = value;
      if(md.isNotEmpty && _emptyMasters.containsKey(masterID)) {
        _emptyMasters.remove(masterID);
        masterDetailMap.put(masterID, md);
      }
    }
  }

  _removeDetail(String key, D value) {
    _unassignedDetails.remove(key);
    final masterID = masterLocator(value);
    final md = masterID == null ? null : masterDetailMap[masterID];
    if(md != null) md.details.remove(key);
    if(excludeEmpty && !md.isNotEmpty) {
      masterDetailMap.remove(masterID);
      _emptyMasters[masterID] = md;
    }
  }

  void dispose() {
    masterMap.removeListener(_calcLoaded);
    detailsMap.removeListener(_calcLoaded);
    _masterSub.cancel();
    _detailsSub.cancel();
    for(var md in masterDetailMap.values) {
      md.details.clear();
    }
    for(var md in _emptyMasters.values) {
      md.details.clear();
    }
    masterDetailMap.clear();
  }

}
