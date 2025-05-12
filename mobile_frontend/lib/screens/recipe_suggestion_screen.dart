import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'recipe_detail_screen.dart';  // RecipeDetailScreen'i import et

class RecipeSuggestionScreen extends StatefulWidget {
  // ... (existing code)
}

class _RecipeSuggestionScreenState extends State<RecipeSuggestionScreen> {
  // ... (existing code)

  Future<void> _fetchRecipes() async {
    // ... (existing code)

    try {
      // ... (existing code)

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isEmpty) {
          // Liste boşsa uyarı göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lütfen malzeme giriniz'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        setState(() {
          _suggestedRecipes = data.map((json) => Recipe.fromJson(json)).toList();
        });
      } else {
        print('API Error: ${response.statusCode}');
      }
    } catch (e) {
      // ... (existing code)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tarif Önerileri'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _ingredientController,
              decoration: InputDecoration(
                labelText: 'Malzemeleri girin (virgülle ayırın)',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _fetchRecipes,
                ),
              ),
            ),
          ),
          if (_suggestedRecipes.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _suggestedRecipes.length,
                itemBuilder: (context, index) {
                  final recipe = _suggestedRecipes[index];
                  return ListTile(
                    title: Text(recipe.title),
                    subtitle: Text(recipe.description),
                    leading: recipe.imageUrl != null
                        ? Image.network(
                            recipe.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : Icon(Icons.restaurant),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecipeDetailScreen(recipe: recipe),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ... (rest of the existing code)
} 