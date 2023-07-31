import 'package:easy_localization/easy_localization.dart';
import 'package:find_safe_places/screens/actions_in_emergencies_screen.dart';
import 'package:find_safe_places/screens/auth/login_screen.dart';
import 'package:find_safe_places/screens/auth/register_screen.dart';
import 'package:find_safe_places/widgets/chose_language_dialog.dart';
import 'package:find_safe_places/widgets/map/bottom_nav_item.dart';
import 'package:flutter/material.dart';

class LoggedOutBottomNav extends StatelessWidget {
  const LoggedOutBottomNav({
    super.key,
    required this.selectedItem,
    required this.selectItem,
  });
  final String selectedItem;
  final Function selectItem;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(0.0),
      margin: const EdgeInsets.all(0.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          BottomNavigateItem(
            icon: Icons.location_on_outlined,
            text: tr('explore'),
            isActive: true,
            onTap: () {
              selectItem('Поруч');
            },
          ),
          BottomNavigateItem(
            icon: Icons.info,
            text: tr('emergency_actions'),
            isActive: selectedItem == 'Дії під час НС',
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
            icon: Icons.person_add,
            text: tr('register'),
            isActive: selectedItem == 'Реєстрація',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RegisterScreen(),
                ),
              );
              // selectItem('Вихід');
            },
          ),
          BottomNavigateItem(
            icon: Icons.login_outlined,
            text: tr('log_in'),
            isActive: selectedItem == 'Вхід',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
              // selectItem('Вихід');
            },
          ),
        ],
      ),
    );
  }
}
