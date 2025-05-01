import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../models/recipe.dart';
import 'recipe_detail_screen.dart';
import 'filter_screen.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:http/http.dart' show HttpDate;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Ana Yemek';
  final ValueNotifier<int> _loadedImages = ValueNotifier<int>(0);
  final ValueNotifier<int> _totalImages = ValueNotifier<int>(0);
  final Map<String, int> _imageLoadStats = {};

  void _updateImageStats(String imagePath, String title) {
    print('Orijinal dosya adı: $imagePath');
    print('Tarif başlığı: $title');
    print('Resim yolu: assets/recipe_images/$imagePath');
    
    try {
      precacheImage(AssetImage('assets/recipe_images/$imagePath'), context);
      _imageLoadStats[imagePath] = (_imageLoadStats[imagePath] ?? 0) + 1;
    } catch (e) {
      print('Resim yüklenirken hata: $e');
      print('Exception: ${e.toString()}');
    }
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
  void dispose() {
    _loadedImages.dispose();
    _totalImages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.white,
            title: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Lezzetli Tarifler',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: _totalImages,
                  builder: (context, total, child) {
                    return ValueListenableBuilder<int>(
                      valueListenable: _loadedImages,
                      builder: (context, loaded, child) {
                        if (total > 0) {
                          return Text(
                            '$loaded/$total',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    );
                  },
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FilterScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: RecipeSearchDelegate(context.read<RecipeProvider>()),
                  );
                },
              ),
            ],
          ),
          Consumer<RecipeProvider>(
            builder: (context, provider, child) {
              return SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategoryList(provider),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                      child: Text(
                        'En Çok Görüntülenen Tarifler',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Consumer<RecipeProvider>(
            builder: (context, provider, child) {
              return _buildRecipeGrid(provider);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(RecipeProvider provider) {
    final categories = provider.categories;
    
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category['name'] == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              selected: isSelected,
              label: Text(category['name']),
              onSelected: (selected) {
                setState(() => _selectedCategory = category['name']);
              },
              backgroundColor: Colors.white,
              selectedColor: Colors.pink.shade100,
              checkmarkColor: Colors.pink,
              labelStyle: TextStyle(
                color: isSelected ? Colors.pink : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.pink : Colors.grey.shade300,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecipeGrid(RecipeProvider provider) {
    if (provider.isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Seçili kategorinin ID'sini bul
    final selectedCategoryId = provider.categories
        .firstWhere((category) => category['name'] == _selectedCategory, orElse: () => {'id': -1})['id'];

    // Seçili kategoriye ait tarifleri al ve görüntülenme sayısına göre sırala
    final recipes = (provider.recipesByCategory[selectedCategoryId] ?? [])
      ..sort((a, b) => (b['views'] ?? 0).compareTo(a['views'] ?? 0));
    
    // İlk 6 tarifi al
    final topRecipes = recipes.take(6).toList();

    if (topRecipes.isEmpty) {
      return SliverFillRemaining(
        child: Center(
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
                'Bu kategoride henüz tarif bulunmuyor',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildRecipeCard(topRecipes[index]),
          childCount: topRecipes.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(
                recipe: Recipe(
                  id: recipe['id'] ?? 0,
                  title: recipe['title'] ?? '',
                  description: recipe['description'],
                  imageUrl: recipe['image_filename'],
                  images: [],
                  userId: recipe['user_id'] ?? 0,
                  username: recipe['username'] ?? '',
                  categoryId: recipe['category_id'] ?? 0,
                  views: recipe['views'] ?? 0,
                  preparationTime: recipe['preparation_time']?.toString(),
                  cookingTime: recipe['cooking_time']?.toString(),
                  ingredients: recipe['ingredients'],
                  instructions: recipe['instructions'],
                  tips: recipe['tips'],
                  servingSize: recipe['serving_size']?.toString(),
                  difficulty: recipe['difficulty'],
                  createdAt: recipe['created_at'] != null ? _parseDate(recipe['created_at']) : null,
                  averageRating: (recipe['average_rating'] as num?)?.toDouble() ?? 0.0,
                  ratingCount: recipe['rating_count'] ?? 0,
                  userRating: recipe['user_rating'],
                ),
              ),
            ),
          );
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
                          print('Resim yüklenirken hata: $error');
                          print('Resim yolu: assets/recipe_images/${recipe['image_filename']}');
                          print('Tarif başlığı: ${recipe['title']}');
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
  }

  DateTime? _parseDate(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        if (dateStr.contains('GMT')) {
          final formatter = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US');
          return formatter.parse(dateStr);
        } else {
          return DateFormat("yyyy-MM-dd HH:mm:ss").parse(dateStr);
        }
      } catch (e) {
        print('Tarih ayrıştırma hatası: $e');
        print('Ayrıştırılamayan tarih: $dateStr');
        return null;
      }
    }
  }
}

class RecipeSearchDelegate extends SearchDelegate<String> {
  final RecipeProvider _recipeProvider;

  RecipeSearchDelegate(this._recipeProvider);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Tarif aramak için yazın',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _recipeProvider.searchRecipes(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Bir hata oluştu',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        final recipes = snapshot.data ?? [];

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
                  'Henüz tarif bulunmuyor',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return ListTile(
              leading: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.restaurant, color: Colors.grey.shade400),
              ),
              title: Text(recipe['title'] ?? ''),
              subtitle: Text(recipe['preparation_time'] ?? ''),
              trailing: Text('${recipe['views'] ?? 0} görüntülenme'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecipeDetailScreen(recipe: Recipe.fromJson(recipe)),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
