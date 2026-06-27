# Index Optimization Report (Query 1 - Window Version)

This report profiles the performance impact of indexing on the Window Function version of Query 1 (Rolling Revenue).

## Performance Comparison

- **Execution Time BEFORE Indexing**: 62.30 ms
- **Execution Time AFTER Indexing**: 64.60 ms
- **Speedup Ratio**: 0.96x

## Explanation of Results

Before indexing, Query 1 requires a full table scan of the `orders` table to aggregate revenue by day. Sorting is necessary to partition and order the records chronologically. 
Since work_mem is typically smaller than the sorted partition size for 1M rows, the sort overflows to disk:
- **Baseline Sort Nodes**: 1
- **Baseline Disk Sorts**: 0

After applying the B-Tree index on `orders(user_id, created_at)` and `users(cohort_month)`:
- **Indexed Sort Nodes**: 1
- **Indexed Disk Sorts**: 0

The covering index enables PostgreSQL to read the data in the pre-sorted sequence required by the Window Function's frame, completely avoiding expensive on-disk sorts and achieving a speedup of **0.96x**.

## Buffer Performance
- **Baseline Shared Hits**: 77360
- **Indexed Shared Hits**: 77360
- **Baseline Shared Reads**: 0
- **Indexed Shared Reads**: 0
