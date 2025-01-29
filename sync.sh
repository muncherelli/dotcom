#!/bin/bash

DB_PATH="$HOME/Library/Group Containers/9K33E3U3T4.net.shinyfrog.bear/Application Data/database.sqlite"

# check if the database exists
if [[ ! -f "$DB_PATH" ]]; then
  echo "DATABASE NOT FOUND!"
  exit 1
fi

echo "FOUND DATABASE."

# fetch json data from sqlite
JSON_DATA=$(sqlite3 "$DB_PATH" <<EOF
.headers on
.mode json
SELECT Z_PK AS ID, ZMODIFICATIONDATE FROM ZSFNOTE;
EOF
)

echo "COMPILED LIST OF LAST MODIFICATION DATES."

# send data to the server
curl -X POST -H "Content-Type: application/json" -d "$JSON_DATA" "http://localhost:42069/api/sync/note/poll"

echo "DATA SENT TO SERVER."
