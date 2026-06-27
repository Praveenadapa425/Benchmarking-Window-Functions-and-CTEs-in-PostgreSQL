# Graph Traversal: Window Functions vs. Recursive CTEs

This report analyzes the limitations of Window Functions when dealing with hierarchical or graph-structured data (such as referral chains) and explains why Common Table Expressions (`WITH RECURSIVE`) are required.

## The Referral Chain Depth Problem

We are tasked with finding the complete referral chain depth for the top 100 users. For example, if User A refers User B, and User B refers User C, the path is `A -> B -> C`, which represents a referral depth of 3.

This relationship is represented in the database as an adjacency list: the `users` table has a `referred_by` column pointing back to `users.user_id`.

## Why Window Functions Cannot Solve This

Window functions operate on a **sliding frame** or partition of an *existing, static* result set. They are designed to calculate aggregates (running totals, averages, ranks) over rows that are already retrieved by the query. 

They cannot traverse relationships to discover new rows dynamically for several key reasons:

### 1. The "Fixed Window" Constraint
Window functions require a defined, static subset of rows (the "window") specified by `PARTITION BY` and `ORDER BY`. The size of this window is fixed relative to the query's current row. 
A window function has no mechanism to:
- Follow a pointer (foreign key) from the current row to a parent row.
- Fetch additional rows that were not part of the initial scan.
- Carry state across arbitrary parent-child levels.

### 2. The "Variable Depth" Constraint
Hierarchical data structures have a variable and unknown depth. The referral chain could be 1 level deep, 8 levels deep, or 100 levels deep. 

To solve this using standard joins or window functions, you would need to hardcode a specific number of self-joins:
- A 3-level depth requires joining the `users` table 3 times.
- A 100-level depth requires joining the `users` table 100 times.

If the tree depth exceeds your hardcoded joins, the query fails to find the full depth. If the tree is shallow, the extra joins waste database resources. Window functions cannot dynamically scale the number of joins or iterations based on the data.

## The Recursive CTE Solution

PostgreSQL's `WITH RECURSIVE` solves this by executing an iterative loop:

1. **Anchor Member**: Selects the starting nodes (the top 100 users).
2. **Recursive Member**: Joins the previous iteration's result set with the `users` table (`u.referred_by = rt.user_id`).
3. **Termination**: The query automatically terminates when a recursive step returns zero rows (i.e., when the bottom of all referral chains is reached).

This allows the database to traverse the graph to arbitrary depths dynamically, representing the only native way to solve graph traversal and hierarchical queries in SQL.
