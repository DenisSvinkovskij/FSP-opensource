import 'package:flutter/material.dart';

class MyTextElevatedButton extends StatelessWidget {
  const MyTextElevatedButton({
    super.key,
    required this.onPress,
    required this.text,
    required this.value,
    required this.isActive,
  });
  final void Function(String value) onPress;
  final String text;
  final String value;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        onPress(value);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isActive ? Theme.of(context).primaryColor : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? Colors.white : Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
