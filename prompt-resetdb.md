The dev database has schema changes applied from a migration on another branch. That branch's
migration files do not exist here, so there is no rollback command available.

Your job is to undo those schema changes manually:

1. Compare the current database schema against what main expects. Do this by:
   - Looking at the migration files that exist in this branch (apps/api) to understand the baseline
   - Querying the database to find tables or columns that exist in the DB but are not referenced
     in any migration file on this branch (those were added by the other branch)

2. Generate the inverse SQL to remove those changes (DROP TABLE, DROP COLUMN, etc.).
   Be careful with order — drop foreign keys and dependent objects before their parents.

3. Show me the SQL before running it and wait for my confirmation.

4. After confirmation, apply it and verify the schema matches what the migrations on this branch expect.
