import pyodbc
from database_config import get_connection_string
import logging
import re
import traceback

class DatabaseService:
    def __init__(self):
        self.conn_str = get_connection_string()
        self.connection = None
        self.setup_logging()
        
    def setup_logging(self):
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
        
    def get_connection(self):
        return pyodbc.connect(self.conn_str)

    def connect(self):
        """Veritabanına bağlantı kurar"""
        try:
            if self.connection:
                return True
                
            self.connection = pyodbc.connect(self.conn_str)
            self.logger.info("Veritabanı bağlantısı başarılı")
            return True
        except Exception as e:
            self.logger.error(f"Veritabanı bağlantı hatası: {str(e)}")
            raise Exception(f"Veritabanı bağlantı hatası: {str(e)}")
            
    def disconnect(self):
        """Veritabanı bağlantısını kapatır"""
        if self.connection:
            self.connection.close()
            self.connection = None
            self.logger.info("Veritabanı bağlantısı kapatıldı")
            
    def get_categories(self):
        """Tüm kategorileri getirir"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT [id] as id, [name] as name 
                    FROM [dbo].[Category] 
                    ORDER BY [name]
                """)
                columns = [column[0] for column in cursor.description]
                categories = [dict(zip(columns, row)) for row in cursor.fetchall()]
                print("Categories from database:", categories)  # Debug print
                return categories
        except Exception as e:
            self.logger.error(f"Kategorileri getirirken hata: {str(e)}")
            raise Exception(f"Kategorileri getirirken hata: {str(e)}")

    def get_recipes(self, category_id=None):
        """Tüm tarifleri veya belirli bir kategoriye ait tarifleri getirir"""
        try:
            print("[DEBUG] get_recipes çağrıldı")
            with self.get_connection() as conn:
                cursor = conn.cursor()
                
                if category_id:
                    query = """
                        SELECT 
                            r.[id],
                            r.[title],
                            r.[ingredients],
                            r.[instructions],
                            r.[created_at],
                            r.[user_id],
                            r.[category_id],
                            r.[views],
                            r.[serving_size],
                            r.[preparation_time],
                            r.[cooking_time],
                            r.[tips],
                            r.[image_filename],
                            r.[ingredients_sections],
                            u.[username],
                            COALESCE(r.[average_rating], 0.0) as average_rating,
                            COALESCE(r.[rating_count], 0) as rating_count,
                            (SELECT COUNT(*) FROM favorites f WHERE f.recipe_id = r.id) AS favorite_count
                        FROM [dbo].[Recipe] r
                        LEFT JOIN [dbo].[User] u ON r.[user_id] = u.[id]
                        WHERE r.[category_id] = ?
                        ORDER BY r.[views] DESC
                    """
                    print(f"[DEBUG] Kategori ID ile sorgu çalıştırılıyor: {category_id}")
                    cursor.execute(query, category_id)
                else:
                    query = """
                        SELECT 
                            r.[id],
                            r.[title],
                            r.[ingredients],
                            r.[instructions],
                            r.[created_at],
                            r.[user_id],
                            r.[category_id],
                            r.[views],
                            r.[serving_size],
                            r.[preparation_time],
                            r.[cooking_time],
                            r.[tips],
                            r.[image_filename],
                            r.[ingredients_sections],
                            u.[username],
                            COALESCE(r.[average_rating], 0.0) as average_rating,
                            COALESCE(r.[rating_count], 0) as rating_count,
                            (SELECT COUNT(*) FROM favorites f WHERE f.recipe_id = r.id) AS favorite_count
                        FROM [dbo].[Recipe] r
                        LEFT JOIN [dbo].[User] u ON r.[user_id] = u.[id]
                        ORDER BY r.[views] DESC
                    """
                    print("[DEBUG] Tüm tarifler için sorgu çalıştırılıyor")
                    cursor.execute(query)
                
                columns = [column[0] for column in cursor.description]
                print(f"[DEBUG] Sütunlar: {columns}")
                
                recipes = []
                for row in cursor.fetchall():
                    try:
                        recipe = dict(zip(columns, row))
                        # Tarih alanlarını string'e çevir
                        if recipe.get('created_at'):
                            recipe['created_at'] = recipe['created_at'].isoformat()
                        recipes.append(recipe)
                    except Exception as e:
                        print(f"[DEBUG] Satır dönüştürme hatası: {str(e)}")
                        continue
                
                print(f"[DEBUG] Veritabanından {len(recipes)} tarif alındı")
                if recipes:
                    print("[DEBUG] İlk tarif örneği:", {
                        'id': recipes[0].get('id'),
                        'title': recipes[0].get('title'),
                        'ingredients': recipes[0].get('ingredients')[:100] + '...' if recipes[0].get('ingredients') else None
                    })
                return recipes[:150]
                
        except Exception as e:
            print(f"[DEBUG] get_recipes hatası: {str(e)}")
            print(f"[DEBUG] Hata detayı: {traceback.format_exc()}")
            return []

    def search_recipes(self, search_term):
        """Tariflerde arama yapar"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT 
                        r.[id],
                        r.[title],
                        r.[ingredients],
                        r.[instructions],
                        r.[created_at],
                        r.[user_id],
                        r.[category_id],
                        r.[views],
                        r.[serving_size],
                        r.[preparation_time],
                        r.[cooking_time],
                        r.[tips],
                        r.[image_filename],
                        r.[ingredients_sections],
                        r.[username],
                        r.[average_rating],
                        r.[rating_count]
                    FROM [dbo].[Recipe] r
                    WHERE r.[title] LIKE ? OR r.[ingredients] LIKE ? OR r.[instructions] LIKE ?
                    ORDER BY r.[views] DESC
                """, f"%{search_term}%", f"%{search_term}%", f"%{search_term}%")
                columns = [column[0] for column in cursor.description]
                recipes = [dict(zip(columns, row)) for row in cursor.fetchall()]
                return recipes
        except Exception as e:
            self.logger.error(f"Tarif araması yapılırken hata: {str(e)}")
            return []

    def get_top_recipes(self):
        """En çok görüntülenen tarifleri getirir"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT TOP 10
                        r.[id],
                        r.[title],
                        r.[ingredients],
                        r.[instructions],
                        r.[created_at],
                        r.[user_id],
                        r.[category_id],
                        r.[views],
                        r.[serving_size],
                        r.[preparation_time],
                        r.[cooking_time],
                        r.[tips],
                        r.[image_filename],
                        r.[ingredients_sections],
                        r.[username],
                        r.[average_rating],
                        r.[rating_count],
                        (SELECT COUNT(*) FROM favorites f WHERE f.recipe_id = r.id) AS favorite_count
                    FROM [dbo].[Recipe] r
                    ORDER BY r.[views] DESC
                """)
                columns = [column[0] for column in cursor.description]
                recipes = [dict(zip(columns, row)) for row in cursor.fetchall()]
                print("Top recipes from database:", recipes)  # Debug print
                return recipes
        except Exception as e:
            self.logger.error(f"En çok görüntülenen tarifler getirilirken hata: {str(e)}")
            return []

    def get_recipes_by_category(self, category_id):
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT 
                        r.[id],
                        r.[title],
                        r.[ingredients],
                        r.[instructions],
                        r.[created_at],
                        r.[user_id],
                        r.[category_id],
                        r.[views],
                        r.[serving_size],
                        r.[preparation_time],
                        r.[cooking_time],
                        r.[tips],
                        r.[image_filename],
                        r.[ingredients_sections],
                        r.[username],
                        r.[average_rating],
                        r.[rating_count],
                        (SELECT COUNT(*) FROM favorites f WHERE f.recipe_id = r.id) AS favorite_count
                    FROM [dbo].[Recipe] r
                    WHERE r.[category_id] = ?
                    ORDER BY r.[views] DESC
                """, category_id)
                columns = [column[0] for column in cursor.description]
                recipes = [dict(zip(columns, row)) for row in cursor.fetchall()]
                return recipes
        except Exception as e:
            self.logger.error(f"Kategoriye göre tarifler getirilirken hata: {str(e)}")
            return []

    def login_user(self, username, password):
        """Kullanıcı girişi kontrolü yapar"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT [id], [username], [email], [password_hash], [profile_image], [appearance]
                    FROM [dbo].[User]
                    WHERE [username] = ?
                """, username)
                
                user = cursor.fetchone()
                if not user:
                    return None, "Kullanıcı bulunamadı"
                
                # Kullanıcı bulundu, bilgileri döndür
                return {
                    'id': user.id,
                    'username': user.username,
                    'email': user.email,
                    'profile_image': user.profile_image,
                    'appearance': user.appearance
                }, None
                
        except Exception as e:
            self.logger.error(f"Giriş yapılırken hata: {str(e)}")
            return None, f"Giriş yapılırken hata oluştu: {str(e)}"

    def register_user(self, username, email, password):
        """Yeni kullanıcı kaydı oluşturur"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                
                # Kullanıcı adı kontrolü
                cursor.execute("SELECT id FROM [dbo].[User] WHERE username = ?", username)
                if cursor.fetchone():
                    return None, "Bu kullanıcı adı zaten kullanılıyor"
                
                # Email kontrolü
                cursor.execute("SELECT id FROM [dbo].[User] WHERE email = ?", email)
                if cursor.fetchone():
                    return None, "Bu email adresi zaten kullanılıyor"
                
                # Yeni kullanıcı ekleme
                cursor.execute("""
                    INSERT INTO [dbo].[User] (username, email, password_hash)
                    VALUES (?, ?, ?)
                """, username, email, password)  # Şimdilik şifreyi direkt kaydediyoruz
                
                conn.commit()
                
                # Eklenen kullanıcının bilgilerini getir
                cursor.execute("""
                    SELECT [id], [username], [email], [profile_image], [appearance]
                    FROM [dbo].[User]
                    WHERE [username] = ?
                """, username)
                
                user = cursor.fetchone()
                return {
                    'id': user.id,
                    'username': user.username,
                    'email': user.email,
                    'profile_image': user.profile_image,
                    'appearance': user.appearance
                }, None
                
        except Exception as e:
            self.logger.error(f"Kullanıcı kaydı oluşturulurken hata: {str(e)}")
            return None, f"Kullanıcı kaydı oluşturulurken hata oluştu: {str(e)}"

    def update_user_profile(self, username, email):
        """Kullanıcı profilini günceller"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                
                # Email formatını kontrol et
                if not re.match(r"[^@]+@[^@]+\.[^@]+", email):
                    return None, "Geçersiz email formatı"
                    
                # Kullanıcı adının benzersiz olduğunu kontrol et
                cursor.execute("""
                    SELECT [id] FROM [dbo].[User] 
                    WHERE [username] = ? AND [email] != ?
                """, (username, email))
                existing_user = cursor.fetchone()
                
                if existing_user:
                    return None, "Bu kullanıcı adı zaten kullanılıyor"
                    
                # Email'in benzersiz olduğunu kontrol et
                cursor.execute("""
                    SELECT [id] FROM [dbo].[User] 
                    WHERE [email] = ? AND [username] != ?
                """, (email, username))
                existing_email = cursor.fetchone()
                
                if existing_email:
                    return None, "Bu email adresi zaten kullanılıyor"
                    
                # Profili güncelle
                cursor.execute("""
                    UPDATE [dbo].[User]
                    SET [username] = ?, [email] = ?
                    WHERE [email] = ?
                """, (username, email, email))
                
                conn.commit()
                
                # Güncellenmiş kullanıcı bilgilerini al
                cursor.execute("""
                    SELECT [id], [username], [email], [profile_image], [appearance]
                    FROM [dbo].[User]
                    WHERE [email] = ?
                """, (email,))
                updated_user = cursor.fetchone()
                
                if updated_user:
                    return {
                        'id': updated_user.id,
                        'username': updated_user.username,
                        'email': updated_user.email,
                        'profile_image': updated_user.profile_image,
                        'appearance': updated_user.appearance
                    }, None
                else:
                    return None, "Kullanıcı güncellenirken bir hata oluştu"
                    
        except Exception as e:
            self.logger.error(f"Profil güncellenirken hata: {str(e)}")
            return None, str(e)

    def change_password(self, email, current_password, new_password):
        """Kullanıcı şifresini değiştirir"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                
                # Kullanıcıyı kontrol et
                cursor.execute("""
                    SELECT [id]
                    FROM [dbo].[User]
                    WHERE [email] = ?
                """, (email,))
                
                user = cursor.fetchone()
                if not user:
                    return None, "Kullanıcı bulunamadı"
                
                # Yeni şifreyi güncelle
                cursor.execute("""
                    UPDATE [dbo].[User]
                    SET [password_hash] = ?
                    WHERE [email] = ?
                """, (new_password, email))
                
                conn.commit()
                
                return {
                    'message': 'Şifre başarıyla güncellendi'
                }, None
                
        except Exception as e:
            self.logger.error(f"Şifre değiştirilirken hata: {str(e)}")
            return None, str(e)

    def get_user_recipes(self, user_id):
        """Kullanıcının tariflerini getirir"""
        try:
            print(f"Getting recipes for user_id: {user_id}")  # Debug log
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT 
                        r.id AS id, 
                        r.title AS title, 
                        r.views AS views, 
                        r.created_at AS created_at, 
                        r.cooking_time AS cooking_time,
                        r.image_filename AS image_filename, 
                        r.ingredients AS ingredients,
                        r.instructions AS instructions,
                        r.tips AS tips,
                        COALESCE(r.serving_size, 'Bilinmiyor') AS serving_size,
                        r.category_id AS category_id,
                        r.user_id AS user_id,
                        u.username AS username,
                        r.preparation_time AS preparation_time,
                        COALESCE(r.average_rating, 0.0) AS average_rating,
                        COALESCE(r.rating_count, 0) AS rating_count
                    FROM [dbo].[Recipe] r
                    LEFT JOIN [dbo].[User] u ON r.user_id = u.id
                    WHERE r.user_id = ?
                    ORDER BY r.created_at DESC
                """, (user_id,))
                columns = [column[0] for column in cursor.description]
                recipes = []
                for row in cursor.fetchall():
                    recipe = dict(zip(columns, row))
                    if recipe.get('created_at'):
                        recipe['created_at'] = recipe['created_at'].isoformat()
                    if not recipe.get('serving_size'):
                        recipe['serving_size'] = 'Bilinmiyor'
                    if not recipe.get('username'):
                        recipe['username'] = 'Anonim'
                    # Tüm metin alanlarını UTF-8 ile encode/decode et
                    for k, v in recipe.items():
                        if v is None:
                            recipe[k] = ''
                        elif not isinstance(v, (int, float, str)):
                            recipe[k] = str(v)
                    recipes.append(recipe)
                print(f"Found {len(recipes)} recipes")  # Debug log
                print("Recipes:", recipes)  # Debug log
                return recipes[:20]
        
        except Exception as e:
            print(f"Error in get_user_recipes: {str(e)}")  # Debug log
            raise Exception(f"Kullanıcının tarifleri getirilirken hata oluştu: {str(e)}")

    def add_to_favorites(self, user_id, recipe_id):
        """Tarifi kullanıcının favorilerine ekler"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                
                # Önce bu tarifin zaten favorilerde olup olmadığını kontrol et
                cursor.execute("""
                    SELECT COUNT(*) as count
                    FROM [dbo].[favorites]
                    WHERE user_id = ? AND recipe_id = ?
                """, (user_id, recipe_id))
                
                if cursor.fetchone()[0] > 0:
                    return False, "Bu tarif zaten favorilerinizde"
                
                # Favorilere ekle
                cursor.execute("""
                    INSERT INTO [dbo].[favorites] (user_id, recipe_id)
                    VALUES (?, ?)
                """, (user_id, recipe_id))
                
                conn.commit()
                return True, "Tarif favorilere eklendi"
                
        except Exception as e:
            self.logger.error(f"Favori ekleme hatası: {str(e)}")
            return False, f"Tarif favorilere eklenirken hata oluştu: {str(e)}"

    def remove_from_favorites(self, user_id, recipe_id):
        """Tarifi kullanıcının favorilerinden kaldırır"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                
                cursor.execute("""
                    DELETE FROM [dbo].[favorites]
                    WHERE user_id = ? AND recipe_id = ?
                """, (user_id, recipe_id))
                
                conn.commit()
                return True, "Tarif favorilerden kaldırıldı"
                
        except Exception as e:
            self.logger.error(f"Favorilerden kaldırma hatası: {str(e)}")
            return False, f"Tarif favorilerden kaldırılırken hata oluştu: {str(e)}"

    def get_user_favorites(self, user_id):
        """Kullanıcının favori tariflerini getirir"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT 
                        r.id AS id, 
                        r.title AS title, 
                        r.views AS views, 
                        r.created_at AS created_at, 
                        r.cooking_time AS cooking_time,
                        r.image_filename AS image_filename, 
                        r.ingredients AS ingredients,
                        r.instructions AS instructions,
                        r.tips AS tips,
                        COALESCE(r.serving_size, 'Bilinmiyor') AS serving_size,
                        r.category_id AS category_id,
                        r.user_id AS user_id,
                        u.username AS username,
                        r.preparation_time AS preparation_time,
                        COALESCE(r.average_rating, 0.0) AS average_rating,
                        COALESCE(r.rating_count, 0) AS rating_count,
                        (SELECT COUNT(*) FROM favorites f WHERE f.recipe_id = r.id) AS favorite_count
                    FROM [dbo].[Recipe] r
                    INNER JOIN [dbo].[favorites] f ON r.id = f.recipe_id
                    INNER JOIN [dbo].[User] u ON r.user_id = u.id
                    WHERE f.user_id = ?
                    ORDER BY r.title
                """, (user_id,))
                columns = [column[0] for column in cursor.description]
                recipes = []
                for row in cursor.fetchall():
                    recipe = dict(zip(columns, row))
                    # Tarih alanlarını string'e çevir
                    if recipe.get('created_at'):
                        recipe['created_at'] = recipe['created_at'].isoformat()
                    # Eksik veya null değerleri doldur
                    if not recipe.get('serving_size'):
                        recipe['serving_size'] = 'Bilinmiyor'
                    if not recipe.get('favorite_count'):
                        recipe['favorite_count'] = 0
                    if not recipe.get('username'):
                        recipe['username'] = 'Anonim'
                    recipes.append(recipe)
                return recipes, None
                
        except Exception as e:
            self.logger.error(f"Favori tarifleri getirme hatası: {str(e)}")
            return None, f"Favori tarifler getirilirken hata oluştu: {str(e)}"

    def is_favorite(self, user_id, recipe_id):
        """Tarifin kullanıcının favorilerinde olup olmadığını kontrol eder"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                
                cursor.execute("""
                    SELECT COUNT(*) as count
                    FROM [dbo].[favorites]
                    WHERE user_id = ? AND recipe_id = ?
                """, (user_id, recipe_id))
                
                count = cursor.fetchone()[0]
                return count > 0, None
                
        except Exception as e:
            self.logger.error(f"Favori kontrolü hatası: {str(e)}")
            return False, f"Favori kontrolü yapılırken hata oluştu: {str(e)}"

    def create_recipe(self, title, user_id, category_id, ingredients, instructions, servings=None, prep_time=None, cook_time=None, tips=None, image_url=None):
        try:
            insert_query = """
                INSERT INTO [dbo].[Recipe] (
                    title, 
                    user_id, 
                    category_id, 
                    ingredients, 
                    instructions, 
                    serving_size, 
                    preparation_time, 
                    cooking_time, 
                    tips, 
                    image_filename,
                    created_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, GETDATE());
            """
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(insert_query, (
                    title,
                    user_id,
                    category_id,
                    ingredients,
                    instructions,
                    servings,
                    prep_time,
                    cook_time,
                    tips,
                    image_url,
                ))
                # Şimdi id'yi al
                cursor.execute("SELECT SCOPE_IDENTITY() as id;")
                recipe_id = cursor.fetchone()[0]

                # Yeni eklenen tarifi getir
                cursor.execute("""
                    SELECT 
                        id, 
                        title, 
                        user_id, 
                        category_id, 
                        ingredients, 
                        instructions, 
                        serving_size as servings, 
                        preparation_time as prep_time, 
                        cooking_time as cook_time, 
                        tips, 
                        image_filename as image_url, 
                        created_at
                    FROM [dbo].[Recipe] 
                    WHERE id = ?
                """, (recipe_id,))
                recipe = cursor.fetchone()
                conn.commit()

                if recipe:
                    return {
                        'id': recipe[0],
                        'title': recipe[1],
                        'user_id': recipe[2],
                        'category_id': recipe[3],
                        'ingredients': recipe[4],
                        'instructions': recipe[5],
                        'servings': recipe[6],
                        'prep_time': recipe[7],
                        'cook_time': recipe[8],
                        'tips': recipe[9],
                        'image_url': recipe[10],
                        'created_at': recipe[11].isoformat() if recipe[11] else None
                    }
                return None
        except Exception as e:
            print(f"Error creating recipe: {str(e)}")
            if 'conn' in locals():
                conn.rollback()
            raise e

    def rate_recipe(self, recipe_id, user_id, rating):
        try:
            # Önce kullanıcının daha önce puan verip vermediğini kontrol et
            check_query = """
                SELECT id FROM RecipeRating 
                WHERE recipe_id = ? AND user_id = ?
            """
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(check_query, (recipe_id, user_id))
                existing_rating = cursor.fetchone()

            if existing_rating:
                # Mevcut puanı güncelle
                update_query = """
                    UPDATE RecipeRating 
                    SET rating = ?, created_at = GETDATE()
                    WHERE recipe_id = ? AND user_id = ?
                """
                with self.get_connection() as conn:
                    cursor = conn.cursor()
                    cursor.execute(update_query, (rating, recipe_id, user_id))
            else:
                # Yeni puan ekle
                insert_query = """
                    INSERT INTO RecipeRating (recipe_id, user_id, rating, created_at)
                    VALUES (?, ?, ?, GETDATE())
                """
                with self.get_connection() as conn:
                    cursor = conn.cursor()
                    cursor.execute(insert_query, (recipe_id, user_id, rating))

            # Ortalama puanı ve toplam puan sayısını hesapla
            stats_query = """
                SELECT AVG(CAST(rating AS FLOAT)) as average_rating, COUNT(*) as rating_count
                FROM RecipeRating
                WHERE recipe_id = ?
            """
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(stats_query, (recipe_id,))
                stats = cursor.fetchone()

            # Tariflerin ortalama puanını güncelle
            update_recipe_query = """
                UPDATE Recipe 
                SET average_rating = ?, rating_count = ?
                WHERE id = ?
            """
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(update_recipe_query, (stats[0], stats[1], recipe_id))
                conn.commit()

            return {
                'success': True,
                'average_rating': float(stats[0]) if stats[0] else 0.0,
                'rating_count': stats[1]
            }

        except Exception as e:
            print(f"Error in rate_recipe: {str(e)}")
            return {'success': False, 'message': str(e)}

    def get_user_rating(self, recipe_id, user_id):
        try:
            query = """
                SELECT rating 
                FROM RecipeRating 
                WHERE recipe_id = ? AND user_id = ?
            """
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(query, (recipe_id, user_id))
                result = cursor.fetchone()
                return result[0] if result else None

        except Exception as e:
            print(f"Error in get_user_rating: {str(e)}")
            return None

    def add_comment(self, recipe_id, user_id, content):
        """Tarife yorum ekler"""
        try:
            self.logger.info(f"Yorum ekleme başladı - recipe_id: {recipe_id}, user_id: {user_id}")
            with self.get_connection() as conn:
                cursor = conn.cursor()
                
                # Yorumu ekle ve ID'sini al
                cursor.execute("""
                    INSERT INTO [dbo].[Comment] (recipe_id, user_id, content, created_at)
                    OUTPUT INSERTED.id
                    VALUES (?, ?, ?, GETDATE())
                """, (recipe_id, user_id, content))
                
                comment_id = cursor.fetchone()[0]
                self.logger.info(f"Yorum eklendi, comment_id: {comment_id}")
                
                # Eklenen yorumu getir
                cursor.execute("""
                    SELECT c.id, c.content, c.created_at, c.user_id, c.recipe_id, u.username
                    FROM [dbo].[Comment] c
                    INNER JOIN [dbo].[User] u ON c.user_id = u.id
                    WHERE c.id = ?
                """, comment_id)
                
                result = cursor.fetchone()
                conn.commit()
                
                if result:
                    comment = {
                        'id': result[0],
                        'content': result[1],
                        'created_at': result[2].isoformat() if result[2] else None,
                        'user_id': result[3],
                        'recipe_id': result[4],
                        'username': result[5]
                    }
                    self.logger.info(f"Yorum başarıyla getirildi: {comment}")
                    return comment
                
                self.logger.error("Yorum eklendi fakat getirilemedi")
                return None
                
        except Exception as e:
            self.logger.error(f"Yorum eklenirken hata: {str(e)}")
            raise Exception(f"Yorum eklenirken bir hata oluştu: {str(e)}")

    def get_recipe_comments(self, recipe_id):
        """Tarife ait yorumları getirir"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT c.id, c.content, c.created_at, c.user_id, c.recipe_id, u.username
                    FROM [dbo].[Comment] c
                    INNER JOIN [dbo].[User] u ON c.user_id = u.id
                    WHERE c.recipe_id = ?
                    ORDER BY c.created_at DESC
                """, recipe_id)
                
                comments = []
                for row in cursor.fetchall():
                    comment = {
                        'id': row[0],
                        'content': row[1],
                        'created_at': row[2].isoformat() if row[2] else None,
                        'user_id': row[3],
                        'recipe_id': row[4],
                        'username': row[5]
                    }
                    comments.append(comment)
                return comments
                
        except Exception as e:
            self.logger.error(f"Yorumlar getirilirken hata: {str(e)}")
            return []

    def delete_comment(self, comment_id, user_id):
        """Kullanıcının yorumunu siler"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                
                # Önce yorumun bu kullanıcıya ait olup olmadığını kontrol et
                cursor.execute("""
                    SELECT COUNT(*) FROM [dbo].[Comment]
                    WHERE id = ? AND user_id = ?
                """, (comment_id, user_id))
                
                if cursor.fetchone()[0] == 0:
                    return False, "Bu yorumu silme yetkiniz yok"
                
                # Yorumu sil
                cursor.execute("""
                    DELETE FROM [dbo].[Comment]
                    WHERE id = ? AND user_id = ?
                """, (comment_id, user_id))
                
                conn.commit()
                return True, "Yorum başarıyla silindi"
                
        except Exception as e:
            self.logger.error(f"Yorum silinirken hata: {str(e)}")
            return False, f"Yorum silinirken hata oluştu: {str(e)}"

    def get_recipe_detail(self, recipe_id):
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT 
                        r.[id],
                        r.[title],
                        r.[ingredients],
                        r.[instructions],
                        r.[created_at],
                        r.[user_id],
                        r.[category_id],
                        r.[views],
                        r.[serving_size],
                        r.[preparation_time],
                        r.[cooking_time],
                        r.[tips],
                        r.[image_filename],
                        r.[ingredients_sections],
                        r.[username],
                        COALESCE(r.[average_rating], 0.0) as average_rating,
                        COALESCE(r.[rating_count], 0) as rating_count,
                        (SELECT COUNT(*) FROM favorites f WHERE f.recipe_id = r.id) AS favorite_count
                    FROM [dbo].[Recipe] r
                    WHERE r.id = ?
                """, (recipe_id,))
                columns = [column[0] for column in cursor.description]
                row = cursor.fetchone()
                if row:
                    recipe = dict(zip(columns, row))
                    if recipe.get('created_at'):
                        recipe['created_at'] = recipe['created_at'].isoformat()
                    return recipe
                return None
        except Exception as e:
            print(f"[DEBUG] get_recipe_detail hatası: {str(e)}")
            print(f"[DEBUG] Hata detayı: {traceback.format_exc()}")
            return None

    def get_to_try_recipes(self, user_id):
        """Kullanıcının denenecek tariflerini getirir"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT
                        id,
                        ai_title AS title,
                        ai_ingredients AS ingredients,
                        ai_instructions AS instructions,
                        ai_serving_size AS serving_size,
                        ai_cooking_time AS cooking_time,
                        ai_preparation_time AS preparation_time,
                        created_at
                    FROM [dbo].[UserRecipeList]
                    WHERE user_id = ? AND status = 'pending'
                    ORDER BY created_at DESC
                """, (int(user_id),))
                columns = [column[0] for column in cursor.description]
                recipes = [dict(zip(columns, row)) for row in cursor.fetchall()]
                return recipes
        except Exception as e:
            print(f"Error in get_to_try_recipes: {str(e)}")
            return []

    def remove_from_to_try(self, user_id, recipe_id):
        """Kullanıcının denenecekler listesinden bir tarifi siler"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    DELETE FROM [dbo].[UserRecipeList]
                    WHERE user_id = ? AND id = ?
                """, (int(user_id), int(recipe_id)))
                conn.commit()
                if cursor.rowcount > 0:
                    return True, "Tarif denenecekler listesinden silindi."
                else:
                    return False, "Kayıt bulunamadı."
        except Exception as e:
            print(f"Error in remove_from_to_try: {str(e)}")
            return False, f"Hata oluştu: {str(e)}"

    def add_to_try(self, user_id, ai_title, ai_ingredients, ai_instructions, ai_serving_size=None, ai_cooking_time=None, ai_preparation_time=None):
        """Kullanıcının denenecekler listesine yeni bir AI tarifi ekler"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    INSERT INTO [dbo].[UserRecipeList] (
                        user_id, ai_title, ai_ingredients, ai_instructions, ai_serving_size, ai_cooking_time, ai_preparation_time, status, created_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', GETDATE())
                """, (
                    int(user_id),
                    ai_title,
                    ai_ingredients,
                    ai_instructions,
                    ai_serving_size,
                    ai_cooking_time,
                    ai_preparation_time
                ))
                conn.commit()
                if cursor.rowcount > 0:
                    return True, "Tarif denenecekler listesine eklendi."
                else:
                    return False, "Ekleme başarısız."
        except Exception as e:
            print(f"Error in add_to_try: {str(e)}")
            return False, f"Hata oluştu: {str(e)}"

    def update_recipe(self, recipe_id, user_id, data):
        """Tarifi günceller"""
        try:
            # Önce tarifin kullanıcıya ait olup olmadığını kontrol et
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT user_id FROM [dbo].[Recipe] WHERE id = ?
                """, (recipe_id,))
                result = cursor.fetchone()
                
                if not result:
                    return False, "Tarif bulunamadı"
                
                if result[0] != user_id:
                    return False, "Bu tarifi düzenleme yetkiniz yok"
                
                # Tarifi güncelle
                update_query = """
                    UPDATE [dbo].[Recipe]
                    SET 
                        title = ?,
                        category_id = ?,
                        ingredients = ?,
                        instructions = ?,
                        serving_size = ?,
                        preparation_time = ?,
                        cooking_time = ?,
                        tips = ?,
                        image_filename = ?
                    WHERE id = ? AND user_id = ?
                """
                
                cursor.execute(update_query, (
                    data.get('title'),
                    data.get('category_id'),
                    data.get('ingredients'),
                    data.get('instructions'),
                    data.get('serving_size'),
                    data.get('prep_time'),
                    data.get('cooking_time'),
                    data.get('tips'),
                    data.get('image_filename'),
                    recipe_id,
                    user_id
                ))
                
                conn.commit()
                return True, "Tarif başarıyla güncellendi"
                
        except Exception as e:
            print(f"Error updating recipe: {str(e)}")
            if 'conn' in locals():
                conn.rollback()
            return False, f"Tarif güncellenirken hata oluştu: {str(e)}"

    def delete_recipe(self, recipe_id, user_id):
        """Tarifi siler"""
        try:
            # Önce tarifin kullanıcıya ait olup olmadığını kontrol et
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT user_id FROM [dbo].[Recipe] WHERE id = ?
                """, (recipe_id,))
                result = cursor.fetchone()
                
                if not result:
                    return False, "Tarif bulunamadı"
                
                if result[0] != user_id:
                    return False, "Bu tarifi silme yetkiniz yok"
                
                # İlişkili kayıtları sil
                cursor.execute("DELETE FROM [dbo].[RecipeRating] WHERE recipe_id = ?", (recipe_id,))
                cursor.execute("DELETE FROM [dbo].[Comment] WHERE recipe_id = ?", (recipe_id,))
                cursor.execute("DELETE FROM [dbo].[favorites] WHERE recipe_id = ?", (recipe_id,))
                
                # Tarifi sil
                cursor.execute("DELETE FROM [dbo].[Recipe] WHERE id = ? AND user_id = ?", (recipe_id, user_id))
                
                conn.commit()
                return True, "Tarif başarıyla silindi"
                
        except Exception as e:
            print(f"Error deleting recipe: {str(e)}")
            if 'conn' in locals():
                conn.rollback()
            return False, f"Tarif silinirken hata oluştu: {str(e)}"

# Singleton instance
db_service = DatabaseService() 