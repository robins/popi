CREATE TABLE testsort (b TEXT);

INSERT INTO testsort(b) SELECT md5(i::TEXT) FROM generate_series(1,10000) as o(i);
