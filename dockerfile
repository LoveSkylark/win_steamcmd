# Use an image that has Wine installed to run Windows applications
# hadolint ignore=DL3007
FROM scottyhardy/docker-wine:latest

# Add ARG for PUID and PGID with a default value
ENV PUID="1001"
ENV PGID="1001"
ARG INI_FILE_VERSION="1.4.6"
ARG RCON_CLI_VERSION="1.6.3"
ENV DEBIAN_FRONTEND="noninteractive"
ENV RDP_SERVER=no
ENV DISPLAY=":0"

#specific  game settings needed
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
ENV PID_FILE="${DIR}/game.pid"

# Install jq, curl, and dependencies for rcon-cli
RUN apt-get update \
  && apt-get install --no-install-recommends --yes jq curl unzip nano bc cron \
  && rm -rf /var/lib/apt/lists/*

RUN touch /var/log/cron.log

# Install RCON
RUN curl -L "https://github.com/itzg/rcon-cli/releases/download/${RCON_CLI_VERSION}/rcon-cli_${RCON_CLI_VERSION}_linux_amd64.tar.gz" | tar xvz \
  && mv rcon-cli /usr/local/bin/ \
  && chmod +x /usr/local/bin/rcon-cli 

# Install INI-FILE editor
RUN curl -L "https://github.com/bitnami/ini-file/releases/download/v${INI_FILE_VERSION}/ini-file-linux-amd64.tar.gz" | tar xvz \
  && mv ini-file-linux-amd64 /usr/local/bin/ini-file \
  && chmod +x /usr/local/bin/ini-file

# Install SteamCMD
RUN mkdir -p .wine/drive_c/Steam/steamapps/common \
  && curl -sL https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip -o steamcmd.zip \
  && unzip steamcmd.zip -d .wine/drive_c/Steam \
  && rm steamcmd.zip




COPY scripts/ ${DIR}/scripts/
COPY cron/ /etc/cron.d/

USER games
WORKDIR ${DIR}

ENTRYPOINT ["./scripts/init.sh"]
