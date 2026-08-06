// Model representing an individual time-blocked activity on a travel day
class TimelineEventModel {
  final String time;
  final String title;
  final String description;

  TimelineEventModel({
    required this.time,
    required this.title,
    required this.description,
  });

  factory TimelineEventModel.fromJson(Map<String, dynamic> json) {
    return TimelineEventModel(
      time: json['time'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'title': title,
      'description': description,
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
  final List<ItineraryDayModel> itinerarySchedule;

  TripModel({
    required this.id,
    required this.title,
    required this.destination,
    required this.dates,
    required this.daysCount,
    required this.travelStyle,
    required this.itinerarySchedule,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    final list = json['itinerarySchedule'] as List? ?? [];
    return TripModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      destination: json['destination'] ?? '',
      dates: json['dates'] ?? 'TBD (Planned)',
      daysCount: json['daysCount'] ?? 0,
      travelStyle: json['travelStyle'] ?? '',
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
      'itinerarySchedule': itinerarySchedule.map((d) => d.toJson()).toList(),
    };
  }
}
