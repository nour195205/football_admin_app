import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/field_model.dart';

class ManageFieldsScreen extends StatefulWidget {
  const ManageFieldsScreen({super.key});

  @override
  State<ManageFieldsScreen> createState() => _ManageFieldsScreenState();
}

class _ManageFieldsScreenState extends State<ManageFieldsScreen> {
  final ApiService _apiService = ApiService();

  // ميثود لاختيار الوقت باستخدام الساعة
  Future<void> _selectTime(BuildContext context, TextEditingController controller, StateSetter setModalState) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.green),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setModalState(() {
        final hour = picked.hour.toString().padLeft(2, '0');
        final minute = picked.minute.toString().padLeft(2, '0');
        controller.text = "$hour:$minute";
      });
    }
  }

  void _showFieldDialog({Field? field}) {
    final nameController = TextEditingController(text: field?.name ?? "");
    
    // قائمة الفترات للتحكم فيها ديناميكياً
    List<Map<String, TextEditingController>> periodControllers = [
      {
        "label": TextEditingController(text: "صباحي"),
        "from": TextEditingController(text: "08:00"),
        "to": TextEditingController(text: "16:00"),
        "price": TextEditingController(text: "100"),
      }
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(field == null ? "إضافة ملعب جديد" : "تعديل الملعب"),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController, 
                    decoration: const InputDecoration(labelText: "اسم الملعب", border: OutlineInputBorder())
                  ),
                  const SizedBox(height: 20),
                  const Text("إعدادات فترات الأسعار", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  const Divider(),
                  
                  ...periodControllers.asMap().entries.map((entry) {
                    int index = entry.key;
                    var controllers = entry.value;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: Colors.grey[50],
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: TextField(controller: controllers['label'], decoration: const InputDecoration(labelText: "اسم الفترة (مثلاً: سهرة)"))),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => setModalState(() => periodControllers.removeAt(index)),
                                )
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                // اختيار وقت البداية
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectTime(context, controllers['from']!, setModalState),
                                    child: IgnorePointer(
                                      child: TextField(
                                        controller: controllers['from'],
                                        decoration: const InputDecoration(labelText: "من", suffixIcon: Icon(Icons.access_time)),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // اختيار وقت النهاية
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectTime(context, controllers['to']!, setModalState),
                                    child: IgnorePointer(
                                      child: TextField(
                                        controller: controllers['to'],
                                        decoration: const InputDecoration(labelText: "إلى", suffixIcon: Icon(Icons.access_time)),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // السعر
                                Expanded(
                                  child: TextField(
                                    controller: controllers['price'], 
                                    decoration: const InputDecoration(labelText: "السعر"),
                                    keyboardType: TextInputType.number
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),

                  TextButton.icon(
                    onPressed: () {
                      setModalState(() {
                        periodControllers.add({
                          "label": TextEditingController(),
                          "from": TextEditingController(),
                          "to": TextEditingController(),
                          "price": TextEditingController(),
                        });
                      });
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text("إضافة فترة سعرية"),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                List<Map<String, dynamic>> prices = periodControllers.map((p) => {
                  "label": p['label']!.text,
                  "from": p['from']!.text,
                  "to": p['to']!.text,
                  "price": p['price']!.text,
                }).toList();

                Map<String, dynamic> data = {
                  "name": nameController.text,
                  "prices": prices,
                };

                // استدعاء ميثود الحفظ من الـ ApiService
                bool success = field == null 
                  ? await _apiService.addFieldWithPrices(data)
                  : await _apiService.updateFieldWithPrices(field.id, data);

                if (success) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم حفظ الملعب والأسعار بنجاح")));
                }
              },
              child: const Text("حفظ الكل", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إدارة الملاعب والأسعار"), backgroundColor: Colors.green),
      body: FutureBuilder<List<Field>>(
        future: _apiService.getFields(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("لا توجد ملاعب مضافة"));
          
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final field = snapshot.data![index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.stadium, color: Colors.white)),
                  title: Text(field.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("اضغط لتعديل الأسعار أو المواعيد"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showFieldDialog(field: field)),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red), 
                        onPressed: () async {
                          bool ok = await _apiService.deleteField(field.id);
                          if (ok) setState(() {});
                        }
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFieldDialog(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}