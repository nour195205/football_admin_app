import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/field_model.dart';
import 'booking_screen.dart';
import 'bookings_list_screen.dart';
import 'manage_fields_screen.dart'; // الملف الجديد اللي عملته
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        backgroundColor: Colors.green,
        centerTitle: true,
        actions: [
          // زرار إدارة الملاعب (التعديل والحذف والإضافة)
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageFieldsScreen()),
              ).then((_) => setState(() {})); // عشان يحدث الداتا لما ترجع
            },
            tooltip: 'إدارة الملاعب',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              "اختر الملعب لإدارة المواعيد",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Field>>(
              future: _apiService.getFields(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.green));
                } else if (snapshot.hasError) {
                  return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('لا توجد ملاعب حالياً. ضيف ملعب من الإعدادات.'));
                } else {
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.85,
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
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.green,
                                child: Icon(Icons.sports_soccer, color: Colors.white, size: 35),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                field.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text("عرض الجدول", style: TextStyle(color: Colors.grey)),
                            ],
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
      // زرار سريع لمشاهدة كل الحجوزات المسجلة
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BookingsListScreen()),
          );
        },
        backgroundColor: Colors.green,
        icon: const Icon(Icons.list_alt, color: Colors.white),
        label: const Text("كل الحجوزات", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}