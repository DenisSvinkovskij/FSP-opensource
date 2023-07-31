import 'dart:async';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:find_safe_places/helpers/map.dart';
import 'package:find_safe_places/services/geo/geolocation.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class SearchLocationScreen extends StatefulWidget {
  final String? initAddress;
  const SearchLocationScreen({super.key, this.initAddress});

  @override
  State<SearchLocationScreen> createState() => _SearchLocationScreenState();
}

class _SearchLocationScreenState extends State<SearchLocationScreen> {
  Timer? _debounce;
  TextEditingController searchController = TextEditingController();
  List places = [];
  ScrollController scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    searchController.text = widget.initAddress ?? '';
  }

  onChangeHandler(value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), () {
      _searchHandler(value);
    });
  }

  _searchHandler(String value) async {
    if (value.trim().isEmpty) {
      setState(() {
        places = [];
      });
      return;
    }
    var response = await placesSearchService.getPlaces(value);
    log('response');
    // var responseInJson = (response ?? []).map((e) => json.encode(e)).toList();
    List searchedPlaces = getParsedResponseFromFeatures(response ?? []);

    setState(() {
      places = searchedPlaces;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: searchController,
                        onChanged: onChangeHandler,
                        autofocus: true,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(50.0)),
                          ),
                          hintText: tr('search_address'),
                          contentPadding: const EdgeInsets.all(8.0),
                          isDense: true,
                          prefixIcon: IconButton(
                            onPressed: () {
                              Navigator.pop(context, null);
                            },
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                          prefixIconColor: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              places.isEmpty
                  ? Container(
                      margin: const EdgeInsets.only(top: 5),
                      child: Text(tr('no_results')),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: places.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Column(
                          children: [
                            ListTile(
                              onTap: () {
                                String text = places[index]['place'];
                                LatLng location = places[index]['location'];
                                FocusManager.instance.primaryFocus?.unfocus();
                                Navigator.pop(context, {
                                  'text': text,
                                  'location': location,
                                });
                              },
                              leading: const SizedBox(
                                height: double.infinity,
                                child: CircleAvatar(child: Icon(Icons.map)),
                              ),
                              title: Text(places[index]['name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(places[index]['address'],
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const Divider(),
                          ],
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
