import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import '../providers/user_provider.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';

class FavoriteRecipesScreen extends StatefulWidget {
  const FavoriteRecipesScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteRecipesScreen> createState() => _FavoriteRecipesScreenState();
}

class _FavoriteRecipesScreenState extends State<FavoriteRecipesScreen> {
  final RecipeService _recipeService = RecipeService();
  List<Recipe> _favoriteRecipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteRecipes();
  }

  Future<void> _loadFavoriteRecipes() async {
    try {
      final user = context.read<UserProvider>().currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Favori tarifleri görmek için giriş yapmalısınız')),
          );
        }
        return;
      }

      final recipes = await _recipeService.getUserFavorites(user.id);
      if (mounted) {
        setState(() {
          _favoriteRecipes = recipes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Favori tarifler yüklenirken bir hata oluştu')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favori Tariflerim'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: user == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Favori tarifleri görmek için\ngiriş yapmalısınız',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Giriş Yap'),
                  ),
                ],
              ),
            )
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _favoriteRecipes.isEmpty
                  ? const Center(
                      child: Text(
                        'Henüz favori tarifin bulunmuyor',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFavoriteRecipes,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _favoriteRecipes.length,
                        itemBuilder: (context, index) {
                          final recipe = _favoriteRecipes[index];
                          return RecipeCard(
                            recipe: recipe,
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
    );
  }
} 