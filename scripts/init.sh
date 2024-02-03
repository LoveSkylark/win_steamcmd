#!/bin/bash

# Function to check if vm.max_map_count is set to a sufficient value
check_vm_max_map_count() {
  local required_map_count
  required_map_count=262144
  local current_map_count
  current_map_count=$(cat /proc/sys/vm/max_map_count)

  if [ "$current_map_count" -lt "$required_map_count" ]; then
    echo "ERROR: host vm.max_map_count is too low ($current_map_count), aneeds to be at least $required_map_count."
    echo ""
    echo "Run the following command on host to fix this issue:"
    echo "sudo -s echo "vm.max_map_count=$required_map_count" >> /etc/sysctl.conf && sudo sysctl -p"
    exit 1
  fi
}

# Main function
main() {
  check_vm_max_map_count
 
  # echo "Home dir: ${DIR}"
  # echo "Windows dir: ${WINE_DIR}"
  # echo "Steam dir: ${STEAM_DIR}"
  # echo "Game dir: ${GAME_DIR}/${GAME_NAME}/"
  
  ${DIR}/scripts/monitoring_game_server.sh &

  exec ${DIR}/scripts/run_game_server.sh
}

# Start the main execution
main