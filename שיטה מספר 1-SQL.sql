USE DynamicCalcDB;
GO



IF OBJECT_ID('sp_DynamicCalculation', 'P') IS NOT NULL
    DROP PROCEDURE sp_DynamicCalculation;
GO

CREATE PROCEDURE sp_DynamicCalculation
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @TargilID INT;
    DECLARE @Formula NVARCHAR(MAX);
    DECLARE @Tnai NVARCHAR(MAX);
    DECLARE @FormulaFalse NVARCHAR(MAX);
    DECLARE @DynamicSQL NVARCHAR(MAX);
    
    DECLARE @StartTime DATETIME2;
    DECLARE @EndTime DATETIME2;
    DECLARE @RunTime FLOAT;
    
    DECLARE @MethodName VARCHAR(50) = 'SQL_Dynamic_SP';

    -- הגדרת Cursor
    DECLARE targil_cursor CURSOR FOR
        SELECT targil_id, targil, tnai, targil_false
        FROM t_targil
        ORDER BY targil_id;

    OPEN targil_cursor;
    
    FETCH NEXT FROM targil_cursor INTO @TargilID, @Formula, @Tnai, @FormulaFalse;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @StartTime = SYSDATETIME();
        
        -- איפוס משתני הנוסחאות לשימוש בקוד
        DECLARE @FormulaWorking NVARCHAR(MAX) = @Formula;
        DECLARE @FormulaFalseWorking NVARCHAR(MAX) = @FormulaFalse;
        
        -- ----------------------------------------------------
        -- 1. טיפול בנוסחאות מיוחדות והמרת הסינטקס ל-T-SQL
        -- ----------------------------------------------------
        
        IF @TargilID = 8 -- נוסחה: log(ABS(b)) + c
        BEGIN
            SET @DynamicSQL = '
                INSERT INTO t_result (data_id, targil_id, method, result)
                SELECT
                    data_id,
                    8,
                    ''' + @MethodName + ''',
                    LOG(ABS(NULLIF(b, 0))) + c 
                FROM t_data;';
        END

        ELSE IF @TargilID = 7 -- נוסחה: sqrt(c^2 + d^2)
        BEGIN
            SET @DynamicSQL = '
                INSERT INTO t_result (data_id, targil_id, method, result)
                SELECT
                    data_id,
                    7,
                    ''' + @MethodName + ''',
                    SQRT(POWER(c, 2) + POWER(d, 2))
                FROM t_data;';
        END

        ELSE IF @TargilID = 10 -- נוסחה: a^3 / 100
        BEGIN
            SET @DynamicSQL = '
                INSERT INTO t_result (data_id, targil_id, method, result)
                SELECT
                    data_id,
                    10,
                    ''' + @MethodName + ''',
                    POWER(a, 3) / 100
                FROM t_data;';
        END

        -- ----------------------------------------------------
        -- 2. טיפול בכל שאר הנוסחאות (גנרי ופשוט)
        -- ----------------------------------------------------
        ELSE -- **התו המיותר '-' הוסר מכאן**
        BEGIN
            -- החלפות פשוטות לביטויים שלא משתנים או משתמשים בפונקציות בסיסיות
            SET @FormulaWorking = REPLACE(@FormulaWorking, 'ABS(', 'ABS(');
            SET @FormulaWorking = REPLACE(@FormulaWorking, 'log(', 'LOG(');
            SET @FormulaWorking = REPLACE(@FormulaWorking, 'sqrt(', 'SQRT(');
            SET @FormulaWorking = REPLACE(@FormulaWorking, 'abs(', 'ABS(');
            
            IF @Tnai IS NULL
            BEGIN
                -- נוסחאות ללא תנאי (1-6, 9)
                SET @DynamicSQL = '
                    INSERT INTO t_result (data_id, targil_id, method, result)
                    SELECT
                        data_id,
                        ' + CAST(@TargilID AS NVARCHAR(10)) + ',
                        ''' + @MethodName + ''',
                        (' + @FormulaWorking + ') 
                    FROM t_data;';
            END
            ELSE
            BEGIN
                -- נוסחאות עם תנאים (11-13)
                SET @FormulaFalseWorking = REPLACE(@FormulaFalseWorking, 'ABS(', 'ABS('); 
                
                -- תיקון: החלפת אופרטור השוואה מ-== ל-= (חובה ב-T-SQL)
                DECLARE @TnaiWorking NVARCHAR(MAX) = REPLACE(@Tnai, '==', '='); 
                
                SET @DynamicSQL = '
                    INSERT INTO t_result (data_id, targil_id, method, result)
                    SELECT
                        data_id,
                        ' + CAST(@TargilID AS NVARCHAR(10)) + ',
                        ''' + @MethodName + ''',
                        CASE 
                            WHEN ' + @TnaiWorking + ' THEN (' + @FormulaWorking + ')
                            ELSE (' + @FormulaFalseWorking + ')
                        END
                    FROM t_data;';
            END
        END -- סוף ELSE הגנרי

        -- ----------------------------------------------------
        -- 3. ביצוע השאילתה הדינמית
        -- ----------------------------------------------------
        EXEC sp_executesql @DynamicSQL;

        -- 4. מדידת זמן ושמירה ללוג
        SET @EndTime = SYSDATETIME();
        SET @RunTime = DATEDIFF(millisecond, @StartTime, @EndTime) / 1000.0;
        
        INSERT INTO t_log (targil_id, method, run_time)
        VALUES (@TargilID, @MethodName, @RunTime);
        
        PRINT 'Completed Targil ID: ' + CAST(@TargilID AS VARCHAR(10)) + ' in ' + CAST(@RunTime AS VARCHAR(20)) + ' seconds.';

        FETCH NEXT FROM targil_cursor INTO @TargilID, @Formula, @Tnai, @FormulaFalse;
    END

    CLOSE targil_cursor;
    DEALLOCATE targil_cursor;
    
    SET NOCOUNT OFF;
END
GO

EXEC sp_DynamicCalculation;

