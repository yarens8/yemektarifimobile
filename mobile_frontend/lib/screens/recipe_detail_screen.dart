import 'package:flutter/material.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> recipe;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: recipe['image_filename'] != null && recipe['image_filename'].toString().isNotEmpty
                ? Image.asset(
                    'assets/recipe_images/${recipe['image_filename']}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('Resim yüklenirken hata: $error');
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRecipeInfo(),
                  const SizedBox(height: 24),
                  _buildIngredients(),
                  const SizedBox(height: 24),
                  _buildInstructions(),
                  if (recipe['tips'] != null &&
                      recipe['tips'].toString().isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildTips(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          recipe['title'] ?? 'İsimsiz Tarif',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.person,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              recipe['username'] ?? 'Anonim',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.timer,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              '${recipe['preparation_time'] ?? 0} dk',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.people,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              '${recipe['serving_size'] ?? 0} kişilik',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIngredients() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Malzemeler',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          recipe['ingredients'] ?? 'Malzeme listesi bulunamadı',
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hazırlanışı',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          recipe['instructions'] ?? 'Hazırlanış adımları bulunamadı',
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Püf Noktaları',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            recipe['tips'],
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
