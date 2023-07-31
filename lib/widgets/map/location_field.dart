import 'package:flutter/material.dart';

class LocationField extends StatefulWidget {
  final bool isDestination;
  final TextEditingController textEditingController;
  final String placeholderText;
  final bool isDisabled;
  final void Function()? onTap;

  const LocationField({
    Key? key,
    required this.isDestination,
    required this.textEditingController,
    required this.placeholderText,
    required this.isDisabled,
    this.onTap,
  }) : super(key: key);

  @override
  State<LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<LocationField> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 5, left: 10),
      child: TextFormField(
        controller: widget.textEditingController,
        enabled: !widget.isDisabled,
        onTap: widget.onTap,
        decoration: InputDecoration(
          border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0))),
          hintText: widget.placeholderText,
          contentPadding: const EdgeInsets.all(8.0),
          isDense: true,
        ),
      ),
    );
  }
}
