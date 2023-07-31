import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:email_validator/email_validator.dart';
import 'package:find_safe_places/constants/ui.dart';
import 'package:find_safe_places/helpers/index.dart';
import 'package:find_safe_places/models/user.dart';
import 'package:find_safe_places/providers/user_provider.dart';
import 'package:find_safe_places/services/firebase/common.dart';
import 'package:find_safe_places/services/firebase/users_firebase.dart';
import 'package:find_safe_places/services/httpRequests/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_libphonenumber/flutter_libphonenumber.dart';
import 'package:provider/provider.dart';

class FamilyAddScreen extends StatefulWidget {
  const FamilyAddScreen({super.key});

  @override
  State<FamilyAddScreen> createState() => _FamilyAddScreenState();
}

class _FamilyAddScreenState extends State<FamilyAddScreen> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  Map<String, String?> asyncErrors = {};

  bool loading = false;

  Future validateNumber(String value) async {
    try {
      if (!mounted) {
        return;
      }
      value = value.replaceAll(' ', '');
      final phoneInfo = await FlutterLibphonenumber().parse(value);

      customUpdateInputTextField(phoneController, phoneInfo['international']);

      if (asyncErrors['phone'] != null) {
        setState(() {
          asyncErrors.remove('phone');
        });
      }
    } catch (e) {
      if ((e as PlatformException).code == 'InvalidNumber') {
        setState(() {
          asyncErrors = {...asyncErrors, 'phone': tr('phone_not_valid')};
        });
      }
    }
  }

  Future sendRequest(Map<String, String> data) async {
    if (!mounted) return;
    UserModel user = Provider.of<UserProvider>(context, listen: false).user;
    Map<String, dynamic> payload = {...data, 'inviteUID': user.uid};

    List<UserModel> users = await UsersFirebase.findUsersBy(
        field: 'email', value: emailController.text);

    if (users.isNotEmpty) {
      var requestUserUID = users.first.uid;
      var userUID = user.uid;
      String familyRequestCollectionDoc =
          'users/$requestUserUID/userFamilyRequests/$userUID';
      String familyCollectionDoc = 'users/$userUID/userFamily/$requestUserUID';

      await CommonFirebase.createByStringReference(
          ref: familyRequestCollectionDoc, data: user.toJson());
      await CommonFirebase.createByStringReference(
          ref: familyCollectionDoc, data: payload);
    } else {
      await sendFamilyInvitation(payload);
    }
  }

  Future<void> onSendRequest() async {
    setState(() {
      loading = true;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        loading = false;
      });
      return;
    }

    String phone = phoneController.text;
    String name = nameController.text;
    String email = emailController.text;
    await validateNumber(phone);
    if (asyncErrors.isNotEmpty) {
      setState(() {
        loading = false;
      });
      return;
    }

    final data = {
      'phone': phone,
      'name': name,
      'email': email,
    };

    await sendRequest(data);

    Timer? timer;
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        timer = Timer(const Duration(seconds: 3), () {
          Navigator.of(context).pop();
        });
        return AlertDialog(
          title: Center(
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF2AE37F),
                  size: 54,
                ),
                Container(
                  margin: const EdgeInsets.only(top: 10.0),
                  child: const Text(
                    'Відправлено',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              ],
            ),
          ),
          content: const Text(
            'Після підтвердження ви отримаєте доступ до геолокації користувача',
            textAlign: TextAlign.center,
          ),
        );
      },
    ).then(
      (val) {
        if (timer != null && timer!.isActive) {
          timer?.cancel();
        }
      },
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(
          color: Colors.black54, //change your color here
        ),
        elevation: 0.0,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
            child: Column(
              children: <Widget>[
                Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(vertical: 30),
                  child: Text(
                    tr('add_family_title'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 30.0),
                  child: TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      border: const UnderlineInputBorder(),
                      labelText: tr('name'),
                      hintText: "Ігор",
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
                    controller: emailController,
                    decoration: InputDecoration(
                      border: const UnderlineInputBorder(),
                      labelText: tr('email'),
                      hintText: "example@gmail.com",
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (text) {
                      if (text == null || text.trim().isEmpty) {
                        return tr('field_cannot_be_empty');
                      }
                      if (!EmailValidator.validate(text)) {
                        return tr('email_not_valid');
                      }
                      return null;
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 30.0),
                  child: TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      border: const UnderlineInputBorder(),
                      labelText: tr('phone'),
                      hintText: "+380 97 002 2369",
                      errorText: asyncErrors['phone'],
                    ),
                    // keyboardType: TextInputType.number,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (text) {
                      if (text == null || text.trim().isEmpty) {
                        return tr('field_cannot_be_empty');
                      }
                      validateNumber(text);
                      return null;
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onSendRequest,
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
                          : Text(tr('send_request')),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
