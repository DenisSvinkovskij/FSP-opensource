import 'package:flutter/material.dart';

class TopInfoWidget extends StatelessWidget {
  const TopInfoWidget({
    super.key,
    required this.text,
    this.icon = Icons.info,
  });
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3.0,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: Colors.white,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: Colors.black12,
          ),
          padding: const EdgeInsets.all(4.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
                color: Colors.black45,
              ),
              const SizedBox(width: 5),
              Text(
                text,
                style: const TextStyle(color: Colors.black87, fontSize: 14),
              )
            ],
          ),
        ),
      ),
    );
  }
}
