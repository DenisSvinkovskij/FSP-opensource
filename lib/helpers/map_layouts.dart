import 'package:find_safe_places/constants/map.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

Future<void> addImageFromAsset(
    String name, String assetName, MapboxMapController controller) async {
  final ByteData bytes = await rootBundle.load(assetName);
  final Uint8List list = bytes.buffer.asUint8List();
  return controller.addImage(name, list);
}

Future<void> removeLayer(String layerId, MapboxMapController controller) async {
  await controller.removeLayer(layerId);
}

Future<void> removeSource(
    String sourceId, MapboxMapController controller) async {
  await controller.removeSource(sourceId);
}

Future<void> addSafePlacesLayer(MapboxMapController controller) async {
  const layerProperties = SymbolLayerProperties(
    iconImage: "shelter",
    iconSize: kNormalSizeSymbolIcon,
    iconAllowOverlap: false,
  );
  await controller.addLayer(
    kSafePlacesSourceId,
    kSafePlacesLayerId,
    layerProperties,
    belowLayerId: kUsersSavedSafePlacesLayerId,
  );
}

Future<void> addUsersSavedSafePlacesLayer(
    MapboxMapController controller) async {
  const layerProps = SymbolLayerProperties(
    iconImage: "saved-places",
    iconSize: 2,
    iconAllowOverlap: true,
    textAllowOverlap: true,
    textField: [Expressions.get, "firstLetter"],
    textColor: 'white',
    textTransform: "uppercase",
    textOffset: [
      Expressions.literal,
      [0, -0.2]
    ],
  );

  await controller.addLayer(
    kUsersSavedSafePlacesSourceId,
    kUsersSavedSafePlacesLayerId,
    layerProps,
    belowLayerId: kEmergenciesFillsLayerId,
  );
}

Future<void> addFamilyLocationsLayer(MapboxMapController controller) async {
  const layerProps = SymbolLayerProperties(
    iconImage: [Expressions.get, "colorIcon"],
    iconSize: 2,
    iconAllowOverlap: true,
    textAllowOverlap: true,
    textField: [Expressions.get, "firstLetter"],
    textColor: 'white',
    textTransform: "uppercase",
    textOffset: [
      Expressions.literal,
      [0, -0.2]
    ],
  );

  await controller.addLayer(
    kFamilyLocationsSourceId,
    kFamilyLocationsLayerId,
    layerProps,
    belowLayerId: kEmergenciesFillsLayerId,
  );
}

Future<void> addSelectedMarkerLayer(MapboxMapController controller) async {
  const layerProps = SymbolLayerProperties(
    iconImage: 'selected',
    iconSize: 2.5,
    iconAllowOverlap: true,
    symbolZOrder: 100,
  );

  await controller.addLayer(
    kSelectedMarkerSourceId,
    kSelectedMarkerLayerId,
    layerProps,
  );
}

Future<void> addFillLayer(MapboxMapController controller) async {
  var layerProps = const FillLayerProperties(
    fillColor: '#FF0000',
    fillOpacity: 0.35,
  );

  controller.addFillLayer(
    kEmergenciesFillsSourceId,
    kEmergenciesFillsLayerId,
    layerProps,
  );
}

Future<void> addInvincibilityPointsLayer(
    {required bool sourceExist,
    required MapboxMapController controller}) async {
  if (!sourceExist) {
    const sourceProperties = VectorSourceProperties(
      url: "mapbox://thylacosmilu.clckcpt890aot29mr4l28fhww-8bes7",
    );
    await controller.addSource(kInvincibilityPointsSourceId, sourceProperties);
  }

  const layerProperties = SymbolLayerProperties(
    iconImage: "invincibility_point",
    iconSize: kNormalSizeSymbolIcon,
    iconAllowOverlap: false,
  );
  await controller.addLayer(
    kInvincibilityPointsSourceId,
    kInvincibilityPointsLayerId,
    layerProperties,
    sourceLayer: kInvincibilityPointsSourceLayerId,
    belowLayerId: kSafePlacesLayerId,
  );
}

Future<void> addInvincibilityBusinessesLayer(
    {required bool sourceExist,
    required MapboxMapController controller}) async {
  if (!sourceExist) {
    const sourceProperties = VectorSourceProperties(
      url: "mapbox://thylacosmilu.clckcqspr01xo27mmngo9klro-9gtkx",
    );
    await controller.addSource(
        kInvincibilityBusinessesSourceId, sourceProperties);
  }

  const layerProperties = SymbolLayerProperties(
    iconImage: "invincibility_business",
    iconSize: kNormalSizeSymbolIcon,
    iconAllowOverlap: false,
  );
  await controller.addLayer(
    kInvincibilityBusinessesSourceId,
    kInvincibilityBusinessesLayerId,
    layerProperties,
    sourceLayer: kInvincibilityBusinessesSourceLayerId,
    belowLayerId: kSafePlacesLayerId,
  );
}
