import pyodbc
import pandas as pd
import time
import numpy as np
import math
import sys

from config import METHOD_NAME, CONNECTION_STRING, ENGINE

def connect_db():
    return pyodbc.connect(CONNECTION_STRING)


def calculate_vectorized_result(data_df, formula_true, formula_condition, formula_false, targil_id):


    clean_formula_true = formula_true.replace('^', '**').replace('ABS', 'abs').replace('LOG', 'log').replace('SQRT','sqrt')
#טיפול מיוחד בנוסחאות 7,8
    if targil_id == 8:
        abs_b = np.abs(data_df['b'].values)
        epsilon = sys.float_info.min
        log_val = np.log(abs_b, out=np.full_like(abs_b, 0.0, dtype=float), where=abs_b > epsilon)
        calculated_values = log_val + data_df['c'].values
        return pd.Series(calculated_values, index=data_df.index)

    elif targil_id == 7:
        calculated_values = np.sqrt(data_df['c'] ** 2 + data_df['d'] ** 2)
        return pd.Series(calculated_values, index=data_df.index)


    elif formula_condition is None:

        if targil_id in [7, 8]:

            return pd.Series(dtype=np.float64, index=data_df.index)  # החזרת סדרה ריקה/לא רלוונטית
        return data_df.eval(clean_formula_true, engine='numexpr')

    # טיפול בנוסחאות מותנות
    else:
        clean_formula_false = formula_false.replace('^', '**').replace('ABS', 'abs').replace('LOG', 'log').replace(
            'SQRT', 'sqrt')

        condition_mask = data_df.eval(formula_condition, engine='numexpr')

        calculated_values = np.where(
            condition_mask,
            data_df.eval(clean_formula_true, engine='numexpr'),
            data_df.eval(clean_formula_false, engine='numexpr')
        )
        return pd.Series(calculated_values, index=data_df.index)


def execute_fast_calculation():

    conn = None
    try:
        conn = connect_db()
        cursor = conn.cursor()
        print(">> החיבור למסד הנתונים הצליח.")

        # 1. טעינת הנוסחאות
        targil_df = pd.read_sql_query("SELECT targil_id, targil, tnai, targil_false FROM t_targil", conn)
        print(f">> נטענו {len(targil_df)} נוסחאות.")

        # 2. טעינת נתוני הבסיס (פעם אחת)
        start_data_load = time.time()
        data_df = pd.read_sql_query("SELECT data_id, a, b, c, d FROM t_data", conn)
        end_data_load = time.time()
        print(f">> נטענו {len(data_df)} רשומות נתונים בזמן של: {end_data_load - start_data_load:.2f} שניות.")

        # 3. לולאה על כל נוסחה
        for index, row in targil_df.iterrows():
            targil_id = row['targil_id']
            formula_true = row['targil']
            formula_condition = row['tnai']
            formula_false = row['targil_false']

            print(f"\n--- מתחיל חישוב עבור Targil ID: {targil_id} (נוסחה: {formula_true}) ---")

            # **מתחילים למדוד זמן כולל (חישוב + שמירה)**
            start_time = time.time()

            try:
                # א. ביצוע החישוב הווקטורי
                calculated_values = calculate_vectorized_result(data_df, formula_true, formula_condition, formula_false, targil_id)

                # ב. הכנת ה-DataFrame לשמירה (1,000,000 רשומות)
                results_batch = pd.DataFrame({
                    'data_id': data_df['data_id'],
                    'targil_id': targil_id,
                    'method': METHOD_NAME,
                    'result': calculated_values
                })

                # ג. שמירת הנתונים ל-t_result
                if ENGINE:
                    results_batch.to_sql(
                        't_result',
                        con=ENGINE,
                        if_exists='append',
                        index=False,
                        chunksize=50000
                    )
                    print(f">> שמירת {len(results_batch)} רשומות ל-t_result בוצעה.")
                else:
                    print("!! לא ניתן לשמור תוצאות: SQLAlchemy Engine אינו זמין.")

                # **מפסיקים למדוד זמן כולל**
                end_time = time.time()
                run_time = end_time - start_time
                print(f"** זמן כולל (חישוב + שמירה ל-DB): {run_time:.4f} שניות **")

                # ד. שמירת הלוג ל-t_log
                cursor.execute("""
                    INSERT INTO t_log (targil_id, method, run_time)
                    VALUES (?, ?, ?)
                """, targil_id, METHOD_NAME, run_time)
                conn.commit()

            except Exception as e:
                print(f"!! שגיאה קריטית בחישוב הנוסחה {targil_id}: {e}")
                print(f"!! נתיב שגיאה: {e.args[0] if e.args else 'לא ידוע'}")

    except Exception as e:
        print(f"שגיאה קריטית בחיבור או בטעינת הנתונים: {e}")
    finally:
        if conn:
            conn.close()
            print(">> חיבור למסד הנתונים נסגר.")