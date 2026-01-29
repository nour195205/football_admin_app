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

  // ميثود لإظهار نافذة إضافة/تعديل الملعب مع فترات متغيرة
  void _showFieldDialog({Field? field}) {
    final nameController = TextEditingController(text: field?.name ?? "");
    
    // قائمة الفترات: كل عنصر عبارة عن Controllers للتحكم في الداتا
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
      builder: (context) => StatefulBuilder( // مهم عشان نحدث القائمة جوه الـ Dialog
        builder: (context, setModalState) => AlertDialog(
          title: Text(field == null ? "إضافة ملعب وفترات" : "تعديل الملعب"),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: "اسم الملعب")),
                  const Divider(),
                  const Text("فترات الأسعار", style: TextStyle(fontWeight: FontWeight.bold)),
                  
                  // عرض الفترات المضافة حالياً
                  ...periodControllers.asMap().entries.map((entry) {
                    int index = entry.key;
                    var controllers = entry.value;
                    return Card(
                      color: Colors.grey[100],
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: TextField(controller: controllers['label'], decoration: const InputDecoration(labelText: "اسم الفترة (مثلاً: سهرة)"))),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setModalState(() => periodControllers.removeAt(index));
                                  },
                                )
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(child: TextField(controller: controllers['from'], decoration: const InputDecoration(labelText: "من (00:00)"))),
                                const SizedBox(width: 10),
                                Expanded(child: TextField(controller: controllers['to'], decoration: const InputDecoration(labelText: "إلى (00:00)"))),
                                const SizedBox(width: 10),
                                Expanded(child: TextField(controller: controllers['price'], decoration: const InputDecoration(labelText: "السعر"), keyboardType: TextInputType.number)),
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
                    icon: const Icon(Icons.add),
                    label: const Text("إضافة فترة أخرى"),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            ElevatedButton(
              onPressed: () async {
                // تجميع البيانات من الـ Controllers
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

                bool success = field == null 
                  ? await _apiService.addFieldWithPrices(data)
                  : await _apiService.updateFieldWithPrices(field.id, data);

                if (success) {
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              child: const Text("حفظ الكل"),
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
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final field = snapshot.data![index];
              return ListTile(
                title: Text(field.name),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showFieldDialog(field: field),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFieldDialog(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}