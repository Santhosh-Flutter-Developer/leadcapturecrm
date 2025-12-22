import 'package:flutter/material.dart';
import '/services/services.dart';
import '/models/models.dart';

class RegionService {
  static final FirebaseConfig firebase = FirebaseConfig();
  static List<RegionModel>? _cachedCountries;

  static Future<List<RegionModel>> getCountries({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedCountries != null) return _cachedCountries!;

    final snapshot = await firebase.regions.orderBy('name').get();
    _cachedCountries = snapshot.docs
        .map((d) => RegionModel.fromMap({...d.data(), 'uid': d.id}))
        .toList();

    return _cachedCountries!;
  }

  static Future<List<StateModel>> getStates({required String regionId}) async {
    try {
      List<StateModel> countries = [];
      var stateDocs = await firebase.regions
          .doc(regionId)
          .collection('states')
          .orderBy('name')
          .get();

      for (var i in stateDocs.docs) {
        var data = i.data();
        data['uid'] = i.id;
        countries.add(StateModel.fromMap(data));
      }

      return countries;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error getting states: $e';
    }
  }

  static Future<List<CityModel>> getCities({
    required String regionId,
    required String stateId,
  }) async {
    try {
      List<CityModel> countries = [];
      var citiesDocs = await firebase.regions
          .doc(regionId)
          .collection('states')
          .doc(stateId)
          .collection('cities')
          .orderBy('name')
          .get();

      for (var i in citiesDocs.docs) {
        var data = i.data();
        data['uid'] = i.id;
        countries.add(CityModel.fromMap(data));
      }

      return countries;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error getting cities: $e';
    }
  }
}
