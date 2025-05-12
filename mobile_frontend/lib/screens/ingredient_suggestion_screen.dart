import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/recipe_service.dart';
import '../models/recipe.dart';
import '../widgets/recipe_card.dart';
import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'dart:ui';
import '../services/auth_service.dart';
import '../screens/recipe_detail_screen.dart';

class IngredientSuggestionScreen extends StatefulWidget {
  @override
  _IngredientSuggestionScreenState createState() => _IngredientSuggestionScreenState();
}

class _IngredientSuggestionScreenState extends State<IngredientSuggestionScreen> with SingleTickerProviderStateMixin {
  final RecipeService _recipeService = RecipeService();
  final List<String> _selectedIngredients = [];
  List<Recipe> _suggestedRecipes = [];
  bool _isLoading = false;
  final TextEditingController _ingredientController = TextEditingController();
  late AnimationController _animationController;

  // Kategori listesi ve ikonları
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Sebzeler', 'icon': Icons.eco},
    {'name': 'Meyveler', 'icon': Icons.apple},
    {'name': 'Et & Tavuk', 'icon': Icons.set_meal},
    {'name': 'Deniz Ürünleri', 'icon': Icons.set_meal_outlined},
    {'name': 'Baharatlar', 'icon': Icons.spa},
    {'name': 'Baklagiller', 'icon': Icons.grass},
    {'name': 'Süt Ürünleri', 'icon': Icons.icecream},
    {'name': 'Yağlar', 'icon': Icons.oil_barrel},
    {'name': 'Tahıllar', 'icon': Icons.rice_bowl},
    {'name': 'İçecekler', 'icon': Icons.local_drink},
  ];
  int? _selectedCategoryIndex;

  // Filtre seçenekleri
  final List<String> _yemekTuruOptions = [
    'Tümü', 'Ana Yemek', 'Aperatif', 'Çorba', 'İçecek', 'Kahvaltılık', 'Salata', 'Tatlı'
  ];
  final List<String> _pisirmeSuresiOptions = [
    'Tümü', '15 dakika veya az', '30 dakika veya az', '45 dakika veya az', '1 saat veya az'
  ];
  final List<String> _porsiyonOptions = [
    'Tümü', '1-2 Kişilik', '3-4 Kişilik', '5-6 Kişilik', '6+ Kişilik'
  ];
  String _selectedYemekTuru = 'Tümü';
  String _selectedPisirmeSuresi = 'Tümü';
  String _selectedPorsiyon = 'Tümü';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _suggestRecipes() async {
    if (_selectedIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen en az bir malzeme ekleyin!')),
      );
      print('[DEBUG] Butona basıldı ama hiç malzeme yok.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('[DEBUG] Tarif öner API çağrısı başlıyor.');
      print('[DEBUG] Seçili malzemeler: ${_selectedIngredients.toString()}');
      print('[DEBUG] Token kontrolü: ${await AuthService.getToken()}');
      
      final recipes = await _recipeService.suggestRecipes(
        ingredients: _selectedIngredients,
      );
      
      print('[DEBUG] API cevabı geldi. Tarif sayısı: ${recipes.length}');
      print('[DEBUG] İlk tarif detayları: ${recipes.isNotEmpty ? recipes.first.toJson() : "Tarif yok"}');

      setState(() {
        _suggestedRecipes = recipes;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
      });
      print('[DEBUG] Tarif öner API hatası: $e');
      print('[DEBUG] Hata stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tarif önerileri alınamadı: $e')),
      );
    }
  }

  void _addIngredient() {
    final value = _ingredientController.text.trim();
    if (value.isNotEmpty && !_selectedIngredients.contains(value)) {
      setState(() {
        _selectedIngredients.add(value);
        _ingredientController.clear();
      });
      _animationController.forward(from: 0);
    }
  }

  // Malzeme türüne göre emoji döndür (örnek)
  String _ingredientEmoji(String name) {
    final n = name.toLowerCase();
    if (n.contains('domates')) return '🍅';
    if (n.contains('biber')) return '🫑';
    if (n.contains('patates')) return '🥔';
    if (n.contains('soğan')) return '🧅';
    if (n.contains('havuç')) return '🥕';
    if (n.contains('yumurta')) return '🥚';
    if (n.contains('tavuk')) return '🍗';
    if (n.contains('et') || n.contains('kıyma')) return '🥩';
    if (n.contains('peynir')) return '🧀';
    if (n.contains('süt')) return '🥛';
    if (n.contains('un')) return '🌾';
    if (n.contains('şeker')) return '🍬';
    if (n.contains('tuz')) return '🧂';
    if (n.contains('balık')) return '🐟';
    if (n.contains('elma')) return '🍏';
    if (n.contains('muz')) return '🍌';
    if (n.contains('limon')) return '🍋';
    return '🥄';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Malzemelerinize Göre Tarifler', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0.5,
      ),
      body: Container(
        color: Colors.white,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          children: [
            const SizedBox(height: 10),
            // Kategori çipleri
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final selected = _selectedCategoryIndex == index;
                  return ChoiceChip(
                    label: Row(
                      children: [
                        Icon(cat['icon'], size: 18, color: selected ? Colors.white : Colors.black54),
                        const SizedBox(width: 4),
                        Text(cat['name'], style: TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    selected: selected,
                    selectedColor: Colors.pink.shade400,
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
                    onSelected: (_) {
                      setState(() {
                        _selectedCategoryIndex = index;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 2),
            // Malzeme ekleme alanı
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
        children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _ingredientController,
                        decoration: const InputDecoration(
                          hintText: 'Malzeme eklemek için yazın...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        ),
                        style: const TextStyle(fontSize: 16),
                        onSubmitted: (_) => _addIngredient(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Material(
                    color: Colors.pink.shade400,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _addIngredient,
                      child: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Icon(Icons.add, color: Colors.white, size: 26),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Kıvrımlı ve dalgalı kenarlı kağıt efekti (gelişmiş)
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Transform.rotate(
                angle: -0.04, // Kağıdı hafif sola eğ
                child: CustomPaint(
                  painter: _CurvedPaperPainterV2(),
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    alignment: Alignment.topLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
              children: [
                Text(
                              "Malzemeler",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.pink.shade400,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text("📝", style: TextStyle(fontSize: 20)),
                          ],
                ),
                        const SizedBox(height: 16),
                        if (_selectedIngredients.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final chipWidth = (constraints.maxWidth - 16) / 2;
                                return Wrap(
                  spacing: 8,
                                  runSpacing: 10,
                                  children: List.generate(_selectedIngredients.length, (index) {
                                    final ingredient = _selectedIngredients[index];
                                    return SizedBox(
                                      width: chipWidth,
                                      child: Chip(
                                        avatar: Text(_ingredientEmoji(ingredient), style: const TextStyle(fontSize: 18)),
                                        label: Text(
                                          ingredient.length > 10 ? ingredient.substring(0, 10) + '…' : ingredient,
                                          style: const TextStyle(fontSize: 14, color: Colors.pink, fontWeight: FontWeight.w600),
                                        ),
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        elevation: 2,
                                        shadowColor: Colors.black12,
                                        deleteIcon: Icon(Icons.close, size: 16, color: Colors.pink.shade300),
                      onDeleted: () {
                        setState(() {
                                            _selectedIngredients.removeAt(index);
                        });
                      },
                                      ),
                    );
                                  }),
                                );
                              },
                            ),
                          ),
                        if (_selectedIngredients.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Text(
                              "Malzeme ekleyin ve tarif önerilerini görün!",
                              style: TextStyle(color: Colors.pink.shade200, fontSize: 15, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Tarif filtreleri kartı
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tarif Filtreleri',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Yemek Türü
                          SizedBox(
                            width: 140,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.restaurant_menu, size: 18, color: Colors.pink),
                                    SizedBox(width: 6),
                                    Text('Yemek Türü', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedYemekTuru,
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                      style: const TextStyle(fontSize: 15, color: Colors.black87),
                                      borderRadius: BorderRadius.circular(12),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedYemekTuru = value!;
                                        });
                                      },
                                      items: _yemekTuruOptions.map((option) {
                                        return DropdownMenuItem<String>(
                                          value: option,
                                          child: Text(option),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Pişirme Süresi
                          SizedBox(
                            width: 150,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.timer, size: 18, color: Colors.pink),
                                    SizedBox(width: 6),
                                    Text('Pişirme Süresi', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedPisirmeSuresi,
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                      style: const TextStyle(fontSize: 15, color: Colors.black87),
                                      borderRadius: BorderRadius.circular(12),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedPisirmeSuresi = value!;
                                        });
                                      },
                                      items: _pisirmeSuresiOptions.map((option) {
                                        return DropdownMenuItem<String>(
                                          value: option,
                                          child: Text(option),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Porsiyon
                          SizedBox(
                            width: 120,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.groups, size: 18, color: Colors.pink),
                                    SizedBox(width: 6),
                                    Text('Porsiyon', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedPorsiyon,
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                      style: const TextStyle(fontSize: 15, color: Colors.black87),
                                      borderRadius: BorderRadius.circular(12),
                                      onChanged: (value) {
                      setState(() {
                                          _selectedPorsiyon = value!;
                                        });
                                      },
                                      items: _porsiyonOptions.map((option) {
                                        return DropdownMenuItem<String>(
                                          value: option,
                                          child: Text(option),
                                        );
                                      }).toList(),
                                    ),
                ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Tarifleri Keşfet butonu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 3,
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.pink.shade100,
                  ).copyWith(
                    backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
                      return null;
                    }),
                  ),
                  onPressed: _suggestRecipes,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF857A6), Color(0xFFFF5858)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
            ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: const Text(
                        'Tarifleri Keşfet',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Tarif önerileri listesi
            Container(
              height: 300,
              color: Colors.white,
            child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.pink))
                : _suggestedRecipes.isEmpty
                    ? Center(
                          child: Text(
                            'Henüz tarif önerisi yok',
                            style: TextStyle(color: Colors.pink.shade400, fontSize: 17, fontWeight: FontWeight.w600),
                          ),
                      )
                    : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _suggestedRecipes.length,
                        itemBuilder: (context, index) {
                          final recipe = _suggestedRecipes[index];
                          return RecipeCard(
                            recipe: recipe,
                            showMatchingIngredients: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RecipeDetailScreen(recipe: recipe),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
        ),
      ),
    );
  }
}

class _CurvedPaperPainterV2 extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Kağıt gölgesi
    final shadowPaint = Paint()
      ..color = Colors.pink.shade100.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 16, size.width - 8, size.height - 8),
        const Radius.circular(36),
      ),
      shadowPaint,
    );

    // 2. Kağıt path'i (daha fazla ve küçük dalga)
    final path = Path();
    path.moveTo(32, 0);
    // Üst kenar
    path.lineTo(size.width - 32, 0);
    // Sağ kenar
    path.lineTo(size.width - 16, size.height - 32);
    // Alt kenar (daha fazla ve küçük dalga)
    double x = size.width - 16;
    double y = size.height - 8;
    bool up = true;
    while (x > 48) {
      final nextX = x - 18;
      final controlX = x - 9;
      final controlY = y + (up ? 7 : -7);
      path.quadraticBezierTo(controlX, controlY, nextX, y);
      x = nextX;
      up = !up;
    }
    path.lineTo(48, y);
    path.quadraticBezierTo(16, y, 32, size.height - 32);
    // Sol kenar
    path.lineTo(16, 32);
    path.quadraticBezierTo(16, 8, 32, 0);
    path.close();

    // 3. Kağıt dolgusu (ortası beyaz, kenarlara doğru çok hafif pembe radial gradient)
    final paperGradient = RadialGradient(
      center: Alignment.center,
      radius: 0.95,
      colors: [
        Color(0xFFFFFBFE),
        Color(0xFFFFF0F6),
      ],
      stops: [0.7, 1.0],
    );
    final paperPaint = Paint()
      ..shader = paperGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paperPaint);

    // 4. Kenarlara hafif pembe stroke
    final borderPaint = Paint()
      ..color = Colors.pink.shade100.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1;
    canvas.drawPath(path, borderPaint);

    // 5. Üstte dar ve oval highlight (ışık vurmuş efekti)
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withOpacity(0.13), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.center,
      ).createShader(Rect.fromLTWH(size.width * 0.18, 0, size.width * 0.64, size.height * 0.18));
    canvas.drawOval(Rect.fromLTWH(size.width * 0.18, 0, size.width * 0.64, size.height * 0.13), highlightPaint);

    // 6. Yatay çizgiler
    final linePaint = Paint()
      ..color = Colors.pink.shade100
      ..strokeWidth = 1.1;
    for (int i = 1; i <= 6; i++) {
      final y = 32 + (size.height - 56) * (i / 7);
      canvas.drawLine(Offset(48, y), Offset(size.width - 48, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 