import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Profil',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Ayarlar sayfasına yönlendir
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.pink,
            child: Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Misafir Kullanıcı',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          _buildProfileMenuItem(
            icon: Icons.favorite,
            title: 'Favori Tariflerim',
            onTap: () {
              // TODO: Favori tariflere yönlendir
            },
          ),
          _buildProfileMenuItem(
            icon: Icons.history,
            title: 'Son Görüntülenenler',
            onTap: () {
              // TODO: Son görüntülenenlere yönlendir
            },
          ),
          _buildProfileMenuItem(
            icon: Icons.add_circle,
            title: 'Tarif Ekle',
            onTap: () {
              // TODO: Tarif ekleme sayfasına yönlendir
            },
          ),
          _buildProfileMenuItem(
            icon: Icons.notifications,
            title: 'Bildirimler',
            onTap: () {
              // TODO: Bildirimlere yönlendir
            },
          ),
          _buildProfileMenuItem(
            icon: Icons.help,
            title: 'Yardım',
            onTap: () {
              // TODO: Yardım sayfasına yönlendir
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.pink),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
} 