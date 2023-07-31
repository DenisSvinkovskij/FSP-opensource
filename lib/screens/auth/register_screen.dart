import 'package:easy_localization/easy_localization.dart';
import 'package:find_safe_places/constants/ui.dart';
import 'package:find_safe_places/models/user.dart';
import 'package:find_safe_places/providers/user_provider.dart';
import 'package:find_safe_places/services/auth/auth.dart';
import 'package:find_safe_places/widgets/google_sign_in_btn.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool loading = false;

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
          child: Column(
            children: <Widget>[
              Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(vertical: 30),
                child: Text(
                  tr('register_title'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Container(
              //   margin: const EdgeInsets.only(bottom: 30.0),
              //   child: TextFormField(
              //     decoration: const InputDecoration(
              //       border: UnderlineInputBorder(),
              //       labelText: "Ім'я та прізвище",
              //       hintText: "Володимир Зеленський",
              //     ),
              //   ),
              // ),
              // Container(
              //   margin: const EdgeInsets.only(bottom: 30.0),
              //   child: TextFormField(
              //     decoration: const InputDecoration(
              //       border: UnderlineInputBorder(),
              //       labelText: 'Номер телефону',
              //       hintText: "+380 99 777 7777",
              //     ),
              //     keyboardType: TextInputType.number,
              //   ),
              // ),
              // Container(
              //   margin: const EdgeInsets.only(bottom: 30.0),
              //   child: TextFormField(
              //     obscureText: true,
              //     decoration: const InputDecoration(
              //       border: UnderlineInputBorder(),
              //       labelText: 'Пароль',
              //       hintText: "********",
              //     ),
              //   ),
              // ),
              // Container(
              //   margin: const EdgeInsets.only(bottom: 20),
              //   child: SizedBox(
              //     width: double.infinity,
              //     child: ElevatedButton(
              //       onPressed: () {},
              //       style: ElevatedButton.styleFrom(
              //         textStyle: const TextStyle(fontSize: 18),
              //         padding: const EdgeInsets.symmetric(vertical: 16),
              //       ),
              //       child: const Text('Cтворити профіль'),
              //     ),
              //   ),
              // ),

              const SizedBox(height: 200),

              GoogleSignInButtonWidget(
                loading: loading,
                onPress: () async {
                  setState(() {
                    loading = true;
                  });
                  try {
                    final UserModel? user = await Auth().signInWithGoogle();
                    if (!mounted) return;
                    Provider.of<UserProvider>(context, listen: false)
                        .setUser(user);
                    Navigator.pop(context);
                  } catch (e) {
                    print(e);
                    setState(() {
                      loading = false;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
