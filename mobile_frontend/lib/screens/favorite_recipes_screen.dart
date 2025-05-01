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
        // Tüm tariflerin resim adlarını yazdır
        for (var recipe in recipes) {
          if (recipe.images.isNotEmpty) {
            print('Tarif: ${recipe.title}');
            print('Backend resim adı: ${recipe.images.first.imageUrl}');
          }
        }
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
                      // TODO: Login sayfasına yönlendir
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
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RecipeDetailScreen(recipe: recipe),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 90,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(15),
                                          color: Colors.grey.shade50,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(15),
                                          child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                                              ? Image.asset(
                                                  'assets/recipe_images/${recipe.imageUrl}',
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    print('Resim yükleme hatası: $error');
                                                    print('Yüklenmeye çalışılan resim: assets/recipe_images/${recipe.imageUrl}');
                                                    return Icon(
                                                      Icons.restaurant_menu,
                                                      color: Colors.grey.shade300,
                                                      size: 35,
                                                    );
                                                  },
                                                )
                                              : Icon(
                                                  Icons.restaurant_menu,
                                                  color: Colors.grey.shade300,
                                                  size: 35,
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 18),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              recipe.title,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.person_outline,
                                                  size: 18,
                                                  color: Colors.grey.shade500,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  recipe.username,
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Container(
                                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                                  width: 4,
                                                  height: 4,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade400,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.timer_outlined,
                                                  size: 18,
                                                  color: Colors.grey.shade500,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${recipe.preparationTime ?? "?"} dk',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.visibility_outlined,
                                                  size: 18,
                                                  color: Colors.grey.shade500,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${recipe.views} görüntülenme',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
} 