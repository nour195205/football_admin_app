import 'dart:convert';
import 'package:football_admin_app/models/field_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // غير الـ IP ده للـ IP بتاعك
  final String baseUrl = "http://192.168.1.4:8000/api";

  // ميثود اللوجن
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Accept': 'application/json'},
        body: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        // حفظ التوكن في الجهاز
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['access_token']);
        return {'success': true, 'token': data['access_token']};
      } else {
        return {'success': false, 'message': 'بيانات الدخول غير صحيحة'};
      }
    } catch (e) {
      return {'success': false, 'message': 'تأكد من اتصالك بالسيرفر: $e'};
    }
  }

Future<List<Field>> getFields() async {
  final response = await http.get(
    Uri.parse('$baseUrl/fields'), // تأكد إن الـ baseUrl أخره /api ومفيش slash زيادة
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    List jsonResponse = jsonDecode(response.body);
    return jsonResponse.map((data) => Field.fromJson(data)).toList();
  } else {
    throw Exception('فشل في تحميل الملاعب');
  }
}

Future<Map<String, dynamic>> getOccupiedSlots(int fieldId, String date) async {
  final response = await http.get(
    Uri.parse('$baseUrl/slots/available?field_id=$fieldId&date=$date'),
    headers: {'Accept': 'application/json'},
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('فشل في تحميل المواعيد');
  }
}

Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');

  // ركز في السطر ده، شيلنا السلاش اللي قبل bookings لو كان الـ baseUrl آخره سلاش
  final url = baseUrl.endsWith('/') ? '${baseUrl}bookings' : '$baseUrl/admin/bookings';

  final response = await http.post(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json', 
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(data),
  );

  // اطبع الرد عشان لو فيه مشكلة في الداتا نعرفها
  print("Response Code: ${response.statusCode}");
  print("Response Body: ${response.body}");

  // فك التشفير وارجاع الخريطة
  return jsonDecode(response.body);
}




// جلب كل الحجوزات
Future<List<dynamic>> getBookings() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');

  final response = await http.get(
    Uri.parse('$baseUrl/admin/bookings'),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('فشل في تحميل قائمة الحجوزات');
  }
}

// حذف حجز
Future<bool> deleteBooking(int id) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');

  final response = await http.delete(
    Uri.parse('$baseUrl/admin/bookings/$id'),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  return response.statusCode == 200;
}

Future<Map<String, dynamic>> updateBooking(int id, Map<String, dynamic> data) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');

  final response = await http.put(
    Uri.parse('$baseUrl/admin/bookings/$id'),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: data.map((key, value) => MapEntry(key, value.toString())),
  );

  return jsonDecode(response.body);
}

// إضافة ملعب جديد
Future<bool> addField(String name) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');

  final response = await http.post(
    Uri.parse('$baseUrl/admin/fields'),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: {'name': name},
  );
  return response.statusCode == 201 || response.statusCode == 200;
}

// حذف ملعب
Future<bool> deleteField(int id) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');

  final response = await http.delete(
    Uri.parse('$baseUrl/admin/fields/$id'), // تأكد من وجود الروت ده في Laravel
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  return response.statusCode == 200;
}

// في api_service.dart
Future<bool> updateField(int id, String newName) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');

  final response = await http.put(
    Uri.parse('$baseUrl/admin/fields/$id'),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: {'name': newName},
  );
  return response.statusCode == 200;
}

// إضافة ملعب مع أسعاره
Future<bool> addFieldWithPrices(Map<String, dynamic> data) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');

  final response = await http.post(
    Uri.parse('$baseUrl/admin/fields'),
    headers: {
      'Content-Type': 'application/json', // ضروري جداً
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(data), // تحويل الـ Map لـ JSON String
  );
  return response.statusCode == 201;
}


// تعديل ملعب مع أسعاره
Future<bool> updateFieldWithPrices(int id, Map<String, dynamic> data) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');

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








}