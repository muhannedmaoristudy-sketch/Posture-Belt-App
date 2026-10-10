import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/posture_provider.dart';
import 'screens/dashboard_screen.dart';

void main() {
  // خطوة مهمة جداً لضمان تهيئة التطبيق وعمل قاعدة البيانات (SQLite) بدون مشاكل
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // تغليف التطبيق بالـ Provider لكي يظل البلوتوث متصلاً وتنتقل البيانات بسلاسة
    ChangeNotifierProvider(
      create: (context) => PostureProvider(),
      child: const PostureBeltApp(),
    ),
  );
}

class PostureBeltApp extends StatelessWidget {
  const PostureBeltApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حزام الوضعية الذكي',
      debugShowCheckedModeBanner: false, // إخفاء شريط الـ Debug الأحمر من الزاوية
      // تطبيق التصميم الصناعي الداكن (Industrial Dark) على كل الشاشات
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF1E1E2C),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E2C),
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const DashboardScreen(), // تعيين لوحة التحكم كأول شاشة تفتح للمستخدم
    );
  }
}
