  // Flutterda uretilen sorguyu backend e yollar atrayıcıyıda acar

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';

class ApiService {
  Future<void> googleAra({required String sorgu}) async {
    final payload = {'sorgu': sorgu};

    final res = await http
        .post(
          Uri.parse('$kBackendUrl/api/ara'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 10));

    Map<String, dynamic>? json;
    try {
      json = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}

    if (res.statusCode != 200) {
      final mesaj = json?['mesaj']?.toString();
      throw Exception(mesaj ?? 'HTTP ${res.statusCode}');
    }

    if (json != null && json['basarili'] == false) {
      throw Exception(json['mesaj']?.toString() ?? 'Arama basarisiz');
    }
  }
}
