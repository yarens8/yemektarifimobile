import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import '../providers/user_provider.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe? recipe;
  final int? recipeId;

  const RecipeDetailScreen({Key? key, this.recipe, this.recipeId}) : super(key: key);

  @override
  _RecipeDetailScreenState createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Recipe? _recipe;
  bool _isLoading = true;
  final RecipeService _recipeService = RecipeService();
  bool _isFavoriting = false;

  @override
  void initState() {
    super.initState();
    if (widget.recipe != null) {
      setState(() {
        _recipe = widget.recipe;
        _isLoading = false;
      });
      if (_recipe!.images.isNotEmpty) {
        print('Tarif: ${_recipe!.title}');
        print('Resim dosya adı: ${_recipe!.images.first.imageUrl}');
      }
    } else if (widget.recipeId != null) {
      _loadRecipeDetails();
    }
  }

  Future<void> _loadRecipeDetails() async {
    try {
      if (widget.recipeId != null) {
        final loadedRecipe = await _recipeService.getRecipeDetail(widget.recipeId!);
        if (mounted && loadedRecipe != null) {
          setState(() {
            _recipe = loadedRecipe;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading recipe details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarif detayları yüklenirken bir hata oluştu')),
        );
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favorilere eklemek için giriş yapmalısınız')),
      );
      return;
    }

    setState(() => _isFavoriting = true);
    try {
      final recipe = _recipe!;
      bool success;
      String message;

      if (recipe.isFavorited) {
        final result = await _recipeService.removeFromFavorites(user.id, recipe.id);
        success = result.$1;
        message = result.$2;
      } else {
        final result = await _recipeService.addToFavorites(user.id, recipe.id);
        success = result.$1;
        message = result.$2;
      }

      if (mounted) {
        if (success) {
          setState(() {
            _recipe = Recipe(
              id: recipe.id,
              title: recipe.title,
              description: recipe.description,
              imageFilename: recipe.imageFilename,
              images: recipe.images,
              user: recipe.user,
              isFavorited: !recipe.isFavorited,
              favoriteCount: recipe.favoriteCount + (recipe.isFavorited ? -1 : 1),
              commentCount: recipe.commentCount,
              views: recipe.views,
              preparationTime: recipe.preparationTime,
              ingredients: recipe.ingredients,
              instructions: recipe.instructions,
              tips: recipe.tips,
            );
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFavoriting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_recipe == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tarif Detayı'),
        ),
        body: const Center(
          child: Text('Tarif bulunamadı'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Tarif resmi
                  _recipe!.images.isNotEmpty
                ? Image.asset(
                          'assets/recipe_images/${_recipe!.images[0].imageUrl}',
                          width: double.infinity,
                          height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                            print('Resim yükleme hatası: $error');
                            print('Yüklenmeye çalışılan resim: assets/recipe_images/${_recipe!.images[0].imageUrl}');
                      return Container(
                              color: Colors.orange.shade50,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.restaurant,
                                    size: 64,
                                    color: Colors.orange.shade300,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Resim yüklenemedi',
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                          ),
                                  ),
                                ],
                        ),
                      );
                    },
                  )
                : Container(
                          color: Colors.orange.shade50,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restaurant,
                                size: 64,
                                color: Colors.orange.shade300,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Resim bulunamadı',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Tarif başlığı
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _recipe!.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 3,
                                color: Colors.black45,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.white,
                              child: const Icon(Icons.person, size: 20, color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _recipe!.user.username,
                              style: const TextStyle(
                        color: Colors.white,
                                fontSize: 16,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                    color: Colors.black45,
                                  ),
                                ],
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
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                color: Colors.black87,
              onPressed: () => Navigator.pop(context),
            ),
          ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: _isFavoriting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
                          ),
                        )
                      : Icon(
                          _recipe!.isFavorited ? Icons.favorite : Icons.favorite_border,
                          color: _recipe!.isFavorited ? Colors.pink : Colors.grey,
                        ),
                  onPressed: _isFavoriting ? null : _toggleFavorite,
                ),
              ),
            ],
          ),
          // İçerik
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // İstatistikler
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatItem(
                            icon: Icons.timer,
                            label: _recipe!.preparationTime ?? 'Belirtilmemiş',
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          _buildStatItem(
                            icon: Icons.favorite,
                            label: '${_recipe!.favoriteCount} Favori',
                            color: Colors.pink,
                          ),
                          const SizedBox(width: 8),
                          _buildStatItem(
                            icon: Icons.remove_red_eye,
                            label: '${_recipe!.views} Görüntülenme',
                            color: Colors.purple,
                          ),
                ],
              ),
            ),
          ),

                  const Divider(),

                  // Malzemeler
                  if (_recipe!.ingredients != null) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
                              Icon(Icons.shopping_basket, color: Colors.orange.shade700),
                              const SizedBox(width: 8),
        const Text(
          'Malzemeler',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _recipe!.ingredients!
                                  .split('\n')
                                  .where((line) => line.trim().isNotEmpty)
                                  .map((line) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(top: 6),
                                              child: Icon(
                                                Icons.fiber_manual_record,
                                                size: 8,
                                                color: Colors.orange.shade700,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                line.trim(),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  height: 1.4,
                                                ),
                                                softWrap: true,
                                              ),
        ),
      ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                  ],

                  // Hazırlanış
                  if (_recipe!.instructions != null) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                          Row(
                            children: [
                              Icon(Icons.restaurant_menu, color: Colors.green.shade700),
                              const SizedBox(width: 8),
        const Text(
                                'Hazırlanış',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: _recipe!.instructions!
                                  .split('\n')
                                  .where((line) => line.trim().isNotEmpty)
                                  .map((line) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.arrow_right,
                                                size: 24, color: Colors.green.shade700),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                line.trim(),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  height: 1.5,
                                                ),
                                              ),
        ),
      ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // İpuçları
                  if (_recipe!.tips != null) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb, color: Colors.amber.shade700),
                              const SizedBox(width: 8),
        const Text(
                                'İpuçları',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
                            ],
                          ),
                          const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
                              color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
                              _recipe!.tips!,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    Color textColor = color;
    if (color == Colors.blue) textColor = Colors.blue.shade700;
    if (color == Colors.pink) textColor = Colors.pink.shade700;
    if (color == Colors.purple) textColor = Colors.purple.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 14,
          ),
        ),
      ],
      ),
    );
  }
}
