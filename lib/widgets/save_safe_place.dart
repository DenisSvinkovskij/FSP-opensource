import 'package:easy_localization/easy_localization.dart';
import 'package:find_safe_places/constants/ui.dart';
import 'package:find_safe_places/models/saved_safe_place.dart';
import 'package:find_safe_places/services/firebase/users_firebase.dart';
import 'package:find_safe_places/services/geo/geolocation.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class SaveSafePlace extends StatefulWidget {
  final LatLng coordinate;
  final Map<String, dynamic> data;
  final Function close;
  const SaveSafePlace({
    super.key,
    required this.coordinate,
    required this.data,
    required this.close,
  });

  @override
  State<SaveSafePlace> createState() => _SaveSafePlaceState();
}

class _SaveSafePlaceState extends State<SaveSafePlace> {
  final _formKey = GlobalKey<FormState>();

  bool loading = true;
  TextEditingController nameController = TextEditingController();
  TextEditingController addressController = TextEditingController();

  Future getAddressFromCoordinates() async {
    var data = await getAddressFromLocation(widget.coordinate);
    if (data.containsKey('error')) {
      setState(() {
        loading = false;
      });
      return;
    }
    addressController.text = data['address'] ?? '';
    setState(() {
      loading = false;
    });
  }

  void setNamePlace(String? name) {
    if (name != null) {
      nameController.text = name;
    }
  }

  void savePlace() async {
    setState(() {
      loading = true;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        loading = false;
      });
      return;
    }

    GeoFirePoint locationWithGeoHash = GeoFlutterFire().point(
      latitude: widget.coordinate.latitude,
      longitude: widget.coordinate.longitude,
    );

    final placeData = SavedSafePlaceModel(
      address: addressController.text,
      location: locationWithGeoHash.geoPoint,
      name: nameController.text,
      placeId: widget.data['placeId'].toString(),
      additionalInfo: widget.data,
    );

    await UsersFirebase.saveSafePlace(
      widget.data['userId'],
      placeData.toJson(),
      widget.data['docId'],
    );

    setState(() {
      loading = false;
    });
    widget.close();
  }

  @override
  void initState() {
    super.initState();
    setNamePlace(widget.data['name']);
    getAddressFromCoordinates();
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(
          color: Colors.white, //change your color here
        ),
        title: Text(tr('save_place')),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
        child: Form(
          key: _formKey,
          child: Column(children: [
            const SizedBox(
              height: 50,
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 30.0),
              child: TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  border: const UnderlineInputBorder(),
                  labelText: tr('title_of'),
                  hintText: tr('title_of'),
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (text) {
                  if (text == null || text.trim().isEmpty) {
                    return tr('field_cannot_be_empty');
                  }
                  return null;
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 30.0),
              child: TextFormField(
                controller: addressController,
                decoration: InputDecoration(
                  border: const UnderlineInputBorder(),
                  labelText: tr('address'),
                  hintText: tr('address'),
                  suffixIcon: const Icon(Icons.map),
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (text) {
                  if (text == null || text.trim().isEmpty) {
                    return tr('field_cannot_be_empty');
                  }
                  return null;
                },
              ),
            ),
            const Spacer(),
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: savePlace,
                  style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 18),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        )
                      : Text(tr('save')),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
