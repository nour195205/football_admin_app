import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // تأكد من استخدام hive_flutter
import 'screens/login_screen.dart';

void main() async {
  // التأكد من تهيئة الـ Widgets قبل أي عملية async
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Hive للعمل مع Flutter
  await Hive.initFlutter();

  // فتح صندوق (Box) لتخزين البيانات محلياً (الكاش)
  await Hive.openBox('offline_data');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin Football',
      theme: ThemeData(
        primarySwatch: Colors.green,
        // إضافة تنسيق بسيط ليكون متناسق مع اللون الأخضر للملاعب
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}