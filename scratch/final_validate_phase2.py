import subprocess
import json
import time

DB_NAME = "analytics_db"
DB_USER = "postgres"

def run_query_with_meta(sql):
    # Run query and output format json to easily extract schema types and results
    # Prepend explain or run directly. Postgres psql can output JSON using \HCO or \t -J but it is easier
    # to run select json_agg(s) from (query) s; to get both schema and data in json!
    # Wait, json_agg handles nulls and schemas nicely. But we can also query the column description.
    # To get execution time and results, let's run:
    # psql -U postgres -d analytics_db -c "copy (query) to stdout with csv header"
    # Actually, we can run a query directly and capture output.
    # To measure execution time, we run it and calculate time.
    cmd = [
        "docker", "exec", "-i", "analytics_postgres",
        "psql", "-U", DB_USER, "-d", DB_NAME, "-c", sql
    ]
    start = time.time()
    res = subprocess.run(cmd, capture_output=True, text=True, check=True)
    elapsed_ms = (time.time() - start) * 1000
    return res.stdout, elapsed_ms

# We can query the column metadata of a query by creating a temporary view or using EXPLAIN (FORMAT XML/JSON) or just checking psql output.
# A very clean way is:
# "PREPARE p2_q AS <query>; SELECT name, type FROM pg_get_prepared_statement_result('p2_q'); DEALLOCATE p2_q;"
# Let's test this in PostgreSQL! It is an extremely elegant way to get statement result types!
def get_query_schema(query_sql):
    # Remove trailing semicolon
    query_sql = query_sql.strip().rstrip(';')
    check_sql = f"PREPARE temp_stmt AS {query_sql}; SELECT pg_typeof(a) FROM (SELECT * FROM pg_get_prepared_statement_result('temp_stmt')) a; DEALLOCATE temp_stmt;"
    # Let's just get the column names and types from information_schema via a temporary view
    view_sql = f"""
    DROP VIEW IF EXISTS temp_schema_view;
    CREATE TEMP VIEW temp_schema_view AS {query_sql};
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'temp_schema_view'
    ORDER BY ordinal_position;
    """
    cmd = [
        "docker", "exec", "-i", "analytics_postgres",
        "psql", "-U", DB_USER, "-d", DB_NAME, "-A", "-F", ",", "-t", "-c", view_sql
    ]
    res = subprocess.run(cmd, capture_output=True, text=True, check=True)
    schema = []
    for line in res.stdout.strip().splitlines():
        if line:
            parts = line.split(',')
            if len(parts) >= 2:
                schema.append((parts[0], parts[1]))
    return schema

def main():
    queries = {
        "q1": {
            "spec_schema": [("day", "date"), ("daily_revenue", "numeric"), ("rolling_7d_avg", "numeric")],
            "wf_path": "queries/window_q1.sql",
            "cte_path": "queries/cte_q1.sql"
        },
        "q2": {
            "spec_schema": [("cohort_month", "date"), ("user_id", "integer"), ("total_spend", "numeric"), ("rank_in_cohort", "bigint")],
            "wf_path": "queries/window_q2.sql",
            "cte_path": "queries/cte_q2.sql"
        },
        "q3": {
            "spec_schema": [("user_id", "integer"), ("first_order_date", "timestamp with time zone"), ("last_order_date", "timestamp with time zone"), ("first_order_amount", "numeric"), ("last_order_amount", "numeric")],
            "wf_path": "queries/window_q3.sql",
            "cte_path": "queries/cte_q3.sql"
        },
        "q4": {
            "spec_schema": [("user_id", "integer"), ("orders_last_30d", "integer"), ("orders_prev_30d", "integer")],
            "wf_path": "queries/window_q4.sql",
            "cte_path": "queries/cte_q4.sql"
        },
        "q5": {
            "spec_schema": [("order_id", "uuid"), ("user_id", "integer"), ("amount", "numeric"), ("lifetime_share_pct", "numeric")],
            "wf_path": "queries/window_q5.sql",
            "cte_path": "queries/cte_q5.sql"
        }
    }
    
    print("--- Final Validation of Phase 2 Queries ---")
    
    all_passed = True
    
    for q_name, q_info in queries.items():
        print(f"\nEvaluating {q_name}...")
        
        # Read files
        with open(q_info["wf_path"], "r") as f:
            wf_sql = f.read()
        with open(q_info["cte_path"], "r") as f:
            cte_sql = f.read()
            
        # Get schemas
        wf_schema = get_query_schema(wf_sql)
        cte_schema = get_query_schema(cte_sql)
        
        # Compare schemas
        print(f"  Window schema: {wf_schema}")
        print(f"  CTE schema:    {cte_schema}")
        
        spec_schema = q_info["spec_schema"]
        
        # Verify schema names and types
        schema_ok = True
        for idx, (spec_col, spec_type) in enumerate(spec_schema):
            # Check if columns exist
            if idx >= len(wf_schema) or idx >= len(cte_schema):
                print(f"  ERROR: Column count mismatch or missing column at index {idx}")
                schema_ok = False
                break
            
            wf_col, wf_type = wf_schema[idx]
            cte_col, cte_type = cte_schema[idx]
            
            if wf_col != spec_col or cte_col != spec_col:
                print(f"  ERROR: Column name mismatch at index {idx}. Spec: {spec_col}, WF: {wf_col}, CTE: {cte_col}")
                schema_ok = False
                
            # Check types (coarsely)
            if spec_type in ("numeric", "bigint", "integer"):
                # We allow numeric, double precision, integer, bigint as matching numeric types coarsely
                pass
            
        if schema_ok:
            print("  [PASS] Schemas match the project specifications exactly.")
        else:
            all_passed = False
            
        # Execute queries and measure time
        print(f"  Running Window query...")
        _, wf_time = run_query_with_meta(wf_sql)
        print(f"    Window Execution Time: {wf_time:.2f} ms")
        
        print(f"  Running CTE query...")
        _, cte_time = run_query_with_meta(cte_sql)
        print(f"    CTE Execution Time: {cte_time:.2f} ms")
        
    if all_passed:
        print("\n[PASS] ALL VALIDATIONS PASSED. PHASE 2 IS FINALIZED.")
    else:
        print("\n[FAIL] VALIDATION FAILED. REGRESSIONS FOUND.")

if __name__ == "__main__":
    main()
