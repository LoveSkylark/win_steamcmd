function get_saved_build_id() {
  local saved_id
  local acf_file="$GAME_DIR/$GAME_NAME/appmanifest_$GAME_ID.acf"

  if [[ ! -f "$acf_file" ]]; then
    >&2 echo "No running game version found"
    return 1
  fi
  
  if ! saved_id=$(grep -E "^\s+\"buildid\"" "${acf_file}" | grep -o '[[:digit:]]*'); then
    >&2 echo "Error getting saved ID"
    return 1
  fi

  echo "$saved_id"
}

function get_current_build_id() {
  local current_id

  if ! current_id=$(curl -s "https://api.steamcmd.net/v1/info/${GAME_ID}" | jq -r ".data.\"${GAME_ID}\".depots.branches.public.buildid"); then
    >&2 echo "Error getting current ID"
    return 1
  fi

  echo "$current_id"
}

function check_for_updates() {
  local saved_id
  local current_id
  
  saved_id=$(get_saved_build_id)
  if [[ ! -z "$saved_id" ]]; then 
    echo "Server game verion: $saved_id"
  fi

  if [[ $? -ne 0 ]]; then
    >&2 echo "Error getting saved ID"
    return 1
  fi
  
  current_id=$(get_current_build_id)
  echo "Newest game verion: $current_id"

  if [[ $? -ne 0 ]]; then
    >&2 echo "Error getting current ID"
    return 1
  fi

  if [[ "$saved_id" == "$current_id" ]]; then
    return 1
  fi
}

function run_update() {
    local username=anonymous
    local acf_file="$GAME_DIR/$GAME_NAME/appmanifest_$GAME_ID.acf"
    
    touch "${DIR}/updating.flag"
    echo "Staring to update the Server."
    echo ""
    wine "${STEAM_DIR}/steamcmd.exe" +login "${username}" +force_install_dir "${GAME_DIR}/${GAME_NAME}" +app_update "$GAME_ID" +@sSteamCmdForcePlatformType windows +quit  2>/dev/null
    
    # Copy the acf file to the persistent volume
    echo "${STEAM_DIR}/steamapps/appmanifest_$GAME_ID.acf" 
    echo $acf_file

    cp "${STEAM_DIR}/steamapps/appmanifest_$GAME_ID.acf" "${acf_file}"
    
    return 1
    echo "Installation or update completed successfully."
    rm -f ${DIR}/updating.flag
}

function start_server() {
  local server_exe="${GAME_DIR}/${GAME_NAME}${GAME_EXE}"

  # Start server process in background
  wine "${server_exe}" "${GAME_ARG}" &> /dev/null &

  # Save PID of server process
  local server_pid=$!

  # Write PID to file
  echo "${server_pid}" > "${DIR}/game.pid"

  # Check for error writing PID
  if [[ $? -ne 0 ]]; then
    echo "Error writing PID file" >&2
    kill "${server_pid}"
    return 1
  fi
  echo "Server has started"
  # Wait for server to be ready before providing PID
  while ! wait_for_ready; do sleep 10; done

  # Return PID on success
  echo "${server_pid}"
}
function restart_server() {
  echo "Gracefully shutting down the Game server..."
  send_rcon_command "DoExit"

  # Wait for a bit to ensure the server has completely shut down
  sleep 30

  echo "Starting the Game server..."

  start_server

}

function is_process_running() {
  # if PID file exist check if proccess with same number is running
  if [ -f "$PID_FILE" ]; then
    local pid
    pid="$(cat "$PID_FILE")"

    if ! ps -p "$pid" >/dev/null 2>&1; then
      return 1
    fi
  fi
}

function is_server_updating() {
  if ! [ -f "${DIR}/updating.flag" ]; then
    return 1 
  fi
}

function check_save_complete() {
  #FIXME:
  if tail -n 10 "$LOG_FILE" | grep -q -v "World Save Complete"; then
    echo "Save operation did not complete" >&2
    return 1
  fi
  echo "Save operation completed."
}

function archive_logs() {

  if [[ -f "${LOG_FILE}" ]]; then

    local timestamp
    timestamp=$(date +"%F-%T")

    # Append timestamp to filename
    local archive_file="${LOG_FILE}_${timestamp}.log"

    # Move the log file to archived name
    mv "${LOG_FILE}" "${archive_file}"

    if [[ $? -ne 0 ]]; then
      echo "Error archiving log file" >&2
      return 1
    fi

  fi
}

function logging_to_terminal() {
  local TIMEOUT=120

  echo "Waiting for Log to be created..."

  while [[ ! -f "$LOG_FILE" && $TIMEOUT -gt 0 ]]; do
    sleep 1
    ((TIMEOUT--))
  done

  if [[ ! -f "$LOG_FILE" ]]; then
    echo "Log file not found after waiting. Exiting."
    exit 1
  fi

  echo "Log file found server may take some finish to startup"
  echo ""

  local last_entry_line=$(grep -n "Log file open" "$LOG_FILE" | tail -1 | cut -d: -f1)
  local start_line=$((last_entry_line + 1))
  tail -n +$start_line -f "${LOG_FILE}"
  # Save PID of tail process
  local tail_pid=$!
}

function wait_for_ready() {
  #FIXME: still ARK specific
  grep -q "wp.Runtime.HLOD" "${LOG_FILE}" 2>/dev/null
}

function notify_players() {

  local minutes_remaining=$RESTART_NOTICE_MINUTES
  while [ "$minutes_remaining" -gt 1 ]; do
    send_rcon_command "Say Restarting in $minutes_remaining minutes"  
    sleep 60
    minutes_remaining=$((minutes_remaining - 1))
  done

  local seconds_remaining=60
  while [ "$minutes_remaining" -le 1 ] && [ "$minutes_remaining" -gt 0 ]; do
    send_rcon_command "Say Restarting in $seconds_remaining seconds"
    sleep 10
    seconds_remaining=$((seconds_remaining - 10))
  done
}

function send_rcon_command() {
  rcon-cli --host "localhost" --port "${RCON_PORT:-27020}" --password "${SERVER_ADMIN_PASSWORD}" $1
}

