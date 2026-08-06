// Model class representing the authenticated User inside the Flutter client
class UserModel {
  final String id;
  final String name;
  final String email;
  final String profilePic;
  final int tripsCount;
  final int countriesCount;
  final int savedItemsCount;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.profilePic,
    required this.tripsCount,
    required this.countriesCount,
    required this.savedItemsCount,
  });

  // Factory constructor to build a UserModel from JSON response data
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final stats = json['travelStats'] ?? {};
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profilePic: json['profilePic'] ?? '',
      tripsCount: stats['tripsCount'] ?? 0,
      countriesCount: stats['countriesCount'] ?? 0,
      savedItemsCount: stats['savedItemsCount'] ?? 0,
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
    };
  }
}
