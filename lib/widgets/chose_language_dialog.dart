import 'package:easy_localization/easy_localization.dart';
import 'package:find_safe_places/models/user.dart';
import 'package:find_safe_places/providers/user_provider.dart';
import 'package:find_safe_places/services/firebase/users_firebase.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChoseLanguageDialog extends StatefulWidget {
  const ChoseLanguageDialog({super.key, required this.currentLocale});
  final Locale currentLocale;

  @override
  State<ChoseLanguageDialog> createState() => _ChoseLanguageDialogState();
}

class _ChoseLanguageDialogState extends State<ChoseLanguageDialog> {
  Locale selectedLocaleLocal = const Locale('en');

  @override
  void initState() {
    super.initState();
    selectedLocaleLocal = widget.currentLocale;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('change_language')),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 10.0,
                    backgroundImage: AssetImage('assets/flag_en.png'),
                  ),
                  const SizedBox(width: 5),
                  Text(tr('english')),
                  const Spacer(),
                  Checkbox(
                    value: selectedLocaleLocal == const Locale('en'),
                    onChanged: (value) {
                      setState(() {
                        selectedLocaleLocal = const Locale('en');
                      });
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 10.0,
                    backgroundImage: AssetImage('assets/flag_ukr.png'),
                  ),
                  const SizedBox(width: 5),
                  Text(tr('ukrainian')),
                  const Spacer(),
                  Checkbox(
                    value: selectedLocaleLocal == const Locale('uk'),
                    onChanged: (value) {
                      setState(() {
                        selectedLocaleLocal = const Locale('uk');
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Save'),
          onPressed: () {
            Navigator.of(context).pop();
            context.setLocale(selectedLocaleLocal);
            UserModel? user =
                Provider.of<UserProvider>(context, listen: false).user;
            if (user == null) {
              return;
            }
            UsersFirebase.updateUser(
                user.uid, {'locale': selectedLocaleLocal.toLanguageTag()});
          },
        ),
      ],
    );
  }
}
