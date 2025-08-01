class HouseHelperProfile {
  final String id;
  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String city;
  final String district;
  final String description;
  final List<String> services;
  final double hourlyRate;
  final double rating;
  final int reviewCount;
  final bool isAvailable;
  final DateTime createdAt;
  final String? profileImageUrl;
  final int experienceYears;
  final DateTime? dateOfBirth;
  final String address;
  final String availability;
  final List<String> languages;
  final bool hasReferences;

  HouseHelperProfile({
    required this.id,
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.city,
    required this.district,
    required this.description,
    required this.services,
    required this.hourlyRate,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isAvailable = true,
    required this.createdAt,
    this.profileImageUrl,
    this.experienceYears = 0,
    this.dateOfBirth,
    this.address = '',
    this.availability = 'Full-time',
    this.languages = const ['English'],
    this.hasReferences = false,
  });

  factory HouseHelperProfile.fromMap(Map<String, dynamic> map) {
    return HouseHelperProfile(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      city: map['city'] ?? '',
      district: map['district'] ?? '',
      description: map['description'] ?? '',
      services: List<String>.from(map['services'] ?? []),
      hourlyRate: (map['hourlyRate'] ?? 0).toDouble(),
      rating: (map['rating'] ?? 0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      isAvailable: map['isAvailable'] ?? true,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      profileImageUrl: map['profileImageUrl'],
      experienceYears: map['experienceYears'] ?? 0,
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.tryParse(map['dateOfBirth'])
          : null,
      address: map['address'] ?? '',
      availability: map['availability'] ?? 'Full-time',
      languages: List<String>.from(map['languages'] ?? ['English']),
      hasReferences: map['hasReferences'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'city': city,
      'district': district,
      'description': description,
      'services': services,
      'hourlyRate': hourlyRate,
      'rating': rating,
      'reviewCount': reviewCount,
      'isAvailable': isAvailable,
      'createdAt': createdAt.toIso8601String(),
      'profileImageUrl': profileImageUrl,
      'experienceYears': experienceYears,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'address': address,
      'availability': availability,
      'languages': languages,
      'hasReferences': hasReferences,
    };
  }
}
