import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import '../screens/recipe_detail_screen.dart';
import '../screens/recipe_edit_screen.dart';
import '../widgets/recipe_card.dart';
import 'auth/login_screen.dart';

class MyRecipesScreen extends StatefulWidget {
  const MyRecipesScreen({super.key});

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  late RecipeService recipeService;
  late int userId;

  List<Recipe> _recipes = [];
  int _currentPage = 1;
  int _totalCount = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  final int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    recipeService = RecipeService();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<UserProvider>().currentUser;
    userId = user?.id ?? 0;
    if (_recipes.isEmpty) {
      _fetchRecipes(reset: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecipes({bool reset = false}) async {
    if (_isLoading || (!_hasMore && !reset)) return;
    setState(() {
      _isLoading = true;
      if (reset) {
        _recipes = [];
        _currentPage = 1;
        _hasMore = true;
        _errorMessage = null;
      }
    });
    try {
      final result = await recipeService.getUserRecipesPaged(userId, page: _currentPage, limit: _pageSize);
      final List<Recipe> newRecipes = List<Recipe>.from(result['recipes'] ?? []);
      final int total = result['totalCount'] ?? 0;
      setState(() {
        _totalCount = total;
        if (reset) {
          _recipes = newRecipes;
        } else {
          _recipes.addAll(newRecipes);
        }
        _hasMore = _recipes.length < _totalCount;
        if (_hasMore) _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Bir hata oluştu: $e';
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoading && _hasMore) {
      _fetchRecipes();
    }
  }

  Future<void> _deleteRecipe(int recipeId) async {
    final result = await recipeService.deleteRecipe(recipeId, userId);
    if (result) {
      setState(() {}); // Listeyi yenile
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarif başarıyla silindi')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarif silinirken hata oluştu')),
      );
    }
  }

  void _showDeleteConfirmation(int recipeId) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.15),
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFFF5F6FA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tarifi Sil',
                style: TextStyle(
                  color: Color(0xFFA259FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bu tarifi silmek istediğinize emin misiniz?',
                style: TextStyle(fontSize: 16, color: Color(0xFF22223B)),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFFA259FF),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    child: const Text('İptal'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteRecipe(recipeId);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFFFF7262),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    child: const Text('Sil'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<UserProvider>().currentUser;
    if (user == null || user.id == null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text(
            'Tariflerim',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            'Lütfen giriş yapın',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Tariflerim',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            )
          : _recipes.isEmpty && !_isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz tarif eklememişsiniz',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      itemCount: _recipes.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < _recipes.length) {
                          final recipe = _recipes[index];
                          return RecipeCard(
                            recipe: recipe,
                            onDelete: () => _showDeleteConfirmation(recipe.id!),
                            onEdit: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RecipeEditScreen(recipe: recipe),
                                ),
                              ).then((value) {
                                if (value == true) _fetchRecipes(reset: true);
                              });
                            },
                            onTap: () {
                              final userProvider = Provider.of<UserProvider>(context, listen: false);
                              if (userProvider.currentUser == null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RecipeDetailScreen(recipe: recipe),
                                  ),
                                );
                              }
                            },
                          );
                        } else {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                      },
                    ),
                    if (_isLoading && _recipes.isEmpty)
                      const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
                        ),
                      ),
                  ],
                ),
    );
  }
} 