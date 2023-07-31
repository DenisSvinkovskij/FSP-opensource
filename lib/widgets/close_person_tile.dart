import 'package:find_safe_places/constants/map.dart';
import 'package:find_safe_places/constants/user.dart';
import 'package:find_safe_places/models/close_person.dart';
import 'package:find_safe_places/models/user.dart';
import 'package:find_safe_places/providers/user_provider.dart';
import 'package:find_safe_places/services/firebase/common.dart';
import 'package:find_safe_places/utils/index.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';

class ClosePersonTile extends StatefulWidget {
  const ClosePersonTile({
    Key? key,
    required this.closePerson,
  }) : super(key: key);

  final ClosePerson closePerson;

  @override
  State<ClosePersonTile> createState() => _ClosePersonTileState();
}

class _ClosePersonTileState extends State<ClosePersonTile> {
  late Color color;
  int index = 0;

  @override
  void initState() {
    super.initState();
    color = widget.closePerson.color != null
        ? hexToColorOrRandomColor(widget.closePerson.color)
        : hexToColorOrRandomColor(kFamilyColorsList.elementAt(index));
  }

  changeColor() async {
    int newIndex = index == kFamilyColorsList.length - 1 ? 0 : index + 1;
    String newColorHex = kFamilyColorsList.elementAt(newIndex);
    setState(() {
      color = hexToColorOrRandomColor(newColorHex);
      index = newIndex;
    });

    if (!mounted) return;
    UserModel user = Provider.of<UserProvider>(context, listen: false).user;
    String familyCollectionDoc =
        'users/${user.uid}/userFamily/${widget.closePerson.uid}';
    await CommonFirebase.createByStringReference(
      ref: familyCollectionDoc,
      data: {'color': newColorHex},
    );
  }

  onPress() {
    try {
      LatLng locationPerson = LatLng(
        widget.closePerson.location?['geopoint'].latitude,
        widget.closePerson.location?['geopoint'].longitude,
      );
      Navigator.pop(context, {
        'tappedSelectedMarkerInfo': {
          'placeId': widget.closePerson.uid,
          'id': widget.closePerson.uid,
          'firstLetter': widget.closePerson.name[0],
          'colorIcon': widget.closePerson.color,
          'docId': widget.closePerson.uid,
          'name': widget.closePerson.name,
          'userId': widget.closePerson.uid,
          'type': kFamilyFeatureType,
        },
        'tappedSelectedMarkerPosition': locationPerson,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Цей користувач ще не підтвердив що ви близькі люди...'),
      ));
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPress,
      child: ListTile(
        title: Text(widget.closePerson.name),
        leading: GestureDetector(
          onTap: changeColor,
          child: CircleAvatar(
            backgroundColor: color,
            foregroundColor: Colors.white,
            child: Text(widget.closePerson.name[0]),
          ),
        ),
        trailing: GestureDetector(
          onTap: changeColor,
          child: Icon(
            Icons.info_outline,
            color: color,
          ),
        ),
      ),
    );
  }
}
