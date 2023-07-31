import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:find_safe_places/constants/map.dart';
import 'package:find_safe_places/constants/other.dart';
import 'package:find_safe_places/constants/ui.dart';
import 'package:find_safe_places/screens/auth/login_screen.dart';
import 'package:find_safe_places/services/geo/geolocation.dart';
import 'package:find_safe_places/widgets/carousel_with_dots.dart';
import 'package:find_safe_places/widgets/map/additional_point_info.dart';
import 'package:find_safe_places/widgets/save_safe_place.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../../helpers/map.dart';

class InfoSlidingUp extends StatefulWidget {
  final ScrollController? scrollController;
  final PanelController panelController;
  final MapboxMapController? mapController;
  final LatLng myLocation;
  final LatLng? selectedMarkerPosition;
  final Map<String, dynamic>? selectedMarkerInfo;
  final Function openSearchBar;
  final Function setAddress;
  final List<Map<String, dynamic>>? emergencyInfo;
  final String? infoType;
  final bool hasInternetConnection;

  const InfoSlidingUp({
    super.key,
    required this.scrollController,
    required this.panelController,
    required this.mapController,
    required this.myLocation,
    required this.selectedMarkerPosition,
    required this.selectedMarkerInfo,
    required this.openSearchBar,
    required this.setAddress,
    required this.emergencyInfo,
    required this.infoType,
    required this.hasInternetConnection,
  });

  @override
  State<InfoSlidingUp> createState() => _InfoSlidingUpState();
}

class _InfoSlidingUpState extends State<InfoSlidingUp> {
  bool loading = false;
  String street = '';
  String globalAddress = '';
  String pathDescription = '';
  String placeOrPersonName = '';
  IconData? descriptionPlaceIcon;
  Map<String, dynamic> route = {};
  bool firstLoad = true;
  bool addressFounded = false;

  onUpdateWidget(InfoSlidingUp? old) async {
    if (widget.selectedMarkerInfo == null ||
        widget.selectedMarkerPosition == null ||
        widget.mapController == null ||
        old?.selectedMarkerPosition == widget.selectedMarkerPosition) return;
    if (!firstLoad) {
      if (widget.panelController.isPanelOpen) return;
    }
    setState(() {
      loading = true;
      addressFounded = false;
    });

    final firstRoute = await calculateRoute(
      'driving',
      widget.myLocation,
      widget.selectedMarkerPosition,
      widget.mapController!,
    );
    if (firstRoute['error'] != null && firstRoute['error']?.isNotEmpty) {
      log(firstRoute['error']);
      setState(() {
        loading = false;
      });
      return;
    }
    var addressData =
        await getAddressFromLocation(widget.selectedMarkerPosition!);
    if (addressData.containsKey('error')) {
      setState(() {
        globalAddress = 'Не визначено точну адресу';
        street = 'Не визначено точну адресу';
        loading = false;
        route = firstRoute;
        pathDescription = generatePathDescription(
            firstRoute['distance'], firstRoute['duration']);
        addressFounded = false;
      });
      return;
    }

    String name = '';
    IconData? icon;

    if (widget.selectedMarkerInfo?['type'] == kSafePlaceFeatureType ||
        widget.selectedMarkerInfo?['type'] == kFamilyFeatureType) {
      name = widget.selectedMarkerInfo!['name'];
      icon = widget.selectedMarkerInfo?['type'] == kFamilyFeatureType
          ? Icons.person
          : Icons.home;
    }

    setState(() {
      globalAddress = addressData['globalAddress'] ?? '';
      street = addressData['address'] ?? '';
      loading = false;
      route = firstRoute;
      pathDescription = generatePathDescription(
          firstRoute['distance'], firstRoute['duration']);
      placeOrPersonName = name;
      descriptionPlaceIcon = icon;
      addressFounded = true;
    });

    widget.setAddress('$street, $globalAddress');
  }

  onClickBuildPath() async {
    if (route.isEmpty || widget.mapController == null) return;
    if (addressFounded) {
      widget.setAddress('$street, $globalAddress');
    }
    widget.openSearchBar();
    await showPath(route, widget.mapController!);
    widget.panelController.animatePanelToPosition(0.8);
  }

  onClickSave() async {
    if (widget.selectedMarkerInfo == null ||
        widget.selectedMarkerPosition == null) return;

    widget.panelController.close();

    if (widget.selectedMarkerInfo?['userId'] != null) {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel:
            MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: Colors.black45,
        transitionDuration: const Duration(milliseconds: 250),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          final tween = Tween(begin: begin, end: end);
          final offsetAnimation = animation.drive(tween);
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        pageBuilder: (BuildContext buildContext, Animation animation,
            Animation secondaryAnimation) {
          return SaveSafePlace(
            coordinate: widget.selectedMarkerPosition!,
            data: widget.selectedMarkerInfo!,
            close: () {
              Navigator.pop(context);
            },
          );
        },
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  void didUpdateWidget(old) {
    super.didUpdateWidget(old);
    onUpdateWidget(old);
  }

  @override
  void dispose() {
    super.dispose();
    widget.scrollController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (firstLoad) {
      onUpdateWidget(null);
      setState(() {
        firstLoad = false;
      });
    }

    return loading
        ? const Center(child: CircularProgressIndicator())
        : getContent();
  }

  getContent() {
    var locale = context.locale.toLanguageTag();
    if (widget.infoType == kInfoTypeEmergency && widget.emergencyInfo != null) {
      return ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.only(
          top: 0,
          left: kDefaultPadding,
          right: kDefaultPadding,
          bottom: kDefaultPadding,
        ),
        children: [
          const SizedBox(height: 5),
          buildDragHandle(),
          const SizedBox(height: 15),
          CarouselWithDots(
            items: widget.emergencyInfo!,
            itemsMapCallback: (i) {
              return Builder(
                builder: (BuildContext context) {
                  return SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          i['title'][locale] ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          i['body'][locale] ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w300,
                            // color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Flexible(
                          child: Text(
                            '${tr('nature')}: ${i['emergencyNature'][locale]}',
                            maxLines: 2,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Flexible(
                          child: Text(
                            '${tr('type')}: ${i['emergencyType'][locale]}',
                            maxLines: 2,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          )
        ],
      );
    }

    if (!widget.hasInternetConnection) {
      return ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.only(
          top: 0,
          left: kDefaultPadding,
          right: kDefaultPadding,
          bottom: kDefaultPadding,
        ),
        children: [
          const SizedBox(height: 5),
          buildDragHandle(),
          const SizedBox(height: 15),
          Text(
            tr('no_connection'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            tr('unable_to_load_additional_information'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w300,
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    bool showAdditionalInfo = widget.selectedMarkerInfo?['pointType'] ==
            kInvincibilityPointType ||
        widget.selectedMarkerInfo?['pointType'] == kInvincibilityBusinessType;

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.only(
        top: 0,
        left: kDefaultPadding,
        right: kDefaultPadding,
        bottom: kDefaultPadding,
      ),
      children: [
        const SizedBox(height: 5),
        buildDragHandle(),
        const SizedBox(height: 15),
        if (placeOrPersonName.isNotEmpty && descriptionPlaceIcon != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                descriptionPlaceIcon,
                size: 18,
                color: Colors.black87,
              ),
              const SizedBox(width: 3),
              Text(
                placeOrPersonName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        Text(
          street,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          globalAddress,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w300,
            color: Colors.grey,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_car_filled_outlined,
              size: 16,
              color: Colors.grey,
            ),
            const SizedBox(width: 3),
            Text(
              pathDescription,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: onClickBuildPath,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                icon: const Icon(
                  Icons.directions_rounded,
                  color: Colors.white,
                ),
                label: const Text(
                  'Маршрут',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              if (widget.selectedMarkerInfo != null &&
                  !widget.selectedMarkerInfo!.containsKey('colorIcon'))
                ElevatedButton.icon(
                  onPressed: () async {
                    onClickSave();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  icon: Icon(
                    Icons.bookmark_add_outlined,
                    color: Theme.of(context).primaryColor,
                  ),
                  label: Text(
                    'Зберегти',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        if (showAdditionalInfo)
          AdditionalPointInfo(
            info: widget.selectedMarkerInfo,
          ),
        const SizedBox(height: 25),
      ],
    );
  }

  Widget buildDragHandle() => Center(
        child: Container(
          width: 30,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      );
}
