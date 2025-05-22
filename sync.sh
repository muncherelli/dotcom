#!/bin/bash

# load environment variables
source .env

# check if API_KEY is set
if [ -z "$API_KEY" ]; then
    echo "Error: API_KEY not set in .env file"
    exit 1
fi

# check if API_URL is set
if [ -z "$API_URL" ]; then
    echo "Error: API_URL not set in .env file"
    exit 1
fi

# path to Bear.app database
BEAR_DB="$HOME/Library/Group Containers/9K33E3U3T4.net.shinyfrog.bear/Application Data/database.sqlite"

# check if database exists
if [ ! -f "$BEAR_DB" ]; then
    echo "Error: Bear.app database not found at $BEAR_DB"
    exit 1
fi

# create temporary files
TEMP_MOD_DATES=$(mktemp)
TEMP_CHANGED_IDS=$(mktemp)
TEMP_FULL_DATA=$(mktemp)

# function to clean up temporary files
cleanup() {
    rm -f "$TEMP_MOD_DATES" "$TEMP_CHANGED_IDS" "$TEMP_FULL_DATA"
}

# set up trap to clean up on exit
trap cleanup EXIT

# step 1: query just PK and modification date in a more concise format
echo "SELECT json_object('ZMODIFICATIONDATES', json_group_object(Z_PK, ZMODIFICATIONDATE)) FROM ZSFNOTE;" | sqlite3 "$BEAR_DB" -json | jq -r '.[0] | to_entries[0].value' | jq . > "$TEMP_MOD_DATES"

# debug: show what we're sending
echo "Sending to API:"
cat "$TEMP_MOD_DATES"

# step 2: send to API to get list of changed IDs
curl -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d @"$TEMP_MOD_DATES" \
    "$API_URL/api/check-modified-notes" > "$TEMP_CHANGED_IDS"

# debug: show what we got back
echo "Received from API:"
cat "$TEMP_CHANGED_IDS"

# step 3: query full details for changed IDs only
# read the changed IDs and construct the SQL query
CHANGED_IDS=$(cat "$TEMP_CHANGED_IDS" | jq -r '.[]' | tr '\n' ',' | sed 's/,$//')

if [ ! -z "$CHANGED_IDS" ]; then
    echo "SELECT \
        Z_PK,\
        Z_ENT,\
        Z_OPT,\
        ZMODIFICATIONDATE,\
        ZTITLE,\
        ZTEXT,\
        ZSUBTITLE,\
        ZUNIQUEIDENTIFIER,\
        ZARCHIVED,\
        ZENCRYPTED,\
        ZHASFILES,\
        ZHASIMAGES,\
        ZHASSOURCECODE,\
        ZLOCKED,\
        ZORDER,\
        ZPERMANENTLYDELETED,\
        ZPINNED,\
        ZSHOWNINTODAYWIDGET,\
        ZSKIPSYNC,\
        ZTODOCOMPLETED,\
        ZTODOINCOMPLETED,\
        ZTRASHED,\
        ZVERSION,\
        ZPASSWORD,\
        ZSERVERDATA,\
        ZARCHIVEDDATE,\
        ZCONFLICTUNIQUEIDENTIFIERDATE,\
        ZCREATIONDATE,\
        ZLOCKEDDATE,\
        ZORDERDATE,\
        ZPINNEDDATE,\
        ZTRASHEDDATE,\
        ZCONFLICTUNIQUEIDENTIFIER,\
        ZENCRYPTIONUNIQUEIDENTIFIER,\
        ZLASTEDITINGDEVICE \
    FROM ZSFNOTE \
    WHERE Z_PK IN ($CHANGED_IDS);" | sqlite3 "$BEAR_DB" -json > "$TEMP_FULL_DATA"

    # step 4: send full data to API for upsert
    curl -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $API_KEY" \
        -d @"$TEMP_FULL_DATA" \
        "$API_URL/api/sync-bear-notes"
fi

echo "Sync completed!" 