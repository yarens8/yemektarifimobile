import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import 'recipe_detail_screen.dart';
import '../models/recipe.dart';
import 'auth/login_screen.dart';
import '../providers/user_provider.dart';

class FilteredRecipesListScreen extends StatefulWidget {
  final String filterType;
  final String title;

  const FilteredRecipesListScreen({
    Key? key,
    required this.filterType,
    required this.title,
  }) : super(key: key);

  @override
  State<FilteredRecipesListScreen> createState() => _FilteredRecipesListScreenState();
}

class _FilteredRecipesListScreenState extends State<FilteredRecipesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<RecipeProvider>(
        builder: (context, recipeProvider, child) {
          if (recipeProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.filterType == 'ingredient') {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Malzeme ara...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              color: Colors.grey[400],
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim();
                      });
                    },
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  Expanded(
                    child: _buildFilteredRecipesList(
                      recipeProvider.recipes
                          .where((recipe) =>
                              recipe['ingredients']
                                  .toString()
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase()))
                          .toList(),
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aramak istediğiniz malzemeyi yazın',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }

          final options = _getFilterOptions(widget.filterType, recipeProvider);
          
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final color = _getCategoryColor(option['name']);
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
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
                            builder: (context) => FilteredRecipesResultScreen(
                              filterType: widget.filterType,
                              filterValue: option['value'],
                              title: option['name'],
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: color.withOpacity(0.1), width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: widget.filterType == 'category'
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.asset(
                                      'assets/category_images/${_getCategoryImageName(option['name'])}.jpg',
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: color.withOpacity(0.08),
                                          child: Icon(
                                            Icons.restaurant,
                                            color: color,
                                            size: 24,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: _buildCategoryIcon(option['name'], color),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option['name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: color.withOpacity(0.5),
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getFilterOptions(String filterType, RecipeProvider provider) {
    switch (filterType) {
      case 'category':
        return provider.categories
          .where((category) => category['name'] != 'Tümü')
          .map((category) => {
            'name': category['name'],
            'value': category['id'],
            'count': provider.getRecipesForCategory(category['id']).length,
          }).toList();
      
      case 'ingredient':
        // Malzeme seçenekleri (örnek)
        return [
          {'name': 'Tavuk', 'value': 'tavuk', 'count': 10},
          {'name': 'Patates', 'value': 'patates', 'count': 15},
          {'name': 'Domates', 'value': 'domates', 'count': 20},
        ];
      
      case 'cooking_time':
        // Pişirme süresi seçenekleri için dinamik sayılar
        final recipes = provider.recipes;
        int under30Count = 0;
        int between30And60Count = 0;
        int over60Count = 0;

        for (var recipe in recipes) {
          final cookTime = recipe['cooking_time']?.toString().toLowerCase() ?? '';
          int minutes = 0;
          
          if (cookTime.contains('saat')) {
            final hours = double.tryParse(cookTime.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
            minutes = (hours * 60).round();
          } else if (cookTime.contains('dk') || cookTime.contains('dakika')) {
            minutes = int.tryParse(cookTime.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          }

          if (minutes <= 30) {
            under30Count++;
          } else if (minutes > 30 && minutes <= 60) {
            between30And60Count++;
          } else if (minutes > 60) {
            over60Count++;
          }
        }

        return [
          {'name': '30 dakikadan az', 'value': 30, 'count': under30Count},
          {'name': '30-60 dakika', 'value': 60, 'count': between30And60Count},
          {'name': '60 dakikadan fazla', 'value': 61, 'count': over60Count},
        ];
      
      case 'serving_size':
        // Porsiyon sayısı seçenekleri için dinamik sayılar
        final recipes = provider.recipes;
        int under2Count = 0;
        int between2And4Count = 0;
        int between4And6Count = 0;
        int over6Count = 0;

        for (var recipe in recipes) {
          final servingSize = recipe['serving_size']?.toString() ?? '';
          final size = int.tryParse(servingSize.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

          if (size <= 2) {
            under2Count++;
          } else if (size > 2 && size <= 4) {
            between2And4Count++;
          } else if (size > 4 && size <= 6) {
            between4And6Count++;
          } else if (size > 6) {
            over6Count++;
          }
        }

        return [
          {'name': '1-2 Kişilik', 'value': 2, 'count': under2Count},
          {'name': '3-4 Kişilik', 'value': 4, 'count': between2And4Count},
          {'name': '5-6 Kişilik', 'value': 6, 'count': between4And6Count},
          {'name': '6+ Kişilik', 'value': 7, 'count': over6Count},
        ];
      
      case 'preparation_time':
        // Hazırlık süresi seçenekleri için dinamik sayılar
        final recipes = provider.recipes;
        int under30Count = 0;
        int between30And60Count = 0;
        int over60Count = 0;

        for (var recipe in recipes) {
          final prepTime = recipe['preparation_time']?.toString().toLowerCase() ?? '';
          int minutes = 0;
          
          if (prepTime.contains('saat')) {
            final hours = double.tryParse(prepTime.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
            minutes = (hours * 60).round();
          } else if (prepTime.contains('dk') || prepTime.contains('dakika')) {
            minutes = int.tryParse(prepTime.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          }

          if (minutes <= 30) {
            under30Count++;
          } else if (minutes > 30 && minutes <= 60) {
            between30And60Count++;
          } else if (minutes > 60) {
            over60Count++;
          }
        }

        return [
          {'name': '30 dakikadan az', 'value': 30, 'count': under30Count},
          {'name': '30-60 dakika', 'value': 60, 'count': between30And60Count},
          {'name': '60 dakikadan fazla', 'value': 61, 'count': over60Count},
        ];
      
      default:
        return [];
    }
  }

  Widget _buildCategoryIcon(String category, Color color) {
    if (category.contains('Kişilik')) {
      final servingSize = category.toLowerCase();
      return Stack(
        children: [
          Icon(Icons.group_rounded, color: color, size: 28),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                servingSize.contains('1-2')
                    ? '2'
                    : servingSize.contains('3-4')
                        ? '4'
                        : servingSize.contains('5-6')
                            ? '6'
                            : '6+',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (category.contains('dakika')) {
      if (category.contains('30 dakikadan az')) {
        return Stack(
          children: [
            Icon(Icons.timer_outlined, color: color, size: 28),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '30-',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      } else if (category.contains('30-60')) {
        return Stack(
          children: [
            Icon(Icons.timer, color: color, size: 28),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '45',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      } else {
        return Stack(
          children: [
            Icon(Icons.hourglass_empty, color: color, size: 28),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '60+',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      }
    }

    switch (category.toLowerCase()) {
      case 'ana yemek':
        return Stack(
          children: [
            Icon(Icons.restaurant_rounded, color: color, size: 28),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.star_rounded, color: color, size: 12),
              ),
            ),
          ],
        );
      case 'aperatif':
        return Stack(
          children: [
            Icon(Icons.tapas_rounded, color: color, size: 28),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.local_pizza_rounded, color: color, size: 12),
              ),
            ),
          ],
        );
      case 'çorba':
        return Stack(
          children: [
            Icon(Icons.soup_kitchen_rounded, color: color, size: 28),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.water_drop_rounded, color: color, size: 12),
              ),
            ),
          ],
        );
      case 'içecek':
        return Stack(
          children: [
            Icon(Icons.local_cafe_rounded, color: color, size: 28),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.local_bar_rounded, color: color, size: 12),
              ),
            ),
          ],
        );
      case 'kahvaltılık':
        return Stack(
          children: [
            Icon(Icons.free_breakfast_rounded, color: color, size: 28),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.egg_rounded, color: color, size: 12),
              ),
            ),
          ],
        );
      case 'salata':
        return Stack(
          children: [
            Icon(Icons.eco_rounded, color: color, size: 28),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.spa_rounded, color: color, size: 12),
              ),
            ),
          ],
        );
      case 'tatlı':
        return Stack(
          children: [
            Icon(Icons.cake_rounded, color: color, size: 28),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.icecream_rounded, color: color, size: 12),
              ),
            ),
          ],
        );
      default:
        return Icon(Icons.restaurant_menu_rounded, color: color, size: 28);
    }
  }

  Color _getCategoryColor(String category) {
    if (category.contains('Kişilik')) {
      if (category.contains('1-2')) {
        return const Color(0xFF66BB6A); // Soft Green
      } else if (category.contains('3-4')) {
        return const Color(0xFF5C6BC0); // Soft Indigo
      } else if (category.contains('5-6')) {
        return const Color(0xFF7E57C2); // Soft Purple
      } else {
        return const Color(0xFFFF7043); // Soft Deep Orange
      }
    }

    if (category.contains('dakika')) {
      if (category.contains('30 dakikadan az')) {
        return const Color(0xFF26A69A); // Soft Teal
      } else if (category.contains('30-60')) {
        return const Color(0xFF5C6BC0); // Soft Indigo
      } else {
        return const Color(0xFFEC407A); // Soft Pink
      }
    }

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

  Widget _buildFilteredRecipesList(List<Map<String, dynamic>> recipes) {
    if (recipes.isEmpty) {
      return Center(
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
              'Bu kriterlere uygun tarif bulunamadı',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
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
                    builder: (context) => RecipeDetailScreen(recipe: Recipe.fromJson(recipe)),
                  ),
                );
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: recipe['image_filename'] != null && recipe['image_filename'].toString().isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.asset(
                            'assets/recipe_images/${recipe['image_filename']}',
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.orange.shade200,
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
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.orange.shade200,
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
                        ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        const Spacer(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.remove_red_eye_outlined,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${recipe['views'] ?? 0}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
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
      },
    );
  }

  Widget _buildFilterIcon(String filterType, String option, Color color) {
    if (filterType == 'serving_size') {
      final servingSize = option.toLowerCase();
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.restaurant_rounded,
                color: color,
                size: 28,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  servingSize.contains('1-2')
                      ? '2'
                      : servingSize.contains('3-4')
                          ? '4'
                          : servingSize.contains('5-6')
                              ? '6'
                              : '6+',
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
      );
    }
    // Varsayılan ikon
    return Icon(Icons.restaurant_menu_rounded, color: color, size: 28);
  }

  Color _getFilterColor(String filterType, String option) {
    if (filterType == 'serving_size') {
      if (option.contains('1-2')) {
        return const Color(0xFF4CAF50); // Yumuşak yeşil
      } else if (option.contains('3-4')) {
        return const Color(0xFF42A5F5); // Yumuşak mavi
      } else if (option.contains('5-6')) {
        return const Color(0xFFAB47BC); // Yumuşak mor
      } else {
        return const Color(0xFFFF7043); // Yumuşak turuncu
      }
    }
    // Varsayılan renk
    return Colors.grey;
  }

  String _getCategoryImageName(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'ana yemek':
        return 'ana_yemek';
      case 'aperatif':
        return 'aperatif';
      case 'çorba':
        return 'corba';
      case 'içecek':
        return 'icecek';
      case 'kahvaltılık':
        return 'kahvaltilik';
      case 'salata':
        return 'salata';
      case 'tatlı':
        return 'tatli';
      case 'yapay zeka tariflerim':
        return 'yapay_zeka_tariflerim';
      default:
        return '';
    }
  }
}

class FilteredRecipesResultScreen extends StatelessWidget {
  final String filterType;
  final dynamic filterValue;
  final String title;

  const FilteredRecipesResultScreen({
    Key? key,
    required this.filterType,
    required this.filterValue,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Consumer<RecipeProvider>(
        builder: (context, recipeProvider, child) {
          if (recipeProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          List<Map<String, dynamic>> filteredRecipes = [];
          
          switch (filterType) {
            case 'category':
              filteredRecipes = recipeProvider.getRecipesForCategory(filterValue);
              break;
            case 'ingredient':
              // Malzemeye göre filtreleme
              filteredRecipes = recipeProvider.recipes
                  .where((recipe) => recipe['ingredients'].toString().toLowerCase().contains(filterValue))
                  .toList();
              break;
            case 'cooking_time':
              // Pişirme süresine göre filtreleme
              filteredRecipes = recipeProvider.recipes
                  .where((recipe) {
                    final cookTime = recipe['cooking_time']?.toString().toLowerCase() ?? '';
                    int minutes = 0;
                    if (cookTime.contains('saat')) {
                      final hours = double.tryParse(cookTime.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
                      minutes = (hours * 60).round();
                    } else if (cookTime.contains('dk') || cookTime.contains('dakika')) {
                      minutes = int.tryParse(cookTime.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                    }
                    if (filterValue == 30) {
                      return minutes <= 30;
                    } else if (filterValue == 60) {
                      return minutes > 30 && minutes <= 60;
                    } else if (filterValue == 61) {
                      return minutes > 60;
                    }
                    return false;
                  })
                  .toList();
              break;
            case 'preparation_time':
              // Hazırlık süresine göre filtreleme
              filteredRecipes = recipeProvider.recipes
                  .where((recipe) {
                    final prepTime = recipe['preparation_time']?.toString().toLowerCase() ?? '';
                    int minutes = 0;
                    if (prepTime.contains('saat')) {
                      final hours = double.tryParse(prepTime.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
                      minutes = (hours * 60).round();
                    } else if (prepTime.contains('dk') || prepTime.contains('dakika')) {
                      minutes = int.tryParse(prepTime.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                    }
                    if (filterValue == 30) {
                      return minutes <= 30;
                    } else if (filterValue == 60) {
                      return minutes > 30 && minutes <= 60;
                    } else if (filterValue == 61) {
                      return minutes > 60;
                    }
                    return false;
                  })
                  .toList();
              break;
            case 'serving_size':
              // Porsiyon sayısına göre filtreleme
              filteredRecipes = recipeProvider.recipes
                  .where((recipe) {
                    final servingSize = recipe['serving_size']?.toString() ?? '';
                    final size = int.tryParse(servingSize.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                    
                    if (filterValue == 2) {
                      return size <= 2;
                    } else if (filterValue == 4) {
                      return size > 2 && size <= 4;
                    } else if (filterValue == 6) {
                      return size > 4 && size <= 6;
                    } else if (filterValue == 7) {
                      return size > 6;
                    }
                    return false;
                  })
                  .toList();
              break;
          }

          return _buildFilteredRecipesList(filteredRecipes);
        },
      ),
    );
  }

  Widget _buildFilteredRecipesList(List<Map<String, dynamic>> recipes) {
    if (recipes.isEmpty) {
      return Center(
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
              'Bu kriterlere uygun tarif bulunamadı',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
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
                    builder: (context) => RecipeDetailScreen(recipe: Recipe.fromJson(recipe)),
                  ),
                );
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: recipe['image_filename'] != null && recipe['image_filename'].toString().isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.asset(
                            'assets/recipe_images/${recipe['image_filename']}',
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.orange.shade200,
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
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.orange.shade200,
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
                        ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        const Spacer(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.remove_red_eye_outlined,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${recipe['views'] ?? 0}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
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
      },
    );
  }
} 