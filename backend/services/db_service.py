from flask_mysqldb import MySQL
import re
from flask import current_app

mysql = MySQL()

class DatabaseService:
    def __init__(self):
        self.mysql = mysql

    def connect(self):
        return self.mysql.connection.cursor()

    def update_user_profile(self, username, email):
        try:
            # Email formatını kontrol et
            if not re.match(r"[^@]+@[^@]+\.[^@]+", email):
                return None, "Geçersiz email formatı"
                
            # Kullanıcı adının benzersiz olduğunu kontrol et
            cursor = self.mysql.connection.cursor(dictionary=True)
            cursor.execute("SELECT * FROM users WHERE username = %s AND email != %s", (username, email))
            existing_user = cursor.fetchone()
            
            if existing_user:
                return None, "Bu kullanıcı adı zaten kullanılıyor"
                
            # Email'in benzersiz olduğunu kontrol et
            cursor.execute("SELECT * FROM users WHERE email = %s AND username != %s", (email, username))
            existing_email = cursor.fetchone()
            
            if existing_email:
                return None, "Bu email adresi zaten kullanılıyor"
                
            # Profili güncelle
            cursor.execute("""
                UPDATE users 
                SET username = %s, email = %s 
                WHERE email = %s
            """, (username, email, email))
            
            self.mysql.connection.commit()
            
            # Güncellenmiş kullanıcı bilgilerini al
            cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
            updated_user = cursor.fetchone()
            cursor.close()
            
            if updated_user:
                return {
                    'id': updated_user['id'],
                    'username': updated_user['username'],
                    'email': updated_user['email']
                }, None
            else:
                return None, "Kullanıcı güncellenirken bir hata oluştu"
                
        except Exception as e:
            print(f"Database error in update_user_profile: {str(e)}")  # Debug print
            return None, str(e)

db_service = DatabaseService() 