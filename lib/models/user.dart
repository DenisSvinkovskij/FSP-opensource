class UserModel {
  late String uid;
  late String displayName;
  late String email;
  late String? phone;
  bool? emailVerified;
  String? photoURL;
  dynamic location;
  List<dynamic>? familyIds;
  late UserSubscriptionsModel? subscriptions;
  late UserAppStateModel userAppState;

  UserModel.fromJson(Map<String, dynamic> json) {
    uid = json['uid'] ?? json['id'];
    displayName = json['displayName'];
    email = json['email'];
    phone = json['phone'];
    emailVerified = json['emailVerified'];
    photoURL = json['photoURL'];
    location = json['location'];
    familyIds = json['familyIds'] ?? [];
    subscriptions = json['subscriptions'] == null
        ? null
        : UserSubscriptionsModel.fromJson(json['subscriptions']);
    userAppState = UserAppStateModel.fromJson(json['userAppState'] ?? {});
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    json['uid'] = uid;
    json['displayName'] = displayName;
    json['email'] = email;
    json['phone'] = phone;
    json['emailVerified'] = emailVerified;
    json['photoURL'] = photoURL;
    json['location'] = location;
    json['familyIds'] = familyIds;
    if (subscriptions == null) {
      json['subscriptions'] = null;
    } else {
      json['subscriptions'] = subscriptions?.toJson();
    }
    json['userAppState'] = userAppState.toJson();
    return json;
  }
}

class UserSubscriptionsModel {
  late bool? pushNotifications;
  late LightOffSubscriptionModel? lightOff;

  UserSubscriptionsModel({this.lightOff, this.pushNotifications = true});

  UserSubscriptionsModel.fromJson(Map<String, dynamic> json) {
    pushNotifications = json['pushNotifications'];
    if (json['lightOff'] == null) {
      lightOff = null;
    } else {
      lightOff = LightOffSubscriptionModel.fromJson(json['lightOff']);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    json['pushNotifications'] = pushNotifications;
    if (lightOff == null) {
      json['lightOff'] = null;
    } else {
      json['lightOff'] = lightOff?.toJson();
    }
    return json;
  }
}

class LightOffSubscriptionModel {
  late int group;
  late bool isEnabled;
  late int timeInMinutes;

  LightOffSubscriptionModel({
    this.isEnabled = false,
    this.group = 1,
    this.timeInMinutes = 0,
  });

  LightOffSubscriptionModel.fromJson(Map<String, dynamic> json) {
    group = json['group'];
    isEnabled = json['isEnabled'];
    timeInMinutes = json['timeInMinutes'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    json['group'] = group;
    json['isEnabled'] = isEnabled;
    json['timeInMinutes'] = timeInMinutes;
    return json;
  }
}

class UserAppStateModel {
  late bool allSafePlacesVisible;
  late bool invincibilityPointsVisible;

  UserAppStateModel({
    this.allSafePlacesVisible = true,
    this.invincibilityPointsVisible = true,
  });

  UserAppStateModel.fromJson(Map<String, dynamic> json) {
    allSafePlacesVisible = json['allSafePlacesVisible'] ?? true;
    invincibilityPointsVisible = json['invincibilityPointsVisible'] ?? true;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    json['allSafePlacesVisible'] = allSafePlacesVisible;
    json['invincibilityPointsVisible'] = invincibilityPointsVisible;
    return json;
  }
}
