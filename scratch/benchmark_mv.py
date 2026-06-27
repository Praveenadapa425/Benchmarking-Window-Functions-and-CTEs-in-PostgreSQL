import subprocess
import time

DB_NAME = "analytics_db"
DB_USER = "postgres"

def run_sql(sql):
    cmd = [
        "docker", "exec", "-i", "analytics_postgres",
        "psql", "-U", DB_USER, "-d", DB_NAME, "-q", "-t", "-A"
    ]
    res = subprocess.run(cmd, input=sql, text=True, capture_output=True, check=True)
    return res.stdout.strip()

def main():
    print("--- Materialized View Strategy Benchmarks ---")
    
    # Read materialized view SQL definition
    with open("queries/materialized_view.sql", "r") as f:
        mv_sql = f.read()
        
    # Read Query 1 Window Function
    with open("queries/window_q1.sql", "r") as f:
        q1_sql = f.read()

    # Drop existing view
    print("Dropping existing Materialized View if any...")
    run_sql("DROP MATERIALIZED VIEW IF EXISTS daily_revenue_stats;")
    
    # 1. Measure initial creation time
    print("Creating Materialized View daily_revenue_stats...")
    start = time.time()
    run_sql(mv_sql)
    create_time_ms = (time.time() - start) * 1000
    print(f"  Initial Creation Time: {create_time_ms:.2f} ms")
    
    # Verify existence
    exists = run_sql("SELECT count(*) FROM pg_matviews WHERE matviewname = 'daily_revenue_stats';")
    print(f"  Exists in pg_matviews? Count = {exists}")
    
    # 2. Compare read performance
    print("Benchmarking read performance...")
    
    # Read from raw window function query
    # Run once to warm up
    run_sql(q1_sql)
    start = time.time()
    run_sql(q1_sql)
    wf_read_time_ms = (time.time() - start) * 1000
    print(f"  Raw Window Function Query Read Time: {wf_read_time_ms:.2f} ms")
    
    # Read from materialized view
    # Run once to warm up
    run_sql("SELECT * FROM daily_revenue_stats;")
    start = time.time()
    run_sql("SELECT * FROM daily_revenue_stats;")
    mv_read_time_ms = (time.time() - start) * 1000
    print(f"  Materialized View Read Time: {mv_read_time_ms:.2f} ms")
    
    # Calculate speedup
    speedup = wf_read_time_ms / mv_read_time_ms if mv_read_time_ms > 0 else 1.0
    print(f"  Read Speedup Ratio: {speedup:.2f}x")
    
    # 3. Insert 10,000 new orders
    print("Inserting 10,000 new orders...")
    insert_sql = """
    INSERT INTO orders (order_id, user_id, product_id, amount, status, created_at, updated_at)
    SELECT
        gen_random_uuid(),
        floor(1 + 199999 * power(random(), 5.0))::int,
        floor(1 + random() * 100)::int,
        round((random() * 495 + 5.00)::numeric, 2),
        'completed',
        CURRENT_DATE,
        NOW()
    FROM generate_series(1, 10000) i;
    """
    run_sql(insert_sql)
    
    # 4. Measure REFRESH time
    print("Refreshing Materialized View...")
    start = time.time()
    run_sql("REFRESH MATERIALIZED VIEW daily_revenue_stats;")
    refresh_time_ms = (time.time() - start) * 1000
    print(f"  Refresh Time: {refresh_time_ms:.2f} ms")

if __name__ == "__main__":
    main()
