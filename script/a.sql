UPDATE pg_settings SET setting = 4 WHERE name = 'max_parallel_degree' AND version() ILIKE '%9.6dev%';

SELECT COUNT(*) FROM testsort;
