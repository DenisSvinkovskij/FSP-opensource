import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GoogleSignInButtonWidget extends StatelessWidget {
  const GoogleSignInButtonWidget({
    super.key,
    required this.loading,
    required this.onPress,
  });
  final bool loading;
  final void Function()? onPress;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPress,
        style: ElevatedButton.styleFrom(
          textStyle: const TextStyle(
            fontSize: 18,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        icon: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                ))
            : FaIcon(
                FontAwesomeIcons.google,
                color: Colors.red[200],
              ),
        label: loading ? const Text('') : Text(tr('log_in_with_google')),
      ),
    );
  }
}
