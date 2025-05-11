import 'package:flutter/material.dart';
import '../models/recipe.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool showMatchingIngredients;
  final VoidCallback? onTap;

  const RecipeCard({
    Key? key,
    required this.recipe,
    this.showMatchingIngredients = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SOLDA GÖRSEL
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/recipe_images/${recipe.imageFilename}',
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 64,
                    height: 64,
                    color: Colors.grey[200],
                    child: Icon(Icons.restaurant, color: Colors.grey[400]),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // SAĞDA BİLGİLER
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarif başlığı
                    Text(
                      recipe.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),

                    // Eşleşen malzemeler
                    if (showMatchingIngredients && recipe.matchingIngredients != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Eşleşen Malzemeler:',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Wrap(
                            spacing: 8,
                            children: recipe.matchingIngredients!.map((ingredient) {
                              return Chip(
                                label: Text(ingredient),
                                backgroundColor: Colors.green[100],
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),

                    // Eksik malzemeler
                    if (showMatchingIngredients && recipe.requiredIngredients != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Eksik Malzemeler:',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Wrap(
                            spacing: 8,
                            children: recipe.requiredIngredients!.map((ingredient) {
                              return Chip(
                                label: Text(ingredient),
                                backgroundColor: Colors.red[100],
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),

                    // Kullanıcı adı, puan ve süre satırı
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            recipe.username,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (recipe.averageRating > 0) ...[
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            recipe.averageRating.toStringAsFixed(1),
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${recipe.ratingCount})',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            recipe.cookingTime != null ? '${recipe.cookingTime} dk' : '',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${recipe.views} görüntülenme',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
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
            ],
          ),
        ),
      ),
    );
  }
} 