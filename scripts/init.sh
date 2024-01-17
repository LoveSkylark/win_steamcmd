#!/bin/bash

# Function to check if vm.max_map_count is set to a sufficient value
check_vm_max_map_count() {
  local required_map_count
  required_map_count=262144
  local current_map_count
  current_map_count=$(cat /proc/sys/vm/max_map_count)

  if [ "$current_map_count" -lt "$required_map_count" ]; then
    echo "ERROR: The vm.max_map_count on the host system is too low ($current_map_count) and needs to be at least $required_map_count."
    echo "To fix this issue run the following command on your Docker host:"
    echo ""
    echo "sudo -s echo "vm.max_map_count=$required_map_count" >> /etc/sysctl.conf && sudo sysctl -p"
    exit 1
  fi
}



# Main function
main() {
  check_vm_max_map_count
  ${DIR}/scripts/setup_game_server.sh
  # Start monitoing the server
  # ./scripts/monitor_ASA.sh &
  exec ./scripts/start_game_server.sh
}

# Start the main execution
main