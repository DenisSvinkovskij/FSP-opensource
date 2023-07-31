import 'dart:async';

import 'package:badges/badges.dart' as badges;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:find_safe_places/constants/ui.dart';
import 'package:find_safe_places/models/close_person.dart';
import 'package:find_safe_places/models/user.dart';
import 'package:find_safe_places/providers/user_provider.dart';
import 'package:find_safe_places/screens/family/add_screen.dart';
import 'package:find_safe_places/screens/family/requests_screen.dart';
import 'package:find_safe_places/services/connectivity/my_connectivity.dart';
import 'package:find_safe_places/services/firebase/users_firebase.dart';
import 'package:find_safe_places/utils/index.dart';
import 'package:find_safe_places/widgets/close_person_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  StreamSubscription? requestsStream;
  int countOfRequests = 0;

  Map _connectingSource = {ConnectivityResult.none: false};
  final MyConnectivity _connectivity = MyConnectivity.instance;
  StreamSubscription<dynamic>? connectivitySub;

  @override
  void initState() {
    super.initState();

    _connectivity.initialize();
    connectivitySub = _connectivity.myStream.listen((source) {
      setState(() => _connectingSource = source);
      if (_connectingSource.keys.toList()[0] == ConnectivityResult.none) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('no_connection'))));
      }
    });
    UserModel user = Provider.of<UserProvider>(context, listen: false).user;
    final streamSub = UsersFirebase.getRequestsInClosePersons(user.uid).listen(
      (snapshots) {
        setState(() {
          countOfRequests = snapshots?.size ?? 0;
        });
      },
    );

    setState(() {
      requestsStream = streamSub;
    });
  }

  @override
  void dispose() {
    requestsStream!.cancel();
    connectivitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    UserModel user = Provider.of<UserProvider>(context, listen: false).user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: UsersFirebase.getClosePersons(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          final array = firestoreCollectionToArray(snapshot.data);
          final res = array.map((e) => ClosePerson.fromJson(e)).toList();

          return SingleChildScrollView(
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
                            tr('family_title'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 8.0,
                            right: 8.0,
                            top: 8.0,
                            bottom: 16.0,
                          ),
                          child: Text(
                            tr('family_subtitle'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ...res.map(
                  (e) {
                    return ClosePersonTile(closePerson: e);
                  },
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FamilyAddScreen(),
                      ),
                    );
                  },
                  child: ListTile(
                    title: Text(tr('add_family')),
                    leading: const Icon(Icons.person_add),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FamilyRequestsScreen(),
                      ),
                    );
                  },
                  child: ListTile(
                    title: Text(tr('add_requests')),
                    leading: badges.Badge(
                      animationDuration: const Duration(milliseconds: 300),
                      animationType: badges.BadgeAnimationType.slide,
                      badgeColor: Theme.of(context).primaryColor,
                      toAnimate: true,
                      showBadge: countOfRequests > 0,
                      badgeContent: Text(
                        '$countOfRequests',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Icon(Icons.people),
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FamilyAddScreen(),
            ),
          );
        },
        child: const Icon(
          Icons.add,
          size: 32.0,
        ),
      ),
    );
  }
}
