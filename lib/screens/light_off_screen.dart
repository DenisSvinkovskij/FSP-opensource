import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:find_safe_places/constants/ui.dart';
import 'package:find_safe_places/models/user.dart';
import 'package:find_safe_places/providers/user_provider.dart';
import 'package:find_safe_places/services/connectivity/my_connectivity.dart';
import 'package:find_safe_places/services/firebase/users_firebase.dart';
import 'package:find_safe_places/services/geo/geolocation.dart';
import 'package:find_safe_places/widgets/my_text_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';

class LightOffScreen extends StatefulWidget {
  const LightOffScreen({super.key});

  @override
  State<LightOffScreen> createState() => _LightOffScreenState();
}

class _LightOffScreenState extends State<LightOffScreen> {
  String region = '';
  int currentValueMinutes = 0;
  final List groups = [
    {'value': '1', 'text': '${tr('group')} 1'},
    {'value': '2', 'text': '${tr('group')} 2'},
    {'value': '3', 'text': '${tr('group')} 3'},
  ];
  String? selectedGroupValue = '1';

  Map _connectingSource = {ConnectivityResult.none: false};
  final MyConnectivity _connectivity = MyConnectivity.instance;
  StreamSubscription<dynamic>? connectivitySub;

  updateLightOffSubInfo() async {
    UserModel? user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return;

    int numberOfGroup = int.parse(selectedGroupValue ?? '1');
    bool isEnabled = currentValueMinutes > 0;
    int timeInMinutes = currentValueMinutes;
    var lightOffSub = LightOffSubscriptionModel(
      group: numberOfGroup,
      isEnabled: isEnabled,
      timeInMinutes: timeInMinutes,
    );

    var completeSub = UserSubscriptionsModel(lightOff: lightOffSub);
    UsersFirebase.updateUser(user.uid, {'subscriptions': completeSub.toJson()});

    var updatedUser = await UsersFirebase.getUserDoc(user.uid);
    if (!mounted) return;
    Provider.of<UserProvider>(context, listen: false)
        .setUser(UserModel.fromJson(updatedUser.data()!));
  }

  onTapButton(String value) {
    int inNum = int.parse(value);
    setState(() {
      currentValueMinutes = inNum;
    });
    updateLightOffSubInfo();
  }

  @override
  void initState() {
    initRegion();
    super.initState();
    _connectivity.initialize();
    connectivitySub = _connectivity.myStream.listen((source) {
      setState(() => _connectingSource = source);
      if (_connectingSource.keys.toList()[0] == ConnectivityResult.none) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('no_connection'))));
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    connectivitySub?.cancel();
  }

  initRegion() async {
    UserModel user = Provider.of<UserProvider>(context, listen: false).user;
    selectedGroupValue = '${user.subscriptions?.lightOff?.group ?? 1}';
    currentValueMinutes = user.subscriptions?.lightOff?.timeInMinutes ?? 0;

    var regionData = await getRegionFromLocation(LatLng(
      user.location['geopoint'].latitude,
      user.location['geopoint'].longitude,
    ));
    if (regionData.containsKey('error')) {
      return;
    }
    setState(() {
      region = regionData['region'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Material(
              elevation: 5.0,
              child: Container(
                padding: const EdgeInsets.all(kDefaultPadding),
                color: Theme.of(context).primaryColor,
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        tr('light_off_title'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(
                top: kDefaultPadding / 2,
                left: kDefaultPadding,
                right: kDefaultPadding,
              ),
              child: Row(
                children: [
                  Text(
                    tr('choose_group'),
                    style: const TextStyle(fontSize: 18),
                  ),
                  DropdownButton2(
                    buttonPadding: const EdgeInsets.all(5.0),
                    dropdownDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    hint: Text(
                      tr('group'),
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    items: groups
                        .map((item) => DropdownMenuItem<String>(
                              value: item['value'],
                              child: Text(
                                item['text'],
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ))
                        .toList(),
                    value: selectedGroupValue,
                    onChanged: (value) {
                      setState(() {
                        selectedGroupValue = value;
                      });
                      updateLightOffSubInfo();
                    },
                    buttonHeight: 40,
                    itemHeight: 40,
                  ),
                ],
              ),
            ),
            const Divider(),
            Container(
              padding: const EdgeInsets.only(
                top: kDefaultPadding / 2,
                left: kDefaultPadding,
                right: kDefaultPadding,
              ),
              child: Column(
                children: [
                  Text(
                    tr('notify_light_off_text'),
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: MyTextElevatedButton(
                              onPress: onTapButton,
                              text: tr('notify_light_off_never'),
                              value: '0',
                              isActive: currentValueMinutes == 0,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: MyTextElevatedButton(
                              onPress: onTapButton,
                              text: tr('notify_light_off_30min'),
                              value: '30',
                              isActive: currentValueMinutes == 30,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: MyTextElevatedButton(
                              onPress: onTapButton,
                              text: tr('notify_light_off_hour'),
                              value: '60',
                              isActive: currentValueMinutes == 60,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: MyTextElevatedButton(
                              onPress: onTapButton,
                              text: tr('notify_light_off_two_hours'),
                              value: '120',
                              isActive: currentValueMinutes == 120,
                            ),
                          ),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
