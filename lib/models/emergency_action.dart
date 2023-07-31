class EmergencyAction {
  EmergencyAction({
    required this.title,
    required this.actions,
    required this.type,
    required this.nature,
    required this.body,
    this.isExpanded = false,
  });
  late Map<String, dynamic> title;
  late Map<String, dynamic> body;
  late Map<String, dynamic> type;
  late Map<String, dynamic> nature;
  late List<dynamic> actions;
  late bool isExpanded;

  EmergencyAction.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    body = json['body'];
    type = json['type'];
    nature = json['nature'];
    actions = json['actions'];
    isExpanded = false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    json['title'] = title;
    json['body'] = body;
    json['type'] = type;
    json['nature'] = nature;
    json['actions'] = actions;
    return json;
  }
}
