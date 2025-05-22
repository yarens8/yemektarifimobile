import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AiRecipeScreen extends StatefulWidget {
  const AiRecipeScreen({Key? key}) : super(key: key);

  @override
  State<AiRecipeScreen> createState() => _AiRecipeScreenState();
}

class _AiRecipeScreenState extends State<AiRecipeScreen> {
  final TextEditingController _ingredientController = TextEditingController();
  final List<String> _ingredients = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> _aiRecipes = [];

  void _addIngredient() {
    final value = _ingredientController.text.trim();
    if (value.isNotEmpty && !_ingredients.contains(value)) {
      setState(() {
        _ingredients.add(value);
        _ingredientController.clear();
      });
    }
  }

  Future<void> _fetchAiRecipes() async {
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen en az bir malzeme girin!')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/ai_recipe'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ingredients': _ingredients}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          setState(() {
            _aiRecipes = data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _aiRecipes = [];
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('AI yanıtı beklenen formatta değil.')),
          );
        }
      } else {
        setState(() {
          _aiRecipes = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI tarifleri alınamadı: ${response.body}')),
        );
      }
    } catch (e) {
      setState(() {
        _aiRecipes = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Tarif Önerileri'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Elinizdeki Malzemeler:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ingredientController,
                    decoration: InputDecoration(
                      hintText: 'Malzeme ekle...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (_) => _addIngredient(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addIngredient,
                  child: Icon(Icons.add),
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(12),
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _ingredients.map((e) => Chip(
                label: Text(e),
                onDeleted: () {
                  setState(() {
                    _ingredients.remove(e);
                  });
                },
              )).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _fetchAiRecipes,
                child: _isLoading
                    ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Tarifleri Getir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _aiRecipes.isEmpty
                  ? Center(child: Text('Henüz AI tarifi yok'))
                  : ListView.builder(
                      itemCount: _aiRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = _aiRecipes[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pink.shade100.withOpacity(0.18),
                                blurRadius: 16,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Başlık
                                Text(
                                  recipe['title'],
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: Colors.pink.shade400),
                                ),
                                const SizedBox(height: 8),
                                // Malzemeler badge gibi
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: List.generate(
                                    (recipe['ingredients'] as List).length,
                                    (i) => Chip(
                                      label: Text(recipe['ingredients'][i], style: TextStyle(fontSize: 13, color: Colors.pink.shade700)),
                                      backgroundColor: Colors.pink.shade50,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Açıklama
                                Text(
                                  recipe['instructions'],
                                  style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
                                ),
                                const SizedBox(height: 14),
                                // Bilgiler: Hazırlama, Pişirme, Porsiyon
                                Row(
                                  children: [
                                    Icon(Icons.timer, size: 18, color: Colors.pink.shade300),
                                    const SizedBox(width: 4),
                                    Text('Hazırlık: ${recipe['prep_time']} dk', style: TextStyle(fontSize: 13)),
                                    const SizedBox(width: 16),
                                    Icon(Icons.local_fire_department, size: 18, color: Colors.orange.shade300),
                                    const SizedBox(width: 4),
                                    Text('Pişirme: ${recipe['cook_time']} dk', style: TextStyle(fontSize: 13)),
                                    const SizedBox(width: 16),
                                    Icon(Icons.people, size: 18, color: Colors.blue.shade300),
                                    const SizedBox(width: 4),
                                    Text('${recipe['servings']} kişilik', style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 40,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Burada "Bu Tarifi Deneyeceğim" fonksiyonu olacak
                                      print('Bu Tarifi Deneyeceğim: ${recipe['title']}');
                                    },
                                    child: Text('Bu Tarifi Deneyeceğim', style: TextStyle(fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.pink.shade400,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      elevation: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
} 