class ClosePerson {
  ClosePerson({
    required this.name,
    this.color,
    this.phone,
    this.email,
    this.inviteUID,
    this.uid,
    this.location,
  });

  late String name;
  String? color;
  String? phone;
  String? email;
  String? inviteUID;
  String? uid;
  dynamic location;

  ClosePerson.fromJson(Map<String, dynamic> json) {
    uid = json['uid'] ?? json['id'];
    name = json['name'] ?? json['displayName'];
    email = json['email'];
    phone = json['phone'];
    inviteUID = json['inviteUID'];
    color = json['color'];
    location = json['location'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    json['uid'] = uid;
    json['name'] = name;
    json['email'] = email;
    json['phone'] = phone;
    json['inviteUID'] = inviteUID;
    json['color'] = color;
    json['location'] = location;
    return json;
  }
}
