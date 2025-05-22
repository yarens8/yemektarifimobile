import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yemektarifimobile/screens/recipe_detail_screen.dart';

class RecipeSuggestionScreen extends StatefulWidget {
  final List<String> selectedIngredients;
  final Map<String, dynamic> filters;

  const RecipeSuggestionScreen({
    Key? key,
    required this.selectedIngredients,
    required this.filters,
  }) : super(key: key);

  @override
  _RecipeSuggestionScreenState createState() => _RecipeSuggestionScreenState();
}

class _RecipeSuggestionScreenState extends State<RecipeSuggestionScreen> {
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _suggestRecipes();
  }

  Future<void> _suggestRecipes() async {
    print('*** _suggestRecipes ÇAĞRILDI ***');
    print('Seçilen malzemeler: \\${widget.selectedIngredients}');
    print('Filtreler: \\${widget.filters}');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      print('Token bulunamadı!');
      setState(() {
        _error = 'Oturum açmanız gerekiyor';
        _isLoading = false;
      });
      return;
    }

    final bodyData = {
      'selectedIngredients': widget.selectedIngredients,
      'filters': widget.filters,
    };
    print('GÖNDERİLEN BODY: ' + jsonEncode(bodyData));
    print('GÖNDERİLEN HEADERS: ' + {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    }.toString());

    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/api/mobile/suggest_recipes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(bodyData),
    );

    print('API yanıtı alındı: ${response.statusCode}');
    print('Yanıt içeriği: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print('Çözümlenen veri: $data');
      
      if (data.isEmpty) {
        setState(() {
          _suggestions = [];
          _error = 'Seçtiğiniz malzemelerle eşleşen tarif bulunamadı';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _suggestions = data.map((item) {
          if (item == null) {
            print('Null öğe bulundu!');
            return <String, dynamic>{};
          }
          return Map<String, dynamic>.from(item);
        }).where((item) => item.isNotEmpty).toList();
        _isLoading = false;
      });
    } else {
      print('Hata kodu: ${response.statusCode}');
      print('Hata mesajı: ${response.body}');
      setState(() {
        _error = 'Tarifler alınırken bir hata oluştu: ${response.statusCode}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarif Önerileri'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _suggestRecipes,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : _suggestions.isEmpty
                  ? const Center(
                      child: Text('Seçtiğiniz malzemelerle eşleşen tarif bulunamadı'),
                    )
                  : ListView.builder(
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final recipe = _suggestions[index];
                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            title: Text(recipe['title'] ?? 'İsimsiz Tarif'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (recipe['prep_time'] != null)
                                  Text('Hazırlama Süresi: ${recipe['prep_time']} dakika'),
                                if (recipe['calories'] != null)
                                  Text('Kalori: ${recipe['calories']}'),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RecipeDetailScreen(
                                    recipeId: recipe['id'],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
      bottomNavigationBar: (_isLoading || _error != null || _suggestions.isEmpty)
          ? null
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  // AI sayfasına yönlendirme veya fonksiyon
                  print('Farklı Tarifler Al butonuna basıldı');
                },
                icon: Icon(Icons.smart_toy),
                label: Text('Farklı Tarifler Al'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
    );
  }
} 