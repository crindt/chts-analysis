#!/bin/bash
# modified from: http://barbedwirebytecodebaconburger.wordpress.com/2009/08/03/migrating-an-old-ms-access-database-to-mysql/
DBFILE=$1
DBNAME=$2
BASENAME=`basename $1 .mdb`
OUTFILE=${BASENAME}-schema.sql
DIALECT=postgres

runtraced() {
    echo "$@"
    "$@"
}
tolower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}


#Check for correct number of arguments
if [ $# -lt 2 ]; then
echo "Usage: access2mysql.sh DBFILE DBNAME [DIALECT]"
echo "Example: access2mysql.sh msaccess.mdb mysql.sql"
exit 1
fi

if [ $# -eq 3 ]; then
    DIALECT=$3
fi
echo "Selected Dialect: $DIALECT"

#Check that DBFILE really exists
if [ ! -f $DBFILE ]; then
echo "$DBFILE does not exist."
exit 1
fi

#All is good, here we go!

#Create schema

mdb-schema --no-indexes $DBFILE $DIALECT > $OUTFILE
runtraced dropdb -U postgres ${DBNAME}
runtraced createdb -U postgres ${DBNAME}
psql -U postgres ${DBNAME} < $OUTFILE

#Export table data
TABLES=`mdb-tables $DBFILE`


for TT in $TABLES; do
    FTT=${BASENAME}-${TT}

    # Do the export on this table, escaping end of line records so we can handle
    # multiple line text fields
    mdb-export -Q -d '\t' -D '%Y-%m-%d %H:%M:%S' -R "XXTIANRXX" t.mdb "$TT" \

        # pipe the export through a perl filter to escape newlines in records
        | perl -p -e 's/^M\n/\\n/' \  # 

        # pipe again through a perl filter to escape quote characters
        | perl -p -e 's/"/""/g' | perl -p -e 's/XXTIANRXX/\n/g' \

        # send the result into a tsv file
        > ${TT}.tsv

    # Clean up some Windows-character stuff
    dos2unix ${TT}.tsv

    # Copy the tsv file into the appropriate database table
    runtraced psql -U postgres -c "\copy \"${TT}\" from '${TT}.tsv' using delimiters E'\t' with CSV header" ${DBNAME}
done

# DOWNCASE TABLE NAMES
for TT in $TABLES; do
    LTT=`tolower "${TT}"`
    runtraced psql -U postgres -c "ALTER TABLE \"${TT}\" RENAME TO \"${LTT}\"" ${DBNAME}
done


#dos2unix $OUTFILE
exit 0
