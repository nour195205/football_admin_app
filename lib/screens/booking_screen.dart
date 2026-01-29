import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  final int fieldId;
  final String fieldName;

  const BookingScreen({super.key, required this.fieldId, required this.fieldName});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final ApiService _apiService = ApiService();
  DateTime _selectedDate = DateTime.now();
  List<dynamic> _occupiedSlots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() => _isLoading = true);
    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    try {
      final data = await _apiService.getOccupiedSlots(widget.fieldId, formattedDate);
      setState(() {
        _occupiedSlots = data['occupied_slots'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      _showSnackBar("خطأ في التحميل: $e", Colors.red);
      setState(() => _isLoading = false);
    }
  }

  // 1. نافذة خيارات الحجز المحجوز (تعديل أو حذف)
  void _showOptionsDialog(dynamic booking) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text("تعديل بيانات الحجز"),
            onTap: () {
              Navigator.pop(context);
              _showEditDialog(booking);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text("إلغاء الحجز نهائياً"),
            onTap: () async {
              Navigator.pop(context);
              _confirmDelete(booking['id']);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 2. نافذة التعديل
  void _showEditDialog(dynamic booking) {
    final TextEditingController nameController = TextEditingController(text: booking['user_name']?.toString());
    final TextEditingController depositController = TextEditingController(text: booking['deposit']?.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تعديل البيانات"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "اسم العميل")),
            TextField(controller: depositController, decoration: const InputDecoration(labelText: "العربون"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () async {
              final res = await _apiService.updateBooking(booking['id'], {
                "user_name": nameController.text,
                "deposit": depositController.text,
              });
              Navigator.pop(context);
              _loadSlots();
              _showSnackBar(res['message'] ?? "تم التعديل", Colors.blue);
            },
            child: const Text("حفظ"),
          ),
        ],
      ),
    );
  }

  // 3. نافذة حجز جديد
  void _showBookingDialog(int hour) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController depositController = TextEditingController(text: "0");
    bool isConstant = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("حجز جديد - $hour:00", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "اسم الزبون")),
              TextField(controller: depositController, decoration: const InputDecoration(labelText: "العربون"), keyboardType: TextInputType.number),
              CheckboxListTile(
                title: const Text("حجز ثابت أسبوعياً؟"),
                value: isConstant,
                onChanged: (val) => setModalState(() => isConstant = val!),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _apiService.createBooking({
                    "field_id": widget.fieldId,
                    "user_name": nameController.text,
                    "start_time": "${hour.toString().padLeft(2, '0')}:00",
                    "end_time": "${(hour + 1).toString().padLeft(2, '0')}:00",
                    "booking_date": DateFormat('yyyy-MM-dd').format(_selectedDate),
                    "is_constant": isConstant ? 1 : 0,
                    "deposit": depositController.text,
                  });
                  Navigator.pop(context);
                  _loadSlots();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50)),
                child: const Text("تأكيد الحجز", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(int id) async {
    bool success = await _apiService.deleteBooking(id);
    if (success) {
      _loadSlots();
      _showSnackBar("تم الحذف بنجاح", Colors.green);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.fieldName), backgroundColor: Colors.green),
      body: Column(
        children: [
          ListTile(
            tileColor: Colors.green.withOpacity(0.1),
            title: Text("التاريخ: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}"),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now().subtract(const Duration(days: 30)), lastDate: DateTime(2030));
              if (picked != null) { setState(() => _selectedDate = picked); _loadSlots(); }
            },
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.4),
                  itemCount: 16,
                  itemBuilder: (context, index) {
                    int hour = index + 8;
                    String timeStr = "${hour.toString().padLeft(2, '0')}:00:00";
                    var booking = _occupiedSlots.firstWhere((s) => s['start_time'] == timeStr, orElse: () => null);
                    bool isOccupied = booking != null;

                    return GestureDetector(
                      onTap: () => isOccupied ? _showOptionsDialog(booking) : _showBookingDialog(hour),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isOccupied ? Colors.red.shade400 : Colors.green.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("$hour:00", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            if (isOccupied) ...[
                              Text(booking['user_name']?.toString() ?? "بدون اسم", style: const TextStyle(color: Colors.white, fontSize: 12)),
                              Text("عربون: ${booking['deposit']?.toString() ?? '0'}", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}