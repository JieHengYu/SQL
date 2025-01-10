CREATE TABLE vacuum_test(
	integer_column integer
);

SELECT pg_size_pretty(
	pg_total_relation_size('vacuum_test')
);

INSERT INTO vacuum_test
SELECT * FROM generate_series(1, 500000);

SELECT pg_size_pretty(
	pg_total_relation_size('vacuum_test')
);

UPDATE vacuum_test
SET integer_column = integer_column + 1;

SELECT pg_size_pretty(
	pg_total_relation_size('vacuum_test')
);

SELECT relname,
       last_vacuum,
       last_autovacuum,
       vacuum_count,
       autovacuum_count
FROM pg_stat_all_tables
WHERE relname = 'vacuum_test';

SELECT pg_size_pretty(
	pg_total_relation_size('vacuum_test')
);

VACUUM vacuum_test;

SELECT relname,
       last_vacuum,
       last_autovacuum,
       vacuum_count,
       autovacuum_count
FROM pg_stat_all_tables
WHERE relname = 'vacuum_test';

VACUUM FULL vacuum_test;

SELECT pg_size_pretty(
	pg_total_relation_size('vacuum_test')
);

SHOW config_file;

SHOW data_directory;
