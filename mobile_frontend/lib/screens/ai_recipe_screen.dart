import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/recipe.dart';
import '../widgets/recipe_card.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'auth/login_screen.dart';

class ChatMessage {
  final String? text; // Kullanıcı mesajı
  final List<Recipe>? recipes; // AI cevabı (tarif listesi)
  final bool isUser;
  ChatMessage.user(this.text) : recipes = null, isUser = true;
  ChatMessage.ai(this.recipes) : text = null, isUser = false;
}

class AiRecipeScreen extends StatefulWidget {
  @override
  _AiRecipeScreenState createState() => _AiRecipeScreenState();
}

class _AiRecipeScreenState extends State<AiRecipeScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  Future<void> _fetchAiRecipes(String userMessage) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/ai_recipe'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_message': userMessage}),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final recipes = data.map((e) => Recipe.fromJson(e)).toList();
        setState(() {
          _messages.add(ChatMessage.ai(recipes));
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI tarifleri alınamadı: \\${response.body}')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu: \\${e}')),
      );
    }
  }

  void _sendMessage() {
    final userMessage = _messageController.text.trim();
    if (userMessage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen bir mesaj girin!')),
      );
      return;
    }
    setState(() {
      _messages.add(ChatMessage.user(userMessage));
      _messageController.clear();
    });
    _fetchAiRecipes(userMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Tarif Önerileri'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                if (msg.isUser) {
                  // Kullanıcı mesajı balonu
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(msg.text ?? '', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  );
                } else {
                  // AI cevabı: tarif kartları
                  final recipes = msg.recipes ?? [];
                  if (recipes.isEmpty) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text("AI'dan tarif bulunamadı.", style: TextStyle(color: Colors.black87)),
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: recipes.map((recipe) => _RecipeChatCard(recipe: recipe)).toList(),
                  );
                }
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CircularProgressIndicator(color: Colors.pinkAccent),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Mesajınızı veya malzemeleri yazın...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.pinkAccent),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeChatCard extends StatelessWidget {
  final Recipe recipe;
  const _RecipeChatCard({required this.recipe});

  Future<void> _addToToTryRecipes(BuildContext context) async {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen giriş yapın!')),
      );
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/to-try-recipes/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'ai_title': recipe.title,
          'ai_ingredients': recipe.ingredients,
          'ai_instructions': recipe.instructions,
          'ai_serving_size': recipe.servingSize,
          'ai_cooking_time': recipe.cookingTime,
          'ai_preparation_time': recipe.prepTime,
        }),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${recipe.title}" denenecekler listesine eklendi!')),
        );
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Bir hata oluştu';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $error')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(recipe.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 6),
            if (recipe.ingredients.isNotEmpty)
              Text('Malzemeler: ${recipe.ingredients}', style: TextStyle(fontSize: 14, color: Colors.black87)),
            if (recipe.instructions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Hazırlanışı: ${recipe.instructions}', style: TextStyle(fontSize: 14, color: Colors.black87)),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (recipe.servingSize != null && recipe.servingSize!.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(recipe.servingSize!, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                      const SizedBox(width: 12),
                    ],
                  ),
                if (recipe.cookingTime != null && recipe.cookingTime!.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.timer, size: 16, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text('${recipe.cookingTime!} dk', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _addToToTryRecipes(context),
                child: Text('Bu tarifi deneyeceğim'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 