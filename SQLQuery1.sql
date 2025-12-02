use master
go
create database DynamicCalcDB
use DynamicCalcDB
go



CREATE TABLE t_data (
    data_id INT IDENTITY(1,1) PRIMARY KEY NOT NULL, 
    a FLOAT NOT NULL,                                
    b FLOAT NOT NULL,                                 
    c FLOAT NOT NULL,                                 
    d FLOAT NOT NULL                                 
);


CREATE TABLE t_targil (
    targil_id INT IDENTITY(1,1) PRIMARY KEY NOT NULL, 
    targil VARCHAR(MAX) NOT NULL,                     
    tnai VARCHAR(MAX) NULL,                           
    targil_false VARCHAR(MAX) NULL
);


CREATE TABLE t_result (
    results_id INT IDENTITY(1,1) PRIMARY KEY NOT NULL, 
    data_id INT NOT NULL,                              
    targil_id INT NOT NULL,                           
    method VARCHAR(50) NOT NULL,                       
    result FLOAT NULL,                                
    
    CONSTRAINT FK_Result_Data FOREIGN KEY (data_id) REFERENCES t_data(data_id),       
    CONSTRAINT FK_Result_Targil FOREIGN KEY (targil_id) REFERENCES t_targil(targil_id) 
);


CREATE TABLE t_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    targil_id INT NOT NULL,                            
    method VARCHAR(50) NOT NULL,                       
    run_time FLOAT NULL,                               
    
    CONSTRAINT FK_Log_Targil FOREIGN KEY (targil_id) REFERENCES t_targil(targil_id)
);



USE DynamicCalcDB; -- שנה לשם מסד הנתונים שלך
GO

SET NOCOUNT ON;

-- הגדרת מספר הרשומות הנדרש
DECLARE @NumRecords INT = 1000000;

-- שימוש ב-CTE רקורסיבי ליצירת סדרה של מיליון מספרים
WITH NumberSequence (n) AS
(
    -- עוגן: מתחיל מהמספר 1
    SELECT 1 AS n
    UNION ALL
    -- רקורסיה: ממשיך להוסיף 1 עד שמגיע ל-@NumRecords
    SELECT n + 1
    FROM NumberSequence
    WHERE n < @NumRecords
)
-- הכנסת הנתונים הרנדומליים (חיוביים ושליליים) לטבלת t_data
INSERT INTO t_data (a, b, c, d)
SELECT 
    -- שדה a: טווח בין -100 ל-100
    CAST((CHECKSUM(NEWID()) % 201) - 100 AS FLOAT) + (CAST(ABS(CHECKSUM(NEWID())) % 100 AS FLOAT) / 100.0) AS a,
    
    -- שדה b: טווח בין -50 ל-50
    CAST((CHECKSUM(NEWID()) % 101) - 50 AS FLOAT) + (CAST(ABS(CHECKSUM(NEWID())) % 100 AS FLOAT) / 100.0) AS b,
    
    -- שדה c: טווח בין -200 ל-200
    CAST((CHECKSUM(NEWID()) % 401) - 200 AS FLOAT) + (CAST(ABS(CHECKSUM(NEWID())) % 100 AS FLOAT) / 100.0) AS c,
    
    -- שדה d: טווח בין -1000 ל-1000
    CAST((CHECKSUM(NEWID()) % 2001) - 1000 AS FLOAT) + (CAST(ABS(CHECKSUM(NEWID())) % 100 AS FLOAT) / 100.0) AS d
FROM 
    NumberSequence
OPTION (MAXRECURSION 0);
GO

-- אימות: בדיקת מספר הרשומות בטבלה
SELECT COUNT(*) AS TotalRecordsIn_t_result FROM t_data;

-- אימות נוסף: הצגת דוגמה של נתונים (צריך לכלול חיוביים ושליליים)
SELECT TOP 10 * FROM t_data ORDER BY NEWID();
GO

select*from t_data
DROP DATABASE DynamicCalcDB


USE DynamicCalcDB; -- ודא שאתה במסד הנתונים הנכון
GO

-- מחיקת נתונים קיימים בטבלת הנוסחאות, אם יש (אנו מניחים ש-t_log ו-t_result ריקות מהשלב הקודם)
TRUNCATE TABLE t_targil;
GO

INSERT INTO t_targil (targil, tnai, targil_false) VALUES
-- --------------------------------------------------------------------------------
-- נוסחאות פשוטות (Simple Formulas) 
-- --------------------------------------------------------------------------------
('a + b', NULL, NULL),                 -- חיבור שני שדות [cite: 34]
('c * 2', NULL, NULL),                 -- כפל שדה בקבוע [cite: 35, 37]
('b - a', NULL, NULL),                 -- חיסור שני שדות [cite: 36, 38]
('d / 4', NULL, NULL),                 -- חילוק שדה בקבוע [cite: 39]
('a * 1.5 - d', NULL, NULL),           -- שילוב של כפל וחיסור

-- --------------------------------------------------------------------------------
-- נוסחאות מורכבות (Complex Formulas) 
-- --------------------------------------------------------------------------------
('(a + b) * 8', NULL, NULL),           -- חיבור שני שדות כפול קבוע [cite: 40, 41]
('sqrt(c^2 + d^2)', NULL, NULL),       -- שורש ריבועי של סכום ריבועים [cite: 41]
('log(ABS(b)) + c', NULL, NULL),       -- חישוב לוגריתם טבעי (של הערך המוחלט של b, כדי למנוע לוג שלילי), ועוד שדה אחר [cite: 42]
('abs(d - b)', NULL, NULL),            -- חישוב ערך מוחלט של הפרש בין שני שדות [cite: 43]
('a^3 / 100', NULL, NULL),             -- דוגמה נוספת לחזקה וחילוק

-- --------------------------------------------------------------------------------
-- נוסחאות עם תנאים (Conditional Formulas) - בונוס [cite: 27, 56]
-- נשים לב: בשלב המימוש, פונקציית התנאי (if) נדרשת להיבנות בקוד [cite: 44, 47, 50]
-- --------------------------------------------------------------------------------
('b * 2', 'a > 5', 'b / 2'),           -- אם a>5 אזי b*2, אחרת b/2[cite: 44, 45]. (הערה: הנוסחה המקורית בקובץ היא if(a>5, b2, b/2) [cite: 44])
('a + 1', 'b < 10', 'd - 1'),          -- אם b<10 אזי a+1, אחרת d-1 [cite: 47, 48]
('1', 'a == c', '0');                  -- אם a=c אזי 1, אחרת 0 [cite: 50]
GO

-- אימות: בדיקת הנוסחאות שהוכנסו
SELECT * FROM t_targil;
GO

select*from t_targil
select*from t_result
select*from t_log

SELECT TOP 10 * FROM t_result where targil_id=13;
SELECT TOP 10 * FROM t_data;

SELECT * FROM t_result 
WHERE targil_id = 7 
  AND method = 'SQL_Dynamic_SP'
SELECT TOP 10 * FROM t_data;

SELECT TOP 10 *
FROM t_result
WHERE targil_id = 7
ORDER BY results_id DESC;

SELECT TOP 10 *
FROM t_data
ORDER BY data_id DESC;

SELECT 
    session_id, 
    login_name, 
    host_name,
    program_name,
    status,
    last_request_start_time
FROM 
    sys.dm_exec_sessions
WHERE 
    database_id = DB_ID('DynamicCalcDB')




	SELECT 
    t2.targil_id,
    t2.targil AS Formula,
    t1.method,
    t1.run_time
FROM t_log t1
JOIN t_targil t2 ON t1.targil_id = t2.targil_id
ORDER BY t1.targil_id, t1.method DESC; 


USE DynamicCalcDB;
GO

-- הגדרת סף שגיאה קטן מאוד לטיפוסי Float
DECLARE @Epsilon FLOAT = 0.000001; 

-- שאילתה להשוואת תוצאות בין שתי השיטות
SELECT 
    t_python.targil_id,
    t_python.data_id,
    t_python.result AS Python_Result,
    t_sql.result AS SQL_Result,
    ABS(t_python.result - t_sql.result) AS Difference
FROM 
    t_result t_python
JOIN 
    t_result t_sql ON t_python.data_id = t_sql.data_id 
                   AND t_python.targil_id = t_sql.targil_id
WHERE
    t_python.method = 'Python_Pandas_Vectorized'
    AND t_sql.method = 'SQL_Dynamic_SP'
    -- בדיקה האם יש הבדל משמעותי
    AND ABS(t_python.result - t_sql.result) > @Epsilon;

-- אם השאילתה מחזירה 0 רשומות, התוצאות זהות (במסגרת סף השגיאה).