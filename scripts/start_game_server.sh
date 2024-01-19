#!/bin/bash

LOG_FILE="${GAME_DIR}/${GAME_NAME}${GAME_LOG}"

# Find the last "Log file open" entry and return the line number
find_new_log_entries() {
  LAST_ENTRY_LINE=$(grep -n "Log file open" "$LOG_FILE" | tail -1 | cut -d: -f1)
  echo $((LAST_ENTRY_LINE + 1)) # Return the line number after the last "Log file open"
}

save_complete_check() {
  # Check if the "World Save Complete" message is in the log file
  if tail -n 10 "$LOG_FILE" | grep -q "World Save Complete"; then
    echo "Save operation completed."
    return 0
  else
    return 1
  fi
}

archive_logs() {
  if [ -f "${LOG_FILE}" ]; then
    local timestamp
    timestamp=$(date +%F-%T)
    mv "${LOG_FILE}" "${LOG_FILE}_${timestamp}.log"
  fi
}

start_logging_to_terminal () {
  # Wait for the log file to be created with a timeout
  #TODO: see if I can't clean this up
  echo "waiting for ${LOG_FILE}"
  local TIMEOUT
  TIMEOUT=120
  while [[ ! -f "${LOG_FILE}" && $TIMEOUT -gt 0 ]]; do
    sleep 1
    ((TIMEOUT--))
  done
  if [[ ! -f "${LOG_FILE}" ]]; then
    echo "Log file not found after waiting. Please check server status."
    return
  fi

}

run_server() {

  # Start the server with conditional arguments
  echo "Starting the ${GAME_NAME} server:"
  echo "Running: ${GAME_EXE} ${GAME_ARG}"
  wine "${GAME_DIR}/${GAME_NAME}${GAME_EXE}" \
    "${GAME_ARG}" 2>/dev/null &

  SERVER_PID=$!
  echo "Server process started with PID: $SERVER_PID"

  # Immediate write to PID file
  echo $SERVER_PID > $DIR/game.pid
  echo "PID $SERVER_PID written to $DIR/game.pid"

  start_logging_to_terminal

  # Find the line to start tailing from
  local START_LINE
  START_LINE=$(find_new_log_entries)

  # Tail the ShooterGame log file starting from the new session entries
  tail -n +"$START_LINE" -f "$LOG_FILE" &
  local TAIL_PID
  TAIL_PID=$!

  # Wait for the server to fully start
  echo "Waiting for server to start..."
  while true; do
  if grep -q "wp.Runtime.HLOD" "$LOG_FILE"; then
    echo "Server started. PID: $SERVER_PID"
    break
  fi
  sleep 10
done

# Wait for the server process to exit
wait $SERVER_PID

# Kill the tail process when the server stops
echo "Server is shuting down..."
kill $TAIL_PID
}

# Main function
main() {
  archive_logs
  run_server
}

# Start the main execution
main
