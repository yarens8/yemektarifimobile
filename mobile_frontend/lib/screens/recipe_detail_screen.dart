import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../models/comment.dart';
import '../services/recipe_service.dart';
import '../providers/user_provider.dart';
import '../providers/recipe_provider.dart';

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
  bool _isRating = false;
  bool _isLoadingComments = false;
  bool _isAddingComment = false;
  List<Comment> _comments = [];
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.recipe != null) {
      setState(() {
        _recipe = widget.recipe;
        _isLoading = false;
      });
      if (_recipe!.imageUrl != null && _recipe!.imageUrl!.isNotEmpty) {
        print('Tarif: ${_recipe!.title}');
        print('Resim dosya adı: ${_recipe!.imageUrl}');
      }
      _loadUserRating();
      _loadComments();
    } else if (widget.recipeId != null) {
      _loadRecipeDetails();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRating() async {
    final user = context.read<UserProvider>().currentUser;
    if (user != null && _recipe != null) {
      try {
        final rating = await _recipeService.getUserRating(
          recipeId: _recipe!.id,
          userId: user.id,
        );
        if (mounted && rating != null) {
          setState(() {
            _recipe = Recipe(
              id: _recipe!.id,
              title: _recipe!.title,
              description: _recipe!.description,
              imageUrl: _recipe!.imageUrl,
              images: _recipe!.images,
              userId: _recipe!.userId,
              username: _recipe!.username,
              categoryId: _recipe!.categoryId,
              isFavorited: _recipe!.isFavorited,
              favoriteCount: _recipe!.favoriteCount,
              commentCount: _recipe!.commentCount,
              views: _recipe!.views,
              cookingTime: _recipe!.cookingTime,
              ingredients: _recipe!.ingredients,
              instructions: _recipe!.instructions,
              tips: _recipe!.tips,
              servingSize: _recipe!.servingSize,
              difficulty: _recipe!.difficulty,
              createdAt: _recipe!.createdAt,
              averageRating: _recipe!.averageRating,
              ratingCount: _recipe!.ratingCount,
              userRating: rating,
            );
          });
        }
      } catch (e) {
        print('Error loading user rating: $e');
      }
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
          _loadUserRating();
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

  Future<void> _loadComments() async {
    if (_recipe == null) return;

    setState(() => _isLoadingComments = true);
    try {
      final comments = await _recipeService.getRecipeComments(_recipe!.id);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      print('Error loading comments: $e');
      if (mounted) {
        setState(() => _isLoadingComments = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yorumlar yüklenirken bir hata oluştu')),
        );
      }
    }
  }

  Future<void> _addComment() async {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorum yapmak için giriş yapmalısınız')),
      );
      return;
    }

    final content = _commentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorum boş olamaz')),
      );
      return;
    }

    setState(() => _isAddingComment = true);
    try {
      final result = await _recipeService.addComment(
        recipeId: _recipe!.id,
        userId: user.id,
        content: content,
      );
      
      if (mounted && result != null) {
        setState(() {
          _comments.insert(0, Comment(
            id: result['id'] ?? 0,
            content: content,
            createdAt: DateTime.now(),
            userId: user.id,
            recipeId: _recipe!.id,
            username: user.username,
          ));
          _commentController.clear();
          _isAddingComment = false;
        });
        
        // Klavyeyi kapat
        FocusScope.of(context).unfocus();
        
        // Başarılı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yorumunuz başarıyla eklendi'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Yorum eklenirken bir hata oluştu'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error adding comment: $e');
      if (mounted) {
        setState(() => _isAddingComment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yorum eklenirken bir hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    final user = context.read<UserProvider>().currentUser;
    if (user == null || user.id != comment.userId) return;

    try {
      final success = await _recipeService.deleteComment(comment.id, user.id);
      if (mounted && success) {
        setState(() {
          _comments.removeWhere((c) => c.id == comment.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yorum başarıyla silindi')),
        );
      }
    } catch (e) {
      print('Error deleting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yorum silinirken bir hata oluştu')),
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
              imageUrl: recipe.imageUrl,
              images: recipe.images,
              userId: recipe.userId,
              username: recipe.username,
              categoryId: recipe.categoryId,
              isFavorited: !recipe.isFavorited,
              favoriteCount: recipe.favoriteCount + (recipe.isFavorited ? -1 : 1),
              commentCount: recipe.commentCount,
              views: recipe.views,
              cookingTime: recipe.cookingTime,
              ingredients: recipe.ingredients,
              instructions: recipe.instructions,
              tips: recipe.tips,
              servingSize: recipe.servingSize,
              difficulty: recipe.difficulty,
              createdAt: recipe.createdAt,
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

  Future<void> _rateRecipe(int rating) async {
    if (_isRating) return;

    setState(() => _isRating = true);
    final user = context.read<UserProvider>().currentUser;

    if (user != null && _recipe != null) {
      try {
        final result = await _recipeService.rateRecipe(
          recipeId: _recipe!.id,
          userId: user.id,
          rating: rating,
        );

        if (result != null && result['success'] == true) {
          // RecipeProvider'ı güncelle
          await context.read<RecipeProvider>().updateRecipeRating(
            _recipe!.id,
            result['average_rating'].toDouble(),
            result['rating_count'],
          );

          if (mounted) {
            setState(() {
              _recipe = Recipe(
                id: _recipe!.id,
                title: _recipe!.title,
                description: _recipe!.description,
                imageUrl: _recipe!.imageUrl,
                images: _recipe!.images,
                userId: _recipe!.userId,
                username: _recipe!.username,
                categoryId: _recipe!.categoryId,
                isFavorited: _recipe!.isFavorited,
                favoriteCount: _recipe!.favoriteCount,
                commentCount: _recipe!.commentCount,
                views: _recipe!.views,
                cookingTime: _recipe!.cookingTime,
                ingredients: _recipe!.ingredients,
                instructions: _recipe!.instructions,
                tips: _recipe!.tips,
                servingSize: _recipe!.servingSize,
                difficulty: _recipe!.difficulty,
                createdAt: _recipe!.createdAt,
                averageRating: result['average_rating'].toDouble(),
                ratingCount: result['rating_count'],
                userRating: rating,
              );
            });
          }
        }
      } catch (e) {
        print('Error rating recipe: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Puan verirken bir hata oluştu')),
          );
        }
      }
    }

    if (mounted) {
      setState(() => _isRating = false);
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
      return const Scaffold(
        body: Center(
          child: Text('Tarif bulunamadı'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _recipe!.isFavorited ? Icons.favorite : Icons.favorite_border,
                color: _recipe!.isFavorited ? Colors.red : Colors.white,
              ),
              onPressed: _isFavoriting ? null : _toggleFavorite,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resim
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: _recipe!.imageUrl != null && _recipe!.imageUrl!.isNotEmpty
                    ? Image.asset(
                        'assets/recipe_images/${_recipe!.imageUrl}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading image: $error');
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, size: 64, color: Colors.grey),
                      );
                    },
                  )
                : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 64, color: Colors.grey),
                      ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Başlık ve İstatistikler
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.purple.shade100.withOpacity(0.9),
                    Colors.pink.shade50.withOpacity(0.9),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      _recipe!.title,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.deepPurple,
                        height: 1.1,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white,
                          child: Text(
                            _recipe!.username?[0].toUpperCase() ?? 'A',
                            style: TextStyle(
                              color: Colors.purple.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _recipe!.username ?? 'Anonim',
                          style: TextStyle(
                            color: Colors.purple.shade700,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildStatChip(
                          icon: Icons.timer_outlined,
                          label: '30 dakika',
                          backgroundColor: Colors.blue.shade50,
                        ),
                        const SizedBox(width: 12),
                        _buildStatChip(
                          icon: Icons.favorite_border,
                          label: '0 Favori',
                          backgroundColor: Colors.pink.shade50,
                        ),
                        const SizedBox(width: 12),
                        _buildStatChip(
                          icon: Icons.visibility_outlined,
                          label: '1029',
                          backgroundColor: Colors.purple.shade50,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Puan Sistemi
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 24,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${(_recipe!.averageRating ?? 0.0).toStringAsFixed(1)}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${_recipe!.ratingCount ?? 0} ${(_recipe!.ratingCount ?? 0) == 0 ? 'değerlendirme' : 'değerlendirme'})',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_recipe!.userRating != null)
                              Text(
                                'Sizin puanınız: ',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            Row(
                              children: List.generate(5, (index) {
                                return InkWell(
                                  onTap: _isRating ? null : () => _rateRecipe(index + 1),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    child: Icon(
                                      index < (_recipe!.userRating ?? 0)
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 32,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Malzemeler
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.pink.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.restaurant_menu,
                            color: Colors.purple.shade700,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Malzemeler',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: Colors.white,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: (_recipe!.ingredients ?? '').split('\n').where((line) => line.trim().isNotEmpty).length,
                      itemBuilder: (context, index) {
                        final ingredients = (_recipe!.ingredients ?? '').split('\n').where((line) => line.trim().isNotEmpty).toList();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.pink.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: Colors.purple.shade700,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  ingredients[index].trim(),
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.2,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Hazırlanışı
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.shade100,
                              Colors.pink.shade100,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.local_dining,
                          color: Colors.purple.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Hazırlanışı',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.shade100.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: (_recipe!.instructions ?? '').split('\n')
                          .where((step) => step.trim().isNotEmpty)
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                        final index = entry.key;
                        final step = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.purple.shade100,
                                      Colors.pink.shade100,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: Colors.purple.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  step.trim(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    height: 1.6,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_recipe!.tips != null && _recipe!.tips!.isNotEmpty) ...[
              const SizedBox(height: 16),
              // Püf Noktaları
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 12),
        const Text(
          'Püf Noktaları',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lightbulb_outline,
                              color: Theme.of(context).primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _recipe!.tips!,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_comments.isNotEmpty || context.read<UserProvider>().currentUser != null) ...[
              const SizedBox(height: 16),
              // Yorumlar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.chat_bubble_outline, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 12),
                            const Text(
                              'Yorumlar',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_comments.length} yorum',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (context.read<UserProvider>().currentUser != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.grey[200]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                              child: Text(
                                context.read<UserProvider>().currentUser!.username[0].toUpperCase(),
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: const InputDecoration(
                                  hintText: 'Yorum yaz...',
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            IconButton(
                              icon: _isAddingComment
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.send_rounded,
                                      color: Theme.of(context).primaryColor,
                                    ),
                              onPressed: _isAddingComment ? null : _addComment,
                            ),
                          ],
                        ),
                      ),
                    if (_isLoadingComments)
                      const Center(child: CircularProgressIndicator())
                    else if (_comments.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Henüz yorum yapılmamış',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'İlk yorumu sen yap!',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _comments.length,
                        separatorBuilder: (context, index) => const Divider(height: 24),
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                child: Text(
                                  comment.username?[0].toUpperCase() ?? 'A',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          comment.username ?? 'Anonim',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
                                            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
                                            comment.formattedDate,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      comment.content,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (context.read<UserProvider>().currentUser?.id == comment.userId)
                                IconButton(
                                  icon: const Icon(Icons.more_horiz),
                                  onPressed: () => _deleteComment(comment),
                                  color: Colors.grey[400],
                                ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[800]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
