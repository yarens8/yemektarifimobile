from flask import Flask, jsonify, request, Response
from database_service import db_service
from flask_cors import CORS
import logging
from decimal import Decimal
import json
from datetime import datetime
from flask_jwt_extended import jwt_required, JWTManager, create_access_token, get_jwt_identity
import traceback
from datetime import timedelta
from flask_jwt_extended.exceptions import NoAuthorizationError
from flask import make_response
import pyodbc
import re
import requests
import os

class CustomJSONEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        if isinstance(obj, datetime):
            return obj.isoformat()
        return super().default(obj)

app = Flask(__name__)
app.config['JSON_AS_ASCII'] = False  # Türkçe karakter desteği
app.json_encoder = CustomJSONEncoder  # Özel JSON encoder'ı ayarla

# JWT ayarları
app.config['JWT_SECRET_KEY'] = 'gizli-anahtar-123'  # Güvenli bir anahtar kullanın
app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(days=1)
jwt = JWTManager(app)

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
            
        # JWT token oluştur
        access_token = create_access_token(identity={'user_id': user['id'], 'username': user['username']})
            
        return jsonify({
            'message': 'Giriş başarılı',
            'user': user,
            'access_token': access_token
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

        logger.info(f"Yorum ekleme isteği alındı - recipe_id: {recipe_id}, user_id: {user_id}")
        comment = db_service.add_comment(recipe_id, user_id, content)
        
        if comment:
            logger.info(f"Yorum başarıyla eklendi: {comment}")
            return jsonify(comment), 201
        else:
            logger.error("Yorum eklenemedi")
            return jsonify({'error': 'Yorum eklenirken bir hata oluştu'}), 500

    except Exception as e:
        logger.error(f"Yorum eklenirken hata: {str(e)}")
        return jsonify({'error': str(e)}), 500

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

def extract_minutes(cooking_time):
    if not cooking_time:
        return 0
    # Sadece ilk bulduğu sayıyı alır
    match = re.search(r'(\d+)', str(cooking_time))
    if match:
        return int(match.group(1))
    return 0

@app.route('/api/mobile/suggest_recipes', methods=['POST'])
def suggest_recipes():
    data = request.get_json(force=True)
    print('[DEBUG] Received request data:', data)
    
    selected_ingredients = data.get('selectedIngredients', [])
    filters = data.get('filters', {})
    print('[DEBUG] Selected ingredients:', selected_ingredients)
    print('[DEBUG] Filters:', filters)

    if not selected_ingredients:
        print('[DEBUG] No ingredients selected, returning empty list')
        return jsonify([])

    like_clauses = []
    params = []
    for ing in selected_ingredients:
        like_clauses.append("ingredients LIKE ?")
        params.append(f"%{ing}%")
    where_sql = "(" + " OR ".join(like_clauses) + ")"

    # Kategori ve porsiyon filtrelerini SQL'de uygula
    if filters.get('yemek_turu') and filters['yemek_turu'] != 'Tümü':
        print('[DEBUG] Adding category filter:', filters['yemek_turu'])
        where_sql += " AND category_id = ?"
        kategori_map = {
            'Ana Yemek': 1,
            'Aperatif': 5,
            'Çorba': 2,
            'İçecek': 6,
            'Kahvaltılık': 7,
            'Salata': 3,
            'Tatlı': 4,
        }
        category_id = kategori_map.get(filters['yemek_turu'])
        print('[DEBUG] Mapped category ID:', category_id)
        params.append(category_id)

    if filters.get('porsiyon') and filters['porsiyon'] != 'Tümü':
        porsiyon = filters['porsiyon']
        print('[DEBUG] Adding serving size filter:', porsiyon)
        if porsiyon == '1-2 Kişilik':
            where_sql += " AND serving_size LIKE ?"
            params.append('%1-2%')
        elif porsiyon == '3-4 Kişilik':
            where_sql += " AND serving_size LIKE ?"
            params.append('%3-4%')
        elif porsiyon == '5-6 Kişilik':
            where_sql += " AND serving_size LIKE ?"
            params.append('%5-6%')
        elif porsiyon == '6+ Kişilik':
            where_sql += " AND (serving_size LIKE ? OR TRY_CAST(serving_size AS INT) >= ?)"
            params.extend(['%6+%', 6])

    query = f"""
    SELECT r.*, 
           (SELECT COUNT(*) FROM favorites f WHERE f.recipe_id = r.id) AS favorite_count
    FROM [YemekTarifleri].[dbo].[Recipe] r
    WHERE {where_sql}
    """
    print('[DEBUG] Final SQL query:', query)
    print('[DEBUG] Query parameters:', params)

    try:
        conn = pyodbc.connect(r'Driver={SQL Server};Server=YAREN\SQLEXPRESS;Database=YemekTarifleri;Trusted_Connection=yes;')
        cursor = conn.cursor()
        cursor.execute(query, params)
        columns = [column[0] for column in cursor.description]
        results = []
        for row in cursor.fetchall():
            recipe = dict(zip(columns, row))
            # Tüm alanları string'e çevir
            for k, v in recipe.items():
                if v is not None:
                    recipe[k] = str(v)
                else:
                    recipe[k] = ""
            # Favori sayısını int olarak ekle
            if 'favorite_count' in recipe:
                try:
                    recipe['favorite_count'] = int(recipe['favorite_count'])
                except:
                    recipe['favorite_count'] = 0
            results.append(recipe)
        conn.close()
        print('[DEBUG] Found recipes before time filter:', len(results))
        print('[DEBUG] First recipe before time filter:', results[0] if results else None)
            
        # Pişirme süresi filtresini Python tarafında uygula
        if filters.get('pisirme_suresi') and filters['pisirme_suresi'] != 'Tümü':
            sure = filters['pisirme_suresi']
            filtered = []
            for recipe in results:
                minutes = extract_minutes(recipe.get('cooking_time', ''))
                if sure == '30 dakikadan az' and minutes < 30:
                    filtered.append(recipe)
                elif sure == '30-60 dakika' and 30 <= minutes <= 60:
                    filtered.append(recipe)
                elif sure == '60 dakikadan fazla' and minutes > 60:
                    filtered.append(recipe)
            print(f'[DEBUG] Recipes after time filter ({sure}):', len(filtered))
            results = filtered

        print('[DEBUG] Found recipes after all filters:', len(results))
        print('[DEBUG] First recipe after all filters:', results[0] if results else None)
        return jsonify(results[:15])
    except Exception as e:
        print('[DEBUG] Database error:', str(e))
        return jsonify({'error': str(e)}), 500

def translate_recipe_keys(recipe):
    """Gemini API'dan gelen Türkçe/karışık anahtarları İngilizce'ye çevirir ve eksik alanları tamamlar"""
    key_map = {
        "Başlık": "title",
        "İsim": "title",
        "Malzemeler": "ingredients",
        "Hazırlanış": "instructions",
        "Hazırlama Süresi": "preparation_time",
        "Hazırlık": "preparation_time",
        "Pişirme Süresi": "cooking_time",
        "Süre": "cooking_time",
        "Porsiyon": "serving_size"
    }
    mapped = {}
    for k, v in recipe.items():
        eng_key = key_map.get(k.strip(), k.strip().lower())
        mapped[eng_key] = v
    # Eksik alanlar için default değerler
    mapped.setdefault('title', '')
    mapped.setdefault('ingredients', '')
    mapped.setdefault('instructions', '')
    mapped.setdefault('serving_size', '')
    mapped.setdefault('preparation_time', '')
    mapped.setdefault('cooking_time', '')
    return mapped

# Basit malzeme çıkarıcı fonksiyon (örnek)
def extract_ingredients_from_text(text, known_ingredients=None):
    if known_ingredients is None:
        # Kendi veritabanındaki Ingredient tablosundan veya sabit bir listeden çekebilirsin
        known_ingredients = [
            'domates', 'peynir', 'makarna', 'biber', 'patates', 'yumurta', 'süt', 'un', 'tavuk', 'et',
            'soğan', 'sarımsak', 'zeytinyağı', 'pirinç', 'bulgur', 'yoğurt', 'salça', 'şeker', 'tuz',
            'elma', 'muz', 'limon', 'havuç', 'kabak', 'ıspanak', 'fasulye', 'mercimek', 'nohut', 'sucuk',
            'balık', 'krema', 'tereyağı', 'maydanoz', 'dereotu', 'nane', 'kekik', 'karabiber', 'pul biber',
            'zeytin', 'mısır', 'bezelye', 'karnabahar', 'brokoli', 'lahana', 'kereviz', 'patlıcan', 'kabak',
            'ceviz', 'fındık', 'badem', 'fıstık', 'çikolata', 'vanilya', 'tarçın', 'susam', 'ketçap', 'mayonez'
        ]
    text_lower = text.lower()
    found = [ing for ing in known_ingredients if ing in text_lower]
    return found

@app.route('/api/ai_recipe', methods=['POST'])
def ai_recipe():
    try:
        data = request.get_json(force=True)
        user_message = data.get('user_message', '').strip()
        if not user_message:
            return jsonify({'error': 'user_message field is required and must be a non-empty string'}), 400

        # Serbest metinden malzeme listesini çıkar
        ingredients = extract_ingredients_from_text(user_message)
        if not ingredients:
            return jsonify({'error': 'No recognizable ingredients found in your message.'}), 400

        # Gemini için prompt oluştur
        prompt = (
            f"Aşağıdaki malzemelerle 10 farklı yaratıcı yemek tarifi öner. "
            f"Sadece geçerli bir JSON array döndür. "
            f"Her tarifin alanları: title, ingredients, instructions, serving_size, preparation_time, cooking_time. "
            f"Başka hiçbir açıklama, metin veya markdown ekleme. "
            f"Malzemeler: {', '.join(ingredients)}"
        )
        reply, err = gemini_generate_content(prompt)
        if err:
            return jsonify({'error': err}), 500
        _, ai_recipes = parse_ai_recipes(reply)
        print('[DEBUG] Gemini yanıtı:', reply)
        print('[DEBUG] Parse edilen tarifler:', ai_recipes)
        from flask import Response
        return Response(
            json.dumps(ai_recipes[:8], ensure_ascii=False),
            content_type="application/json; charset=utf-8"
        )
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/ai-chat', methods=['POST'])
def ai_chat():
    try:
        user_message = request.json.get('message')
        GEMINI_API_KEY = "AIzaSyBYITo8SvLOJdrAd5ITVwitLb9-43_gwN8"
        GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=" + GEMINI_API_KEY
        data = {
            "contents": [
                {"parts": [{"text": user_message}]}
            ]
        }
        response = requests.post(GEMINI_URL, json=data)
        response_json = response.json()
        if "candidates" not in response_json:
            return Response(
                json.dumps({"error": response_json}, ensure_ascii=False),
                content_type="application/json; charset=utf-8"
            )
        gemini_reply = response_json['candidates'][0]['content']['parts'][0]['text']
        return Response(
            json.dumps({"reply": gemini_reply}, ensure_ascii=False),
            content_type="application/json; charset=utf-8"
        )
    except Exception as e:
        return Response(
            json.dumps({"error": str(e)}, ensure_ascii=False),
            content_type="application/json; charset=utf-8"
        )

@app.errorhandler(NoAuthorizationError)
def handle_auth_error(e):
    print('JWT HATASI:', str(e))
    return make_response(jsonify({'error': 'JWT HATASI', 'detail': str(e)}), 401)

def gemini_generate_content(prompt):
    """Gemini API'ya prompt gönderir ve yanıtı döndürür."""
    try:
        GEMINI_API_KEY = "AIzaSyBYITo8SvLOJdrAd5ITVwitLb9-43_gwN8"
        GEMINI_URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={GEMINI_API_KEY}"
        data = {
            "contents": [
                {"parts": [{"text": prompt}]}
            ]
        }
        response = requests.post(GEMINI_URL, json=data)
        response_json = response.json()
        if "candidates" not in response_json:
            return None, response_json
        gemini_reply = response_json['candidates'][0]['content']['parts'][0]['text']
        return gemini_reply, None
    except Exception as e:
        return None, str(e)

def parse_ai_recipes(reply):
    """Gemini'den gelen metni JSON tarif listesine çevirir."""
    # JSON bloklarını ayıkla
    try:
        # JSON bloklarını bul
        matches = re.findall(r'\{[\s\S]*?\}', reply)
        recipes = []
        for m in matches:
            try:
                recipe = json.loads(m)
                recipe = translate_recipe_keys(recipe)
                recipes.append(recipe)
            except Exception:
                continue
        return None, recipes
    except Exception as e:
        return str(e), []

@app.route('/to-try-recipes', methods=['GET'])
def to_try_recipes():
    user_id = request.args.get('user_id')
    if not user_id:
        return jsonify({'error': 'Kullanıcı ID gerekli'}), 400
    try:
        recipes = db_service.get_to_try_recipes(user_id)
        return jsonify({'recipes': recipes}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/to-try-recipes/remove', methods=['POST'])
def remove_from_to_try():
    try:
        data = request.get_json()
        user_id = data.get('user_id')
        recipe_id = data.get('recipe_id')
        if not user_id or not recipe_id:
            return jsonify({'error': 'user_id ve recipe_id gereklidir'}), 400
        success, message = db_service.remove_from_to_try(user_id, recipe_id)
        if success:
            return jsonify({'message': message}), 200
        else:
            return jsonify({'error': message}), 400
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/to-try-recipes/add', methods=['POST'])
def add_to_try():
    try:
        data = request.get_json()
        user_id = data.get('user_id')
        ai_title = data.get('ai_title')
        ai_ingredients = data.get('ai_ingredients')
        ai_instructions = data.get('ai_instructions')
        ai_serving_size = data.get('ai_serving_size')
        ai_cooking_time = data.get('ai_cooking_time')
        ai_preparation_time = data.get('ai_preparation_time')
        if not user_id or not ai_title or not ai_ingredients or not ai_instructions:
            return jsonify({'error': 'user_id, ai_title, ai_ingredients, ai_instructions gereklidir'}), 400
        success, message = db_service.add_to_try(user_id, ai_title, ai_ingredients, ai_instructions, ai_serving_size, ai_cooking_time, ai_preparation_time)
        if success:
            return jsonify({'message': message}), 200
        else:
            return jsonify({'error': message}), 400
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/recipes/<int:recipe_id>', methods=['PUT'])
def update_recipe(recipe_id):
    """Tarifi günceller"""
    try:
        data = request.get_json()
        user_id = data.get('user_id')
        
        if not user_id:
            return jsonify({'error': 'Kullanıcı ID gerekli'}), 400
            
        success, message = db_service.update_recipe(recipe_id, user_id, data)
        
        if success:
            return jsonify({'message': message}), 200
        else:
            return jsonify({'error': message}), 400
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/recipes/<int:recipe_id>', methods=['DELETE'])
def delete_recipe(recipe_id):
    """Tarifi siler"""
    try:
        user_id = request.args.get('user_id')
        
        if not user_id:
            return jsonify({'error': 'Kullanıcı ID gerekli'}), 400
            
        success, message = db_service.delete_recipe(recipe_id, int(user_id))
        
        if success:
            return jsonify({'message': message}), 200
        else:
            return jsonify({'error': message}), 400
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/recipes/<int:recipe_id>', methods=['GET'])
def get_recipe_detail(recipe_id):
    recipe = db_service.get_recipe_detail(recipe_id)
    if recipe:
        return Response(
            json.dumps(recipe, ensure_ascii=False, cls=CustomJSONEncoder),
            content_type="application/json; charset=utf-8"
        )
    else:
        return jsonify({'error': 'Tarif bulunamadı'}), 404

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