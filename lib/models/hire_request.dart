enum HireStatus {
  pending,
  accepted,
  ongoing,
  completed,
  cancelled,
  rejected,
  finished,
  canceled
}

class HireRequest {
  final String id;
  final String helperUid;
  final String helperName;
  final String employerUid;
  final String employerName;
  final String serviceType;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final double hourlyRate;
  final int estimatedHours;
  final double totalAmount;
  final HireStatus status;
  final String location;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;
  final String startTime;
  final int hoursPerDay;
  final List<String> activities;
  final String workAddress;
  final String helperPhone;
  final String employerPhone;

  HireRequest({
    required this.id,
    required this.helperUid,
    required this.helperName,
    required this.employerUid,
    required this.employerName,
    required this.serviceType,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.hourlyRate,
    required this.estimatedHours,
    required this.totalAmount,
    required this.status,
    required this.location,
    required this.createdAt,
    this.updatedAt,
    this.notes,
    this.startTime = '09:00',
    this.hoursPerDay = 8,
    this.activities = const [],
    this.workAddress = '',
    this.helperPhone = '',
    this.employerPhone = '',
  });

  String get statusDisplayText {
    switch (status) {
      case HireStatus.pending:
        return 'Pending';
      case HireStatus.accepted:
        return 'Accepted';
      case HireStatus.ongoing:
        return 'In Progress';
      case HireStatus.completed:
      case HireStatus.finished:
        return 'Completed';
      case HireStatus.cancelled:
      case HireStatus.canceled:
        return 'Cancelled';
      case HireStatus.rejected:
        return 'Rejected';
    }
  }

  factory HireRequest.fromMap(Map<String, dynamic> map) {
    return HireRequest(
      id: map['id'] ?? '',
      helperUid: map['helperUid'] ?? '',
      helperName: map['helperName'] ?? '',
      employerUid: map['employerUid'] ?? '',
      employerName: map['employerName'] ?? '',
      serviceType: map['serviceType'] ?? '',
      description: map['description'] ?? '',
      startDate: DateTime.tryParse(map['startDate'] ?? '') ?? DateTime.now(),
      endDate:
          map['endDate'] != null ? DateTime.tryParse(map['endDate']) : null,
      hourlyRate: (map['hourlyRate'] ?? 0).toDouble(),
      estimatedHours: map['estimatedHours'] ?? 0,
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      status: HireStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => HireStatus.pending,
      ),
      location: map['location'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt:
          map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
      notes: map['notes'],
      startTime: map['startTime'] ?? '09:00',
      hoursPerDay: map['hoursPerDay'] ?? 8,
      activities: List<String>.from(map['activities'] ?? []),
      workAddress: map['workAddress'] ?? '',
      helperPhone: map['helperPhone'] ?? '',
      employerPhone: map['employerPhone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'helperUid': helperUid,
      'helperName': helperName,
      'employerUid': employerUid,
      'employerName': employerName,
      'serviceType': serviceType,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'hourlyRate': hourlyRate,
      'estimatedHours': estimatedHours,
      'totalAmount': totalAmount,
      'status': status.toString().split('.').last,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'notes': notes,
      'startTime': startTime,
      'hoursPerDay': hoursPerDay,
      'activities': activities,
      'workAddress': workAddress,
      'helperPhone': helperPhone,
      'employerPhone': employerPhone,
    };
  }
}
