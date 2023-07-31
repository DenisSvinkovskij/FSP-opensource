import 'package:find_safe_places/models/user.dart';
import 'package:find_safe_places/providers/user_provider.dart';
import 'package:find_safe_places/widgets/map/bottom_nav_logged_in_panel.dart';
import 'package:find_safe_places/widgets/map/bottom_nav_logged_out_panel.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';

class BottomMapNavigation extends StatelessWidget {
  const BottomMapNavigation({
    super.key,
    required this.selectedItem,
    required this.selectItem,
    required this.reAddAllPlacesLayer,
    required this.setSelectedMarker,
    required this.isVisibleInvincibilityPoints,
    required this.toggleVisibleInvincibilityPoints,
    required this.toggleVisibleAllSafePlaces,
    required this.isVisibleAllSafePlaces,
  });
  final String selectedItem;
  final Function selectItem;
  final Function reAddAllPlacesLayer;
  final void Function(Map<String, dynamic> info, LatLng position)
      setSelectedMarker;
  final bool isVisibleInvincibilityPoints;
  final void Function(bool isVisibleInvincibility)
      toggleVisibleInvincibilityPoints;
  final bool isVisibleAllSafePlaces;
  final void Function(bool isVisibleInvincibility) toggleVisibleAllSafePlaces;

  @override
  Widget build(BuildContext context) {
    UserModel? user = Provider.of<UserProvider>(context, listen: true).user;
    return AnimatedPositioned(
      width: MediaQuery.of(context).size.width,
      height: 60,
      bottom: 0.0,
      left: 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
      child: Container(
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.4),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ]),
        child: user == null
            ? LoggedOutBottomNav(
                selectItem: selectItem,
                selectedItem: selectedItem,
              )
            : LoggedInBottomNav(
                selectItem: selectItem,
                selectedItem: selectedItem,
                reAddAllPlacesLayer: reAddAllPlacesLayer,
                setSelectedMarker: setSelectedMarker,
                isVisibleInvincibilityPoints: isVisibleInvincibilityPoints,
                toggleVisibleInvincibilityPoints:
                    toggleVisibleInvincibilityPoints,
                isVisibleAllSafePlaces: isVisibleAllSafePlaces,
                toggleVisibleAllSafePlaces: toggleVisibleAllSafePlaces,
              ),
      ),
    );
  }
}
