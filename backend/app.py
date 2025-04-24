from flask import Flask, jsonify, request
from database_service import db_service
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

@app.route('/')
def home():
    return jsonify({'message': 'Lezzetli Tarifler API çalışıyor!'})

@app.route('/api/categories', methods=['GET'])
def get_categories():
    try:
        categories = db_service.get_categories()
        print("Categories endpoint response:", categories)  # Debug print
        return jsonify(categories)
    except Exception as e:
        print(f"Error in categories endpoint: {str(e)}")  # Debug print
        return jsonify({"error": str(e)}), 500

@app.route('/api/recipes', methods=['GET'])
def get_recipes():
    try:
        recipes = db_service.get_recipes()
        return jsonify(recipes)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/recipes/category/<int:category_id>', methods=['GET'])
def get_recipes_by_category(category_id):
    try:
        recipes = db_service.get_recipes_by_category(category_id)
        print(f"Category {category_id} recipes response:", recipes)  # Debug print
        return jsonify(recipes)
    except Exception as e:
        print(f"Error in category recipes endpoint: {str(e)}")  # Debug print
        return jsonify({"error": str(e)}), 500

@app.route('/api/top-recipes', methods=['GET'])
def get_top_recipes():
    try:
        recipes = db_service.get_top_recipes()
        print("Top recipes endpoint response:", recipes)  # Debug print
        return jsonify(recipes)
    except Exception as e:
        print(f"Error in top recipes endpoint: {str(e)}")  # Debug print
        return jsonify({"error": str(e)}), 500

@app.route('/api/recipes/search', methods=['GET'])
def search_recipes():
    try:
        query = request.args.get('q', '')
        recipes = db_service.search_recipes(query)
        print(f"Search recipes response for query '{query}':", recipes)  # Debug print
        return jsonify(recipes)
    except Exception as e:
        print(f"Error in search recipes endpoint: {str(e)}")  # Debug print
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    try:
        # Uygulama başlarken veritabanı bağlantısını test et
        db_service.connect()
        app.run(host='0.0.0.0', port=5000, debug=True)
    except Exception as e:
        print(f"Uygulama başlatılırken hata: {str(e)}") 