import sqlalchemy

METHOD_NAME = 'Python_Pandas_Vectorized'

#הגדרת חיבור למסד נתנונים
SERVER_NAME = r'STERN\SQLEXPRESS'
DATABASE_NAME = 'DynamicCalcDB'
DRIVER = 'ODBC Driver 17 for SQL Server'
DRIVER_URL_ENCODED = 'ODBC+Driver+17+for+SQL+Server'

CONNECTION_STRING = f'DRIVER={{{DRIVER}}};SERVER={SERVER_NAME};DATABASE={DATABASE_NAME};Trusted_Connection=yes;'
ENGINE_STRING = f'mssql+pyodbc://{SERVER_NAME}/{DATABASE_NAME}?driver={DRIVER_URL_ENCODED}&trusted_connection=yes'

# יצירת Engine באמצעות SQLAlchemy
try:
    ENGINE = sqlalchemy.create_engine(ENGINE_STRING)
except Exception as e:
    print(f"!! שגיאה ביצירת SQLAlchemy Engine: {e}")
    ENGINE = None