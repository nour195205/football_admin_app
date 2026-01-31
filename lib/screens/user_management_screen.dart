import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _apiService.getUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      _showSnackBar("خطأ في تحميل المستخدمين", Colors.red);
      setState(() => _isLoading = false);
    }
  }

  // --- الدايلوج المحدث مع تأكيد الباسورد والعين ---
  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    bool isPasswordVisible = false;
    String selectedRole = 'user';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text("إضافة مستخدم جديد", textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "الاسم الكامل", prefixIcon: Icon(Icons.person)),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "البريد الإلكتروني", prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                ),
                // حقل كلمة المرور مع العين
                TextField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: "كلمة المرور",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setModalState(() => isPasswordVisible = !isPasswordVisible),
                    ),
                  ),
                ),
                // حقل تأكيد كلمة المرور
                TextField(
                  controller: confirmPasswordController,
                  obscureText: !isPasswordVisible,
                  decoration: const InputDecoration(
                    labelText: "تأكيد كلمة المرور",
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: "الصلاحية", border: OutlineInputBorder()),
                  items: ['admin', 'staff', 'user'].map((role) {
                    return DropdownMenuItem(value: role, child: Text(role.toUpperCase()));
                  }).toList(),
                  onChanged: (val) => setModalState(() => selectedRole = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                // فحص الحقول
                if (nameController.text.isEmpty || emailController.text.isEmpty || passwordController.text.isEmpty) {
                  _showSnackBar("برجاء ملء جميع الحقول", Colors.orange);
                  return;
                }
                // فحص تطابق الباسورد
                if (passwordController.text != confirmPasswordController.text) {
                  _showSnackBar("كلمات المرور غير متطابقة!", Colors.red);
                  return;
                }

                final res = await _apiService.addUserByAdmin({
                  "name": nameController.text,
                  "email": emailController.text,
                  "password": passwordController.text,
                  "role": selectedRole,
                });

                if (res['status'] == 'success') {
                  Navigator.pop(context);
                  _fetchUsers();
                  _showSnackBar("تمت إضافة ${nameController.text} بنجاح", Colors.green);
                } else {
                  _showSnackBar(res['message'] ?? "فشل الإضافة", Colors.red);
                }
              },
              child: const Text("إضافة مستخدم", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إدارة المستخدمين"),
        backgroundColor: Colors.green,
        actions: [IconButton(onPressed: _fetchUsers, icon: const Icon(Icons.refresh))],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : ListView.builder(
              padding: const EdgeInsets.only(top: 10),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: user['role'] == 'admin' ? Colors.red : Colors.blue,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${user['email']}\nالدور: ${user['role']}"),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (newRole) async {
                        bool success = await _apiService.updateUserRole(user['id'], newRole);
                        if (success) {
                          _fetchUsers();
                          _showSnackBar("تم تغيير الصلاحية لـ $newRole", Colors.green);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'admin', child: Text("ترقية لآدمن")),
                        const PopupMenuItem(value: 'staff', child: Text("تعيين كـ Staff")),
                        const PopupMenuItem(value: 'user', child: Text("يوزر عادي")),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}