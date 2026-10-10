class TransitLocationModel {
  final String city;
  final String code;
  final String terminal;
  final String gate;
  final DateTime time;

  TransitLocationModel({
    required this.city,
    required this.code,
    required this.terminal,
    required this.gate,
    required this.time,
  });

  factory TransitLocationModel.fromJson(Map<String, dynamic> json) {
    return TransitLocationModel(
      city: json['city']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      terminal: json['terminal']?.toString() ?? 'T1',
      gate: json['gate']?.toString() ?? 'A1',
      time: json['time'] != null
          ? DateTime.tryParse(json['time'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'code': code,
      'terminal': terminal,
      'gate': gate,
      'time': time.toIso8601String(),
    };
  }
}

class TransportModel {
  final String id;
  final String? tripId;
  final String transportType; // flight, train, bus, ferry
  final String carrier;
  final String carrierCode;
  final String transitNumber;
  final String bookingReference;
  final String passengerName;
  final TransitLocationModel departure;
  final TransitLocationModel arrival;
  final String seatNumber;
  final String seatClass;
  final String status;
  final String qrCodeData;
  final DateTime createdAt;

  TransportModel({
    required this.id,
    this.tripId,
    required this.transportType,
    required this.carrier,
    required this.carrierCode,
    required this.transitNumber,
    required this.bookingReference,
    required this.passengerName,
    required this.departure,
    required this.arrival,
    required this.seatNumber,
    required this.seatClass,
    required this.status,
    required this.qrCodeData,
    required this.createdAt,
  });

  factory TransportModel.fromJson(Map<String, dynamic> json) {
    final depObj = json['departure'] as Map<String, dynamic>? ?? {};
    final arrObj = json['arrival'] as Map<String, dynamic>? ?? {};

    return TransportModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      tripId: json['tripId']?.toString(),
      transportType: json['transportType']?.toString() ?? 'flight',
      carrier: json['carrier']?.toString() ?? 'Carrier',
      carrierCode: json['carrierCode']?.toString() ?? 'RW',
      transitNumber: json['transitNumber']?.toString() ?? 'RW-101',
      bookingReference: json['bookingReference']?.toString() ?? 'RW-PNR',
      passengerName: json['passengerName']?.toString() ?? 'Traveler',
      departure: TransitLocationModel.fromJson(depObj),
      arrival: TransitLocationModel.fromJson(arrObj),
      seatNumber: json['seatNumber']?.toString() ?? '14A',
      seatClass: json['seatClass']?.toString() ?? 'Economy',
      status: json['status']?.toString() ?? 'On Time',
      qrCodeData: json['qrCodeData']?.toString() ?? 'RW-QR-DATA',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'id': id,
      if (tripId != null) 'tripId': tripId,
      'transportType': transportType,
      'carrier': carrier,
      'carrierCode': carrierCode,
      'transitNumber': transitNumber,
      'bookingReference': bookingReference,
      'passengerName': passengerName,
      'departure': departure.toJson(),
      'arrival': arrival.toJson(),
      'seatNumber': seatNumber,
      'seatClass': seatClass,
      'status': status,
      'qrCodeData': qrCodeData,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  TransportModel copyWith({
    String? status,
    TransitLocationModel? departure,
    TransitLocationModel? arrival,
  }) {
    return TransportModel(
      id: id,
      tripId: tripId,
      transportType: transportType,
      carrier: carrier,
      carrierCode: carrierCode,
      transitNumber: transitNumber,
      bookingReference: bookingReference,
      passengerName: passengerName,
      departure: departure ?? this.departure,
      arrival: arrival ?? this.arrival,
      seatNumber: seatNumber,
      seatClass: seatClass,
      status: status ?? this.status,
      qrCodeData: qrCodeData,
      createdAt: createdAt,
    );
  }
}
