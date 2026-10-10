class RoomTypeModel {
  final String id;
  final String name;
  final String bed;
  final int maxGuests;
  final double pricePerNight;
  final List<String> features;

  RoomTypeModel({
    required this.id,
    required this.name,
    required this.bed,
    required this.maxGuests,
    required this.pricePerNight,
    required this.features,
  });

  factory RoomTypeModel.fromJson(Map<String, dynamic> json) {
    return RoomTypeModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Standard Room',
      bed: json['bed']?.toString() ?? '1 Queen Bed',
      maxGuests: (json['maxGuests'] as num?)?.toInt() ?? 2,
      pricePerNight: (json['pricePerNight'] as num?)?.toDouble() ?? 2500.0,
      features: (json['features'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bed': bed,
      'maxGuests': maxGuests,
      'pricePerNight': pricePerNight,
      'features': features,
    };
  }
}

class HotelModel {
  final String id;
  final String title;
  final String city;
  final String address;
  final double rating;
  final int reviewsCount;
  final double pricePerNight;
  final String distance;
  final String image;
  final String description;
  final List<String> amenities;
  final double? latitude;
  final double? longitude;
  final List<RoomTypeModel> roomTypes;

  HotelModel({
    required this.id,
    required this.title,
    required this.city,
    required this.address,
    required this.rating,
    required this.reviewsCount,
    required this.pricePerNight,
    required this.distance,
    required this.image,
    required this.description,
    required this.amenities,
    this.latitude,
    this.longitude,
    required this.roomTypes,
  });

  factory HotelModel.fromJson(Map<String, dynamic> json) {
    final rawRooms = json['roomTypes'] as List? ?? [];
    List<RoomTypeModel> rooms = rawRooms
        .map((r) => RoomTypeModel.fromJson(r as Map<String, dynamic>))
        .toList();

    // Ensure at least one default room type exists
    final double basePrice = (json['pricePerNight'] as num?)?.toDouble() ?? 3000.0;
    if (rooms.isEmpty) {
      rooms = [
        RoomTypeModel(
          id: 'def-rm-1',
          name: 'Deluxe Room',
          bed: '1 King Bed',
          maxGuests: 2,
          pricePerNight: basePrice,
          features: ['Free WiFi', 'Air Conditioned', 'City View'],
        ),
        RoomTypeModel(
          id: 'def-rm-2',
          name: 'Executive Suite',
          bed: '1 King Bed + Lounge',
          maxGuests: 3,
          pricePerNight: basePrice * 1.5,
          features: ['Living Area', 'Complimentary Breakfast', 'Bathtub'],
        ),
      ];
    }

    return HotelModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Luxury Hotel',
      city: json['city']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 120,
      pricePerNight: basePrice,
      distance: json['distance']?.toString() ?? '1.0 km from Center',
      image: json['image']?.toString() ??
          'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=800&q=80',
      description: json['description']?.toString() ??
          'Experience comfort and elevated hospitality with contemporary decor and curated amenities.',
      amenities: (json['amenities'] as List?)?.map((e) => e.toString()).toList() ??
          ['Free High-Speed WiFi', 'Swimming Pool', 'Breakfast Available', 'Room Service'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      roomTypes: rooms,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'city': city,
      'address': address,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'pricePerNight': pricePerNight,
      'distance': distance,
      'image': image,
      'description': description,
      'amenities': amenities,
      'latitude': latitude,
      'longitude': longitude,
      'roomTypes': roomTypes.map((r) => r.toJson()).toList(),
    };
  }
}
