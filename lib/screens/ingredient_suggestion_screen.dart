import 'package:flutter/material.dart';
import 'package:yemek_tarifi_app/services/auth_service.dart';

class IngredientSuggestionScreen extends StatefulWidget {
  // ... (existing code)
  @override
  _IngredientSuggestionScreenState createState() => _IngredientSuggestionScreenState();
}

class _IngredientSuggestionScreenState extends State<IngredientSuggestionScreen> {
  // ... (existing code)

  Future<void> _suggestRecipes() async {
    print('*** GERÇEK ÇALIŞAN _suggestRecipes BURASI! ***');
    print('[DEBUG] Tarif öner API çağrısı başlıyor.');
    print('*** INGREDIENT_SUGGESTION _suggestRecipes ÇAĞRILDI ***');
    print('Seçilen malzemeler: \\${_selectedIngredients}');
    print('Filtreler: yemek_turu=\${_selectedYemekTuru}, pisirme_suresi=\${_selectedPisirmeSuresi}, porsiyon=\${_selectedPorsiyon}');
    print('Token: \\${await AuthService.getToken()}');
    // ... mevcut kod ...
  }

  @override
  Widget build(BuildContext context) {
    // ... (existing code)
    return Scaffold(
      // ... (existing code)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('*** INGREDIENT_SUGGESTION BUTONA BASILDI ***');
          _suggestRecipes();
        },
        child: Icon(Icons.add),
      ),
    );
  }
} 