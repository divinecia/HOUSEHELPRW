import 'user_role.dart';

class BehaviorReport {
  final String? id;
  final String reportedWorkerId;
  final String reportedWorkerName;
  final String reporterHouseholdId;
  final String reporterHouseholdName;
  final String incidentDescription;
  final ReportSeverity severity;
  final DateTime incidentDate;
  final String location;
  final List<String>? evidenceUrls;
  final ReportStatus status;
  final DateTime reportedAt;
  final String? adminNotes;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final bool emailSentToIsange;
  final DateTime? emailSentAt;

  BehaviorReport({
    this.id,
    required this.reportedWorkerId,
    required this.reportedWorkerName,
    required this.reporterHouseholdId,
    required this.reporterHouseholdName,
    required this.incidentDescription,
    required this.severity,
    required this.incidentDate,
    required this.location,
    this.evidenceUrls,
    this.status = ReportStatus.pending,
    required this.reportedAt,
    this.adminNotes,
    this.resolvedAt,
    this.resolvedBy,
    this.emailSentToIsange = false,
    this.emailSentAt,
  });

  factory BehaviorReport.fromJson(Map<String, dynamic> json) {
    return BehaviorReport(
      id: json['id'],
      reportedWorkerId: json['reported_worker_id'] ?? '',
      reportedWorkerName: json['reported_worker_name'] ?? '',
      reporterHouseholdId: json['reporter_household_id'] ?? '',
      reporterHouseholdName: json['reporter_household_name'] ?? '',
      incidentDescription: json['incident_description'] ?? '',
      severity: ReportSeverity.values.firstWhere(
        (e) => e.toString().split('.').last == (json['severity'] ?? 'medium'),
        orElse: () => ReportSeverity.medium,
      ),
      incidentDate: DateTime.parse(json['incident_date']),
      location: json['location'] ?? '',
      evidenceUrls: json['evidence_urls'] != null
          ? List<String>.from(json['evidence_urls'])
          : null,
      status: ReportStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] ?? 'pending'),
        orElse: () => ReportStatus.pending,
      ),
      reportedAt: DateTime.parse(json['reported_at']),
      adminNotes: json['admin_notes'],
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
      resolvedBy: json['resolved_by'],
      emailSentToIsange: json['email_sent_to_isange'] ?? false,
      emailSentAt: json['email_sent_at'] != null
          ? DateTime.parse(json['email_sent_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reported_worker_id': reportedWorkerId,
      'reported_worker_name': reportedWorkerName,
      'reporter_household_id': reporterHouseholdId,
      'reporter_household_name': reporterHouseholdName,
      'incident_description': incidentDescription,
      'severity': severity.toString().split('.').last,
      'incident_date': incidentDate.toIso8601String(),
      'location': location,
      'evidence_urls': evidenceUrls,
      'status': status.toString().split('.').last,
      'reported_at': reportedAt.toIso8601String(),
      'admin_notes': adminNotes,
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolved_by': resolvedBy,
      'email_sent_to_isange': emailSentToIsange,
      'email_sent_at': emailSentAt?.toIso8601String(),
    };
  }
}

enum ReportSeverity { low, medium, high, critical }

enum ReportStatus { pending, investigating, resolved, dismissed, escalated }

class FixMessage {
  final String? id;
  final String reporterId;
  final String reporterName;
  final UserRole reporterRole;
  final String title;
  final String description;
  final FixMessageType type;
  final FixMessagePriority priority;
  final FixMessageStatus status;
  final DateTime reportedAt;
  final String? assignedTo;
  final DateTime? assignedAt;
  final String? adminNotes;
  final DateTime? resolvedAt;
  final String? resolution;
  final List<String>? attachments;

  FixMessage({
    this.id,
    required this.reporterId,
    required this.reporterName,
    required this.reporterRole,
    required this.title,
    required this.description,
    required this.type,
    this.priority = FixMessagePriority.medium,
    this.status = FixMessageStatus.pending,
    required this.reportedAt,
    this.assignedTo,
    this.assignedAt,
    this.adminNotes,
    this.resolvedAt,
    this.resolution,
    this.attachments,
  });

  factory FixMessage.fromJson(Map<String, dynamic> json) {
    return FixMessage(
      id: json['id'],
      reporterId: json['reporter_id'] ?? '',
      reporterName: json['reporter_name'] ?? '',
      reporterRole: UserRole.values.firstWhere(
        (e) =>
            e.toString().split('.').last ==
            (json['reporter_role'] ?? 'house_holder'),
        orElse: () => UserRole.house_holder,
      ),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: FixMessageType.values.firstWhere(
        (e) => e.toString().split('.').last == (json['type'] ?? 'bug'),
        orElse: () => FixMessageType.bug,
      ),
      priority: FixMessagePriority.values.firstWhere(
        (e) => e.toString().split('.').last == (json['priority'] ?? 'medium'),
        orElse: () => FixMessagePriority.medium,
      ),
      status: FixMessageStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] ?? 'pending'),
        orElse: () => FixMessageStatus.pending,
      ),
      reportedAt: DateTime.parse(json['reported_at']),
      assignedTo: json['assigned_to'],
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'])
          : null,
      adminNotes: json['admin_notes'],
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
      resolution: json['resolution'],
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'reporter_name': reporterName,
      'reporter_role': reporterRole.toString().split('.').last,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'status': status.toString().split('.').last,
      'reported_at': reportedAt.toIso8601String(),
      'assigned_to': assignedTo,
      'assigned_at': assignedAt?.toIso8601String(),
      'admin_notes': adminNotes,
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolution': resolution,
      'attachments': attachments,
    };
  }
}

enum FixMessageType { bug, featureRequest, improvement, question, other }

enum FixMessagePriority { low, medium, high, urgent }

enum FixMessageStatus {
  pending,
  inProgress,
  resolved,
  dismissed,
  needsMoreInfo
}

class SystemSettings {
  final String? id;
  final String defaultLanguage;
  final double taxRate;
  final double serviceFeePercentage;
  final Map<String, dynamic> benefitsOptions;
  final Map<String, dynamic> notificationSettings;
  final Map<String, dynamic> paymentSettings;
  final DateTime lastUpdated;
  final String updatedBy;

  SystemSettings({
    this.id,
    this.defaultLanguage = 'en',
    this.taxRate = 0.18,
    this.serviceFeePercentage = 0.05,
    required this.benefitsOptions,
    required this.notificationSettings,
    required this.paymentSettings,
    required this.lastUpdated,
    required this.updatedBy,
  });

  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    return SystemSettings(
      id: json['id'],
      defaultLanguage: json['default_language'] ?? 'en',
      taxRate: (json['tax_rate'] ?? 0.18).toDouble(),
      serviceFeePercentage: (json['service_fee_percentage'] ?? 0.05).toDouble(),
      benefitsOptions: json['benefits_options'] ?? {},
      notificationSettings: json['notification_settings'] ?? {},
      paymentSettings: json['payment_settings'] ?? {},
      lastUpdated: DateTime.parse(json['last_updated']),
      updatedBy: json['updated_by'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'default_language': defaultLanguage,
      'tax_rate': taxRate,
      'service_fee_percentage': serviceFeePercentage,
      'benefits_options': benefitsOptions,
      'notification_settings': notificationSettings,
      'payment_settings': paymentSettings,
      'last_updated': lastUpdated.toIso8601String(),
      'updated_by': updatedBy,
    };
  }
}
