import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import '../providers/user_provider.dart';

class RecipeDetailScreen extends StatefulWidget {
  final int? recipeId;
  final Recipe? recipe;

  const RecipeDetailScreen({
    Key? key,
    this.recipeId,
    this.recipe,
  }) : assert(recipeId != null || recipe != null, 'Either recipeId or recipe must be provided'),
       super(key: key);

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final RecipeService _recipeService = RecipeService();
  Recipe? _recipe;
  bool _isLoading = true;
  bool _isFavoriting = false;

  @override
  void initState() {
    super.initState();
    if (widget.recipe != null) {
      _recipe = widget.recipe;
      _isLoading = false;
    } else {
      _loadRecipe();
    }
  }

  Future<void> _loadRecipe() async {
    try {
      final recipe = await _recipeService.getRecipeDetail(widget.recipeId!);
      setState(() {
        _recipe = recipe;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarif yüklenirken bir hata oluştu')),
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recipe == null
              ? const Center(child: Text('Tarif bulunamadı'))
              : CustomScrollView(
                  slivers: [
                    // App Bar
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
                                    _recipe!.images[0].imageUrl,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
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
                                                          color: Colors.orange.shade700
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
