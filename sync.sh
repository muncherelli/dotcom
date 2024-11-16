#!/bin/bash

# start the overall timer
script_start_time=$(date +%s)

# function to display elapsed time for each step
log_with_time() {
  step_start_time=$1
  message=$2
  current_time=$(date +%s)
  elapsed=$((current_time - step_start_time))
  printf "[%ds] %s\n" "$elapsed" "$message"
}

# load environment variables
set -a
source .env
set +a

# default variables with ability to override via .env
NOTE_SYNC_ENABLED=${NOTE_SYNC_ENABLED:-false}
FILE_SYNC_ENABLED=${FILE_SYNC_ENABLED:-false}
FILE_SYNC_PARALLEL=${FILE_SYNC_PARALLEL:-5}
NOTE_SYNC_DIRECTORY=${NOTE_SYNC_DIRECTORY:-"$HOME/Library/Group Containers/9K33E3U3T4.net.shinyfrog.bear/Application Data"}
NOTE_SYNC_DATABASE=${NOTE_SYNC_DATABASE:-"$NOTE_SYNC_DIRECTORY/database.sqlite"}
FILE_SYNC_DIRECTORY=${FILE_SYNC_DIRECTORY:-"$NOTE_SYNC_DIRECTORY/Local Files"}
NOTE_SYNC_COMPRESS=${NOTE_SYNC_COMPRESS:-true}

# ensure required environment variables for file sync are set
if [[ -z "$FILE_SYNC_USER" || -z "$FILE_SYNC_PASSWORD" || -z "$FILE_SYNC_HOST" || -z "$FILE_SYNC_REMOTE_DIRECTORY" || -z "$FILE_SYNC_PARALLEL" || -z "$FILE_SYNC_DIRECTORY" ]]; then
  step_start_time=$(date +%s)
  log_with_time $step_start_time "Error: Required environment variables for file sync are missing"
  exit 1
fi

# delete files quietly
delete_files() {
  if [ -f "$1" ]; then
    rm "$1"
  fi
}

# perform file sync if enabled
if [ "$FILE_SYNC_ENABLED" = "true" ]; then
  step_start_time=$(date +%s)
  echo "Starting file sync"
  lftp -u "$FILE_SYNC_USER","$FILE_SYNC_PASSWORD" "$FILE_SYNC_HOST" <<EOF
set ftp:ssl-allow no
mirror -R --parallel=$FILE_SYNC_PARALLEL "$FILE_SYNC_DIRECTORY" "$FILE_SYNC_REMOTE_DIRECTORY"
bye
EOF
  log_with_time $step_start_time "File sync completed successfully"
else
  step_start_time=$(date +%s)
  log_with_time $step_start_time "File sync is disabled"
fi

# perform note sync if enabled
if [ "$NOTE_SYNC_ENABLED" = "true" ]; then
  step_start_time=$(date +%s)
  log_with_time $step_start_time "Starting note sync"

  # define the database and output file paths
  DATABASE="$NOTE_SYNC_DATABASE"
  OUTPUT_FILE=".notes_$(date +%s).json"  # create a dotfile with a random name based on timestamp
  TAR_FILE="notes.tar.gz"

  # define the tables and columns to extract
  tables=(
      "ZSFNOTE:Z_PK, ZUNIQUEIDENTIFIER"
      "ZSFNOTEFILE:Z_PK, ZUNIQUEIDENTIFIER"
  )

  # initialize combined json output
  combined_output="{}"

  for table_info in "${tables[@]}"; do
    step_start_time=$(date +%s)
    # split the table info into table name and columns
    IFS=':' read -r table columns <<< "$table_info"
    log_with_time $step_start_time "Extracting data from table $table"

    # extract data from the sqlite database in json format for the given columns
    table_json=$(sqlite3 "$DATABASE" -json "SELECT $columns FROM $table;")

    # update the combined json output with the current table data, keyed by Z_PK
    combined_output=$(echo "$combined_output" | jq --arg table "$table" --argjson data "$table_json" '. + {($table): ($data | map({(.Z_PK | tostring): .}) | add)}')
    log_with_time $step_start_time "Extraction from table $table completed"
  done

  step_start_time=$(date +%s)
  # save the combined json output to the output file
  echo "$combined_output" | jq '.' > "$OUTPUT_FILE"
  log_with_time $step_start_time "Note sync completed successfully"

  # if compression is enabled, compress the output
  if [ "$NOTE_SYNC_COMPRESS" = "true" ]; then
    step_start_time=$(date +%s)
    original_size=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
    echo "Compressing $OUTPUT_FILE ($original_size)"
    tar -czf "$TAR_FILE" "$OUTPUT_FILE"
    compressed_size=$(ls -lh "$TAR_FILE" | awk '{print $5}')
    log_with_time $step_start_time "Compression completed successfully: $compressed_size"

    # delete the json file after compression
    delete_files "$OUTPUT_FILE"

    # upload compressed file
    step_start_time=$(date +%s)
    echo "Uploading $TAR_FILE"
    lftp -u "$FILE_SYNC_USER","$FILE_SYNC_PASSWORD" "$FILE_SYNC_HOST" <<EOF
set ftp:ssl-allow no
put "$TAR_FILE" -o "$FILE_SYNC_REMOTE_DIRECTORY/$(basename "$TAR_FILE")"
bye
EOF
    log_with_time $step_start_time "Upload of $TAR_FILE completed successfully"

    # delete the tar file after upload
    delete_files "$TAR_FILE"
  else
    # upload uncompressed file
    step_start_time=$(date +%s)
    echo "Uploading $OUTPUT_FILE"
    lftp -u "$FILE_SYNC_USER","$FILE_SYNC_PASSWORD" "$FILE_SYNC_HOST" <<EOF
set ftp:ssl-allow no
put "$OUTPUT_FILE" -o "$FILE_SYNC_REMOTE_DIRECTORY/$(basename "$OUTPUT_FILE")"
bye
EOF
    log_with_time $step_start_time "Upload of $OUTPUT_FILE completed successfully"

    # delete the json file after upload
    delete_files "$OUTPUT_FILE"
  fi

else
  step_start_time=$(date +%s)
  log_with_time $step_start_time "Note sync is disabled"
fi

# calculate and print the total script execution time
script_end_time=$(date +%s)
total_elapsed=$((script_end_time - script_start_time))
printf "Script completed in %ds\n" "$total_elapsed"
