import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../models/recipe.dart';
import 'recipe_detail_screen.dart';
import 'filter_screen.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:http/http.dart' show HttpDate;
import '../providers/user_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = Provider.of<UserProvider>(context, listen: false).userId;
      context.read<RecipeProvider>().loadInitialData(userId);
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
    final categories = provider.categories.where((category) => category['name'] != 'Tümü' && category['name'] != 'Yapay Zeka Tariflerim').toList();
    
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
          childAspectRatio: 0.68,
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
                recipe: Recipe.fromJson(recipe),
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 135,
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
                        height: 135,
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
                      height: 135,
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
                    if ((recipe['serving_size'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.groups, size: 14, color: Colors.green[700]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              recipe['serving_size'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if ((recipe['average_rating'] ?? 0) > 0) ...[
                          Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              (recipe['average_rating'] ?? 0.0).toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '(${recipe['rating_count'] ?? 0})',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(
                          Icons.remove_red_eye_outlined,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${recipe['views'] ?? 0}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
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

    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _recipeProvider.searchRecipes(query, userId),
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
              leading: Builder(
                builder: (context) {
                  final imageFilename = recipe['image_filename'];
                  if (imageFilename != null && imageFilename.toString().isNotEmpty) {
                    final assetPath = 'assets/recipe_images/$imageFilename';
                    print('Aranan dosya: $assetPath');
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        assetPath,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('Görsel bulunamadı: $assetPath');
                          return Icon(Icons.restaurant, color: Colors.grey.shade400);
                        },
                      ),
                    );
                  } else {
                    return Icon(Icons.restaurant, color: Colors.grey.shade400);
                  }
                },
              ),
              title: Text(recipe['title'] ?? ''),
              subtitle: Text(
                recipe['cooking_time']?.toString() ?? 'Süre belirtilmemiş',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
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
