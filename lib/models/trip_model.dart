// Model representing an individual time-blocked activity on a travel day
class TimelineEventModel {
  final String? id;
  final String time;
  final String title;
  final String description;
  final List<String> votes;
  final String addedBy;
  final double? latitude;
  final double? longitude;

  TimelineEventModel({
    this.id,
    required this.time,
    required this.title,
    required this.description,
    this.votes = const [],
    this.addedBy = 'AI Assistant',
    this.latitude,
    this.longitude,
  });

  factory TimelineEventModel.fromJson(Map<String, dynamic> json) {
    final votesList = json['votes'] as List? ?? [];
    return TimelineEventModel(
      id: json['_id'] ?? json['id'],
      time: json['time'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      votes: votesList.map((v) => v.toString()).toList(),
      addedBy: json['addedBy'] ?? 'AI Assistant',
      latitude: (json['latitude'] as num?)?.toDouble() ?? (json['lat'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble() ?? (json['lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'time': time,
      'title': title,
      'description': description,
      'votes': votes,
      'addedBy': addedBy,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}

// Model representing a trip companion collaborator
class CollaboratorModel {
  final String userId;
  final String name;
  final String email;

  CollaboratorModel({
    required this.userId,
    required this.name,
    required this.email,
  });

  factory CollaboratorModel.fromJson(Map<String, dynamic> json) {
    return CollaboratorModel(
      userId: json['userId'] ?? json['_id'] ?? '',
      name: json['name'] ?? 'Travel Companion',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
    };
  }
}

// Model representing a single day within a travel itinerary schedule
class ItineraryDayModel {
  final int dayNumber;
  final List<TimelineEventModel> events;

  ItineraryDayModel({
    required this.dayNumber,
    required this.events,
  });

  factory ItineraryDayModel.fromJson(Map<String, dynamic> json) {
    final list = json['events'] as List? ?? [];
    return ItineraryDayModel(
      dayNumber: json['dayNumber'] ?? 0,
      events: list.map((e) => TimelineEventModel.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayNumber': dayNumber,
      'events': events.map((e) => e.toJson()).toList(),
    };
  }
}

// Model representing a complete saved travel trip
class TripModel {
  final String id;
  final String title;
  final String destination;
  final String dates;
  final int daysCount;
  final String travelStyle;
  final String? inviteCode;
  final List<CollaboratorModel> collaborators;
  final List<ItineraryDayModel> itinerarySchedule;

  TripModel({
    required this.id,
    required this.title,
    required this.destination,
    required this.dates,
    required this.daysCount,
    required this.travelStyle,
    this.inviteCode,
    this.collaborators = const [],
    required this.itinerarySchedule,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    final list = json['itinerarySchedule'] as List? ?? [];
    final collabList = json['collaborators'] as List? ?? [];
    return TripModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      destination: json['destination'] ?? '',
      dates: json['dates'] ?? 'TBD (Planned)',
      daysCount: json['daysCount'] ?? 0,
      travelStyle: json['travelStyle'] ?? '',
      inviteCode: json['inviteCode'],
      collaborators: collabList.map((c) => CollaboratorModel.fromJson(c)).toList(),
      itinerarySchedule: list.map((d) => ItineraryDayModel.fromJson(d)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'destination': destination,
      'dates': dates,
      'daysCount': daysCount,
      'travelStyle': travelStyle,
      if (inviteCode != null) 'inviteCode': inviteCode,
      'collaborators': collaborators.map((c) => c.toJson()).toList(),
      'itinerarySchedule': itinerarySchedule.map((d) => d.toJson()).toList(),
    };
  }
}
