
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

-- (אם השאילתה מחזירה 0 רשומות, התוצאות זהות (במסגרת סף השגיאה.