import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:find_safe_places/constants/map.dart';
import 'package:find_safe_places/constants/other.dart';
import 'package:find_safe_places/helpers/map.dart';
import 'package:find_safe_places/helpers/map_layouts.dart';
import 'package:find_safe_places/helpers/notifications.dart';
import 'package:find_safe_places/models/close_person.dart';
import 'package:find_safe_places/models/saved_safe_place.dart';
import 'package:find_safe_places/models/user.dart';
import 'package:find_safe_places/providers/user_provider.dart';
import 'package:find_safe_places/screens/search_location_screen.dart';
import 'package:find_safe_places/services/connectivity/my_connectivity.dart';
import 'package:find_safe_places/services/firebase/common.dart';
import 'package:find_safe_places/services/firebase/users_firebase.dart';
import 'package:find_safe_places/services/httpRequests/index.dart';
import 'package:find_safe_places/utils/index.dart';
import 'package:find_safe_places/screens/splash/splash_screen.dart';
import 'package:find_safe_places/services/geo/geolocation.dart';
import 'package:find_safe_places/widgets/map/bottom_map_navigation.dart';
import 'package:find_safe_places/widgets/map/info_sliding_up.dart';
import 'package:find_safe_places/widgets/map/search_direction_map_panel.dart';
import 'package:find_safe_places/widgets/map/search_place_map_panel.dart';
import 'package:find_safe_places/widgets/top_Info_widget.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'dart:core';

import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class FullMap extends StatefulWidget {
  const FullMap({
    super.key,
    this.initCalculatePath = false,
    this.initialSelectedMarkerPosition,
    this.initialSelectedMarkerInfo,
  });
  final bool initCalculatePath;
  final LatLng? initialSelectedMarkerPosition;
  final Map<String, dynamic>? initialSelectedMarkerInfo;

  @override
  State createState() => FullMapState();
}

class FullMapState extends State<FullMap> {
  MapboxMapController? controller;
  final GlobalKey<ScaffoldState> _scaffoldStateKey = GlobalKey<ScaffoldState>();
  final PanelController panelController = PanelController();
  StreamSubscription? usersSavedSafePlacesFeaturesSubscription;
  StreamSubscription? emergenciesSubscription;
  StreamSubscription? familyDocsSub;

  Map _connectingSource = {ConnectivityResult.none: false};
  final MyConnectivity _connectivity = MyConnectivity.instance;
  StreamSubscription<dynamic>? connectivitySub;

  LatLng myCurrentLocation = const LatLng(49.842957, 24.041111);
  LatLng? selectedMarkerPosition;
  Map<String, dynamic>? selectedMarkerInfo;

  List<Map<String, dynamic>>? myCurrentEmergency;
  List<Map<String, dynamic>>? selectedEmergency;

  double zoomState = 6.0;
  bool isLight = true;
  bool isMapStyleLoaded = false;
  bool visibleAllSafePlaces = true;
  bool visibleFamilyLocations = true;
  bool isVisibleInvincibilityPoints = true;
  bool needToLoadUsersPlaces = true;
  bool isClosedTopSearch = true;
  String? loggedUserId;
  bool locationPermission = false;
  bool haveInitialData = false;
  PanelState defaultPanelState = PanelState.CLOSED;
  bool isNowInEmergencyZone = false;

  bool hasInternetConnection = true;
  String loadedOfflineRegion = 'idle';

  String? infoType;

  String? selectedMarkerLocationAddress;
  String selectedBottomNavItemText = 'Поруч';

  SplashScreen splash = const SplashScreen(hidden: false);

  var usersSavedSafePlacesFeatures = [];
  var familyLocationsFeatures = [];
  var emergencyFills = [];
  List<String> localSendedNotificationIds = [];

  _onMapCreated(MapboxMapController controller) async {
    this.controller = controller;

    await setOfflineTileCountLimit(
      10000000,
      accessToken: kMapAccessToken,
    );
    try {
      await installOfflineMapTiles("assets/cache.db");
    } catch (e) {
      log('error on load offline map');
      print(e);
    }

    if (locationPermission) {
      Position currentLocation = await getLocation();
      LatLng myLocationLatLng = LatLng(
        currentLocation.latitude,
        currentLocation.longitude,
      );
      setState(() {
        myCurrentLocation = myLocationLatLng;
      });
      await moveCameraToPosition(target: myLocationLatLng);
      checkEmergencyFillsAndSendNotifications(emergencyFills);
      downloadVisibleRegion();
    }
  }

  downloadVisibleRegion() async {
    sleep(const Duration(seconds: 1));
    if ((controller!.cameraPosition?.zoom ?? 1) < 11) return;
    var bounds = await controller!.getVisibleRegion();
    log(_connectingSource.keys.toList()[0].toString());
    if (_connectingSource.keys.toList()[0] == ConnectivityResult.wifi &&
        loadedOfflineRegion != 'pending' &&
        loadedOfflineRegion != 'loaded') {
      await cleanUpExpiredRegions();
      setState(() {
        loadedOfflineRegion = 'pending';
      });
      downloadRegionStreets(bounds)
          .then(
            (value) => {
              setState(() {
                loadedOfflineRegion = 'loaded';
              })
            },
          )
          .onError(
            (error, stackTrace) => {
              setState(() {
                loadedOfflineRegion = 'error';
              })
            },
          );
    }
  }

  Future<void> addAllImagesToMap() async {
    await addImageFromAsset("7E57C2", "assets/7E57C2_marker.png", controller!);
    await addImageFromAsset("9CCC65", "assets/9CCC65_marker.png", controller!);
    await addImageFromAsset("FFCA28", "assets/FFCA28_marker.png", controller!);
    await addImageFromAsset("selected", "assets/red_marker.png", controller!);
    await addImageFromAsset("shelter", "assets/shelter.png", controller!);
    await addImageFromAsset(
      "invincibility_point",
      "assets/invincibility_point_marker.png",
      controller!,
    );
    await addImageFromAsset(
      "invincibility_business",
      "assets/invincibility_businesses_marker.png",
      controller!,
    );
    await addImageFromAsset(
        "saved-places", "assets/saved_marker.png", controller!);
  }

  _onUserLocationUpdated(location) async {
    if (!mounted) return;
    UserModel? user = Provider.of<UserProvider>(context, listen: false).user;

    if (locationPermission) {
      checkEmergencyFillsAndSendNotifications(emergencyFills);
    }

    if (locationPermission && (location.speed ?? 0.0) > 0.2 && user != null) {
      double latitude = location.runtimeType == LocationData
          ? location.latitude
          : location.position.latitude;
      double longitude = location.runtimeType == LocationData
          ? location.longitude
          : location.position.longitude;

      final point = GeoFlutterFire().point(
        latitude: latitude,
        longitude: longitude,
      );

      await UsersFirebase.updateUser(user.uid, {'location': point.data});
      await UsersFirebase.updateUserForFamily(
        user.uid,
        {'location': point.data},
        user.familyIds ?? [],
      );
    }
  }

  Future<void> addGeoJsonSource(sourceId, points) async {
    await controller!.addGeoJsonSource(sourceId, {
      'type': "FeatureCollection",
      'features': points,
    });
  }

  Future<void> updateGeoJsonSource(sourceId, points) async {
    await controller!.setGeoJsonSource(sourceId, {
      'type': "FeatureCollection",
      'features': points,
    });
  }

  _onStyleLoadedCallback() async {
    await addAllImagesToMap();
    await removeLayer(kSafePlacesLayerId, controller!);
    await removeLayer(kFamilyLocationsLayerId, controller!);
    await removeLayer(kUsersSavedSafePlacesLayerId, controller!);
    await removeLayer(kEmergenciesFillsLayerId, controller!);

    // await addInvincibilityBusinessesLayer(
    //   sourceExist: false,
    //   controller: controller!,
    // );
    // await addInvincibilityPointsLayer(
    //   sourceExist: false,
    //   controller: controller!,
    // );
    await addGeoJsonSource(
      kUsersSavedSafePlacesSourceId,
      usersSavedSafePlacesFeatures,
    );
    await addGeoJsonSource(
      kEmergenciesFillsSourceId,
      getEmergencyFills([]),
    );
    await addGeoJsonSource(
      kFamilyLocationsSourceId,
      [],
    );
    await addGeoJsonSource(
      kSelectedMarkerSourceId,
      [],
    );
    await addSafePlacesLayer(controller!);
    await addUsersSavedSafePlacesLayer(controller!);
    await addFamilyLocationsLayer(controller!);
    await addFillLayer(controller!);
    await addSelectedMarkerLayer(controller!);
    addFillFeaturesTapedListener();
    addListenersToFeatures();

    if (haveInitialData) {
      setState(() {
        selectedMarkerPosition = widget.initialSelectedMarkerPosition;
        selectedMarkerInfo = widget.initialSelectedMarkerInfo;
        infoType = kInfoTypeMarker;
      });
      addSelectedMarkerInSource(widget.initialSelectedMarkerPosition,
          widget.initialSelectedMarkerInfo);
      moveCameraToPosition(target: widget.initialSelectedMarkerPosition!);
      openBottomPanel();
    }

    setState(() {
      splash = const SplashScreen(hidden: true);
      isMapStyleLoaded = true;
    });
    if (emergenciesSubscription == null) {
      addEmergenciesSub();
    }
    if (!mounted) return;
    UserModel? user = Provider.of<UserProvider>(context, listen: false).user;

    if (user != null) {
      addSetUserSavedSafePlacesSub(user.uid);
      addFamilySub(user.uid);
      setState(() {
        loggedUserId = user.uid;
      });
    }
  }

  void addListenersToFeatures() {
    controller!.onFeatureTapped.add((id, point, coordinates) async {
      final features = await controller!.queryRenderedFeatures(
        point,
        [kFamilyLocationsLayerId],
        null,
      );

      familyFeaturesCallback(point, tapedCoords, data) async {
        setState(() {
          selectedMarkerPosition = tapedCoords;
          selectedMarkerInfo = data;
          infoType = kInfoTypeMarker;
        });
        addSelectedMarkerInSource(tapedCoords, data);
        openBottomPanel();
      }

      commonFeatureListen(id, point, features, familyFeaturesCallback);
    });

    controller!.onFeatureTapped.add((id, point, coordinates) async {
      final features = await controller!.queryRenderedFeatures(
        point,
        [
          kUsersSavedSafePlacesLayerId,
          kSafePlacesLayerId,
          kInvincibilityPointsLayerId,
          kInvincibilityBusinessesLayerId,
        ],
        null,
      );

      log('click feature');
      log('${features.length}');

      safePlacesCallback(point, tapedCoords, data) async {
        setState(() {
          selectedMarkerPosition = tapedCoords;
          selectedMarkerInfo = data;
          infoType = kInfoTypeMarker;
        });
        addSelectedMarkerInSource(tapedCoords, data);
        openBottomPanel();
      }

      commonFeatureListen(id, point, features, safePlacesCallback);
    });
  }

  addSelectedMarkerInSource(coords, data) {
    updateGeoJsonSource(kSelectedMarkerSourceId, [
      {
        'type': "Feature",
        'id': 'selected-marker',
        'properties': data,
        'geometry': {
          'type': "Point",
          'coordinates': [coords.longitude, coords.latitude]
        }
      }
    ]);
  }

  clearSelectedMarkerSource() {
    updateGeoJsonSource(kSelectedMarkerSourceId, []);
  }

  moveCameraToPosition({required LatLng target, double? newZoom}) async {
    double zoom = controller!.cameraPosition!.zoom < 11
        ? 11
        : controller!.cameraPosition!.zoom;
    await controller!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: newZoom ?? zoom,
        ),
      ),
    );
  }

  Future commonFeatureListen(id, point, features, Function callback) async {
    var one = await features.firstWhere((element) {
      return element['id'] == id;
    }, orElse: () => null);

    if (one == null && features.isEmpty) {
      return;
    }

    if (one == null && features.isNotEmpty) {
      one = features.first;
    }

    final lat = one['geometry']['coordinates'][1];
    final lng = one['geometry']['coordinates'][0];

    moveCameraToPosition(
      target: LatLng(
        lat,
        lng,
      ),
    );

    var propertiesFromFeature =
        one['properties']['properties'] ?? one['properties'];
    final jsonStr = propertiesFromFeature.runtimeType == String
        ? propertiesFromFeature
        : json.encode(propertiesFromFeature);

    final decodedJson = json.decode(jsonStr);
    Map<String, dynamic> data = decodedJson.containsKey('name')
        ? decodedJson
        : {
            ...decodedJson,
            'placeholder': 'Вибрати',
            'userId': loggedUserId,
            'placeId': decodedJson['id']
          };

    LatLng tapedCoords = LatLng(
      lat,
      lng,
    );

    callback(point, tapedCoords, data);
  }

  Future<void> moveCameraToMyPosition() async {
    await Location.instance.requestService();

    PermissionStatus permissionStatus =
        await Location.instance.requestPermission();
    if (permissionStatus == PermissionStatus.deniedForever ||
        permissionStatus == PermissionStatus.denied) {
      return;
    }

    Position currentLocation = await getLocation();
    setState(() {
      myCurrentLocation = LatLng(
        currentLocation.latitude,
        currentLocation.longitude,
      );
    });

    controller!.updateMyLocationTrackingMode(MyLocationTrackingMode.Tracking);
    await moveCameraToPosition(
      target: LatLng(
        currentLocation.latitude,
        currentLocation.longitude,
      ),
    );
    downloadVisibleRegion();
  }

  Future<void> addSetUserSavedSafePlacesSub(String userId) async {
    final safePlacesSub = UsersFirebase.getUsersSafePlaces(userId).listen(
      (querySnapshot) async {
        var results = firestoreCollectionToArray(querySnapshot);
        var parsedResults =
            results.map((e) => SavedSafePlaceModel.fromJson(e)).toList();

        final usersSavedSafePlacesPoints =
            getSavedSafePlacesFeatures(parsedResults, userId);

        setState(() {
          usersSavedSafePlacesFeatures = usersSavedSafePlacesPoints;
        });

        if (controller != null && isMapStyleLoaded) {
          await updateGeoJsonSource(
            kUsersSavedSafePlacesSourceId,
            usersSavedSafePlacesFeatures,
          );
        }
      },
    );

    if (usersSavedSafePlacesFeaturesSubscription != null) {
      usersSavedSafePlacesFeaturesSubscription?.cancel();
    }

    setState(() {
      usersSavedSafePlacesFeaturesSubscription = safePlacesSub;
      needToLoadUsersPlaces = false;
    });
  }

  Future<void> removeUsersSafePlacesSub() async {
    await usersSavedSafePlacesFeaturesSubscription?.cancel();
  }

  void addFillFeaturesTapedListener() {
    controller!.onFeatureTapped.add(
      (id, point, coordinates) async {
        final features = await controller!.queryRenderedFeatures(
          point,
          [
            kEmergenciesFillsLayerId,
          ],
          null,
        );
        if (features.isNotEmpty) {
          if (features.length > 1) {
            bool isFeaturesAreSelected = false;
            List selectedIds =
                (selectedEmergency ?? []).map((e) => e['id']).toList();
            for (var e in features) {
              var res = selectedIds.indexOf(e?['properties']?['id']);
              isFeaturesAreSelected = res == -1 ? false : true;
            }
            if (infoType != null &&
                features.length == selectedEmergency?.length &&
                isFeaturesAreSelected) {
              onMapClick(point, coordinates);
              return;
            }

            showEmergencyInfo(features);
            return;
          } else {
            if (features.length == selectedEmergency?.length &&
                features.first?['properties']?['id'] ==
                    selectedEmergency?.first['id']) {
              onMapClick(point, coordinates);
              return;
            }

            showEmergencyInfo(features);
            return;
          }
        }
      },
    );
  }

  showEmergencyInfo(List<dynamic> features) {
    resetSelectedMarker();

    setState(() {
      infoType = kInfoTypeEmergency;
      selectedEmergency =
          features.map((e) => e['properties'] as Map<String, dynamic>).toList();
    });
    openBottomPanel();
  }

  resetSelectedMarker() {
    setState(() {
      selectedMarkerPosition = null;
      selectedMarkerInfo = null;
      selectedMarkerLocationAddress = null;
      isClosedTopSearch = true;
      selectedEmergency = null;
      infoType = null;
    });
    clearSelectedMarkerSource();
    panelController.close();
  }

  Future<void> addEmergenciesSub() async {
    final emergenciesSub = CommonFirebase.getEmergencies().listen(
      (querySnapshot) async {
        var results = firestoreCollectionToArray(querySnapshot);
        var fills = results
            .where((element) => element['geometryObject'] == 'polygon')
            .toList();

        var newFills = getEmergencyFills(fills);

        setState(() {
          emergencyFills = newFills;
        });

        if (controller != null && isMapStyleLoaded) {
          await updateGeoJsonSource(
            kEmergenciesFillsSourceId,
            newFills,
          );
        }

        checkEmergencyFillsAndSendNotifications(newFills);
      },
    );

    if (emergenciesSubscription != null) {
      emergenciesSubscription?.cancel();
    }

    setState(() {
      emergenciesSubscription = emergenciesSub;
    });
  }

  Future<void> removeEmergenciesSub() async {
    await emergenciesSubscription?.cancel();
  }

  Future<void> addFamilySub(String userId) async {
    final familySub =
        UsersFirebase.getClosePersonsByStatus(userId, 'accepted').listen(
      (querySnapshot) async {
        var results = firestoreCollectionToArray(querySnapshot);
        List<ClosePerson> persons = results
            .map((e) => ClosePerson.fromJson(e))
            .where((element) => element.location != null)
            .toList();

        final familyPoints = getFamilyFeatures(persons);

        setState(() {
          familyLocationsFeatures = familyPoints;
        });

        if (controller != null && isMapStyleLoaded) {
          await updateGeoJsonSource(
            kFamilyLocationsSourceId,
            familyLocationsFeatures,
          );
        }
      },
    );

    if (familyDocsSub != null) {
      familyDocsSub?.cancel();
    }

    setState(() {
      familyDocsSub = familySub;
    });
  }

  Future<void> removeFamilySub() async {
    await familyDocsSub?.cancel();
  }

  checkEmergencyFillsAndSendNotifications(List fills) {
    UserModel? user = Provider.of<UserProvider>(context, listen: false).user;
    int inEmergencyCount = 0;
    List<Map<String, dynamic>> currentEmergencies = [];

    for (var element in fills) {
      bool isInEmergency = checkIfPositionInPolygon(
          myCurrentLocation, element['geometry']['coordinates'][0]);
      if (isInEmergency) {
        var locale = context.locale.toLanguageTag();
        sendNotificationAboutEmergency(
          element['properties']['id'],
          element['properties']['title'][locale],
          element['properties']['body'][locale],
          user,
          localSendedNotificationIds,
        );
        setState(() {
          localSendedNotificationIds.add(element['properties']['id']);
        });

        var currentEmergency = element['properties'];
        inEmergencyCount += 1;
        currentEmergencies.add(currentEmergency);
      }
    }

    if (inEmergencyCount == 0) {
      setState(() {
        isNowInEmergencyZone = false;
        myCurrentEmergency = null;
      });
    } else {
      setState(() {
        isNowInEmergencyZone = true;
        myCurrentEmergency = currentEmergencies;
      });
    }
  }

  selectBottomNavItem(String item) async {
    if (item == 'Поруч' && selectedBottomNavItemText == 'Поруч') {
      if (controller == null) return;
      dynamic marker = await getSelectedOrNearestMarker(
        myCurrentLocation,
        selectedMarkerPosition,
        controller!,
      );

      if (marker[0] == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No visible safe places on screen')));
        return;
      }

      setState(() {
        selectedMarkerPosition = LatLng(marker[1], marker[0]);
        selectedMarkerInfo = {};
        infoType = kInfoTypeMarker;
      });
      addSelectedMarkerInSource(LatLng(marker[1], marker[0]), {});
      openBottomPanel();

      moveCameraToPosition(
        target: LatLng(marker[1], marker[0]),
      );
    }

    setState(() {
      selectedBottomNavItemText = item;
    });
  }

  reAddSafePlacesLayer() {
    removeLayer(kSafePlacesLayerId, controller!);
    addSafePlacesLayer(controller!);
  }

  reAddInvincibilityBusinessesLayer() {
    removeLayer(kInvincibilityBusinessesLayerId, controller!);
    addInvincibilityBusinessesLayer(
      sourceExist: true,
      controller: controller!,
    );
  }

  reAddInvincibilityPointsLayer() {
    removeLayer(kInvincibilityPointsLayerId, controller!);
    addInvincibilityPointsLayer(
      sourceExist: true,
      controller: controller!,
    );
  }

  toggleVisibleInvincibilityPoints(bool isVisible) {
    setState(() {
      isVisibleInvincibilityPoints = isVisible;
    });

    if (!isVisible) {
      removeLayer(kInvincibilityBusinessesLayerId, controller!);
      removeLayer(kInvincibilityPointsLayerId, controller!);
    } else {
      reAddInvincibilityBusinessesLayer();
      reAddInvincibilityPointsLayer();
    }
  }

  toggleVisibleAllSafePlaces(bool isVisible) {
    setState(() {
      visibleAllSafePlaces = isVisible;
    });

    if (!isVisible) {
      removeLayer(kSafePlacesLayerId, controller!);
    } else {
      addSafePlacesLayer(controller!);
    }
  }

  onTapSearch() async {
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SearchLocationScreen(initAddress: selectedMarkerLocationAddress),
        ));

    if (result == null) return;

    if (!mounted) return;

    UserModel? user = Provider.of<UserProvider>(context, listen: false).user;
    setSelectedMarker({'userId': user?.uid}, result['location']);
  }

  setSelectedMarker(Map<String, dynamic> info, LatLng position) {
    moveCameraToPosition(target: position);
    setState(() {
      selectedMarkerInfo = info;
      selectedMarkerPosition = position;
      infoType = kInfoTypeMarker;
      selectedEmergency = null;
    });
    addSelectedMarkerInSource(position, info);
    openBottomPanel();
  }

  onMapClick(point, LatLng coordinates) async {
    UserModel? user = Provider.of<UserProvider>(context, listen: false).user;
    if (selectedMarkerPosition == null) {
      setSelectedMarker({'userId': user?.uid}, coordinates);
      return;
    }
    resetSelectedMarker();
  }

  getEmergencyWarnWidget() {
    if (isNowInEmergencyZone) {
      return Container(
        alignment: Alignment.topCenter,
        padding: const EdgeInsets.only(
          top: 70,
        ),
        child: Column(
          children: [
            FloatingActionButton(
              heroTag: 'in-danger',
              mini: true,
              onPressed: () async {
                setState(() {
                  infoType = kInfoTypeEmergency;
                  selectedEmergency = myCurrentEmergency;
                });
                openBottomPanel();
                moveCameraToMyPosition();
              },
              backgroundColor: Colors.red,
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        alignment: Alignment.topCenter,
        padding: const EdgeInsets.only(
          top: 70,
        ),
        child: Column(),
      );
    }
  }

  openBottomPanel({double? value}) {
    panelController.animatePanelToPosition(value ?? 0.7);
  }

  @override
  void initState() {
    setUpLocationService();
    if (widget.initialSelectedMarkerInfo != null &&
        widget.initialSelectedMarkerPosition != null) {
      haveInitialData = true;
      splash = const SplashScreen(hidden: true);
    }
    UserModel? user = Provider.of<UserProvider>(context, listen: false).user;

    if (user != null) {
      visibleAllSafePlaces = user.userAppState.allSafePlacesVisible;
      isVisibleInvincibilityPoints =
          user.userAppState.invincibilityPointsVisible;
    }
    super.initState();

    _connectivity.initialize();
    connectivitySub = _connectivity.myStream.listen((source) {
      setState(() => _connectingSource = source);
      if (_connectingSource.keys.toList()[0] == ConnectivityResult.none) {
        hasInternetConnection = false;
      } else {
        hasInternetConnection = true;
      }
    });
    CommonFirebase.getEmergenciesInfo();
  }

  setUpLocationService() async {
    getShelters();
    bool serviceEnabled = await Location.instance.requestService();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('location_services_disabled'))),
      );
      return;
    }
    PermissionStatus permissionStatus =
        await Location.instance.requestPermission();
    if (permissionStatus != PermissionStatus.deniedForever &&
        permissionStatus != PermissionStatus.denied) {
      locationPermission = true;
      moveCameraToMyPosition();
      Location.instance.enableBackgroundMode(enable: true);
      Location.instance.changeSettings(
        distanceFilter: 20,
        interval: kHourInMilliseconds,
      );

      Location.instance.onLocationChanged.listen(_onUserLocationUpdated);
    }
  }

  getShelters() async {
    final allSheltersFromSQL = await getAllShelters();
    if (allSheltersFromSQL == null) return;
    if (allSheltersFromSQL['ok'] == false) return;
    var data = jsonDecode(allSheltersFromSQL['data']);
    var geoJson = getSafePlacesFeatures(data);
    await addGeoJsonSource(
      kSafePlacesSourceId,
      geoJson,
    );
  }

  @override
  void dispose() {
    super.dispose();
    removeUsersSafePlacesSub();
    removeEmergenciesSub();
    removeFamilySub();
    connectivitySub?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    UserModel? user = Provider.of<UserProvider>(context, listen: true).user;

    if (user != null && loggedUserId == null) {
      addSetUserSavedSafePlacesSub(user.uid);
      addFamilySub(user.uid);
      setState(() {
        loggedUserId = user.uid;
        visibleAllSafePlaces = user.userAppState.allSafePlacesVisible;
        isVisibleInvincibilityPoints =
            user.userAppState.invincibilityPointsVisible;
      });
      if (controller != null) {
        addUsersSavedSafePlacesLayer(controller!);
        addFamilyLocationsLayer(controller!);
        toggleVisibleInvincibilityPoints(isVisibleInvincibilityPoints);
      }
    }
    if (user == null && loggedUserId != null) {
      removeUsersSafePlacesSub();
      removeLayer(kUsersSavedSafePlacesLayerId, controller!);
      removeFamilySub();
      removeLayer(kFamilyLocationsLayerId, controller!);
      setState(() {
        loggedUserId = null;
      });
    }

    return Scaffold(
      key: _scaffoldStateKey,
      body: SlidingUpPanel(
        controller: panelController,
        maxHeight: 300,
        minHeight: 0.0,
        defaultPanelState: defaultPanelState,
        onPanelClosed: () {
          setState(() {
            isClosedTopSearch = true;
          });
        },
        panelBuilder: (sc) => InfoSlidingUp(
          scrollController: sc,
          panelController: panelController,
          myLocation: myCurrentLocation,
          selectedMarkerPosition: selectedMarkerPosition,
          selectedMarkerInfo: selectedMarkerInfo,
          emergencyInfo: selectedEmergency,
          infoType: infoType,
          mapController: controller,
          hasInternetConnection: hasInternetConnection,
          setAddress: (String address) {
            setState(() {
              selectedMarkerLocationAddress = address;
            });
          },
          openSearchBar: () {
            setState(() {
              isClosedTopSearch = false;
            });
          },
        ),
        body: SafeArea(
          child: SizedBox(
            child: Stack(
              children: <Widget>[
                MapboxMap(
                  scrollGesturesEnabled: true,
                  myLocationEnabled: true,
                  trackCameraPosition: true,
                  accessToken: kMapAccessToken,
                  onMapCreated: _onMapCreated,
                  onStyleLoadedCallback: _onStyleLoadedCallback,
                  initialCameraPosition: CameraPosition(
                    target: myCurrentLocation,
                    zoom: zoomState,
                  ),
                  onMapClick: onMapClick,
                  onUserLocationUpdated: _onUserLocationUpdated,
                  annotationOrder: const [
                    AnnotationType.symbol,
                    AnnotationType.line,
                    AnnotationType.circle,
                    AnnotationType.fill
                  ],
                  styleString: 'mapbox://styles/mapbox/streets-v12',
                ),
                getEmergencyWarnWidget(),
                Container(
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(
                    top: 70,
                    right: 15,
                  ),
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: 'my-location',
                        mini: true,
                        onPressed: moveCameraToMyPosition,
                        backgroundColor: Colors.white,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                hasInternetConnection
                    ? Container()
                    : Container(
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.only(
                          top: 70,
                        ),
                        child: Column(
                          children: [
                            TopInfoWidget(text: tr('no_connection')),
                          ],
                        ),
                      ),
                SearchPlaceMapPanel(
                  myLocation: myCurrentLocation,
                  onTapSearch: onTapSearch,
                  closed: isClosedTopSearch,
                  text: selectedMarkerLocationAddress,
                ),
                SearchDirectionMapPanel(
                  selectedMarkerLocation: selectedMarkerPosition,
                  myLocation: myCurrentLocation,
                  mapController: controller,
                  onTapSearch: onTapSearch,
                  closed: isClosedTopSearch,
                  selectedMarkerLocationAddress: selectedMarkerLocationAddress,
                ),
                BottomMapNavigation(
                  setSelectedMarker: setSelectedMarker,
                  selectItem: selectBottomNavItem,
                  selectedItem: selectedBottomNavItemText,
                  isVisibleInvincibilityPoints: isVisibleInvincibilityPoints,
                  isVisibleAllSafePlaces: visibleAllSafePlaces,
                  toggleVisibleAllSafePlaces: toggleVisibleAllSafePlaces,
                  reAddAllPlacesLayer: () {
                    reAddSafePlacesLayer();
                    reAddInvincibilityBusinessesLayer();
                    reAddInvincibilityPointsLayer();
                  },
                  toggleVisibleInvincibilityPoints:
                      toggleVisibleInvincibilityPoints,
                ),
                splash,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
