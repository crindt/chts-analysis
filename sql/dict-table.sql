DROP TABLE IF EXISTS DICTTABLE;
CREATE TABLE DICTTABLE (
       itemno   CHARACTER(10) PRIMARY KEY,
       varname  VARCHAR,
       vardesc  VARCHAR,
       progname VARCHAR,
       program  VARCHAR,
       multresp BOOLEAN,
       datatype CHARACTER(1),
       width    FLOAT,
       vals     VARCHAR,
       question VARCHAR,
       skips    VARCHAR,
       cond     VARCHAR
);
