import 'package:flutter/material.dart';

class BottomNavigateItem extends StatelessWidget {
  const BottomNavigateItem({
    super.key,
    required this.icon,
    required this.text,
    required this.isActive,
    required this.onTap,
  });
  final IconData icon;
  final String text;
  final bool isActive;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderOnForeground: false,
      elevation: 1.0,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                color:
                    isActive ? Theme.of(context).primaryColor : Colors.black54,
                size: 24,
              ),
              Text(
                text,
                style: TextStyle(
                  color: isActive
                      ? Theme.of(context).primaryColor
                      : Colors.black54,
                  fontSize: 12,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
