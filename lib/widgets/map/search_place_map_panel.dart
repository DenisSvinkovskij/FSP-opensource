import 'package:easy_localization/easy_localization.dart';
import 'package:find_safe_places/helpers/index.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class SearchPlaceMapPanel extends StatefulWidget {
  final LatLng myLocation;
  final Function onTapSearch;
  final bool closed;
  final String? text;

  const SearchPlaceMapPanel({
    super.key,
    required this.myLocation,
    this.text,
    required this.onTapSearch,
    required this.closed,
  });

  @override
  State<SearchPlaceMapPanel> createState() => _SearchMapPanelState();
}

class _SearchMapPanelState extends State<SearchPlaceMapPanel> {
  TextEditingController searchLocationController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  onUpdateWidget(SearchPlaceMapPanel old) {
    if (widget.text != old.text) {
      customUpdateInputTextField(searchLocationController, widget.text ?? "");
    }
  }

  @override
  void didUpdateWidget(old) {
    onUpdateWidget(old);
    super.didUpdateWidget(old);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      width: MediaQuery.of(context).size.width,
      top: 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Material(
                elevation: 3,
                borderRadius: const BorderRadius.all(Radius.circular(50.0)),
                child: TextFormField(
                  controller: searchLocationController,
                  onTap: () {
                    widget.onTapSearch();
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(50.0)),
                      borderSide: BorderSide.none,
                    ),
                    hintText: tr('search_address'),
                    contentPadding: const EdgeInsets.all(8.0),
                    isDense: true,
                    prefixIcon: const Icon(
                      Icons.location_on_sharp,
                      color: Colors.black54,
                      size: 24,
                    ),
                    prefixIconColor: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
