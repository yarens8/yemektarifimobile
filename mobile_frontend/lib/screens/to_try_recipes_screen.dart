import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../services/recipe_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth/login_screen.dart';

class ToTryRecipesScreen extends StatefulWidget {
  const ToTryRecipesScreen({Key? key}) : super(key: key);

  @override
  _ToTryRecipesScreenState createState() => _ToTryRecipesScreenState();
}

class _ToTryRecipesScreenState extends State<ToTryRecipesScreen> {
  final ApiService _apiService = ApiService();
  final RecipeService _recipeService = RecipeService();
  bool _isLoading = true;
  List<dynamic> _recipes = [];

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);
    try {
      final userId = Provider.of<UserProvider>(context, listen: false).userId;
      if (userId == null) {
        setState(() {
          _recipes = [];
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kullanıcı bulunamadı, lütfen giriş yapın.')),
          );
        }
        return;
      }
      final recipes = await _apiService.getToTryRecipes(userId);
      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tarifler yüklenirken bir hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _addToAiRecipes(int recipeIndex) async {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    if (userId == null) return;
    final recipe = _recipes[recipeIndex];
    final result = await _recipeService.createRecipe(
      title: recipe['title'] ?? '',
      userId: userId,
      categoryId: 9, // AI tariflerim kategorisi (doğru id)
      ingredients: recipe['ingredients'] ?? '',
      instructions: recipe['instructions'] ?? '',
    );
    if (result['success'] == true && mounted) {
      try {
        await _removeFromToTryBackend(recipe['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarif yapay zeka tariflerime eklendi ve deneneceklerden silindi!')),
        );
        setState(() {
          _recipes.removeAt(recipeIndex);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI tariflerime eklendi ama deneneceklerden silinemedi: \\${e.toString()}')),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu: \\${result['message']}')),
      );
    }
  }

  Future<void> _removeFromToTryBackend(int recipeId) async {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    if (userId == null) return;
    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/to-try-recipes/remove'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'recipe_id': recipeId}),
    );
    if (response.statusCode == 200) {
      // Başarılı
      return;
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Silme işlemi başarısız');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Denenecek Tariflerim'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recipes.isEmpty
              ? const Center(child: Text('Henüz denenecek tarifiniz yok.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = _recipes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe['title'] ?? 'İsimsiz Tarif',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Malzemeler:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              recipe['ingredients'] ?? recipe['ai_ingredients'] ?? 'Malzemeler belirtilmemiş',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            Text('Hazırlanış:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              recipe['instructions'] ?? recipe['ai_instructions'] ?? 'Hazırlanış bilgisi yok',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if ((recipe['serving_size'] ?? recipe['ai_serving_size']) != null && (recipe['serving_size'] ?? recipe['ai_serving_size']).toString().isNotEmpty)
                                  Row(
                                    children: [
                                      Icon(Icons.people, size: 16, color: Colors.grey),
                                      const SizedBox(width: 3),
                                      Text((recipe['serving_size'] ?? recipe['ai_serving_size']).toString(), style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                      const SizedBox(width: 12),
                                    ],
                                  ),
                                if ((recipe['cooking_time'] ?? recipe['ai_cooking_time']) != null && (recipe['cooking_time'] ?? recipe['ai_cooking_time']).toString().isNotEmpty)
                                  Row(
                                    children: [
                                      Icon(Icons.timer, size: 16, color: Colors.grey),
                                      const SizedBox(width: 3),
                                      Text((recipe['cooking_time'] ?? recipe['ai_cooking_time']).toString(), style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                      const SizedBox(width: 12),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final userProvider = Provider.of<UserProvider>(context, listen: false);
                                      if (userProvider.currentUser == null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                                        );
                                      } else {
                                        await _addToAiRecipes(index);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Denedim ve Beğendim'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _removeFromToTryBackend(recipe['id']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Sil'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
} 