#!/bin/bash

# load environment variables
source .env

# logging function
log() {
    echo "[sync] $1"
}

# check if API_KEY is set
if [ -z "$API_KEY" ]; then
    log "Error: API_KEY not set in .env file"
    exit 1
fi

# check if API_URL is set
if [ -z "$API_URL" ]; then
    log "Error: API_URL not set in .env file"
    exit 1
fi

# Check if resync flag is set
RESYNC=false
if [ "$1" = "--resync" ]; then
    RESYNC=true
    log "Full resync requested..."
fi

# path to Bear.app database
BEAR_DB="$HOME/Library/Group Containers/9K33E3U3T4.net.shinyfrog.bear/Application Data/database.sqlite"

# check if database exists
if [ ! -f "$BEAR_DB" ]; then
    log "Error: Bear.app database not found at $BEAR_DB"
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

# If resync is requested, trigger the resync endpoint first
if [ "$RESYNC" = true ]; then
    log "Truncating tables via API..."
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $API_KEY" \
        "$API_URL/api/resync" > /dev/null
    log "Tables truncated."
fi

# step 1: query just PK and modification date in a more concise format
log "Querying Bear note modification dates..."
echo "SELECT json_object('ZMODIFICATIONDATES', json_group_object(Z_PK, ZMODIFICATIONDATE)) FROM ZSFNOTE;" | sqlite3 "$BEAR_DB" -json | jq -r '.[0] | to_entries[0].value' | jq . > "$TEMP_MOD_DATES"

# step 2: send to API to get list of changed IDs
log "Checking for changed notes..."
curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d @"$TEMP_MOD_DATES" \
    "$API_URL/api/check-modified-notes" > "$TEMP_CHANGED_IDS"

NUM_CHANGED=$(jq length "$TEMP_CHANGED_IDS")
log "$NUM_CHANGED notes to sync."

# step 3: query full details for changed IDs only
CHANGED_IDS=$(cat "$TEMP_CHANGED_IDS" | jq -r '.[]' | tr '\n' ',' | sed 's/,$//')

if [ ! -z "$CHANGED_IDS" ]; then
    log "Fetching full note data from Bear..."
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

    log "Uploading notes to API..."
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $API_KEY" \
        -d @"$TEMP_FULL_DATA" \
        "$API_URL/api/sync-bear-notes" > /dev/null
    log "Notes uploaded."
else
    log "No notes to sync."
fi

log "Sync completed!" 