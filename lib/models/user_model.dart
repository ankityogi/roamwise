class EmergencyContactModel {
  final String name;
  final String phone;

  EmergencyContactModel({required this.name, required this.phone});

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
    };
  }
}

// Model class representing the authenticated User inside the Flutter client
class UserModel {
  final String id;
  final String name;
  final String email;
  final String profilePic;
  final int tripsCount;
  final int countriesCount;
  final int savedItemsCount;
  final List<EmergencyContactModel> emergencyContacts;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.profilePic,
    required this.tripsCount,
    required this.countriesCount,
    required this.savedItemsCount,
    required this.emergencyContacts,
  });

  // Factory constructor to build a UserModel from JSON response data
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final stats = json['travelStats'] ?? {};
    final contactsList = json['emergencyContacts'] as List? ?? [];
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profilePic: json['profilePic'] ?? '',
      tripsCount: stats['tripsCount'] ?? 0,
      countriesCount: stats['countriesCount'] ?? 0,
      savedItemsCount: stats['savedItemsCount'] ?? 0,
      emergencyContacts: contactsList
          .map((c) => EmergencyContactModel.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  // Convert model back to Map for ease of transfer or caching
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'profilePic': profilePic,
      'travelStats': {
        'tripsCount': tripsCount,
        'countriesCount': countriesCount,
        'savedItemsCount': savedItemsCount,
      },
      'emergencyContacts': emergencyContacts.map((c) => c.toJson()).toList(),
    };
  }
}
