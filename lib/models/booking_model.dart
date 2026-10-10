class BookingContactModel {
  final String name;
  final String email;
  final String phone;

  BookingContactModel({
    required this.name,
    required this.email,
    required this.phone,
  });

  factory BookingContactModel.fromJson(Map<String, dynamic> json) {
    return BookingContactModel(
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
    };
  }
}

class BookingGuestsModel {
  final int adults;
  final int children;

  BookingGuestsModel({required this.adults, required this.children});

  factory BookingGuestsModel.fromJson(Map<String, dynamic> json) {
    return BookingGuestsModel(
      adults: (json['adults'] as num?)?.toInt() ?? 1,
      children: (json['children'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'adults': adults,
      'children': children,
    };
  }
}

class BookingPricingModel {
  final double baseTotal;
  final double taxAndFees;
  final double totalAmount;

  BookingPricingModel({
    required this.baseTotal,
    required this.taxAndFees,
    required this.totalAmount,
  });

  factory BookingPricingModel.fromJson(Map<String, dynamic> json) {
    return BookingPricingModel(
      baseTotal: (json['baseTotal'] as num?)?.toDouble() ?? 0.0,
      taxAndFees: (json['taxAndFees'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseTotal': baseTotal,
      'taxAndFees': taxAndFees,
      'totalAmount': totalAmount,
    };
  }
}

class BookingModel {
  final String id;
  final String bookingReference;
  final String hotelTitle;
  final String hotelImage;
  final String hotelLocation;
  final double hotelRating;
  final String roomType;
  final double pricePerNight;
  final int numberOfRooms;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int numberOfNights;
  final BookingGuestsModel guests;
  final BookingContactModel contactDetails;
  final String specialRequests;
  final BookingPricingModel pricing;
  final String status;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.bookingReference,
    required this.hotelTitle,
    required this.hotelImage,
    required this.hotelLocation,
    required this.hotelRating,
    required this.roomType,
    required this.pricePerNight,
    required this.numberOfRooms,
    required this.checkInDate,
    required this.checkOutDate,
    required this.numberOfNights,
    required this.guests,
    required this.contactDetails,
    required this.specialRequests,
    required this.pricing,
    required this.status,
    required this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final hotelObj = json['hotel'] as Map<String, dynamic>? ?? {};
    final guestsObj = json['guests'] as Map<String, dynamic>? ?? {};
    final contactObj = json['contactDetails'] as Map<String, dynamic>? ?? {};
    final pricingObj = json['pricing'] as Map<String, dynamic>? ?? {};

    return BookingModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      bookingReference: json['bookingReference']?.toString() ?? 'RW-HTL-000000',
      hotelTitle: hotelObj['title']?.toString() ?? json['hotelTitle']?.toString() ?? 'Reserved Hotel',
      hotelImage: hotelObj['image']?.toString() ??
          json['hotelImage']?.toString() ??
          'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=800&q=80',
      hotelLocation: hotelObj['location']?.toString() ?? json['hotelLocation']?.toString() ?? '',
      hotelRating: (hotelObj['rating'] as num?)?.toDouble() ?? 4.5,
      roomType: json['roomType']?.toString() ?? 'Deluxe Room',
      pricePerNight: (json['pricePerNight'] as num?)?.toDouble() ?? 0.0,
      numberOfRooms: (json['numberOfRooms'] as num?)?.toInt() ?? 1,
      checkInDate: json['checkInDate'] != null
          ? DateTime.tryParse(json['checkInDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      checkOutDate: json['checkOutDate'] != null
          ? DateTime.tryParse(json['checkOutDate'].toString()) ?? DateTime.now().add(const Duration(days: 1))
          : DateTime.now().add(const Duration(days: 1)),
      numberOfNights: (json['numberOfNights'] as num?)?.toInt() ?? 1,
      guests: BookingGuestsModel.fromJson(guestsObj),
      contactDetails: BookingContactModel.fromJson(contactObj),
      specialRequests: json['specialRequests']?.toString() ?? '',
      pricing: BookingPricingModel.fromJson(pricingObj),
      status: json['status']?.toString() ?? 'confirmed',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'id': id,
      'bookingReference': bookingReference,
      'hotelTitle': hotelTitle,
      'hotelImage': hotelImage,
      'hotelLocation': hotelLocation,
      'hotelRating': hotelRating,
      'roomType': roomType,
      'pricePerNight': pricePerNight,
      'numberOfRooms': numberOfRooms,
      'checkInDate': checkInDate.toIso8601String(),
      'checkOutDate': checkOutDate.toIso8601String(),
      'numberOfNights': numberOfNights,
      'guests': guests.toJson(),
      'contactDetails': contactDetails.toJson(),
      'specialRequests': specialRequests,
      'pricing': pricing.toJson(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
