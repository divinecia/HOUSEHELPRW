import '../services/supabase_service.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContact {
  final String id;
  final String name;
  final String number;
  final String category;
  final String description;
  final DateTime createdAt;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.number,
    required this.category,
    required this.description,
    required this.createdAt,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'],
      name: json['name'],
      number: json['number'],
      category: json['category'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'category': category,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class EmergencyService {
  /// Get all emergency contacts
  static Future<List<EmergencyContact>> getAllEmergencyContacts() async {
    try {
      final data = await SupabaseService.read(
        table: 'emergency_contacts',
        orderBy: 'category, name',
      );

      return data.map((json) => EmergencyContact.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching emergency contacts: $e');
      return [];
    }
  }

  /// Get emergency contacts by category
  static Future<List<EmergencyContact>> getEmergencyContactsByCategory(
      String category) async {
    try {
      final data = await SupabaseService.read(
        table: 'emergency_contacts',
        filters: {'category': category},
        orderBy: 'name',
      );

      return data.map((json) => EmergencyContact.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching emergency contacts by category: $e');
      return [];
    }
  }

  /// Search emergency contacts
  static Future<List<EmergencyContact>> searchEmergencyContacts(
      String query) async {
    try {
      final data = await SupabaseService.read(
        table: 'emergency_contacts',
        orderBy: 'name',
      );

      final contacts =
          data.map((json) => EmergencyContact.fromJson(json)).toList();

      // Filter contacts based on query
      return contacts.where((contact) {
        return contact.name.toLowerCase().contains(query.toLowerCase()) ||
            contact.description.toLowerCase().contains(query.toLowerCase()) ||
            contact.number.contains(query);
      }).toList();
    } catch (e) {
      print('Error searching emergency contacts: $e');
      return [];
    }
  }

  /// Make a phone call to emergency number
  static Future<bool> makeEmergencyCall(String phoneNumber) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        return true;
      } else {
        print('Could not launch phone app for number: $phoneNumber');
        return false;
      }
    } catch (e) {
      print('Error making emergency call: $e');
      return false;
    }
  }

  /// Log emergency call for internal tracking
  static Future<void> logEmergencyCall({
    required String contactId,
    required String userId,
    required String userRole,
    String? notes,
  }) async {
    try {
      await SupabaseService.create(
        table: 'emergency_call_logs',
        data: {
          'contact_id': contactId,
          'user_id': userId,
          'user_role': userRole,
          'notes': notes,
          'called_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Error logging emergency call: $e');
    }
  }

  /// Submit emergency report to admin
  static Future<bool> submitEmergencyReport({
    required String userId,
    required String userRole,
    required String emergencyType,
    required String description,
    String? contactUsed,
    String? location,
    List<String>? evidenceUrls,
  }) async {
    try {
      await SupabaseService.create(
        table: 'emergency_reports',
        data: {
          'user_id': userId,
          'user_role': userRole,
          'emergency_type': emergencyType,
          'description': description,
          'contact_used': contactUsed,
          'location': location,
          'evidence_urls': evidenceUrls,
          'status': 'submitted',
          'reported_at': DateTime.now().toIso8601String(),
        },
      );

      return true;
    } catch (e) {
      print('Error submitting emergency report: $e');
      return false;
    }
  }

  /// Get emergency categories
  static List<String> getEmergencyCategories() {
    return [
      'General',
      'Crime',
      'Violence',
      'Traffic',
      'Support',
      'Utility',
    ];
  }

  /// Get predefined emergency contacts (fallback if database is empty)
  static List<EmergencyContact> getDefaultEmergencyContacts() {
    return [
      EmergencyContact(
        id: 'emergency_112',
        name: 'General Emergency',
        number: '112',
        category: 'General',
        description: 'Universal access for life-threatening emergencies',
        createdAt: DateTime.now(),
      ),
      EmergencyContact(
        id: 'rib_166',
        name: 'RIB - Crime Info',
        number: '166',
        category: 'Crime',
        description: 'Report threats, harassment, or criminal acts',
        createdAt: DateTime.now(),
      ),
      EmergencyContact(
        id: 'gbv_3512',
        name: 'Gender-Based Violence',
        number: '3512',
        category: 'Violence',
        description: 'Report abuse, GBV, or exploitation at workplace/home',
        createdAt: DateTime.now(),
      ),
      EmergencyContact(
        id: 'child_116',
        name: 'Child Help Line',
        number: '116',
        category: 'Support',
        description: 'For households involving child workers or abuse cases',
        createdAt: DateTime.now(),
      ),
      EmergencyContact(
        id: 'isange_3029',
        name: 'Isange One Stop Center',
        number: '3029',
        category: 'Support',
        description: 'For physical or psychological abuse (trauma care)',
        createdAt: DateTime.now(),
      ),
      EmergencyContact(
        id: 'police_abuse_3511',
        name: 'Abuse by Police Officer',
        number: '3511',
        category: 'Crime',
        description:
            'In case of intimidation or misconduct during verification',
        createdAt: DateTime.now(),
      ),
      EmergencyContact(
        id: 'rib_dissatisfaction_2040',
        name: 'RIB Dissatisfaction',
        number: '2040',
        category: 'Support',
        description: 'If user feels RIB handled a case poorly',
        createdAt: DateTime.now(),
      ),
      EmergencyContact(
        id: 'traffic_police_118',
        name: 'Traffic Police',
        number: '118',
        category: 'Traffic',
        description: 'Report incidents while in transit to jobs',
        createdAt: DateTime.now(),
      ),
      EmergencyContact(
        id: 'anti_corruption_997',
        name: 'Anti-Corruption',
        number: '997',
        category: 'Crime',
        description: 'Report bribery in hiring, training, or app moderation',
        createdAt: DateTime.now(),
      ),
      EmergencyContact(
        id: 'reg_customer_2727',
        name: 'REG – Customer Service',
        number: '2727',
        category: 'Utility',
        description: 'Report utility issues when tied to job conditions',
        createdAt: DateTime.now(),
      ),
      EmergencyContact(
        id: 'traffic_accident_113',
        name: 'Traffic Accident',
        number: '113',
        category: 'Traffic',
        description: 'Report while commuting for work',
        createdAt: DateTime.now(),
      ),
    ];
  }

  /// Initialize emergency contacts in database (for admin use)
  static Future<void> initializeEmergencyContacts() async {
    try {
      final existingContacts = await getAllEmergencyContacts();

      if (existingContacts.isEmpty) {
        final defaultContacts = getDefaultEmergencyContacts();

        for (final contact in defaultContacts) {
          await SupabaseService.create(
            table: 'emergency_contacts',
            data: contact.toJson()..remove('id'),
          );
        }

        print('Emergency contacts initialized successfully');
      }
    } catch (e) {
      print('Error initializing emergency contacts: $e');
    }
  }

  /// Get emergency reports for admin
  static Future<List<Map<String, dynamic>>> getEmergencyReports({
    String? status,
    String? emergencyType,
    int? limit,
  }) async {
    try {
      Map<String, dynamic>? filters;

      if (status != null || emergencyType != null) {
        filters = {};
        if (status != null) filters['status'] = status;
        if (emergencyType != null) filters['emergency_type'] = emergencyType;
      }

      final data = await SupabaseService.read(
        table: 'emergency_reports',
        orderBy: 'reported_at',
        ascending: false,
        limit: limit,
        filters: filters,
      );

      return data;
    } catch (e) {
      print('Error fetching emergency reports: $e');
      return [];
    }
  }

  /// Update emergency report status (admin only)
  static Future<bool> updateEmergencyReportStatus({
    required String reportId,
    required String status,
    String? adminNotes,
    String? adminId,
  }) async {
    try {
      await SupabaseService.update(
        table: 'emergency_reports',
        id: reportId,
        data: {
          'status': status,
          'admin_notes': adminNotes,
          'reviewed_by': adminId,
          'reviewed_at': DateTime.now().toIso8601String(),
        },
      );

      return true;
    } catch (e) {
      print('Error updating emergency report status: $e');
      return false;
    }
  }
}
