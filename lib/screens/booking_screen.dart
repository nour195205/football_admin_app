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

  // ميثود تحويل الساعة لنظام 12 ساعة AM/PM للعرض فقط
  String _formatTime12H(int hour) {
    final DateTime tempDate = DateTime(2026, 1, 1, hour);
    return DateFormat('h:mm a').format(tempDate);
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
      _showSnackBar("خطأ في الاتصال بالسيرفر", Colors.red);
      setState(() => _isLoading = false);
    }
  }

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
            title: const Text("إلغاء الحجز"),
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

  void _showEditDialog(dynamic booking) {
    final nameController = TextEditingController(text: booking['user_name']?.toString());
    final depositController = TextEditingController(text: booking['deposit']?.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تعديل الحجز"),
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

  void _showBookingDialog(int hour) {
    final nameController = TextEditingController();
    final depositController = TextEditingController(text: "0");
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
              Text("حجز جديد - ${_formatTime12H(hour)}", 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 10),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "اسم الزبون", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: depositController, decoration: const InputDecoration(labelText: "العربون", border: OutlineInputBorder()), keyboardType: TextInputType.number),
              CheckboxListTile(
                title: const Text("حجز ثابت؟ (أسبوعياً)"),
                value: isConstant,
                activeColor: Colors.green,
                onChanged: (val) => setModalState(() => isConstant = val!),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty) {
                    _showSnackBar("يرجى كتابة اسم الزبون", Colors.orange);
                    return;
                  }

                  // نداء الـ API واستقبال الـ Map
                  final res = await _apiService.createBooking({
                    "field_id": widget.fieldId,
                    "user_name": nameController.text,
                    "start_time": "${hour.toString().padLeft(2, '0')}:00",
                    "end_time": "${((hour + 1) % 24).toString().padLeft(2, '0')}:00",
                    "booking_date": DateFormat('yyyy-MM-dd').format(_selectedDate),
                    "is_constant": isConstant ? 1 : 0,
                    "deposit": depositController.text,
                  });

                  // فحص الحالة القادمة من الباك إند
                  if (res['status'] == 'success') {
                    Navigator.pop(context);
                    _loadSlots();
                    _showSnackBar(res['message'] ?? "تم الحجز بنجاح", Colors.green);
                  } else {
                    // في حالة وجود حجز مسبق (الرسالة التي كتبناها في Laravel)
                    _showSnackBar(res['message'] ?? "فشل الحجز", Colors.red);
                    _loadSlots(); // تحديث المربعات
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50)),
                child: const Text("تأكيد الحجز", style: TextStyle(color: Colors.white, fontSize: 16)),
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
      _showSnackBar("تم إلغاء الحجز", Colors.green);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fieldName),
        backgroundColor: Colors.green,
        actions: [IconButton(onPressed: _loadSlots, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          // اختيار التاريخ
          InkWell(
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
                _loadSlots();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_month, color: Colors.green),
                  const SizedBox(width: 10),
                  Text(
                    "التاريخ: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          
          // عرض المربعات (24 ساعة)
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.green))
              : GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                    crossAxisSpacing: 10, 
                    mainAxisSpacing: 10, 
                    childAspectRatio: 1.4
                  ),
                  itemCount: 24, // يوم كامل
                  itemBuilder: (context, index) {
                    int hour = index;
                    String timeStr = "${hour.toString().padLeft(2, '0')}:00:00";
                    
                    var booking = _occupiedSlots.firstWhere(
                      (s) => s['start_time'] == timeStr, 
                      orElse: () => null
                    );
                    bool isOccupied = booking != null;

                    return GestureDetector(
                      onTap: () => isOccupied ? _showOptionsDialog(booking) : _showBookingDialog(hour),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isOccupied ? Colors.red[400] : Colors.green[400],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatTime12H(hour), // نظام AM/PM
                              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)
                            ),
                            if (isOccupied) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  booking['user_name']?.toString() ?? "ثابت", 
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              Text("عربون: ${booking['deposit']}", style: const TextStyle(color: Colors.white70, fontSize: 10)),
                            ] else ...[
                              const Text("متاح", style: TextStyle(color: Colors.white70, fontSize: 13)),
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