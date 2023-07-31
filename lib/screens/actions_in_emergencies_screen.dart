import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:find_safe_places/constants/ui.dart';
import 'package:find_safe_places/models/emergency_action.dart';
import 'package:find_safe_places/services/connectivity/my_connectivity.dart';
import 'package:find_safe_places/services/firebase/common.dart';
import 'package:flutter/material.dart';

class ActionsInEmergenciesScreen extends StatefulWidget {
  const ActionsInEmergenciesScreen({super.key});

  @override
  State<ActionsInEmergenciesScreen> createState() =>
      _ActionsInEmergenciesScreenState();
}

class _ActionsInEmergenciesScreenState
    extends State<ActionsInEmergenciesScreen> {
  Timer? _debounce;

  List<EmergencyAction> actions = [];
  List<EmergencyAction> allActions = [];
  bool loading = true;

  Map _connectingSource = {ConnectivityResult.none: false};
  final MyConnectivity _connectivity = MyConnectivity.instance;
  StreamSubscription<dynamic>? connectivitySub;

  _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      final filteredActions = allActions
          .where((element) => element.title[context.locale.toLanguageTag()]
              .toLowerCase()
              .contains(query.toLowerCase()))
          .map((e) {
        e.isExpanded = false;
        return e;
      }).toList();

      setState(() {
        actions = filteredActions;
      });
    });
  }

  @override
  void initState() {
    loadEmergencies();
    _connectivity.initialize();
    connectivitySub = _connectivity.myStream.listen((source) {
      setState(() => _connectingSource = source);
      if (_connectingSource.keys.toList()[0] == ConnectivityResult.none) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('no_connection'))));
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    connectivitySub?.cancel();
    super.dispose();
  }

  loadEmergencies() async {
    final snapshot = await CommonFirebase.getEmergenciesInfo();
    if (!snapshot.exists) {
      return;
    }

    List<dynamic> test = snapshot.data()!['emergencyTypes'];
    var data = test.map((e) => EmergencyAction.fromJson(e)).toList();
    setState(() {
      allActions = data;
      actions = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var locale = context.locale.toLanguageTag();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(
          color: Colors.white, //change your color here
        ),
        title: Text(tr('actions_in_emergencies_title')),
        elevation: 0,
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Material(
                    elevation: 10.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding,
                        vertical: kDefaultPadding,
                      ),
                      color: Theme.of(context).primaryColor,
                      child: TextField(
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: tr('actions_search_hint'),
                          fillColor: Colors.white,
                          filled: true,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            onPressed: () {
                              log('suffixIcon micro pressed');
                            },
                            icon: const Icon(
                              Icons.mic,
                              color: Colors.black54,
                            ),
                          ),
                          border: const UnderlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(10.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ExpansionPanelList(
                    expansionCallback: (int index, bool isExpanded) {
                      setState(() {
                        actions[index].isExpanded = !isExpanded;
                      });
                    },
                    dividerColor: Colors.black26,
                    children: actions
                        .map(
                          (e) => ExpansionPanel(
                            headerBuilder:
                                (BuildContext context, bool isExpanded) {
                              return ListTile(
                                minVerticalPadding: 6.0,
                                leading: Icon(
                                  Icons.description,
                                  color: Colors.blue[500],
                                ),
                                title: Text(e.title[locale]),
                                subtitle: Text(tr('follow_these_instructions')),
                              );
                            },
                            body: Column(
                              children: e.actions
                                  .map(
                                    (el) => Container(
                                      margin: const EdgeInsets.only(
                                        right: kDefaultPadding,
                                        left: kDefaultPadding,
                                        bottom: kDefaultPadding,
                                      ),
                                      alignment: Alignment.topLeft,
                                      child: Text(el[locale]),
                                    ),
                                  )
                                  .toList(),
                            ),
                            isExpanded: e.isExpanded,
                            canTapOnHeader: true,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
    );
  }
}
