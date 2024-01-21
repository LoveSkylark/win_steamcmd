#!/bin/bash

is_server_updating() {
  if ! [ -f "${DIR}/updating.flag" ]; then
    return 1 
  fi
}

main() {
  fi !(is_server_updating); then
    echo "Checking if server is up to date"
    
    if check_for_updates; then
      notify_players
      send_rcon_command "saveworld"
      #update only
      #restart only
      restart_server
    fi
  fi
}

# Start the main execution
main