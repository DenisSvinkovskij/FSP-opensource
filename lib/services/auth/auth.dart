import 'dart:developer';
import 'package:find_safe_places/models/user.dart';
import 'package:find_safe_places/services/firebase/users_firebase.dart';
import 'package:find_safe_places/services/geo/geolocation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Auth {
  final GoogleSignIn googleSignIn = GoogleSignIn();

  Future signInWithGoogle() async {
    await FirebaseAuth.instance.signOut();
    await googleSignIn.signOut();

    FirebaseAuth auth = FirebaseAuth.instance;

    final GoogleSignInAccount? googleSignInAccount =
        await googleSignIn.signIn();
    final GoogleSignInAuthentication? googleSignInAuthentication =
        await googleSignInAccount?.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleSignInAuthentication?.accessToken,
      idToken: googleSignInAuthentication?.idToken,
    );

    final UserCredential authResult =
        await auth.signInWithCredential(credential);

    // final User? user = authResult.user;

    final User? currentUser = auth.currentUser;

    if (currentUser == null) {
      log('Login Cancelled because currentUser not found');
      return currentUser;
    }

    if (!authResult.user!.emailVerified) {
      log('Login Cancelled because email not verified');
      return currentUser;
    }

    String? fcmToken = await FirebaseMessaging.instance.getToken();

    final location = await getLocationWithGeoHash();

    final userForDb = {
      'displayName': currentUser.displayName,
      'email': currentUser.email,
      'emailVerified': currentUser.emailVerified,
      'photoURL': currentUser.photoURL,
      'uid': currentUser.uid,
    };

    if (location != false) {
      userForDb['location'] = location;
    }

    if (fcmToken != null) {
      userForDb['fcmToken'] = fcmToken;
    }

    await UsersFirebase.updateUser(currentUser.uid, userForDb);
    var updatedUser = await UsersFirebase.getUserDoc(currentUser.uid);

    log('success google auth');
    return UserModel.fromJson(updatedUser.data()!);
  }

  Future<void> signOut() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    await googleSignIn.signOut();
    await auth.signOut();
    log("User Sign Out");
  }

  Future<User?> signInUsingEmailPassword({
    required String email,
    required String password,
  }) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user;

    UserCredential userCredential = await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    user = userCredential.user;
    return user;
  }

  static Future<User?> registerUsingEmailPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user;

    UserCredential userCredential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    user = userCredential.user;
    await user!.updateDisplayName(name);
    await user.reload();
    user = auth.currentUser;

    final location = await getLocationWithGeoHash();

    final userForDb = {
      'displayName': auth.currentUser?.displayName,
      'email': auth.currentUser?.email,
      'emailVerified': auth.currentUser?.emailVerified,
      'photoURL': auth.currentUser?.photoURL,
      'uid': auth.currentUser?.uid,
      'location': location,
    };

    await UsersFirebase.updateUser(auth.currentUser!.uid, userForDb);
    return user;
  }

  static Future<User?> refreshUser(User user) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    await user.reload();
    User? refreshedUser = auth.currentUser;

    return refreshedUser;
  }
}
