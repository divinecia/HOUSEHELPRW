import '../models/hire_request.dart';

class HireRequestService {
  static final HireRequestService _instance = HireRequestService._internal();
  factory HireRequestService() => _instance;
  HireRequestService._internal();

  // Sample data for demonstration
  final List<HireRequest> _sampleRequests = [
    HireRequest(
      id: '1',
      helperUid: '1',
      helperName: 'Alice Johnson',
      employerUid: 'emp1',
      employerName: 'John Doe',
      serviceType: 'House Cleaning',
      description: 'Weekly house cleaning service',
      startDate: DateTime.now().add(const Duration(days: 1)),
      hourlyRate: 1500.0,
      estimatedHours: 4,
      totalAmount: 6000.0,
      status: HireStatus.pending,
      location: 'Kigali, Gasabo',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    HireRequest(
      id: '2',
      helperUid: '2',
      helperName: 'Bob Smith',
      employerUid: 'emp2',
      employerName: 'Jane Smith',
      serviceType: 'Cooking',
      description: 'Daily cooking service for family',
      startDate: DateTime.now().add(const Duration(days: 3)),
      hourlyRate: 2000.0,
      estimatedHours: 3,
      totalAmount: 6000.0,
      status: HireStatus.accepted,
      location: 'Kigali, Nyarugenge',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  Future<List<HireRequest>> getAllRequests() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _sampleRequests;
  }

  Future<List<HireRequest>> getRequestsForHelper(String helperUid) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _sampleRequests
        .where((request) => request.helperUid == helperUid)
        .toList();
  }

  Future<List<HireRequest>> getRequestsForEmployer(String employerUid) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _sampleRequests
        .where((request) => request.employerUid == employerUid)
        .toList();
  }

  Future<HireRequest?> getRequestById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));

    try {
      return _sampleRequests.firstWhere((request) => request.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<bool> createRequest(HireRequest request) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _sampleRequests.add(request);
    return true;
  }

  Future<bool> updateRequestStatus(String id, HireStatus status) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _sampleRequests.indexWhere((request) => request.id == id);
    if (index != -1) {
      final request = _sampleRequests[index];
      final updatedRequest = HireRequest(
        id: request.id,
        helperUid: request.helperUid,
        helperName: request.helperName,
        employerUid: request.employerUid,
        employerName: request.employerName,
        serviceType: request.serviceType,
        description: request.description,
        startDate: request.startDate,
        endDate: request.endDate,
        hourlyRate: request.hourlyRate,
        estimatedHours: request.estimatedHours,
        totalAmount: request.totalAmount,
        status: status,
        location: request.location,
        createdAt: request.createdAt,
        updatedAt: DateTime.now(),
        notes: request.notes,
      );
      _sampleRequests[index] = updatedRequest;
      return true;
    }
    return false;
  }

  Future<bool> deleteRequest(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _sampleRequests.indexWhere((request) => request.id == id);
    if (index != -1) {
      _sampleRequests.removeAt(index);
      return true;
    }
    return false;
  }

  Stream<List<HireRequest>> getAllHireRequestsStream() {
    // Return a stream that emits the sample data
    return Stream.periodic(const Duration(seconds: 1), (int index) {
      return _sampleRequests;
    });
  }

  Future<bool> updateHireRequestStatus(String id, HireStatus status) async {
    return await updateRequestStatus(id, status);
  }

  Future<bool> deleteHireRequest(String id) async {
    return await deleteRequest(id);
  }

  Future<List<HireRequest>> getTodaysHireRequests(String helperUid) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final today = DateTime.now();
    return _sampleRequests
        .where((request) =>
            request.helperUid == helperUid &&
            request.startDate.year == today.year &&
            request.startDate.month == today.month &&
            request.startDate.day == today.day)
        .toList();
  }

  Future<List<HireRequest>> getUpcomingHireRequests(String helperUid) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final today = DateTime.now();
    return _sampleRequests
        .where((request) =>
            request.helperUid == helperUid && request.startDate.isAfter(today))
        .toList();
  }

  Future<Map<String, List<HireRequest>>> getHireRequestsGroupedByDate(
      String helperUid) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final Map<String, List<HireRequest>> grouped = {};

    for (final request
        in _sampleRequests.where((r) => r.helperUid == helperUid)) {
      final dateKey =
          '${request.startDate.year}-${request.startDate.month}-${request.startDate.day}';
      grouped.putIfAbsent(dateKey, () => []).add(request);
    }

    return grouped;
  }
}
