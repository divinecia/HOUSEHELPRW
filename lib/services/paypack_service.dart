import 'dart:convert';
import 'package:http/http.dart' as http;

class PaypackService {
  // Replace with your actual Paypack credentials
  static const String _baseUrl = 'https://payments.paypack.rw';
  static const String _clientId = 'YOUR_PAYPACK_CLIENT_ID';
  static const String _clientSecret = 'YOUR_PAYPACK_CLIENT_SECRET';

  static String? _accessToken;
  static DateTime? _tokenExpiry;

  // Get access token
  static Future<String?> _getAccessToken() async {
    // Check if token is still valid
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/agents/authorize'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'client_id': _clientId,
          'client_secret': _clientSecret,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        // Assume token expires in 1 hour (adjust based on Paypack documentation)
        _tokenExpiry = DateTime.now().add(const Duration(hours: 1));
        return _accessToken;
      } else {
        print('Failed to get access token: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting access token: $e');
      return null;
    }
  }

  // Initiate payment
  static Future<Map<String, dynamic>?> initiatePayment({
    required double amount,
    required String phoneNumber,
    required String description,
    String? webhookUrl,
  }) async {
    final token = await _getAccessToken();
    if (token == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/transactions/cashin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
          'number': phoneNumber,
          'environment': 'development', // Change to 'production' for live
          'webhook_url': webhookUrl,
          'description': description,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print('Failed to initiate payment: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error initiating payment: $e');
      return null;
    }
  }

  // Check transaction status
  static Future<Map<String, dynamic>?> checkTransactionStatus(
      String transactionId) async {
    final token = await _getAccessToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/transactions/$transactionId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to check transaction status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error checking transaction status: $e');
      return null;
    }
  }

  // Get transaction history
  static Future<List<Map<String, dynamic>>?> getTransactionHistory({
    int offset = 0,
    int limit = 20,
  }) async {
    final token = await _getAccessToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/transactions?offset=$offset&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        print('Failed to get transaction history: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting transaction history: $e');
      return null;
    }
  }
}
