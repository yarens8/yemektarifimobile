import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import 'recipe_detail_screen.dart';
import 'category_recipes_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final ValueNotifier<int> _loadedImages = ValueNotifier<int>(0);
  final ValueNotifier<int> _totalImages = ValueNotifier<int>(0);

  void _updateImageStats(bool success) {
    _totalImages.value++;
    if (success) _loadedImages.value++;
  }

  @override
  void dispose() {
    _loadedImages.dispose();
    _totalImages.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Widget oluşturulduğunda verileri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecipeProvider>().loadInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecipeProvider>(
      builder: (context, recipeProvider, child) {
        if (recipeProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = recipeProvider.categories;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Kategoriler',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: Container(
            color: Colors.grey[50],
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final recipes = recipeProvider.getRecipesForCategory(category['id']);
                final color = _getCategoryColor(category['name'] ?? '');
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryRecipesScreen(
                              categoryId: category['id'],
                              categoryName: category['name'],
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              color.withOpacity(0.05),
                              Colors.white,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: color.withOpacity(0.1),
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: _buildCategoryIcon(category['name'] ?? '', color),
                                    ),
                                    Positioned(
                                      right: -4,
                                      bottom: -4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: color.withOpacity(0.2),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          '${recipes.length}',
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category['name'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getCategoryDescription(category['name'] ?? ''),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: color,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _getCategoryDescription(String category) {
    switch (category.toLowerCase()) {
      case 'ana yemek':
        return 'Doyurucu ana yemek tarifleri';
      case 'aperatif':
        return 'Pratik atıştırmalık tarifler';
      case 'çorba':
        return 'Sıcacık çorba tarifleri';
      case 'içecek':
        return 'Serinleten içecek tarifleri';
      case 'kahvaltılık':
        return 'Güne güzel başlangıç';
      case 'salata':
        return 'Hafif ve sağlıklı salatalar';
      case 'tatlı':
        return 'Tatlı krizine çözümler';
      default:
        return 'Lezzetli tarifler';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'ana yemek':
        return const Color(0xFF5C6BC0); // Soft Indigo
      case 'aperatif':
        return const Color(0xFFAB47BC); // Soft Purple
      case 'çorba':
        return const Color(0xFF26A69A); // Soft Teal
      case 'içecek':
        return const Color(0xFFFF7043); // Soft Deep Orange
      case 'kahvaltılık':
        return const Color(0xFFEC407A); // Soft Pink
      case 'salata':
        return const Color(0xFF66BB6A); // Soft Green
      case 'tatlı':
        return const Color(0xFFFFA726); // Soft Orange
      default:
        return const Color(0xFF78909C); // Soft Blue Grey
    }
  }

  Widget _buildCategoryIcon(String category, Color color) {
    String imagePath = '';
    switch (category.toLowerCase()) {
      case 'ana yemek':
        imagePath = 'assets/category_images/ana_yemek.jpg';
        break;
      case 'aperatif':
        imagePath = 'assets/category_images/aperatif.jpg';
        break;
      case 'çorba':
        imagePath = 'assets/category_images/corba.jpg';
        break;
      case 'içecek':
        imagePath = 'assets/category_images/icecek.jpg';
        break;
      case 'kahvaltılık':
        imagePath = 'assets/category_images/kahvaltilik.jpg';
        break;
      case 'salata':
        imagePath = 'assets/category_images/salata.jpg';
        break;
      case 'tatlı':
        imagePath = 'assets/category_images/tatli.jpg';
        break;
      default:
        return Icon(Icons.restaurant_menu_rounded, color: color, size: 28);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Image.asset(
            imagePath,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showRecipeDetails(recipe),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipe['image_filename'] != null && recipe['image_filename'].toString().isNotEmpty)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.asset(
                      'assets/recipe_images/${recipe['image_filename']}',
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('Resim yüklenirken hata: $error');
                        return Container(
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.orange.shade300,
                                Colors.orange.shade100,
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.restaurant,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Görüntülenme sayısı overlay
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.remove_red_eye,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe['views'] ?? 0}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      recipe['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe['ingredients'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.grey[200],
                              child: Icon(
                                Icons.person_outline,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              recipe['created_by']?.toString() ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (recipe['created_date'] != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(recipe['created_date']),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final DateTime dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    } catch (e) {
      print('Tarih dönüştürme hatası: $e');
      return '';
    }
  }

  void _showRecipeDetails(Map<String, dynamic> recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: recipe),
      ),
    );
  }

  IconData _getCategoryIcon(String? categoryName) {
    if (categoryName == null) return Icons.restaurant;
    
    switch (categoryName.toLowerCase()) {
      case 'ana yemek':
        return Icons.dinner_dining;
      case 'çorba':
        return Icons.soup_kitchen;
      case 'tatlı':
        return Icons.cake;
      case 'aperatif':
        return Icons.tapas;
      case 'salata':
        return Icons.eco;
      case 'içecek':
        return Icons.local_drink;
      default:
        return Icons.restaurant;
    }
  }
} 