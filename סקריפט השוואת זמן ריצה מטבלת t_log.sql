USE DynamicCalcDB;
GO

USE DynamicCalcDB;
GO

SELECT 
    t1.targil_id,
    CASE 
        WHEN t2.tnai IS NOT NULL THEN 
            'IF (' + t2.tnai + ') THEN ' + t2.targil + ' ELSE ' + t2.targil_false
        ELSE
            t2.targil  
    END AS Full_Formula,
    t1.method,
    t1.run_time
FROM t_log t1
JOIN t_targil t2 ON t1.targil_id = t2.targil_id
ORDER BY t1.targil_id, t1.method DESC;