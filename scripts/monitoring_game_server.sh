#!/bin/bash

. ${DIR}/scripts/functions.sh

main_loop() {
  CHECK_INTERVAL=3600
  LAST_CHECK_TIME=$(check_last_update_check)
  echo "Update last checked: $LAST_CHECK_TIME"

  if !(is_time_to_check ${LAST_CHECK_TIME}) && !(is_server_updating); then
    echo "Checking if server is up to date"
    
    if check_for_updates; then
      notify_players
      send_rcon_command "saveworld"
      restart_server
    fi
  fi

  if !(is_process_running) && !(is_server_updating); then
    echo "Server not found, starting server"
    start_server
  fi
  sleep 30
}

main() {

  # Waiting for server to start before turning on  monitoring
  sleep 3600
  
  #start monitoring
  echo "Server monitoring has started"
  while true; do
    main_loop
  done
}

# Start the main execution
main