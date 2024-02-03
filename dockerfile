# Use an image that has Wine installed to run Windows applications
# hadolint ignore=DL3007
FROM scottyhardy/docker-wine:latest

ARG RCON_CLI_VERSION="1.6.3"
ENV DEBIAN_FRONTEND="noninteractive"
ENV RDP_SERVER=no
ENV DISPLAY=":0"
ENV RESTART_NOTICE_MINUTES="5"

#Specific  game settings needed
ENV GAME_ID=""
ENV GAME_NAME=""
ENV GAME_EXE: ""
ENV GAME_ARG: ""
ENV GAME_LOG=""

# Folder Structure
ENV DIR="/usr/games"
ENV WINE_DIR="${DIR}/.wine/drive_c"
ENV STEAM_DIR="${WINE_DIR}/Steam"
ENV GAME_DIR="${WINE_DIR}/Steam/steamapps/common"

# Stored var
ENV PID_FILE="${DIR}/game.pid"
ENV UPDATE_FILE="${DIR}/updating.flag"
ENV TIME_FILE="${DIR}/last_update"

# Install jq, curl, and dependencies for rcon-cli
RUN apt-get update \
  && apt-get install --no-install-recommends --yes jq curl unzip nano bc sudo \
  && rm -rf /var/lib/apt/lists/*

# # Install RCON
# RUN curl -L "https://github.com/itzg/rcon-cli/releases/download/${RCON_CLI_VERSION}/rcon-cli_${RCON_CLI_VERSION}_linux_amd64.tar.gz" | tar xvz \
#   && mv rcon-cli /usr/local/bin/ \
#   && chmod +x /usr/local/bin/rcon-cli 

WORKDIR ${DIR}

# Install SteamCMD
RUN mkdir -p .wine/drive_c/Steam/steamapps/common \
  && curl -sL https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip -o steamcmd.zip \
  && unzip steamcmd.zip -d .wine/drive_c/Steam \
  && rm steamcmd.zip

COPY scripts/ ${DIR}/scripts/
COPY cron/ /etc/cron.d/



ENTRYPOINT ["./scripts/init.sh"]
