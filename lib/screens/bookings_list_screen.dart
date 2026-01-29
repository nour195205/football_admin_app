import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BookingsListScreen extends StatefulWidget {
  const BookingsListScreen({super.key});

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen> {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل الحجوزات'), backgroundColor: Colors.green),
      body: FutureBuilder<List<dynamic>>(
        future: _apiService.getBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('لا توجد حجوزات حالياً'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final booking = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text("العميل: ${booking['user_name']}"),
                    subtitle: Text("التاريخ: ${booking['booking_date']} | الساعة: ${booking['start_time']}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(booking['id']),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح الحجز؟'),
        content: const Text('هل أنت متأكد من إلغاء هذا الحجز؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              bool success = await _apiService.deleteBooking(id);
              if (success) {
                Navigator.pop(context);
                setState(() {}); // تحديث الصفحة
              }
            },
            child: const Text('تأكيد المسح', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}