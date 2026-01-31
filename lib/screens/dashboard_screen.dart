import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/field_model.dart';
import 'booking_screen.dart';
import 'bookings_list_screen.dart';
import 'manage_fields_screen.dart';
import 'user_management_screen.dart'; // استيراد شاشة إدارة المستخدمين
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();

  // ميثود تسجيل الخروج
  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('لوحة التحكم - المدير'),
        backgroundColor: Colors.green,
        elevation: 0,
        centerTitle: true,
        actions: [
          // أيقونة إدارة المستخدمين (إضافة/تغيير صلاحيات)
          IconButton(
            icon: const Icon(Icons.people_alt_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserManagementScreen()),
              );
            },
            tooltip: 'إدارة المستخدمين',
          ),
          // زرار إعدادات الملاعب
          IconButton(
            icon: const Icon(Icons.app_registration_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageFieldsScreen()),
              ).then((_) => setState(() {}));
            },
            tooltip: 'إدارة الملاعب',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الجزء العلوي الترحيبي
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Center(
              child: Text(
                "سانتياجو",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromARGB(221, 66, 167, 96)),
              ),
            ),
          ),
          
          Expanded(
            child: FutureBuilder<List<Field>>(
              future: _apiService.getFields(), // بيجيب من Hive لو مفيش نت
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.green));
                } else if (snapshot.hasError) {
                  return Center(child: Text('خطأ في الاتصال: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sports_soccer, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 10),
                        const Text('لا توجد ملاعب مضافة حالياً'),
                      ],
                    ),
                  );
                } else {
                  return GridView.builder(
                    padding: const EdgeInsets.all(15),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final field = snapshot.data![index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookingScreen(
                                fieldId: field.id,
                                fieldName: field.name,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 4,
                          shadowColor: Colors.black26,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [Colors.white, Colors.green.withOpacity(0.05)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.stadium_outlined, color: Colors.green, size: 50),
                                const SizedBox(height: 10),
                                Text(
                                  field.name,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    "إدارة الجدول",
                                    style: TextStyle(color: Colors.green, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BookingsListScreen()),
          );
        },
        backgroundColor: Colors.green,
        elevation: 6,
        icon: const Icon(Icons.history_rounded, color: Colors.white),
        label: const Text("كل الحجوزات", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}