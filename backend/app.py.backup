from flask import Flask, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Cross Origin Resource Sharing'i etkinleştir

@app.route('/')
def home():
    return jsonify({'message': 'Lezzetli Tarifler API çalışıyor!'})

@app.route('/api/categories')
def get_categories():
    # Örnek kategori verileri
    categories = [
        {"id": 1, "name": "Çorbalar", "icon": "soup"},
        {"id": 2, "name": "Ana Yemekler", "icon": "main_dish"},
        {"id": 3, "name": "Tatlılar", "icon": "dessert"},
        {"id": 4, "name": "Salatalar", "icon": "salad"},
        {"id": 5, "name": "İçecekler", "icon": "beverage"}
    ]
    return jsonify(categories)

@app.route('/api/recipes')
def get_recipes():
    # Örnek tarif verileri
    recipes = [
        {
            "id": 1,
            "name": "Mercimek Çorbası",
            "categoryId": 1,
            "preparationTime": 30,
            "description": "Klasik Türk mutfağının vazgeçilmezi"
        },
        {
            "id": 2,
            "name": "Karnıyarık",
            "categoryId": 2,
            "preparationTime": 45,
            "description": "Patlıcan severlerin favorisi"
        }
    ]
    return jsonify(recipes)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True) 