import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';

const Color kPrimary = Color(0xFFA259FF); // Mor
const Color kAccent = Color(0xFFFF7262); // Pembe
const Color kBg = Color(0xFFF5F6FA); // Açık arka plan
const Color kText = Color(0xFF22223B); // Koyu yazı
const Color kCardBg = Color(0xFFF3EFFF); // Hafif mor kart arka planı
const Color kHint = Color(0xFFB39DDB); // Açık mor hint
const Color kPink = Color(0xFFFF69B4); // Canlı pembe

class RecipeEditScreen extends StatefulWidget {
  final Recipe recipe;
  const RecipeEditScreen({Key? key, required this.recipe}) : super(key: key);

  @override
  State<RecipeEditScreen> createState() => _RecipeEditScreenState();
}

class _RecipeEditScreenState extends State<RecipeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _ingredientsController;
  late TextEditingController _instructionsController;
  late TextEditingController _servingsController;
  late TextEditingController _prepTimeController;
  late TextEditingController _cookTimeController;
  late TextEditingController _tipsController;
  late TextEditingController _imageController;
  int _selectedCategoryId = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.recipe.title);
    _ingredientsController = TextEditingController(text: widget.recipe.ingredients);
    _instructionsController = TextEditingController(text: widget.recipe.instructions);
    _servingsController = TextEditingController(text: widget.recipe.servingSize);
    _prepTimeController = TextEditingController(text: widget.recipe.prepTime);
    _cookTimeController = TextEditingController(text: widget.recipe.cookingTime);
    _tipsController = TextEditingController(text: widget.recipe.tips);
    _imageController = TextEditingController(text: widget.recipe.imageFilename);
    _selectedCategoryId = widget.recipe.categoryId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    _servingsController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _tipsController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _updateRecipe() async {
    if (!_formKey.currentState!.validate()) return;
    if (_servingsController.text.trim().isEmpty ||
        _imageController.text.trim().isEmpty ||
        _instructionsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm zorunlu alanları doldurun!')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final updatedFields = {
      'id': widget.recipe.id,
      'title': _titleController.text,
      'ingredients': _ingredientsController.text,
      'instructions': _instructionsController.text,
      'serving_size': _servingsController.text,
      'prep_time': _prepTimeController.text,
      'cooking_time': _cookTimeController.text,
      'tips': _tipsController.text,
      'image_filename': _imageController.text,
      'category_id': _selectedCategoryId,
      'user_id': widget.recipe.userId,
    };
    final result = await RecipeService().updateRecipe(updatedFields);
    setState(() => _isLoading = false);
    if (result) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tarif güncellendi')));
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Güncelleme başarısız')));
      }
    }
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kHint),
        filled: true,
        fillColor: kCardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kAccent, width: 2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {'id': 1, 'name': 'Ana Yemek'},
      {'id': 5, 'name': 'Aperatif'},
      {'id': 2, 'name': 'Çorba'},
      {'id': 6, 'name': 'İçecek'},
      {'id': 7, 'name': 'Kahvaltılık'},
      {'id': 3, 'name': 'Salata'},
      {'id': 4, 'name': 'Tatlı'},
      {'id': 8, 'name': 'Tümü'},
      {'id': 9, 'name': 'Yapay Zeka Tariflerim'},
    ];
    final List<int> categoryIds = categories.map((c) => c['id'] as int).toList();
    final int dropdownValue = categoryIds.contains(_selectedCategoryId) ? _selectedCategoryId : categories.first['id'];
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: kPrimary),
        title: const Text('Tarifi Düzenle', style: TextStyle(color: kText, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    _FieldLabel('Tarif Adı'),
                    _FieldCard(
                      child: TextFormField(
                        controller: _titleController,
                        decoration: _inputDecoration('Tarif adı'),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: kText),
                        validator: (v) => v == null || v.isEmpty ? 'Başlık gerekli' : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel('Malzemeler'),
                    _FieldCard(
                      child: TextFormField(
                        controller: _ingredientsController,
                        decoration: _inputDecoration('Malzemeleri girin'),
                        maxLines: 4,
                        style: const TextStyle(fontSize: 16, color: kText),
                        validator: (v) => v == null || v.isEmpty ? 'Malzemeler gerekli' : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel('Hazırlanış'),
                    _FieldCard(
                      child: TextFormField(
                        controller: _instructionsController,
                        decoration: _inputDecoration('Hazırlanışı yazın'),
                        maxLines: 5,
                        style: const TextStyle(fontSize: 16, color: kText),
                        validator: (v) => v == null || v.isEmpty ? 'Hazırlanış gerekli' : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel('Püf Noktası'),
                    _FieldCard(
                      child: TextFormField(
                        controller: _tipsController,
                        decoration: _inputDecoration('Varsa püf noktası yazın (isteğe bağlı)'),
                        maxLines: 2,
                        style: const TextStyle(fontSize: 16, color: kText),
                        // İsteğe bağlı, validator yok
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel('Porsiyon'),
                              _FieldCard(
                                child: TextFormField(
                                  controller: _servingsController,
                                  decoration: _inputDecoration('Örn: 4-5 Kişilik'),
                                  style: const TextStyle(fontSize: 16, color: kText),
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
                              _FieldLabel('Hazırlama Süresi'),
                              _FieldCard(
                                child: TextFormField(
                                  controller: _prepTimeController,
                                  decoration: _inputDecoration('Örn: 20 dk'),
                                  style: const TextStyle(fontSize: 16, color: kText),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel('Pişirme Süresi'),
                              _FieldCard(
                                child: TextFormField(
                                  controller: _cookTimeController,
                                  decoration: _inputDecoration('Örn: 40 dk'),
                                  style: const TextStyle(fontSize: 16, color: kText),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel('Görsel Dosya Adı'),
                    _FieldCard(
                      child: TextFormField(
                        controller: _imageController,
                        decoration: _inputDecoration('örn: yemek.jpg'),
                        style: const TextStyle(fontSize: 16, color: kText),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel('Kategori'),
                    _FieldCard(
                      child: DropdownButtonFormField<int>(
                        value: dropdownValue,
                        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                        items: categories
                            .map((cat) => DropdownMenuItem(
                                  value: cat['id'] as int,
                                  child: Text(cat['name'] as String),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedCategoryId = v ?? categories.first['id']),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [kPrimary, kAccent],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: kPrimary.withOpacity(0.18),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _updateRecipe,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Kaydet'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 2),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kPink),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final Widget child;
  const _FieldCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.zero,
      color: kCardBg,
      shadowColor: kPrimary.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: child,
      ),
    );
  }
} 