import 'package:flutter/material.dart';
import 'filtered_recipes_list_screen.dart';

class FilterScreen extends StatelessWidget {
  const FilterScreen({Key? key}) : super(key: key);

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
        title: const Text(
          'Tarifleri Filtrele',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            _buildFilterCard(
              context,
              'Kategoriler',
              'Yemek türüne göre tarifleri keşfet',
              'category',
              const Color(0xFF6C63FF),
              const Color(0xFFF3F2FF),
            ),
            _buildFilterCard(
              context,
              'Malzemeler',
              'Malzemelere göre tarifleri filtrele',
              'ingredient',
              const Color(0xFF00C2B8),
              const Color(0xFFE8F8F7),
            ),
            _buildFilterCard(
              context,
              'Hazırlık Süresi',
              'Hazırlama süresine göre tarifleri bul',
              'preparation_time',
              const Color(0xFFFF6B6B),
              const Color(0xFFFFF2F2),
            ),
            _buildFilterCard(
              context,
              'Porsiyon Sayısı',
              'Kişi sayısına göre tarifleri listele',
              'serving_size',
              const Color(0xFF4ECDC4),
              const Color(0xFFEFFBFA),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard(
    BuildContext context,
    String title,
    String subtitle,
    String filterType,
    Color color,
    Color backgroundColor,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FilteredRecipesListScreen(
                  filterType: filterType,
                  title: title,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIcon(filterType),
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: color,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String filterType) {
    switch (filterType) {
      case 'category':
        return Icons.grid_view_rounded;
      case 'ingredient':
        return Icons.restaurant_menu_rounded;
      case 'preparation_time':
        return Icons.schedule_rounded;
      case 'serving_size':
        return Icons.groups_rounded;
      default:
        return Icons.list_rounded;
    }
  }
} 