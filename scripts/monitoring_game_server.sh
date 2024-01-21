#!/bin/bash

. ${DIR}/scripts/functions.sh

is_process_running() {
  # if PID file exist check if proccess with same number is running
  if [ -f "$PID_FILE" ]; then
    local pid
    pid="$(cat "$PID_FILE")"

    if ! ps -p "$pid" >/dev/null 2>&1; then
      return 1
    fi
  fi
}

is_server_updating() {
  if ! [ -f "${DIR}/updating.flag" ]; then
    return 1 
  fi
}


is_time_to_check() {
  local current_time="$(date +%s)" 
  # local interval_seconds=$((CHECK_INTERVAL * 3600))
  local interval_seconds=$((CHECK_INTERVAL * 60))
   
  if (( $current_time - ${1} > $interval_seconds )); then
    echo "XX Triggered update"
    ${1}=$current_time
    echo "XXA $LAST_CHECK_TIME"
    return 1
  fi
}

main_loop() {
  CHECK_INTERVAL=1
  LAST_CHECK_TIME="${LAST_CHECK_TIME:-0}"
  echo "XXB $LAST_CHECK_TIME"

  if !(is_time_to_check ${LAST_CHECK_TIME}) && !(is_server_updating); then
    echo "Checking if server is up to date"
    
    if check_for_updates; then
      notify_players
      send_rcon_command "saveworld"
      #update only
      #restart only
      restart_server
    fi
  fi

  if !(is_process_running) && !(is_server_updating); then
    echo "Server not found, starting server"
    start_server
  fi
  echo "XX loop is running"
  sleep 10
}

main() {

  # waiting for server to start before turning on  monitoring
  while !(is_process_running); do
    sleep 5
  done

  #start monitoring
  echo "Server monitoring has started"
  while true; do
    main_loop
  done
}

# Start the main execution
main