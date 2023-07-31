import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:find_safe_places/constants/ui.dart';
import 'package:find_safe_places/models/user.dart';
import 'package:find_safe_places/providers/user_provider.dart';
import 'package:find_safe_places/services/firebase/common.dart';
import 'package:find_safe_places/services/firebase/users_firebase.dart';
import 'package:find_safe_places/utils/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:text_helpers/text_helpers.dart';

class FamilyRequestsScreen extends StatefulWidget {
  const FamilyRequestsScreen({super.key});

  @override
  State<FamilyRequestsScreen> createState() => _FamilyRequestsScreenState();
}

class _FamilyRequestsScreenState extends State<FamilyRequestsScreen> {
  Map<String, String> loadingItems = {};

  Future<void> acceptRequest(String itemUID) async {
    UserModel user = Provider.of<UserProvider>(context, listen: false).user;
    UserModel? requestedUser = await UsersFirebase.getUserDoc(itemUID).then(
      (value) => value.exists ? UserModel.fromJson(value.data()!) : null,
    );
    if (requestedUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. User not found')),
      );
      return;
    }

    String docRef = 'users/$itemUID/userFamily/${user.uid}';
    String myClosePeoplesRef = 'users/${user.uid}/userFamily/$itemUID';
    String requestRef = 'users/${user.uid}/userFamilyRequests/$itemUID';

    await Future.wait([
      UsersFirebase.updateUser(user.uid, {
        'familyIds': FieldValue.arrayUnion([itemUID])
      }),
      UsersFirebase.updateUser(itemUID, {
        'familyIds': FieldValue.arrayUnion([user.uid])
      })
    ]);

    await Future.wait([
      CommonFirebase.createByStringReference(
          ref: docRef, data: {...user.toJson(), 'status': 'accepted'}),
      CommonFirebase.createByStringReference(
          ref: myClosePeoplesRef,
          data: {...requestedUser.toJson(), 'status': 'accepted'}),
    ]).then((value) {
      CommonFirebase.deleteDocByStringReference(ref: requestRef);
    }).catchError((err) {
      log(err.toString());
    });
  }

  Future<void> declineRequest(String itemUID) async {
    if (!mounted) return;
    UserModel user = Provider.of<UserProvider>(context, listen: false).user;
    String docRef = 'users/$itemUID/userFamily/${user.uid}';
    String requestRef = 'users/${user.uid}/userFamilyRequests/$itemUID';

    await Future.wait([
      CommonFirebase.createByStringReference(
          ref: docRef, data: {'status': 'declined'}),
      CommonFirebase.deleteDocByStringReference(ref: requestRef),
    ]);
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
          stream: UsersFirebase.getRequestsInClosePersons(user.uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Something went wrong'));
            }

            final array = firestoreCollectionToArray(snapshot.data);
            final res = array.map((e) => UserModel.fromJson(e)).toList();
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
                              tr('add_requests'),
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
                              tr('add_requests_subtitle'),
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
                    (e) => Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 5.0, vertical: 5.0),
                      elevation: 2.0,
                      child: ListTile(
                        title: InlineText(e.displayName),
                        subtitle: Text(e.phone ?? ''),
                        leading: CircleAvatar(
                          backgroundColor: hexToColorOrRandomColor(null),
                          child: Text(e.displayName[0]),
                        ),
                        trailing: Wrap(
                          children: [
                            IconButton(
                              onPressed: () async {
                                setState(() {
                                  loadingItems = {e.uid: 'decline'};
                                });
                                await declineRequest(e.uid);
                                setState(() {
                                  loadingItems.remove(e.uid);
                                });
                              },
                              icon: loadingItems[e.uid] == 'decline'
                                  ? const CircularProgressIndicator.adaptive()
                                  : const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                    ),
                            ),
                            IconButton(
                              onPressed: () async {
                                setState(() {
                                  loadingItems = {e.uid: 'accept'};
                                });
                                await acceptRequest(e.uid);
                                setState(() {
                                  loadingItems.remove(e.uid);
                                });
                              },
                              icon: loadingItems[e.uid] == 'accept'
                                  ? const CircularProgressIndicator.adaptive()
                                  : const Icon(
                                      Icons.check,
                                      color: Colors.green,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
    );
  }
}
