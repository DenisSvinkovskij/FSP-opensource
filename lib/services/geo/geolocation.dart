import 'package:easy_localization/easy_localization.dart';
import 'package:find_safe_places/constants/map.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mapbox_search/mapbox_search.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as maps_toolkit;

var geoCodingService = ReverseGeoCoding(
  apiKey: kMapAccessToken,
  limit: 1,
  types: PlaceType.address,
);
var placesSearchService = PlacesSearch(
  apiKey: kMapAccessToken,
  limit: 5,
);

Future<Position> getLocation() async {
  Position position = await GeolocatorPlatform.instance.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.best,
    ),
  );

  return position;
}

Future getLocationWithGeoHash() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  permission = await Geolocator.checkPermission();
  if (!serviceEnabled || permission == LocationPermission.denied) {
    return false;
  }
  Position position = await GeolocatorPlatform.instance.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.best,
    ),
  );

  GeoFirePoint locationWithGeoHash = GeoFlutterFire()
      .point(latitude: position.latitude, longitude: position.longitude);

  return locationWithGeoHash.data;
}

Future<bool> handleLocationPermission(context) async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('location_services_disabled'))));
    return false;
  }
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('location_permissions_denied'))));
      return false;
    }
  }
  if (permission == LocationPermission.deniedForever) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('location_permissions_denied_permanently'))));
    return false;
  }
  return true;
}

Future<Map<String, String>> getAddressFromLocation(LatLng location) async {
  var addresses = await geoCodingService.getAddress(Location(
    lat: location.latitude,
    lng: location.longitude,
  ));
  var first = (addresses ?? []).isNotEmpty ? addresses?.first : null;
  if (first == null) {
    return {'error': 'Address not found'};
  }
  List<String> text = first.text!.split(' ');

  String str = text.elementAt(text.length - 1).toLowerCase();
  text.insert(0, str);
  text.removeAt(text.length - 1);
  text.add(first.addressNumber ?? '');

  String address = text.join(' ');
  List<String> addressArr = first.placeName!.split(', ');
  addressArr.removeRange(0, 2);
  String globalAddress = addressArr.join(', ');
  return {
    'address': address,
    'globalAddress': globalAddress,
  };
}

Future<Map<String, String>> getRegionFromLocation(LatLng location) async {
  var geoCodingServiceRegion = ReverseGeoCoding(
    apiKey: kMapAccessToken,
    country: "UA",
    types: PlaceType.region,
  );

  var addresses = await geoCodingServiceRegion.getAddress(Location(
    lat: location.latitude,
    lng: location.longitude,
  ));
  var first = (addresses ?? []).isNotEmpty ? addresses?.first : null;
  if (first == null) {
    return {'error': 'Address not found'};
  }

  List<String> text = first.text!.split(' ');

  String region = text[0];

  return {
    'region': region,
  };
}

dynamic getNearestMarker(arr, myPosition) {
  var distances = {};
  var closest = -1;

  for (var i = 0; i < arr.length; i++) {
    var mlat = arr[i][1];
    var mlng = arr[i][0];

    var d = GeolocatorPlatform.instance
        .distanceBetween(myPosition.latitude, myPosition.longitude, mlat, mlng);
    distances[i] = d;
    if (closest == -1 || d < distances[closest]) {
      closest = i;
    }
  }

  return arr[closest];
}

bool checkIfPositionInPolygon(
  LatLng position,
  List polygon,
) {
  maps_toolkit.LatLng positionLatLng =
      maps_toolkit.LatLng(position.latitude, position.longitude);
  List<maps_toolkit.LatLng> polygonLatLng = [];
  for (var element in polygon) {
    polygonLatLng.add(maps_toolkit.LatLng(element[1], element[0]));
  }

  return maps_toolkit.PolygonUtil.containsLocation(
    positionLatLng,
    polygonLatLng,
    false,
  );
}
