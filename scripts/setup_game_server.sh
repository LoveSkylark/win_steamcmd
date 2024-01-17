
get_build_id_from_acf() {
  local acf_file="$GAME_DIR/$GAME_NAME/appmanifest_$GAME_ID.acf"
  if [[ -f "$acf_file" ]]; then
    local build_id
    build_id=$(grep -E "^\s+\"buildid\"\s+" "$acf_file" | grep -o '[[:digit:]]*')
    echo "$build_id"
  else
    echo ""
  fi
}

# Get the current build ID from SteamCMD API
get_build_id_from_api() {
  local build_id
  build_id=$(curl -sX GET "https://api.steamcmd.net/v1/info/$GAME_ID" | jq -r ".data.\"$GAME_ID\".depots.branches.public.buildid")
  echo "$build_id"
}

setup_server() {
  local saved_build_id
  saved_build_id=$(get_build_id_from_acf)
  local current_build_id
  current_build_id=$(get_build_id_from_api)

  if [ -z "$saved_build_id" ] || [ "$saved_build_id" != "$current_build_id" ]; then
    echo "New $GAME_NAME installation or update required..."
    touch $DIR/updating.flag
    echo "Current server build is $saved_build_id"
    echo "Updating server to build $current_build_id"
    USERNAME=anonymous
    wine "$STEAM_DIR/steamcmd.exe" +login "$USERNAME" +force_install_dir "$GAME_DIR/$GAME_NAME" +app_update "$GAME_ID" +@sSteamCmdForcePlatformType windows +quit  2>/dev/null
    
    # Copy the acf file to the persistent volume
    cp "$STEAM_DIR/steamapps/appmanifest_$GAME_ID.acf" "$GAME_DIR/$GAME_NAME/appmanifest_$GAME_ID.acf"
    echo "Installation or update completed successfully."
    rm -f $DIR/updating.flag
  else
    echo "No setup required. Server build ID $saved_build_id is up to date."
  fi
}


# Main function
main() {
  setup_server
}

# Start the main execution
main
