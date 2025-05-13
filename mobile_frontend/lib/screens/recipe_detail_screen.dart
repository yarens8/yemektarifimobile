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
      if (_recipe!.imageFilename != null && _recipe!.imageFilename!.isNotEmpty) {
        print('Tarif: ${_recipe!.title}');
        print('Resim dosya adı: ${_recipe!.imageFilename}');
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
              imageFilename: _recipe!.imageFilename,
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
              updatedAt: _recipe!.updatedAt,
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
              imageFilename: recipe.imageFilename,
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
              updatedAt: recipe.updatedAt,
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
                imageFilename: _recipe!.imageFilename,
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
                updatedAt: _recipe!.updatedAt,
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

  Widget _infoChip(IconData icon, String label, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
                children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: iconColor, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget buildRecipeImage() {
      final imageFilename = _recipe?.imageFilename;
      if (imageFilename == null || imageFilename.isEmpty) {
        return Container(
          width: double.infinity,
          height: 320,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: const Icon(Icons.image, size: 60, color: Colors.grey),
        );
      }
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        child: Image.asset(
          'assets/recipe_images/$imageFilename',
          width: double.infinity,
          height: 320,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: double.infinity,
            height: 320,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 60, color: Colors.redAccent),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.purple.shade700),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recipe == null
              ? const Center(child: Text('Tarif bulunamadı'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stack ile görsel, başlık, favori, kullanıcı
                      Stack(
                        children: [
                          buildRecipeImage(),
                          // Gradient overlay
                          Positioned(
                            left: 0, right: 0, bottom: 0,
                            child: Container(
                              height: 130,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                                ),
                              ),
                            ),
                          ),
                          // Başlık ve kullanıcı
                          Positioned(
                            left: 20, bottom: 36,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_recipe!.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
        Row(
          children: [
                                    const Icon(Icons.person, color: Colors.white, size: 18),
                                    const SizedBox(width: 6),
                                    Text('Tarif Sahibi: ${_recipe!.username}', style: const TextStyle(color: Colors.white, fontSize: 15)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Favori butonu
                          Positioned(
                            right: 20, top: 20,
                            child: Material(
                              color: Colors.white,
                              shape: const CircleBorder(),
                              elevation: 4,
                              child: IconButton(
                                icon: Icon(_recipe!.isFavorited ? Icons.favorite : Icons.favorite_border, color: Colors.pink, size: 26),
                                onPressed: _isFavoriting ? null : _toggleFavorite,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Bilgi kartları ve puanlama
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Column(
                              children: [
                            Row(
                              children: [
                                Expanded(child: _infoChip(Icons.timer, '${_recipe!.cookingTime ?? ''} dakika', Colors.blue.shade50, Colors.blue)),
                                const SizedBox(width: 8),
                                    Expanded(child: _infoChip(Icons.groups, 'Porsiyon: ${_recipe!.servingSize ?? 'Bilinmiyor'}', Colors.green.shade50, Colors.green)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                Expanded(child: _infoChip(Icons.favorite, '${_recipe!.favoriteCount} Favori', Colors.pink.shade50, Colors.pink)),
                                const SizedBox(width: 8),
                                Expanded(child: _infoChip(Icons.remove_red_eye, '${_recipe!.views} Görüntülenme', Colors.purple.shade50, Colors.purple)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Ortalama puan
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.yellow.shade50,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 22),
                                  const SizedBox(width: 6),
                                  Text(
                                    (_recipe!.averageRating != null
                                        ? _recipe!.averageRating!.toStringAsFixed(1)
                                        : '0.0'),
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                                  ),
                                  const SizedBox(width: 6),
            Text(
                                    '(${_recipe!.ratingCount ?? 0} değerlendirme)',
                                    style: const TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Kullanıcı puanı
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Sizin puanınız:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: List.generate(5, (index) {
                                      final userRating = _recipe!.userRating ?? 0;
                                      return GestureDetector(
                                        onTap: () {
                                          _rateRecipe(index + 1);
                                        },
                                        child: Icon(
                                          index < userRating ? Icons.star : Icons.star_border,
                                          color: Colors.amber,
                                          size: 28,
                                        ),
                                      );
                                    }),
                                  ),
                                ],
              ),
            ),
          ],
        ),
                      ),
                      // Malzemeler kartı
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                            Row(
                              children: [
                                const Icon(Icons.shopping_basket, color: Colors.orange, size: 22),
                                const SizedBox(width: 8),
                                const Text('Malzemeler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              ],
        ),
        const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: (_recipe!.ingredients ?? '').split('\n').where((e) => e.trim().isNotEmpty).map((e) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('• ', style: TextStyle(color: Colors.orange, fontSize: 18)),
                                      Expanded(child: Text(e, style: const TextStyle(fontSize: 16))),
                                    ],
                                  ),
                                )).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Hazırlanış
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Card(
                          color: Color(0xFFFFCDD2),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(color: Colors.red.shade100, width: 1.2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.menu_book, color: Colors.deepPurple, size: 24),
                                    SizedBox(width: 8),
                                    Text('Hazırlanışı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
                                  ],
                                ),
                                SizedBox(height: 10),
                                ...(_recipe!.instructions ?? '')
                                    .split('\n')
                                    .where((e) => e.trim().isNotEmpty)
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map((entry) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                                          child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                                              Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color: Colors.purple.shade50,
                                                  shape: BoxShape.circle,
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  '${entry.key + 1}',
          style: TextStyle(
                                                    color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  entry.value,
                                                  style: TextStyle(fontSize: 16),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // İpuçları
                      if ((_recipe!.tips ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Card(
                            color: Colors.yellow[50],
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.tips_and_updates, color: Colors.orange, size: 22),
                                      SizedBox(width: 8),
                                      Text('Püf Noktalar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                                      const Icon(Icons.info_outline, color: Colors.orange),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(_recipe!.tips!, style: const TextStyle(fontSize: 15))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      // Yorumlar başlığı
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.comment, color: Colors.purple.shade200, size: 24),
                            SizedBox(width: 8),
                            Text('Yorumlar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.purple.shade400)),
                          ],
                        ),
                      ),
                      // Yorum ekleme kutusu
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: Card(
                          color: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.purple.shade50,
                                  child: Icon(Icons.person, color: Colors.purple.shade200),
                                  radius: 20,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _commentController,
                                    decoration: InputDecoration(
                                      hintText: 'Yorumunuzu yazın...',
                                      border: InputBorder.none,
                                    ),
                                    minLines: 1,
                                    maxLines: 3,
                                    enabled: !_isAddingComment,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                ElevatedButton(
                                  onPressed: _isAddingComment ? null : _addComment,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple.shade200,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: EdgeInsets.all(10),
                                    elevation: 0,
                                  ),
                                  child: _isAddingComment
                                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : Icon(Icons.send, color: Colors.white, size: 20),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Yorumlar listesi
                      if (_isLoadingComments)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_comments.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text('Henüz yorum yok.', style: TextStyle(color: Colors.grey[600])),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            final user = context.read<UserProvider>().currentUser;
                            final isOwner = user != null && user.id == comment.userId;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.purple.shade50,
          child: Text(
                                      (comment.username != null && comment.username!.isNotEmpty)
                                        ? comment.username![0].toUpperCase()
                                        : '?',
                                      style: TextStyle(color: Colors.purple.shade200, fontWeight: FontWeight.bold),
                                    ),
                                    radius: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Card(
                                      color: Colors.white,
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(comment.username ?? 'Kullanıcı', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple.shade600, fontSize: 15)),
                                                const SizedBox(width: 8),
                                                Text(comment.formattedDate, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                                if (isOwner) ...[
                                                  Spacer(),
                                                  IconButton(
                                                    icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 20),
                                                    tooltip: 'Yorumu Sil',
                                                    padding: EdgeInsets.zero,
                                                    constraints: BoxConstraints(),
                                                    onPressed: () async {
                                                      final confirm = await showDialog<bool>(
                                                        context: context,
                                                        builder: (ctx) => AlertDialog(
                                                          title: Text('Yorumu Sil'),
                                                          content: Text('Bu yorumu silmek istediğine emin misin?'),
                                                          actions: [
                                                            TextButton(child: Text('Vazgeç'), onPressed: () => Navigator.pop(ctx, false)),
                                                            TextButton(child: Text('Sil', style: TextStyle(color: Colors.red)), onPressed: () => Navigator.pop(ctx, true)),
                                                          ],
                                                        ),
                                                      );
                                                      if (confirm == true) {
                                                        _deleteComment(comment);
                                                      }
                                                    },
                                                  ),
                                                ]
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(comment.content, style: TextStyle(fontSize: 15)),
                                          ],
                                        ),
                                      ),
          ),
        ),
      ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
    );
  }
}
