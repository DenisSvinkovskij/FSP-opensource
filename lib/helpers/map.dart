import 'dart:convert';
import 'dart:developer';

import 'package:find_safe_places/constants/map.dart';
import 'package:find_safe_places/models/close_person.dart';
import 'package:find_safe_places/models/saved_safe_place.dart';
import 'package:find_safe_places/services/geo/geolocation.dart';
import 'package:find_safe_places/services/httpRequests/mapbox.dart';
import 'package:find_safe_places/utils/map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mapbox_search/mapbox_search.dart';

List getSafePlacesFeatures(List places) {
  return places
      .map(
        (e) => {
          'type': "Feature",
          'id': e['id'],
          'properties': {
            'placeId': e['id'],
            'id': e['id'],
          },
          'geometry': jsonDecode(e['geometry']),
        },
      )
      .toList();
}

List getFamilyFeatures(List<ClosePerson> persons) {
  return persons
      .map(
        (e) => {
          'type': "Feature",
          'id': e.uid,
          'properties': {
            'type': kFamilyFeatureType,
            'name': e.name,
            'firstLetter': e.name[0],
            'colorIcon': e.color?.replaceAll('#', '') ?? '7E57C2',
            'docId': e.uid,
            'placeId': e.uid,
            'id': e.uid,
            'userId': e.uid,
          },
          'geometry': {
            'type': "Point",
            'coordinates': [
              e.location?['geopoint'].longitude,
              e.location?['geopoint'].latitude
            ]
          }
        },
      )
      .toList();
}

List<dynamic> getEmergencyFills(List fills) {
  return fills.map(
    (item) {
      var geometry = item['affectArea']?.map((area) {
        var latitude = area['latitude'];
        var longitude = area['longitude'];

        return [longitude, latitude];
      })?.toList();

      return {
        'type': "Feature",
        'properties': {
          'type': kEmergencyFeatureType,
          'emergencyType': item['type'],
          'emergencyNature': item['emergencyNature'],
          'id': item['id'],
          'title': item['title'],
          'body': item['body'],
        },
        'geometry': {
          'type': "Polygon",
          'coordinates': [geometry]
        }
      };
    },
  ).toList();
}

List getSavedSafePlacesFeatures(
  List<SavedSafePlaceModel> places,
  String userId,
) {
  return places
      .map(
        (e) => {
          'type': "Feature",
          'id': e.placeId,
          'properties': {
            ...(e.additionalInfo ?? {}),
            'type': kSafePlaceFeatureType,
            'name': e.name,
            'firstLetter': e.firstLetter,
            'address': e.address,
            'docId': e.id,
            'placeId': e.placeId,
            'id': e.placeId,
            'userId': userId,
          },
          'geometry': {
            'type': "Point",
            'coordinates': [e.location.longitude, e.location.latitude]
          }
        },
      )
      .toList();
}

Future<Map<String, dynamic>> calculateRoute(String typeTrip, LatLng myLocation,
    LatLng? selectedMarkerPosition, MapboxMapController controller) async {
  dynamic marker = await getSelectedOrNearestMarker(
    myLocation,
    selectedMarkerPosition,
    controller,
  );
  if (marker[0] == null) {
    return marker;
  }
  final response =
      await getMapboxRoute(myLocation, LatLng(marker[1], marker[0]), typeTrip);
  if (response == null) {
    return {'error': 'error in method getMapboxRoute'};
  }
  final firstRoute = response['routes'][0];
  return firstRoute;
}

Future getSelectedOrNearestMarker(LatLng myLocation,
    LatLng? selectedMarkerPosition, MapboxMapController controller) async {
  dynamic marker;
  if (selectedMarkerPosition != null) {
    marker = [
      selectedMarkerPosition.longitude,
      selectedMarkerPosition.latitude
    ];
  } else {
    var features = await controller.queryRenderedFeaturesInRect(
      Rect.largest,
      [
        kUsersSavedSafePlacesLayerId,
        kSafePlacesLayerId,
      ],
      null,
    );
    var allCoords = features.map((e) => e['geometry']['coordinates']).toList();
    if (allCoords.isEmpty) {
      return {'error': 'No visible safe places on screen'};
    }
    marker = getNearestMarker(allCoords, myLocation);
  }
  return marker;
}

Future<void> showPath(firstRoute, MapboxMapController controller) async {
  List route = firstRoute['geometry']['coordinates'];
  var geojson = {
    'type': 'Feature',
    'properties': {},
    'geometry': {'type': 'LineString', 'coordinates': route}
  };

  var lastPoint = {
    'type': 'Feature',
    'properties': {},
    'geometry': {'type': 'Point', 'coordinates': route.last}
  };

  await controller.removeLayer('path-to-safe-place-line-layer');
  await controller.removeLayer('safe-place-line-pin-layer');
  await controller.removeSource('path-to-safe-place-source');
  await controller.removeSource('safe-place-pin-source');

  await controller.addGeoJsonSource('path-to-safe-place-source', {
    'type': "FeatureCollection",
    'features': [geojson],
  });

  await controller.addGeoJsonSource('safe-place-pin-source', {
    'type': "FeatureCollection",
    'features': [lastPoint],
  });

  await controller.addLayer(
    'path-to-safe-place-source',
    'path-to-safe-place-line-layer',
    const LineLayerProperties(
      lineCap: 'round',
      lineJoin: 'round',
      lineColor: '#4285F4',
      lineWidth: 5,
      lineOpacity: 0.8,
    ),
  );

  await controller.addLayer(
    'safe-place-pin-source',
    'safe-place-line-pin-layer',
    const SymbolLayerProperties(
      iconImage: 'selected',
      iconSize: 2.5,
      iconAllowOverlap: true,
      symbolZOrder: 100,
    ),
  );

  List<LatLng> listForComputeBounds = route
      .map(
        (e) => LatLng(
          e[1],
          e[0],
        ),
      )
      .toList();

  LatLngBounds bounds = computeBounds(listForComputeBounds);

  await controller.animateCamera(CameraUpdate.newLatLngBounds(
    bounds,
    bottom: 200,
    left: 50,
    right: 50,
    top: 180,
  ));
}

String generatePathDescription(dynamic distance, dynamic duration,
    {bool justTime = false}) {
  String? finalDistance;
  String? finalTime;

  if (distance < 500) {
    finalDistance = '${(distance).toStringAsFixed(0)}м';
  } else {
    double distanceInKiloMeters = distance / 1000;
    finalDistance = '${(distanceInKiloMeters).toStringAsFixed(1)}км';
  }

  int hours, mins;
  hours = duration ~/ 3600;
  mins = ((duration - hours * 3600)) ~/ 60;

  if (hours > 0) {
    finalTime = '$hoursг $minsхв';
  } else if (hours > 0 && mins == 0) {
    finalTime = '$hoursг';
  } else {
    finalTime = '$minsхв';
  }

  if (justTime) {
    return finalTime;
  }

  return '$finalDistance ≈ $finalTime';
}

List getParsedResponseFromFeatures(List<MapBoxPlace> features) {
  List parsedResponses = [];

  for (var feature in features) {
    if (feature.placeName == null ||
        feature.center == null ||
        feature.center!.length < 2) {
      continue;
    }
    Map response = {
      'name': feature.text,
      'address': feature.placeName!.split('${feature.text}, ')[1],
      'place': feature.placeName,
      'location': LatLng(feature.center![1], feature.center![0])
    };
    parsedResponses.add(response);
  }
  return parsedResponses;
}

Future cleanUpExpiredRegions() async {
  var regions = await getListOfRegions();
  log('all regions count ${regions.length}');
  var now = DateTime.now();
  var dayNow = DateTime(now.year, now.month, now.day);
  for (var region in regions) {
    if (!region.metadata.containsKey('expireDay')) {
      await deleteOfflineRegion(region.id);
      continue;
    }
    if (!dayNow
        .difference(DateTime.parse(region.metadata['expireDay']))
        .isNegative) {
      await deleteOfflineRegion(region.id);
    }
  }
}

Future downloadRegionStreets(LatLngBounds bounds) async {
  var now = DateTime.now();
  var dayToDelete = DateTime(now.year, now.month, now.day + 1);
  await downloadOfflineRegion(
    accessToken: kMapAccessToken,
    metadata: {'expireDay': dayToDelete.toString()},
    OfflineRegionDefinition(
      bounds: bounds,
      minZoom: 6,
      maxZoom: 22,
      mapStyleUrl: 'mapbox://styles/mapbox/streets-v12',
      includeIdeographs: true,
    ),
    onEvent: (DownloadRegionStatus status) {
      log(status.toString());
      if (status.runtimeType == Success) {
        // ...
      } else if (status.runtimeType == InProgress) {
        // int progress = (status as InProgress).progress.round();
        // ...
      } else if (status.runtimeType == Error) {
        log((status as Error).cause.details);
        log(status.cause.message ?? '');
        log(status.cause.code);
        // ...
      }
    },
  ).catchError((error) async {
    log(error.toString());
    return error;
  });
}
