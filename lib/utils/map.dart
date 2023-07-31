import 'dart:math';

import 'package:mapbox_gl/mapbox_gl.dart';

LatLngBounds computeBounds(List<LatLng> list) {
  assert(list.isNotEmpty);
  var firstLatLng = list.first;
  var s = firstLatLng.latitude,
      n = firstLatLng.latitude,
      w = firstLatLng.longitude,
      e = firstLatLng.longitude;
  for (var i = 1; i < list.length; i++) {
    var latlng = list[i];
    s = min(s, latlng.latitude);
    n = max(n, latlng.latitude);
    w = min(w, latlng.longitude);
    e = max(e, latlng.longitude);
  }
  return LatLngBounds(southwest: LatLng(s, w), northeast: LatLng(n, e));
}
