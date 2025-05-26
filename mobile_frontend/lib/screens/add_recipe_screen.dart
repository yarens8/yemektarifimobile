import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/recipe_service.dart';
import 'dart:io';
import 'dart:convert';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({Key? key}) : super(key: key);

  @override
  _AddRecipeScreenState createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipeService = RecipeService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController();
  final TextEditingController _cookTimeController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _tipsController = TextEditingController();
  
  String? _selectedCategory;
  File? _recipeImage;
  String? _base64Image;
  
  List<Map<String, dynamic>> categories = [
    {'id': 1, 'name': 'Ana Yemek'},
    {'id': 5, 'name': 'Aperatif'},
    {'id': 2, 'name': 'Çorba'},
    {'id': 6, 'name': 'İçecek'},
    {'id': 7, 'name': 'Kahvaltılık'},
    {'id': 3, 'name': 'Salata'},
    {'id': 4, 'name': 'Tatlı'},
  ];

  // Fotoğrafı base64'e çeviren yardımcı fonksiyon
  Future<String?> _imageToBase64(File? imageFile) async {
    if (imageFile == null) return null;
    List<int> imageBytes = await imageFile.readAsBytes();
    return base64Encode(imageBytes);
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080, // Resmi boyutunu sınırla
      maxHeight: 1080,
      imageQuality: 85, // Kaliteyi biraz düşür ama çok değil
    );
    
    if (image != null) {
      setState(() {
        _recipeImage = File(image.path);
      });
      
      // Resmi base64'e çevir
      _base64Image = await _imageToBase64(_recipeImage);
    }
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce giriş yapın')),
      );
      return;
    }

    try {
      // Yükleme göstergesi
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Tarifi kaydet
      final result = await _recipeService.createRecipe(
        title: _titleController.text,
        userId: user.id,
        categoryId: int.parse(_selectedCategory!),
        ingredients: _ingredientsController.text,
        instructions: _instructionsController.text,
        servings: _servingsController.text,
        prepTime: _prepTimeController.text,
        cookTime: _cookTimeController.text,
        tips: _tipsController.text,
        imageUrl: _base64Image, // Base64 formatındaki resmi gönder
      );

      // Yükleme göstergesini kapat
      Navigator.pop(context);

      if (result['success']) {
        // Başarılı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarif başarıyla eklendi'),
            backgroundColor: Colors.green,
          ),
        );
        // Ana sayfaya dön
        Navigator.pop(context);
      } else {
        // Hata mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Yükleme göstergesini kapat
      Navigator.pop(context);
      // Hata mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.pink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Yeni Tarif',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Fotoğraf Seçimi
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: _recipeImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        child: Image.file(
                          _recipeImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 50,
                            color: Colors.pink,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Yemek Fotoğrafı Ekle',
                            style: TextStyle(
                              color: Colors.pink,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarif Adı
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'Tarif Adı',
                        hintText: 'Örn: Çikolatalı Brownie',
                        prefixIcon: Icon(Icons.restaurant_menu, color: Colors.pink),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.pink),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.pink, width: 2),
                        ),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Lütfen tarif adını girin' : null,
                    ),
                    SizedBox(height: 20),

                    // Kategori Seçimi
                    DropdownButtonFormField<int>(
                      value: _selectedCategory != null ? int.parse(_selectedCategory!) : null,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        prefixIcon: Icon(Icons.category, color: Colors.pink),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.pink, width: 2),
                        ),
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem(
                          value: category['id'] as int,
                          child: Text(category['name'] as String),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedCategory = newValue?.toString();
                        });
                      },
                      validator: (value) => value == null ? 'Lütfen kategori seçin' : null,
                    ),
                    SizedBox(height: 20),

                    // Porsiyon ve Süreler
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _servingsController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Porsiyon',
                              hintText: '4-6',
                              prefixIcon: Icon(Icons.people, color: Colors.pink),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.pink, width: 2),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _prepTimeController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Hazırlama (dk)',
                              hintText: '20',
                              prefixIcon: Icon(Icons.timer, color: Colors.pink),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.pink, width: 2),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _cookTimeController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Pişirme (dk)',
                              hintText: '45',
                              prefixIcon: Icon(Icons.local_fire_department, color: Colors.pink),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.pink, width: 2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Malzemeler
                    Text(
                      'Malzemeler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade50,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.pink),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Her malzemeyi yeni bir satıra yazın',
                              style: TextStyle(color: Colors.pink.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _ingredientsController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: '2 yumurta\n1 su bardağı şeker\n250g un',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.pink, width: 2),
                        ),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Lütfen malzemeleri girin' : null,
                    ),
                    SizedBox(height: 20),

                    // Hazırlanışı
                    Text(
                      'Hazırlanışı',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade50,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.pink),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Her adımı ayrı bir madde olarak yazın',
                              style: TextStyle(color: Colors.pink.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _instructionsController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText: '1. Fırını 180 dereceye ısıtın\n2. Yumurta ve şekeri çırpın',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.pink, width: 2),
                        ),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Lütfen hazırlanış adımlarını girin' : null,
                    ),
                    SizedBox(height: 20),

                    // İpuçları
                    Text(
                      'İpuçları ve Öneriler (İsteğe Bağlı)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _tipsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Daha iyi sonuç için önerilerinizi yazın...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.pink, width: 2),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),

                    // Kaydet Butonu
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveRecipe,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          'Tarifi Paylaş',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

  @override
  void dispose() {
    _titleController.dispose();
    _servingsController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    _tipsController.dispose();
    super.dispose();
  }
} 