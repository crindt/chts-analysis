--- Quick function to convert nulls to zero
CREATE FUNCTION null_to_zero (integer) RETURNS integer AS $$
 SELECT CASE WHEN $1 IS NULL THEN 0 ELSE $1 END
$$ LANGUAGE SQL;

--- function to get last element of arbitrarily sized array
--- from: http://stackoverflow.com/questions/2949881/getting-the-last-element-of-a-postgres-array-declaratively
CREATE FUNCTION last_elem (integer[]) RETURNS integer AS $$
 SELECT $1[array_upper($1,1)];
$$ LANGUAGE SQL;

--- function to get first element of array
CREATE FUNCTION first_elem (integer[]) RETURNS integer AS $$
 SELECT $1[1];
$$ LANGUAGE SQL;

--- convert 3am->3am hours to 3:00->27:00 for sorting purposes
CREATE FUNCTION thr (integer) RETURNS integer AS $$
 SELECT CASE WHEN $1 < 3 THEN $1+24 ELSE $1 END
$$ LANGUAGE SQL;

-- time difference in minutes
CREATE FUNCTION tdiff (integer,integer,integer,integer) RETURNS integer AS $$
 SELECT 60*thr($3)+$4 - (60*thr($1)+$2)
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION array_avg(double precision[])
RETURNS double precision AS $$
SELECT avg(v) FROM unnest($1) g(v)
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION array_max(double precision[])
RETURNS double precision AS $$
SELECT max(v) FROM unnest($1) g(v)
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION array_min(double precision[])
RETURNS double precision AS $$
SELECT min(v) FROM unnest($1) g(v)
$$ LANGUAGE sql;
