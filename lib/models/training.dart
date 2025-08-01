class Training {
  final String? id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final bool isMandatory;
  final bool isPaid;
  final double? cost;
  final int maxParticipants;
  final String instructorId;
  final String instructorName;
  final TrainingStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String>? prerequisites;
  final String? category;

  Training({
    this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.location,
    this.isMandatory = false,
    this.isPaid = false,
    this.cost,
    this.maxParticipants = 20,
    required this.instructorId,
    required this.instructorName,
    this.status = TrainingStatus.scheduled,
    required this.createdAt,
    this.updatedAt,
    this.prerequisites,
    this.category,
  });

  factory Training.fromJson(Map<String, dynamic> json) {
    return Training(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      location: json['location'] ?? '',
      isMandatory: json['is_mandatory'] ?? false,
      isPaid: json['is_paid'] ?? false,
      cost: json['cost']?.toDouble(),
      maxParticipants: json['max_participants'] ?? 20,
      instructorId: json['instructor_id'] ?? '',
      instructorName: json['instructor_name'] ?? '',
      status: TrainingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] ?? 'scheduled'),
        orElse: () => TrainingStatus.scheduled,
      ),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      prerequisites: json['prerequisites'] != null
          ? List<String>.from(json['prerequisites'])
          : null,
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'location': location,
      'is_mandatory': isMandatory,
      'is_paid': isPaid,
      'cost': cost,
      'max_participants': maxParticipants,
      'instructor_id': instructorId,
      'instructor_name': instructorName,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'prerequisites': prerequisites,
      'category': category,
    };
  }

  Training copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    bool? isMandatory,
    bool? isPaid,
    double? cost,
    int? maxParticipants,
    String? instructorId,
    String? instructorName,
    TrainingStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? prerequisites,
    String? category,
  }) {
    return Training(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      isMandatory: isMandatory ?? this.isMandatory,
      isPaid: isPaid ?? this.isPaid,
      cost: cost ?? this.cost,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      instructorId: instructorId ?? this.instructorId,
      instructorName: instructorName ?? this.instructorName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      prerequisites: prerequisites ?? this.prerequisites,
      category: category ?? this.category,
    );
  }
}

enum TrainingStatus { scheduled, inProgress, completed, cancelled, postponed }

class TrainingParticipation {
  final String? id;
  final String trainingId;
  final String workerId;
  final String workerName;
  final DateTime requestedAt;
  final ParticipationStatus status;
  final DateTime? completedAt;
  final double? score;
  final bool? certificateIssued;
  final String? feedback;
  final bool paymentRequired;
  final bool paymentCompleted;
  final String? paymentId;

  TrainingParticipation({
    this.id,
    required this.trainingId,
    required this.workerId,
    required this.workerName,
    required this.requestedAt,
    this.status = ParticipationStatus.requested,
    this.completedAt,
    this.score,
    this.certificateIssued,
    this.feedback,
    this.paymentRequired = false,
    this.paymentCompleted = false,
    this.paymentId,
  });

  factory TrainingParticipation.fromJson(Map<String, dynamic> json) {
    return TrainingParticipation(
      id: json['id'],
      trainingId: json['training_id'] ?? '',
      workerId: json['worker_id'] ?? '',
      workerName: json['worker_name'] ?? '',
      requestedAt: DateTime.parse(json['requested_at']),
      status: ParticipationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] ?? 'requested'),
        orElse: () => ParticipationStatus.requested,
      ),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      score: json['score']?.toDouble(),
      certificateIssued: json['certificate_issued'],
      feedback: json['feedback'],
      paymentRequired: json['payment_required'] ?? false,
      paymentCompleted: json['payment_completed'] ?? false,
      paymentId: json['payment_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'training_id': trainingId,
      'worker_id': workerId,
      'worker_name': workerName,
      'requested_at': requestedAt.toIso8601String(),
      'status': status.toString().split('.').last,
      'completed_at': completedAt?.toIso8601String(),
      'score': score,
      'certificate_issued': certificateIssued,
      'feedback': feedback,
      'payment_required': paymentRequired,
      'payment_completed': paymentCompleted,
      'payment_id': paymentId,
    };
  }
}

enum ParticipationStatus {
  requested,
  approved,
  rejected,
  inProgress,
  completed,
  failed,
  cancelled
}
