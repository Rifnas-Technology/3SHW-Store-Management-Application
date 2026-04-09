import 'package:flutter/material.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'add_product_page.dart';
import 'product_view_page.dart';
import 'splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '3SHW',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFDD23E)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(title: 'Store Dashboard'),
        '/add-product': (context) => const AddProductPage(),
        '/product-view': (context) => const ProductViewPage(),
      },
    );
  }
}
