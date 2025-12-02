--הסבר על הסקריפט שממלא את ה-t_data
--סיכום פעולות הסקריפט - יצירת סדרת מספרים (CTE רקורסיבי):
--הסקריפט מגדיר משתנה @NumRecords ל-1,000,000.
--הוא משתמש בביטוי טבלאי משותף (CTE - Common Table Expression) רקורסיבי בשם NumberSequence כדי ליצור רצף שלם של מספרים מ-1 עד 1,000,000.
--הפקודה OPTION (MAXRECURSION 0) נחוצה כדי לעקוף את מגבלת הרקורסיה הסטנדרטית של SQL Server ולאפשר יצירת מיליון רשומות.

--יצירת מיליון רשומות.
-- יצירת נתונים רנדומליים והכנסה לטבלההסקריפט מבצע INSERT INTO t_data על בסיס הרצף שיצר ה-CTE.
--עבור כל רשומה, הוא מחשב ערכים רנדומליים עבור העמודות a, b, c, ו-d באמצעות הפונקציות:CHECKSUM(NEWID()): משמש כמקור זרעים רנדומליים (Seed) עבור כל שורה.
--מודולו (%): מגביל את המספר הרנדומלי לטווח רצוי (למשל, $\pm 100$ עבור a).
--החישוב משלב ערכים שלמים וחלקי שבר (Float) ומאפשר גם מספרים שליליים כדי להבטיח מגוון נתונים (כנדרש במטלה).


USE DynamicCalcDB; 
GO

SET NOCOUNT ON;

DECLARE @NumRecords INT = 1000000;

WITH NumberSequence (n) AS
(
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1
    FROM NumberSequence
    WHERE n < @NumRecords
)

INSERT INTO t_data (a, b, c, d)
SELECT 
    CAST((CHECKSUM(NEWID()) % 201) - 100 AS FLOAT) + (CAST(ABS(CHECKSUM(NEWID())) % 100 AS FLOAT) / 100.0) AS a,
    CAST((CHECKSUM(NEWID()) % 101) - 50 AS FLOAT) + (CAST(ABS(CHECKSUM(NEWID())) % 100 AS FLOAT) / 100.0) AS b,
    CAST((CHECKSUM(NEWID()) % 401) - 200 AS FLOAT) + (CAST(ABS(CHECKSUM(NEWID())) % 100 AS FLOAT) / 100.0) AS c,
    CAST((CHECKSUM(NEWID()) % 2001) - 1000 AS FLOAT) + (CAST(ABS(CHECKSUM(NEWID())) % 100 AS FLOAT) / 100.0) AS d
FROM 
    NumberSequence
OPTION (MAXRECURSION 0);
GO

SELECT COUNT(*) AS TotalRecordsIn_t_result FROM t_data;

SELECT TOP 10 * FROM t_data ORDER BY NEWID();


--מילוי ה-t_targil

INSERT INTO t_targil (targil, tnai, targil_false) VALUES
-- --------------------------------------------------------------------------------
-- נוסחאות פשוטות
-- --------------------------------------------------------------------------------
('a + b', NULL, NULL),                
('c * 2', NULL, NULL),                 
('b - a', NULL, NULL),               
('d / 4', NULL, NULL),                
('a * 1.5 - d', NULL, NULL),         

-- --------------------------------------------------------------------------------
-- נוסחאות מורכבות (Complex Formulas) 
-- --------------------------------------------------------------------------------
('(a + b) * 8', NULL, NULL),           
('sqrt(c^2 + d^2)', NULL, NULL),      
('log(ABS(b)) + c', NULL, NULL),       
('abs(d - b)', NULL, NULL),            
('a^3 / 100', NULL, NULL),

-- --------------------------------------------------------------------------------
-- נוסחאות עם תנאים 
-- --------------------------------------------------------------------------------
('b * 2', 'a > 5', 'b / 2'),          
('a + 1', 'b < 10', 'd - 1'),          
('1', 'a == c', '0');                  
GO
