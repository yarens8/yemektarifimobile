import pyodbc

def get_db_connection():
    conn = pyodbc.connect(
        'Driver={SQL Server};'
        'Server=YAREN\\SQLEXPRESS;'
        'Database=YemekTarifleri;'
        'Trusted_Connection=yes;'  # Windows Authentication
    )
    return conn

def test_connection():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('SELECT @@version')
        version = cursor.fetchone()[0]
        cursor.close()
        conn.close()
        return True, f"Bağlantı başarılı! SQL Server versiyonu: {version}"
    except Exception as e:
        return False, f"Bağlantı hatası: {str(e)}" 