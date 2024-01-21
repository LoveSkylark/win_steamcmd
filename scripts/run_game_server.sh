#!/bin/bash

. ${DIR}/scripts/functions.sh

LOG_FILE="${GAME_DIR}/${GAME_NAME}${GAME_LOG}"

main() {

  archive_logs

  echo "${GAME_NAME}"
  echo "#########################  Updateing the game server #########################"
  # Update server if needed
  if check_for_updates; then
    run_update
  else
    echo "No update required. Server is up to date."
  fi

  # Start server and terminal
  echo "#########################  Staring the game server #########################"
  SERVER_PID=$(start_server) &

  logging_to_terminal
  
  # Wait for server exit
  wait $SERVER_PID

  #FIXME: needo to verifay or start the save proccess
  check_save_complete
  
  # Cleanup
  kill

}

# Start the main execution
main