import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/main_screen.dart';
import 'providers/recipe_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RecipeProvider(),
      child: MaterialApp(
        title: 'Lezzetli Tarifler',
        theme: ThemeData(
          primarySwatch: Colors.pink,
          scaffoldBackgroundColor: Colors.grey[50],
        ),
        home: const MainScreen(),
      ),
    );
  }
}
