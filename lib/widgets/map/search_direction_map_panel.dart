import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:find_safe_places/helpers/map.dart';
import 'package:find_safe_places/widgets/map/location_field.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class SearchDirectionMapPanel extends StatefulWidget {
  final LatLng? selectedMarkerLocation;
  final String? selectedMarkerLocationAddress;
  final MapboxMapController? mapController;
  final LatLng myLocation;
  final Function onTapSearch;
  final bool closed;

  const SearchDirectionMapPanel({
    super.key,
    required this.myLocation,
    this.mapController,
    this.selectedMarkerLocation,
    this.selectedMarkerLocationAddress,
    required this.onTapSearch,
    required this.closed,
  });

  @override
  State<SearchDirectionMapPanel> createState() =>
      _SearchDirectionMapPanelState();
}

class _SearchDirectionMapPanelState extends State<SearchDirectionMapPanel>
    with TickerProviderStateMixin {
  TextEditingController searchLocationController = TextEditingController();
  Map<String, dynamic> routeCar = {};
  String carPathDescription = '-';
  String walkPathDescription = '-';
  Map<String, dynamic> routeWalk = {};
  late TabController tabController;
  int selectedTapIndex = 0;

  onUpdateWidget(SearchDirectionMapPanel old) async {
    if (widget.selectedMarkerLocationAddress ==
        old.selectedMarkerLocationAddress) return;
    searchLocationController.text = widget.selectedMarkerLocationAddress ?? '';
    if (widget.selectedMarkerLocation == null || widget.mapController == null) {
      return;
    }
    final firstRouteCar = await calculateRoute(
      'driving',
      widget.myLocation,
      widget.selectedMarkerLocation,
      widget.mapController!,
    );
    final firstRouteWalk = await calculateRoute(
      'walking',
      widget.myLocation,
      widget.selectedMarkerLocation,
      widget.mapController!,
    );
    if (firstRouteCar['error'] != null && firstRouteCar['error']?.isNotEmpty ||
        firstRouteWalk['error'] != null &&
            firstRouteWalk['error']?.isNotEmpty) {
      log(firstRouteCar['error']);
      log(firstRouteWalk['error']);
      return;
    }
    setState(() {
      routeCar = firstRouteCar;
      routeWalk = firstRouteWalk;
      carPathDescription = generatePathDescription(
        firstRouteCar['distance'],
        firstRouteCar['duration'],
        justTime: true,
      );
      walkPathDescription = generatePathDescription(
        firstRouteWalk['distance'],
        firstRouteWalk['duration'],
        justTime: true,
      );
    });
  }

  generatePath(Map route) async {
    if (widget.mapController == null || route.isEmpty) return;
    await showPath(route, widget.mapController!);
  }

  @override
  void initState() {
    super.initState();
    tabController = TabController(
      initialIndex: 0,
      length: 2,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(old) {
    super.didUpdateWidget(old);
    onUpdateWidget(old);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      width: MediaQuery.of(context).size.width,
      top: widget.closed ? -200.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Column(
                          children: [
                            const Icon(Icons.my_location, size: 14),
                            Container(
                              margin: const EdgeInsets.only(top: 3),
                              color: Colors.black,
                              width: 1,
                              height: 25,
                            ),
                            const Icon(
                              Icons.location_on_sharp,
                              size: 18,
                              color: Colors.red,
                            ),
                          ],
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              LocationField(
                                isDestination: false,
                                textEditingController: TextEditingController(),
                                placeholderText: tr('your_location'),
                                isDisabled: true,
                              ),
                              LocationField(
                                isDestination: true,
                                textEditingController: searchLocationController,
                                placeholderText: tr('search_address'),
                                isDisabled: false,
                                onTap: () {
                                  widget.onTapSearch();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            TabBar(
              controller: tabController,
              onTap: (value) {
                setState(() {
                  selectedTapIndex = value;
                });
                if (value == 0) {
                  generatePath(routeCar);
                }
                if (value == 1) {
                  generatePath(routeWalk);
                }
              },
              tabs: [
                Tab(
                  child: Center(
                    child: Row(
                      children: [
                        const Spacer(),
                        Icon(
                          Icons.directions_car,
                          color: selectedTapIndex == 0
                              ? Theme.of(context).primaryColor
                              : Colors.black54,
                          size: 20,
                        ),
                        Text(
                          carPathDescription,
                          style: TextStyle(
                            color: selectedTapIndex == 0
                                ? Theme.of(context).primaryColor
                                : Colors.black54,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: Center(
                    child: Row(
                      children: [
                        const Spacer(),
                        Icon(
                          Icons.directions_walk,
                          color: selectedTapIndex == 1
                              ? Theme.of(context).primaryColor
                              : Colors.black54,
                          size: 20,
                        ),
                        Text(
                          walkPathDescription,
                          style: TextStyle(
                            color: selectedTapIndex == 1
                                ? Theme.of(context).primaryColor
                                : Colors.black54,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
