import 'dart:convert';
import 'package:football_admin_app/models/field_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';

class ApiService {
  final String baseUrl = "http://192.168.1.4:8000/api";
  final _box = Hive.box('offline_data'); // الصندوق اللي فتحناه في المين

  // ميثود مساعدة لجلب التوكن
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ميثود اللوجن (بدون كاش لأنها تحتاج سيرفر)
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Accept': 'application/json'},
        body: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['access_token']);
        return {'success': true, 'token': data['access_token']};
      } else {
        return {'success': false, 'message': 'بيانات الدخول غير صحيحة'};
      }
    } catch (e) {
      return {'success': false, 'message': 'تأكد من اتصالك بالسيرفر'};
    }
  }

  // جلب الملاعب مع الكاش (Hive)
  Future<List<Field>> getFields() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fields'),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // تحديث الكاش أول ما الداتا تيجي سليمة
        await _box.put('cached_fields', response.body);
        List jsonResponse = jsonDecode(response.body);
        return jsonResponse.map((data) => Field.fromJson(data)).toList();
      }
    } catch (e) {
      // لو مفيش نت، بص في Hive
      String? cached = _box.get('cached_fields');
      if (cached != null) {
        List jsonResponse = jsonDecode(cached);
        return jsonResponse.map((data) => Field.fromJson(data)).toList();
      }
    }
    return []; 
  }

  // جلب المواعيد المحجوزة مع الكاش (Hive)
  Future<Map<String, dynamic>> getOccupiedSlots(int fieldId, String date) async {
    String cacheKey = 'slots_${fieldId}_$date';
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/slots/available?field_id=$fieldId&date=$date'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        // تحديث كاش المواعيد لهذا التاريخ وهذا الملعب
        await _box.put(cacheKey, response.body);
        return jsonDecode(response.body);
      }
    } catch (e) {
      // لو مفيش نت، هات آخر مواعيد اتسحبت لليوم ده
      String? cached = _box.get(cacheKey);
      if (cached != null) {
        return jsonDecode(cached);
      }
    }
    return {"occupied_slots": []};
  }

  // إنشاء حجز (Post لا تدعم الكاش - لازم نت)
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) async {
    String? token = await _getToken();
    final url = '$baseUrl/admin/bookings';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    return jsonDecode(response.body);
  }

  // جلب كل الحجوزات مع الكاش
  Future<List<dynamic>> getBookings() async {
    String? token = await _getToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/bookings'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        await _box.put('all_admin_bookings', response.body);
        return jsonDecode(response.body);
      }
    } catch (e) {
      String? cached = _box.get('all_admin_bookings');
      if (cached != null) return jsonDecode(cached);
    }
    return [];
  }

  // حذف حجز
  Future<bool> deleteBooking(int id) async {
    String? token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/bookings/$id'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  // تعديل حجز
  Future<Map<String, dynamic>> updateBooking(int id, Map<String, dynamic> data) async {
    String? token = await _getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/admin/bookings/$id'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  // إضافة ملعب مع الأسعار
  Future<bool> addFieldWithPrices(Map<String, dynamic> data) async {
    String? token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/admin/fields'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return response.statusCode == 201;
  }

  // تعديل ملعب مع الأسعار
  Future<bool> updateFieldWithPrices(int id, Map<String, dynamic> data) async {
    String? token = await _getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/admin/fields/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  // حذف ملعب
  Future<bool> deleteField(int id) async {
    String? token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/fields/$id'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }
}