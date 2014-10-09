#!/bin/bash

TYPES="HH PER ACTIVITY VEH PLACE LD LookUp_Home LookUp_Per LookUp_Place LookUp_LD ASSN_TravelDate Fips Make TRANSYS SERIES"

for xlssheet in ${TYPES}; do 
    # create CSV
    csv=datadict-${xlssheet}.csv
    /usr/local/bin/xls2csv -x Caltrans_matrix_updated_12162013_deliv_IncludingLookUpTables.xls -w ${xlssheet} -c $csv

    # create dict table
    lc=`echo $xlssheet | tr '[:upper:]' '[:lower:]'`  # make name lowercase
    tbl=dict_"$lc"
    cat dict-table.sql | sed "s/DICTTABLE/"$tbl"/g" | psql -U postgres chts-2010
    psql -U postgres -c "\copy $tbl (itemno, varname, vardesc, progname, program, multresp, datatype, width, vals, question, skips, cond) FROM '$csv' WITH CSV HEADER" chts-2010
done

