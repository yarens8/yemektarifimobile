import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import 'filtered_recipes_list_screen.dart';

class FilteredRecipesScreen extends StatelessWidget {
  const FilteredRecipesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtreleme Seçenekleri'),
      ),
      body: ListView(
        children: [
          _buildFilterSection(
            context,
            'Kategoriler',
            Icons.category,
            () {
              // Kategoriler sayfasına yönlendir
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FilteredRecipesListScreen(
                    filterType: 'category',
                    title: 'Kategoriler',
                  ),
                ),
              );
            },
          ),
          _buildFilterSection(
            context,
            'Malzemeler',
            Icons.local_grocery_store,
            () {
              // Malzemeler sayfasına yönlendir
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FilteredRecipesListScreen(
                    filterType: 'ingredient',
                    title: 'Malzemeler',
                  ),
                ),
              );
            },
          ),
          _buildFilterSection(
            context,
            'Pişirme Süresi',
            Icons.local_fire_department,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FilteredRecipesListScreen(
                    filterType: 'cooking_time',
                    title: 'Pişirme Süresi',
                  ),
                ),
              );
            },
          ),
          _buildFilterSection(
            context,
            'Hazırlık Süresi',
            Icons.timer,
            () {
              // Hazırlık süresi sayfasına yönlendir
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FilteredRecipesListScreen(
                    filterType: 'preparation_time',
                    title: 'Hazırlık Süresi',
                  ),
                ),
              );
            },
          ),
          _buildFilterSection(
            context,
            'Porsiyon Sayısı',
            Icons.people,
            () {
              // Porsiyon sayısı sayfasına yönlendir
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FilteredRecipesListScreen(
                    filterType: 'serving_size',
                    title: 'Porsiyon Sayısı',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
} 