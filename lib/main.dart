import 'dart:async';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:find_safe_places/constants/notifications.dart';
import 'package:find_safe_places/models/user.dart';
import 'package:find_safe_places/providers/user_provider.dart';
import 'package:find_safe_places/screens/actions_in_emergencies_screen.dart';
import 'package:find_safe_places/screens/map_screen.dart';
import 'package:find_safe_places/services/firebase/users_firebase.dart';
import 'package:find_safe_places/services/notifications/local_notifications_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

final StreamController<String?> selectNotificationStream =
    StreamController<String?>.broadcast();

Future<void> notify(RemoteMessage message) async {
  if (message.data.containsKey('emergency')) {
    LocalNotificationService.showNotificationAboutEmergency(
      message.data['title'] ?? "",
      message.data['body'] ?? "",
    );
  } else {
    LocalNotificationService.showNotification(
      message.data['title'] ?? "",
      message.data['body'] ?? "",
    );
  }
}

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  // ? UNCOMMENT WHEN DefaultFirebaseOptions WILL BE ADDED
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  LocalNotificationService.setup(selectNotificationStream);

  runApp(
    EasyLocalization(
      path: 'assets/translations',
      supportedLocales: const [Locale('en'), Locale('uk')],
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      child: const RootMaterial(),
    ),
  );
}

class RootMaterial extends StatelessWidget {
  const RootMaterial({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserProvider())],
      child: MaterialApp(
        title: 'Find Safe Place',
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyApp(),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    requestPermissionsNotifications();
    configureSelectNotificationSubject();

    FirebaseMessaging.instance.onTokenRefresh.listen(onTokenRefresh);
    FirebaseAuth.instance.authStateChanges().listen(onAuthStateChanges);

    FirebaseMessaging.onMessage.listen(notify);
  }

  Future onTokenRefresh(token) async {
    if (!mounted) return;
    UserModel? user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return;
    UsersFirebase.updateUser(user.uid, {'fcmToken': token});
  }

  Future onAuthStateChanges(User? user) async {
    if (user == null) {
      log('User is currently signed out!');
    } else {
      final dbUser = await UsersFirebase.getUserDoc(user.uid)
          .then((value) => UserModel.fromJson(value.data()!));

      if (!mounted) return;
      Provider.of<UserProvider>(context, listen: false).setUser(dbUser);
    }
  }

  void configureSelectNotificationSubject() {
    selectNotificationStream.stream.listen((String? payload) async {
      var split = (payload ?? " | ").split('|');
      if (split[0] == kNavigationActionId &&
          split[1] == 'ActionsInEmergencies') {
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (BuildContext context) => const ActionsInEmergenciesScreen(),
        ));
        return;
      }

      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            const FullMap(initCalculatePath: true),
      ));
    });
  }

  @override
  void dispose() {
    selectNotificationStream.close();
    super.dispose();
  }

  requestPermissionsNotifications() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('User granted permission');
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      log('User granted provisional permission');
      debugPrint('User granted provisional permission');
    } else {
      log('User denied or not accept permission');
      debugPrint('User denied or not accept permission');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const FullMap();
  }
}
