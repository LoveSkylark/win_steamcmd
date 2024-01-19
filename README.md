# win_steamcmd
A Docker container that runs the Windows version of the SteamCMD command line tool through Wine to host a dedicated Steam game server on Linux.

## Overview
his Docker image eliminates the need for a dedicated Windows or Windows VM server by running SteamCMD through Wine. It provides an easy way to leverage SteamCMD's capabilities for game updates, installation and management on Linux systems.

The image is built on the `scottyhardy/docker-wine` Docker image and uses bash scripts to handle server startup, installation, updating and monitoring.


> This project was originally based on the excellent work done by Acekorneya/Ark-Survival-Ascended-Server and camalot/Ark-Survival-Ascended-Server. Their designs focused on hosting the game "ARK - Survival Ascended".

> This project aims to generalize and simplify their work to allow hosting dedicated Steam servers for any Windows-based game on Linux using Docker.

## Usage
**win_steamcmd** docker needs to know five things so it can run a game server:
1. `GAME_ID` - The Steam Application ID used to identify the game, this can be found at [SteamDB](https://steamdb.info/apps/)
2. `GAME_NAME` - The exact name of the game name used to construct the folder in **/steamapps/common/**
3. `GAME_EXE` - Location of the server executable with in the `GAME_NAME` folder.
4. `GAME_ARG` - The arguments used to configure[^1] he server no FIXME:
5. `GAME_LOG` - Location game Log, used for healthmonitoring of the container and outpintig log FIXME:

[^1]: Any configuration not suportead as an argument can be done by volume mapping config files into the container (*see [games/ARK Survival Ascended Dedicated Server/docker-compose.yaml](https://github.com/LoveSkylark/win_steamcmd/blob/main/games/ARK%20Survival%20Ascended%20Dedicated%20Server/docker-compose.yaml) for an example*)


### 



## Copy
docker build -t win_steamcmd .
docker run -it --rm -v <path/to/steam/depot>:/home/steamcmd win_steamcmd <commands>
Mount the local Steam depot folder (where game files are stored) into the container so SteamCMD can access them.

Then pass SteamCMD commands as arguments, such as:

Copy
docker run -it --rm -v /path/to/steam/depot:/home/steamcmd win_steamcmd force_install_dir 730 validate
To update a specific appid.

Things to note
Wine is used to run SteamCMD in a Windows-like environment. Performance may vary.
The base image is debian:buster-slim for a small final image size.
Make sure to mount the local Steam depot folder for game files to be accessible.
Pass SteamCMD commands as arguments when running the container.
Any cached files or configs in /home/steamcmd will persist between runs.
Let me know if any part of the README needs more explanation or examples!