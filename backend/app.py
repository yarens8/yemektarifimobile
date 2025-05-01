from flask import Flask, jsonify, request
from database_service import db_service
from flask_cors import CORS
import logging
from decimal import Decimal
import json
from datetime import datetime

class CustomJSONEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        if isinstance(obj, datetime):
            return obj.isoformat()
        return super().default(obj)

app = Flask(__name__)
app.json_encoder = CustomJSONEncoder  # Özel JSON encoder'ı ayarla

# CORS ayarlarını güncelle
CORS(app, resources={r"/api/*": {"origins": "*", "methods": ["GET", "POST", "PUT", "DELETE"]}})

# Logging ayarları
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

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

@app.route('/api/auth/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        username = data.get('username')
        password = data.get('password')
        
        if not username or not password:
            return jsonify({'error': 'Kullanıcı adı ve şifre gereklidir'}), 400
            
        user, error = db_service.login_user(username, password)
        
        if error:
            return jsonify({'error': error}), 401
            
        return jsonify({
            'message': 'Giriş başarılı',
            'user': user
        })
        
    except Exception as e:
        print(f"Login endpoint error: {str(e)}")  # Debug print
        return jsonify({'error': str(e)}), 500

@app.route('/api/auth/register', methods=['POST'])
def register():
    try:
        data = request.get_json()
        username = data.get('username')
        email = data.get('email')
        password = data.get('password')
        
        if not username or not email or not password:
            return jsonify({'error': 'Kullanıcı adı, email ve şifre gereklidir'}), 400
            
        user, error = db_service.register_user(username, email, password)
        
        if error:
            return jsonify({'error': error}), 400
            
        return jsonify({
            'message': 'Kayıt başarılı',
            'user': user
        }), 201
        
    except Exception as e:
        print(f"Register endpoint error: {str(e)}")  # Debug print
        return jsonify({'error': str(e)}), 500

@app.route('/api/auth/profile', methods=['PUT'])
def update_profile():
    try:
        data = request.get_json()
        username = data.get('username')
        email = data.get('email')
        
        if not username or not email:
            return jsonify({'error': 'Kullanıcı adı ve email gereklidir'}), 400
            
        user, error = db_service.update_user_profile(username, email)
        
        if error:
            return jsonify({'error': error}), 400
            
        return jsonify({
            'message': 'Profil başarıyla güncellendi',
            'user': user
        })
        
    except Exception as e:
        print(f"Update profile endpoint error: {str(e)}")  # Debug print
        return jsonify({'error': str(e)}), 500

@app.route('/api/auth/change-password', methods=['POST'])
def change_password():
    try:
        data = request.get_json()
        email = data.get('email')
        current_password = data.get('currentPassword')
        new_password = data.get('newPassword')
        
        if not email or not current_password or not new_password:
            return jsonify({'error': 'Email, mevcut şifre ve yeni şifre gereklidir'}), 400
            
        result, error = db_service.change_password(email, current_password, new_password)
        
        if error:
            return jsonify({'error': error}), 400
            
        return jsonify(result)
        
    except Exception as e:
        print(f"Change password endpoint error: {str(e)}")  # Debug print
        return jsonify({'error': str(e)}), 500

@app.route('/api/recipes/user/<user_id>', methods=['GET'])
def get_user_recipes(user_id):
    try:
        logger.info(f"Received request for user_id: {user_id}")
        # user_id'yi int'e çevir
        user_id = int(user_id)
        logger.info(f"Converted user_id to int: {user_id}")
        
        recipes = db_service.get_user_recipes(user_id)
        logger.info(f"Successfully retrieved {len(recipes)} recipes")
        
        response = jsonify(recipes)
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response
        
    except Exception as e:
        logger.error(f"Error in get_user_recipes endpoint: {str(e)}")
        error_response = jsonify({'error': str(e)})
        error_response.headers.add('Access-Control-Allow-Origin', '*')
        return error_response, 500

@app.route('/api/favorites/add', methods=['POST'])
def add_to_favorites():
    try:
        data = request.get_json()
        user_id = data.get('user_id')
        recipe_id = data.get('recipe_id')
        
        if not user_id or not recipe_id:
            return jsonify({'message': 'Kullanıcı ID ve tarif ID gerekli'}), 400
            
        success, message = db_service.add_to_favorites(user_id, recipe_id)
        
        if success:
            return jsonify({'message': message}), 200
        else:
            return jsonify({'message': message}), 400
            
    except Exception as e:
        return jsonify({'message': str(e)}), 500

@app.route('/api/favorites/remove', methods=['DELETE'])
def remove_from_favorites():
    try:
        data = request.get_json()
        user_id = data.get('user_id')
        recipe_id = data.get('recipe_id')
        
        if not user_id or not recipe_id:
            return jsonify({'message': 'Kullanıcı ID ve tarif ID gerekli'}), 400
            
        success, message = db_service.remove_from_favorites(user_id, recipe_id)
        
        if success:
            return jsonify({'message': message}), 200
        else:
            return jsonify({'message': message}), 400
            
    except Exception as e:
        return jsonify({'message': str(e)}), 500

@app.route('/api/favorites/check', methods=['GET'])
def check_favorite():
    try:
        user_id = request.args.get('user_id')
        recipe_id = request.args.get('recipe_id')
        
        if not user_id or not recipe_id:
            return jsonify({'message': 'Kullanıcı ID ve tarif ID gerekli'}), 400
            
        is_favorite, error = db_service.is_favorite(user_id, recipe_id)
        
        if error:
            return jsonify({'message': error}), 400
            
        return jsonify({'is_favorite': is_favorite}), 200
            
    except Exception as e:
        return jsonify({'message': str(e)}), 500

@app.route('/api/favorites', methods=['GET'])
def get_user_favorites():
    try:
        user_id = request.args.get('user_id')
        
        if not user_id:
            return jsonify({'message': 'Kullanıcı ID gerekli'}), 400
            
        recipes, error = db_service.get_user_favorites(user_id)
        
        if error:
            return jsonify({'message': error}), 400
            
        return jsonify({'recipes': recipes}), 200
            
    except Exception as e:
        return jsonify({'message': str(e)}), 500

@app.route('/api/recipes/create', methods=['POST'])
def create_recipe():
    try:
        data = request.get_json()
        required_fields = ['title', 'user_id', 'category_id', 'ingredients', 'instructions']
        
        # Zorunlu alanları kontrol et
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'{field} alanı gereklidir'}), 400
        
        # Tarifi veritabanına ekle
        recipe = db_service.create_recipe(
            title=data['title'],
            user_id=data['user_id'],
            category_id=data['category_id'],
            ingredients=data['ingredients'],
            instructions=data['instructions'],
            servings=data.get('servings'),
            prep_time=data.get('prep_time'),
            cook_time=data.get('cook_time'),
            tips=data.get('tips'),
            image_url=data.get('image_url')
        )
        
        return jsonify({
            'message': 'Tarif başarıyla eklendi',
            'recipe': recipe
        }), 201
        
    except Exception as e:
        print(f"Create recipe endpoint error: {str(e)}")  # Debug print
        return jsonify({'error': str(e)}), 500

@app.route('/api/recipes/<int:recipe_id>/rate', methods=['POST'])
def rate_recipe(recipe_id):
    try:
        data = request.get_json()
        user_id = data.get('user_id')
        rating = data.get('rating')

        if not all([user_id, rating]):
            return jsonify({'error': 'Kullanıcı ID ve puan gereklidir'}), 400

        if not isinstance(rating, int) or rating < 1 or rating > 5:
            return jsonify({'error': 'Puan 1 ile 5 arasında olmalıdır'}), 400

        result = db_service.rate_recipe(recipe_id, user_id, rating)
        if result.get('success'):
            return jsonify({
                'message': 'Puan başarıyla verildi',
                'average_rating': result['average_rating'],
                'rating_count': result['rating_count']
            }), 200
        else:
            return jsonify({'error': result.get('message')}), 400

    except Exception as e:
        print(f"Error rating recipe: {str(e)}")
        return jsonify({'error': 'Puan verme işlemi sırasında bir hata oluştu'}), 500

@app.route('/api/recipes/<int:recipe_id>/user-rating', methods=['GET'])
def get_user_rating(recipe_id):
    try:
        user_id = request.args.get('user_id')
        if not user_id:
            return jsonify({'error': 'Kullanıcı ID gerekli'}), 400

        rating = db_service.get_user_rating(recipe_id, int(user_id))
        return jsonify({'rating': rating})

    except Exception as e:
        print(f"Error getting user rating: {str(e)}")
        return jsonify({'error': 'Kullanıcı puanı alınırken bir hata oluştu'}), 500

@app.route('/api/recipes/<int:recipe_id>/comments', methods=['GET'])
def get_recipe_comments(recipe_id):
    """Tarife ait yorumları getirir"""
    try:
        comments = db_service.get_recipe_comments(recipe_id)
        return jsonify(comments)
    except Exception as e:
        print(f"Error getting recipe comments: {str(e)}")
        return jsonify({'error': 'Yorumlar alınırken bir hata oluştu'}), 500

@app.route('/api/recipes/<int:recipe_id>/comments', methods=['POST'])
def add_comment(recipe_id):
    """Tarife yorum ekler"""
    try:
        data = request.get_json()
        user_id = data.get('user_id')
        content = data.get('content')

        if not user_id or not content:
            return jsonify({'error': 'Kullanıcı ID ve yorum içeriği gerekli'}), 400

        comment = db_service.add_comment(recipe_id, user_id, content)
        if comment:
            return jsonify(comment), 201
        else:
            return jsonify({'error': 'Yorum eklenirken bir hata oluştu'}), 500

    except Exception as e:
        print(f"Error adding comment: {str(e)}")
        return jsonify({'error': 'Yorum eklenirken bir hata oluştu'}), 500

@app.route('/api/comments/<int:comment_id>', methods=['DELETE'])
def delete_comment(comment_id):
    """Yorumu siler"""
    try:
        data = request.get_json()
        user_id = data.get('user_id')

        if not user_id:
            return jsonify({'error': 'Kullanıcı ID gerekli'}), 400

        success, message = db_service.delete_comment(comment_id, user_id)
        if success:
            return jsonify({'message': message}), 200
        else:
            return jsonify({'error': message}), 403

    except Exception as e:
        print(f"Error deleting comment: {str(e)}")
        return jsonify({'error': 'Yorum silinirken bir hata oluştu'}), 500

if __name__ == '__main__':
    try:
        logger.info("Starting the server...")
        # Uygulama başlarken veritabanı bağlantısını test et
        db_service.connect()
        logger.info("Database connection successful")
        # Tüm network arayüzlerinden gelen istekleri dinle
        app.run(host='0.0.0.0', port=5000, debug=True, threaded=True)
    except Exception as e:
        logger.error(f"Uygulama başlatılırken hata: {str(e)}")
        raise 