import pyodbc
from database_config import get_connection_string
import logging

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

# Singleton instance
db_service = DatabaseService() 