class Payment {
  final String id;
  final String transactionId;
  final double amount;
  final String currency;
  final String phoneNumber;
  final String description;
  final String status; // pending, completed, failed, cancelled
  final String paymentMethod; // mobile_money, card, etc.
  final String? hireRequestId;
  final String? houseHelperId;
  final String? houseHolderId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;

  Payment({
    required this.id,
    required this.transactionId,
    required this.amount,
    required this.currency,
    required this.phoneNumber,
    required this.description,
    required this.status,
    required this.paymentMethod,
    this.hireRequestId,
    this.houseHelperId,
    this.houseHolderId,
    required this.createdAt,
    this.completedAt,
    this.metadata,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? '',
      transactionId: json['transaction_id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'RWF',
      phoneNumber: json['phone_number'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      paymentMethod: json['payment_method'] ?? 'mobile_money',
      hireRequestId: json['hire_request_id'],
      houseHelperId: json['house_helper_id'],
      houseHolderId: json['house_holder_id'],
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'amount': amount,
      'currency': currency,
      'phone_number': phoneNumber,
      'description': description,
      'status': status,
      'payment_method': paymentMethod,
      'hire_request_id': hireRequestId,
      'house_helper_id': houseHelperId,
      'house_holder_id': houseHolderId,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  Payment copyWith({
    String? id,
    String? transactionId,
    double? amount,
    String? currency,
    String? phoneNumber,
    String? description,
    String? status,
    String? paymentMethod,
    String? hireRequestId,
    String? houseHelperId,
    String? houseHolderId,
    DateTime? createdAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Payment(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      description: description ?? this.description,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      hireRequestId: hireRequestId ?? this.hireRequestId,
      houseHelperId: houseHelperId ?? this.houseHelperId,
      houseHolderId: houseHolderId ?? this.houseHolderId,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isCancelled => status == 'cancelled';
}
