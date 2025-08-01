import '../models/house_helper_profile.dart';

class HouseHelperService {
  static final HouseHelperService _instance = HouseHelperService._internal();
  factory HouseHelperService() => _instance;
  HouseHelperService._internal();

  // Sample data for demonstration
  final List<HouseHelperProfile> _sampleHelpers = [
    HouseHelperProfile(
      id: '1',
      uid: 'helper_uid_1',
      fullName: 'Alice Johnson',
      email: 'alice@example.com',
      phoneNumber: '+250781234567',
      city: 'Kigali',
      district: 'Gasabo',
      description: 'Experienced house cleaner with 5+ years of experience',
      services: ['Cleaning', 'Laundry'],
      hourlyRate: 1500.0,
      rating: 4.8,
      reviewCount: 45,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      experienceYears: 5,
      dateOfBirth: DateTime(1990, 5, 15),
      address: 'Kimisagara, Nyarugenge, Kigali',
      availability: 'Full-time',
      languages: ['English', 'Kinyarwanda'],
    ),
    HouseHelperProfile(
      id: '2',
      uid: 'helper_uid_2',
      fullName: 'Bob Smith',
      email: 'bob@example.com',
      phoneNumber: '+250782345678',
      city: 'Kigali',
      district: 'Nyarugenge',
      description: 'Professional cook and cleaner',
      services: ['Cooking', 'Cleaning'],
      hourlyRate: 2000.0,
      rating: 4.5,
      reviewCount: 23,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      experienceYears: 3,
      dateOfBirth: DateTime(1985, 8, 22),
      address: 'Kacyiru, Gasabo, Kigali',
      availability: 'Part-time',
      languages: ['English', 'French'],
    ),
  ];

  Future<List<HouseHelperProfile>> getAllHelpers() async {
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate network delay
    return _sampleHelpers;
  }

  Future<List<HouseHelperProfile>> getAllProfiles({
    String? city,
    List<String>? services,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (city == null && services == null) {
      return _sampleHelpers;
    }

    return _sampleHelpers.where((helper) {
      bool matchesCity = city == null || helper.city == city;
      bool matchesServices = services == null ||
          services.isEmpty ||
          services.any((service) => helper.services.contains(service));
      return matchesCity && matchesServices;
    }).toList();
  }

  Future<List<HouseHelperProfile>> searchHelpers({
    String? city,
    String? service,
    double? maxRate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return _sampleHelpers.where((helper) {
      bool matchesCity = city == null ||
          helper.city.toLowerCase().contains(city.toLowerCase());
      bool matchesService = service == null ||
          helper.services
              .any((s) => s.toLowerCase().contains(service.toLowerCase()));
      bool matchesRate = maxRate == null || helper.hourlyRate <= maxRate;

      return matchesCity && matchesService && matchesRate;
    }).toList();
  }

  Future<HouseHelperProfile?> getHelperById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));

    try {
      return _sampleHelpers.firstWhere((helper) => helper.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateHelper(HouseHelperProfile helper) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final index = _sampleHelpers.indexWhere((h) => h.id == helper.id);
    if (index != -1) {
      _sampleHelpers[index] = helper;
      return true;
    }
    return false;
  }

  Future<bool> deleteHelper(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _sampleHelpers.indexWhere((h) => h.id == id);
    if (index != -1) {
      _sampleHelpers.removeAt(index);
      return true;
    }
    return false;
  }

  Future<bool> deleteProfile(String uid) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _sampleHelpers.indexWhere((h) => h.uid == uid);
    if (index != -1) {
      _sampleHelpers.removeAt(index);
      return true;
    }
    return false;
  }
}
