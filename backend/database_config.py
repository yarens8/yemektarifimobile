# SQL Server bağlantı bilgileri
DB_CONFIG = {
    'driver': 'SQL Server',
    'server': 'YAREN\\SQLEXPRESS',
    'database': 'YemekTarifleri',
    'trusted_connection': 'yes'
}

def get_connection_string():
    return (
        "Driver={SQL Server};"
        "Server=YAREN\\SQLEXPRESS;"
        "Database=YemekTarifleri;"
        "Trusted_Connection=yes"
    ) 