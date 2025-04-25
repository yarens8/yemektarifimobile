import pyodbc
from database_config import get_connection_string
import logging
import re

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
            with self.get_connection() as conn:
                cursor = conn.cursor()
                
                if category_id:
                    query = """
                        SELECT 
                            [id],
                            [title],
                            [ingredients],
                            [instructions],
                            [created_at],
                            [user_id],
                            [category_id],
                            [views],
                            [serving_size],
                            [preparation_time],
                            [cooking_time],
                            [tips],
                            [image_filename],
                            [ingredients_sections],
                            [username]
                        FROM [dbo].[Recipe]
                        WHERE [category_id] = ?
                        ORDER BY [views] DESC
                    """
                    cursor.execute(query, category_id)
                else:
                    query = """
                        SELECT 
                            [id],
                            [title],
                            [ingredients],
                            [instructions],
                            [created_at],
                            [user_id],
                            [category_id],
                            [views],
                            [serving_size],
                            [preparation_time],
                            [cooking_time],
                            [tips],
                            [image_filename],
                            [ingredients_sections],
                            [username]
                        FROM [dbo].[Recipe]
                        ORDER BY [views] DESC
                    """
                    cursor.execute(query)
                
                columns = [column[0] for column in cursor.description]
                recipes = [dict(zip(columns, row)) for row in cursor.fetchall()]
                print("Recipes from database:", recipes)  # Debug print
                return recipes
                
        except Exception as e:
            self.logger.error(f"Tarifler getirilirken hata: {str(e)}")
            return []

    def search_recipes(self, search_term):
        """Tariflerde arama yapar"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT 
                        [id],
                        [title],
                        [ingredients],
                        [instructions],
                        [created_at],
                        [user_id],
                        [category_id],
                        [views],
                        [serving_size],
                        [preparation_time],
                        [cooking_time],
                        [tips],
                        [image_filename],
                        [ingredients_sections],
                        [username]
                    FROM [dbo].[Recipe]
                    WHERE [title] LIKE ? OR [ingredients] LIKE ? OR [instructions] LIKE ?
                    ORDER BY [views] DESC
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
                        [id],
                        [title],
                        [ingredients],
                        [instructions],
                        [created_at],
                        [user_id],
                        [category_id],
                        [views],
                        [serving_size],
                        [preparation_time],
                        [cooking_time],
                        [tips],
                        [image_filename],
                        [ingredients_sections],
                        [username]
                    FROM [dbo].[Recipe]
                    ORDER BY [views] DESC
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
                        [id],
                        [title],
                        [ingredients],
                        [instructions],
                        [created_at],
                        [user_id],
                        [category_id],
                        [views],
                        [serving_size],
                        [preparation_time],
                        [cooking_time],
                        [tips],
                        [image_filename],
                        [ingredients_sections],
                        [username]
                    FROM [dbo].[Recipe]
                    WHERE [category_id] = ?
                    ORDER BY [views] DESC
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
                        id,
                        title,
                        views
                    FROM [dbo].[Recipe]
                    WHERE user_id = ?
                    ORDER BY created_at DESC
                """, (user_id,))
                
                recipes = []
                for row in cursor.fetchall():
                    recipes.append({
                        'id': row[0],
                        'title': row[1],
                        'views': row[2]
                    })
                
                print(f"Found {len(recipes)} recipes")  # Debug log
                print("Recipes:", recipes)  # Debug log
                return recipes
                
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
                    SELECT r.*
                    FROM [dbo].[Recipe] r
                    INNER JOIN [dbo].[favorites] f ON r.id = f.recipe_id
                    WHERE f.user_id = ?
                    ORDER BY r.title
                """, (user_id,))
                
                columns = [column[0] for column in cursor.description]
                recipes = [dict(zip(columns, row)) for row in cursor.fetchall()]
                
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

# Singleton instance
db_service = DatabaseService() 