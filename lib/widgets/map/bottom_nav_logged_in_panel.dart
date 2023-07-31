import 'package:easy_localization/easy_localization.dart';
import 'package:find_safe_places/models/user.dart';
import 'package:find_safe_places/providers/user_provider.dart';
import 'package:find_safe_places/screens/actions_in_emergencies_screen.dart';
import 'package:find_safe_places/screens/family/family_screen.dart';
import 'package:find_safe_places/screens/light_off_screen.dart';
import 'package:find_safe_places/services/auth/auth.dart';
import 'package:find_safe_places/services/firebase/users_firebase.dart';
import 'package:find_safe_places/widgets/chose_language_dialog.dart';
import 'package:find_safe_places/widgets/map/bottom_nav_item.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';

class LoggedInBottomNav extends StatefulWidget {
  const LoggedInBottomNav({
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
  State<LoggedInBottomNav> createState() => _LoggedInBottomNavState();
}

class _LoggedInBottomNavState extends State<LoggedInBottomNav> {
  final ScrollController scrollController = ScrollController();

  updateUserAppState({required String field, dynamic value}) {
    UserModel? user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return;

    UsersFirebase.updateUser(user.uid, {
      'userAppState': {field: value}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(0.0),
      margin: const EdgeInsets.all(0.0),
      child: Scrollbar(
        thumbVisibility: true,
        radius: const Radius.circular(10.0),
        thickness: 2,
        scrollbarOrientation: ScrollbarOrientation.top,
        controller: scrollController,
        child: ListView(
          scrollDirection: Axis.horizontal,
          controller: scrollController,
          children: [
            BottomNavigateItem(
              icon: Icons.location_on_outlined,
              text: tr('explore'),
              isActive: widget.selectedItem == 'Поруч',
              onTap: () {
                widget.selectItem('Поруч');
              },
            ),
            BottomNavigateItem(
              icon: Icons.people,
              text: tr('family'),
              isActive: widget.selectedItem == 'Близькі',
              onTap: () async {
                var result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FamilyScreen(),
                  ),
                );
                if (result == null) return;
                widget.setSelectedMarker(
                  result['tappedSelectedMarkerInfo'],
                  result['tappedSelectedMarkerPosition'],
                );
              },
            ),
            BottomNavigateItem(
              icon: Icons.bookmark,
              text: tr('saved'),
              isActive: !widget.isVisibleAllSafePlaces,
              onTap: () {
                widget
                    .toggleVisibleAllSafePlaces(!widget.isVisibleAllSafePlaces);
                updateUserAppState(
                  field: 'allSafePlacesVisible',
                  value: !widget.isVisibleAllSafePlaces,
                );
              },
            ),
            BottomNavigateItem(
              icon: Icons.offline_bolt,
              text: tr('invincibility'),
              isActive: widget.isVisibleInvincibilityPoints,
              onTap: () {
                widget.toggleVisibleInvincibilityPoints(
                    !widget.isVisibleInvincibilityPoints);
                updateUserAppState(
                  field: 'invincibilityPointsVisible',
                  value: !widget.isVisibleInvincibilityPoints,
                );
              },
            ),
            BottomNavigateItem(
              icon: Icons.info,
              text: tr('emergency_actions'),
              isActive: widget.selectedItem == 'Дії під час НС',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ActionsInEmergenciesScreen(),
                  ),
                );
              },
            ),
            BottomNavigateItem(
              icon: Icons.lightbulb,
              text: tr('light'),
              isActive: widget.selectedItem == 'Світло',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LightOffScreen(),
                  ),
                );
              },
            ),
            BottomNavigateItem(
              icon: Icons.info,
              text: tr('language'),
              isActive: false,
              onTap: () {
                showDialog<void>(
                  context: context,
                  barrierDismissible: false, // user must tap button!
                  builder: (BuildContext context) {
                    return ChoseLanguageDialog(
                      currentLocale: context.locale,
                    );
                  },
                );
              },
            ),
            BottomNavigateItem(
              icon: Icons.logout_rounded,
              text: tr('log_out'),
              isActive: widget.selectedItem == 'Вихід',
              onTap: () async {
                await Auth().signOut();
                widget.selectItem('Вихід');
                widget.selectItem('Поруч');

                // ignore: use_build_context_synchronously
                context.read<UserProvider>().setUser(null);
                widget.reAddAllPlacesLayer();
              },
            ),
          ],
        ),
      ),
    );
  }
}
